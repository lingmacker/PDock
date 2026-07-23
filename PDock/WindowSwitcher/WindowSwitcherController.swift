import AppKit
import ApplicationServices
@preconcurrency import CoreGraphics
import Observation

enum WindowSwitcherState: Equatable {
    case stopped
    case needsPermissions
    case running
    case failed
}

struct SwitcherWindow: Identifiable, @unchecked Sendable {
    let id: WindowIdentity
    var title: String
    let applicationName: String
    let applicationIcon: NSImage
    var frame: CGRect
    var isMinimized: Bool
    let element: AXUIElement

    var switchableWindow: SwitchableWindow {
        SwitchableWindow(id: id, title: title, frame: frame, isMinimized: isMinimized)
    }
}

struct WindowSwitcherCard: Identifiable, @unchecked Sendable {
    let id: WindowIdentity
    let title: String
    let applicationName: String
    let applicationIcon: NSImage
    var thumbnail: WindowThumbnail
}

@MainActor
@Observable
final class WindowSwitcherController {
    private(set) var state: WindowSwitcherState = .stopped
    private(set) var isPresented = false

    @ObservationIgnored private let panelController = WindowSwitcherPanelController()
    @ObservationIgnored private let thumbnailCapturer: any WindowThumbnailCapturing
    @ObservationIgnored private let activator = WindowActivator(system: LiveWindowActivationSystem())
    @ObservationIgnored private var eventTap: CFMachPort?
    @ObservationIgnored private var eventTapSource: CFRunLoopSource?
    @ObservationIgnored private var workspaceObservers: [NSObjectProtocol] = []
    @ObservationIgnored private var mouseMonitor: Any?
    @ObservationIgnored private var captureTask: Task<Void, Never>?
    @ObservationIgnored private var reconcileTask: Task<Void, Never>?
    @ObservationIgnored private var recentWindowTask: Task<Void, Never>?
    @ObservationIgnored private var windows: [SwitcherWindow] = []
    @ObservationIgnored private var recentWindowIDs: [WindowIdentity] = []
    @ObservationIgnored private var selectedIndex = 0
    @ObservationIgnored private var originalWindowID: WindowIdentity?
    @ObservationIgnored private var cancelled = false
    @ObservationIgnored private var onPresentationChanged: ((Bool) -> Void)?

    init(thumbnailCapturer: any WindowThumbnailCapturing = ScreenCaptureThumbnailCapturer()) {
        self.thumbnailCapturer = thumbnailCapturer
    }

    func setPresentationChangedHandler(_ handler: @escaping (Bool) -> Void) {
        onPresentationChanged = handler
    }

    func start() {
        guard AXIsProcessTrusted(), CGPreflightScreenCaptureAccess() else {
            stop()
            state = .needsPermissions
            return
        }
        guard eventTap == nil else {
            state = .running
            return
        }

        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let reference = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: windowSwitcherEventTapCallback,
            userInfo: reference
        ) else {
            state = .failed
            return
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        eventTapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        startWorkspaceObservation()
        startRecentWindowTracking()
        state = .running
    }

    func stop() {
        cancelSwitch()
        if let source = eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        if let tap = eventTap {
            CFMachPortInvalidate(tap)
        }
        eventTap = nil
        eventTapSource = nil
        stopWorkspaceObservation()
        recentWindowTask?.cancel()
        recentWindowTask = nil
        state = .stopped
    }

    func refreshPermissionsAndState(enabled: Bool) {
        enabled ? start() : stop()
    }

    fileprivate func handleEvent(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let eventTap {
                CGEvent.tapEnable(tap: eventTap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let flags = event.flags
        let commandDown = flags.contains(.maskCommand)

        if type == .keyDown, keyCode == 48, commandDown {
            beginOrAdvance(reverse: flags.contains(.maskShift))
            return nil
        }

        guard isPresented else {
            return Unmanaged.passUnretained(event)
        }

        if type == .keyDown, keyCode == 53 {
            cancelSwitch()
            return nil
        }
        if type == .flagsChanged, !commandDown {
            commitSwitch()
            return Unmanaged.passUnretained(event)
        }
        if type == .keyDown, keyCode != 48 {
            cancelSwitch()
        }
        return Unmanaged.passUnretained(event)
    }

    private func beginOrAdvance(reverse: Bool) {
        if isPresented {
            moveSelection(by: reverse ? -1 : 1)
            return
        }

        windows = discoverWindows()
        guard !windows.isEmpty else {
            return
        }
        orderByRecentUse()
        originalWindowID = focusedWindowIdentity()
        if windows.count == 1 {
            selectedIndex = 0
        } else if reverse {
            selectedIndex = windows.count - 1
        } else {
            selectedIndex = 1
        }
        cancelled = false
        isPresented = true
        onPresentationChanged?(true)
        panelController.present(
            cards: makeCards(),
            selectedID: windows[selectedIndex].id,
            screen: presentationScreen(),
            onSelect: { [weak self] id in self?.selectAndCommit(id) },
            onClose: { [weak self] id in self?.closeWindow(id) }
        )
        startMouseMonitoring()
        startCapturing()
        startReconciling()
    }

    private func moveSelection(by offset: Int) {
        guard !windows.isEmpty else { return }
        selectedIndex = (selectedIndex + offset + windows.count) % windows.count
        panelController.select(windows[selectedIndex].id)
    }

    private func commitSwitch() {
        guard isPresented else { return }
        let selected = windows.indices.contains(selectedIndex) ? windows[selectedIndex] : nil
        finishPresentation()
        guard !cancelled, let selected else { return }
        activator.activate(WindowActivationTarget(id: selected.id, element: selected.element))
        recordRecent(selected.id)
    }

    private func selectAndCommit(_ id: WindowIdentity) {
        guard let index = windows.firstIndex(where: { $0.id == id }) else { return }
        selectedIndex = index
        commitSwitch()
    }

    private func closeWindow(_ id: WindowIdentity) {
        guard
            let index = windows.firstIndex(where: { $0.id == id }),
            let closeButton: AXUIElement = accessibilityAttribute(
                windows[index].element,
                kAXCloseButtonAttribute
            )
        else { return }

        guard AXUIElementPerformAction(
            closeButton,
            kAXPressAction as CFString
        ) == .success else { return }
        windows.remove(at: index)
        recentWindowIDs.removeAll { $0 == id }

        guard !windows.isEmpty else {
            finishPresentation()
            return
        }
        if index < selectedIndex {
            selectedIndex -= 1
        } else if selectedIndex >= windows.count {
            selectedIndex = windows.count - 1
        }
        panelController.update(cards: makeCards(), selectedID: windows[selectedIndex].id)
    }

    private func cancelSwitch() {
        guard isPresented else { return }
        cancelled = true
        finishPresentation()
        if
            let originalWindowID,
            let original = windows.first(where: { $0.id == originalWindowID })
        {
            activator.activate(WindowActivationTarget(id: original.id, element: original.element))
        }
    }

    private func finishPresentation() {
        isPresented = false
        panelController.dismiss()
        captureTask?.cancel()
        reconcileTask?.cancel()
        captureTask = nil
        reconcileTask = nil
        stopMouseMonitoring()
        onPresentationChanged?(false)
        windows.removeAll(keepingCapacity: true)
    }

    private func makeCards() -> [WindowSwitcherCard] {
        windows.map {
            WindowSwitcherCard(
                id: $0.id,
                title: $0.title,
                applicationName: $0.applicationName,
                applicationIcon: $0.applicationIcon,
                thumbnail: .loading
            )
        }
    }

    private func startCapturing() {
        captureTask?.cancel()
        let records = windows.map(\.switchableWindow)
        captureTask = Task { [weak self, thumbnailCapturer] in
            let thumbnails = await thumbnailCapturer.thumbnails(for: records)
            guard !Task.isCancelled else { return }
            self?.panelController.apply(thumbnails)
        }
    }

    private func startReconciling() {
        reconcileTask?.cancel()
        reconcileTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled, isPresented else { return }
                reconcileWindows()
            }
        }
    }

    private func reconcileWindows() {
        let selectedID = windows.indices.contains(selectedIndex) ? windows[selectedIndex].id : nil
        let discovered = discoverWindows()
        guard !discovered.isEmpty else {
            cancelSwitch()
            return
        }
        let byID = Dictionary(uniqueKeysWithValues: discovered.map { ($0.id, $0) })
        var reconciled = windows.compactMap { byID[$0.id] }
        let known = Set(reconciled.map(\.id))
        reconciled.append(contentsOf: discovered.filter { !known.contains($0.id) })
        windows = reconciled
        selectedIndex = selectedID.flatMap { id in windows.firstIndex { $0.id == id } }
            ?? min(selectedIndex, windows.count - 1)
        panelController.update(cards: makeCards(), selectedID: windows[selectedIndex].id)
    }

    private func discoverWindows() -> [SwitcherWindow] {
        let ownBundleIdentifier = Bundle.main.bundleIdentifier
        var result: [SwitcherWindow] = []
        for application in NSWorkspace.shared.runningApplications
        where application.activationPolicy == .regular
            && application.bundleIdentifier != ownBundleIdentifier
        {
            let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
            guard let elements: [AXUIElement] = accessibilityAttribute(
                applicationElement,
                kAXWindowsAttribute
            ) else { continue }
            let name = application.localizedName ?? application.bundleIdentifier ?? "Application"
            let icon = application.icon ?? NSImage(systemSymbolName: "app", accessibilityDescription: nil)!
            for element in elements {
                let role: String? = accessibilityAttribute(element, kAXRoleAttribute)
                let subrole: String? = accessibilityAttribute(element, kAXSubroleAttribute)
                guard
                    role == (kAXWindowRole as String),
                    subrole == (kAXStandardWindowSubrole as String),
                    let frame = accessibilityFrame(element)
                else { continue }
                let id = WindowIdentity(
                    processID: application.processIdentifier,
                    elementID: Int(truncatingIfNeeded: CFHash(element))
                )
                let rawTitle: String = accessibilityAttribute(element, kAXTitleAttribute) ?? ""
                result.append(
                    SwitcherWindow(
                        id: id,
                        title: rawTitle.isEmpty
                            ? String(localized: "Untitled")
                            : rawTitle,
                        applicationName: name,
                        applicationIcon: icon,
                        frame: frame,
                        isMinimized: accessibilityAttribute(
                            element,
                            kAXMinimizedAttribute
                        ) ?? false,
                        element: element
                    )
                )
            }
        }
        return result
    }

    private func orderByRecentUse() {
        let current = focusedWindowIdentity()
        let ranks = Dictionary(uniqueKeysWithValues: recentWindowIDs.enumerated().map { ($1, $0) })
        windows.sort { lhs, rhs in
            if lhs.id == current { return true }
            if rhs.id == current { return false }
            return (ranks[lhs.id] ?? Int.max) < (ranks[rhs.id] ?? Int.max)
        }
    }

    private func focusedWindowIdentity() -> WindowIdentity? {
        guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
        let applicationElement = AXUIElementCreateApplication(application.processIdentifier)
        guard let window: AXUIElement = accessibilityAttribute(
            applicationElement,
            kAXFocusedWindowAttribute
        ) else { return nil }
        return WindowIdentity(
            processID: application.processIdentifier,
            elementID: Int(truncatingIfNeeded: CFHash(window))
        )
    }

    private func recordRecent(_ id: WindowIdentity) {
        recentWindowIDs.removeAll { $0 == id }
        recentWindowIDs.insert(id, at: 0)
    }

    private func startWorkspaceObservation() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(
            center.addObserver(
                forName: NSWorkspace.didActivateApplicationNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    guard let id = self?.focusedWindowIdentity() else { return }
                    self?.recordRecent(id)
                }
            }
        )
        if let id = focusedWindowIdentity() {
            recordRecent(id)
        }
    }

    private func stopWorkspaceObservation() {
        let center = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(center.removeObserver)
        workspaceObservers.removeAll()
    }

    private func presentationScreen() -> NSScreen {
        if
            let currentID = originalWindowID ?? focusedWindowIdentity(),
            let current = windows.first(where: { $0.id == currentID }),
            let (screen, _) = ScreenGeometry().screenAndAppKitRect(for: current.frame)
        {
            return screen
        }
        let point = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(point) }) ?? NSScreen.main!
    }

    private func startRecentWindowTracking() {
        recentWindowTask?.cancel()
        recentWindowTask = Task { [weak self] in
            var lastID: WindowIdentity?
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, !Task.isCancelled, !isPresented else { continue }
                let currentID = focusedWindowIdentity()
                if let currentID, currentID != lastID {
                    recordRecent(currentID)
                    lastID = currentID
                }
            }
        }
    }

    private func startMouseMonitoring() {
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) {
            [weak self] _ in
            Task { @MainActor in
                guard let self, self.isPresented else { return }
                if !self.panelController.contains(NSEvent.mouseLocation) {
                    self.cancelSwitch()
                }
            }
        }
    }

    private func stopMouseMonitoring() {
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
        }
        mouseMonitor = nil
    }
}

private func windowSwitcherEventTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let userInfo else {
        return Unmanaged.passUnretained(event)
    }
    let controllerAddress = UInt(bitPattern: userInfo)
    return MainActor.assumeIsolated {
        guard let pointer = UnsafeMutableRawPointer(bitPattern: controllerAddress) else {
            return Unmanaged.passUnretained(event)
        }
        let controller = Unmanaged<WindowSwitcherController>
            .fromOpaque(pointer)
            .takeUnretainedValue()
        return controller.handleEvent(type: type, event: event)
    }
}
