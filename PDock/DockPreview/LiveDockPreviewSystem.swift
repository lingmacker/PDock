import AppKit
import ApplicationServices
import CoreGraphics

struct WindowActivationTarget {
    let id: WindowIdentity
    let element: AXUIElement
}

@MainActor
protocol WindowActivationSystem {
    func unhideApplication(processID: Int32)
    func activateApplication(processID: Int32)
    func setMinimized(_ minimized: Bool, for target: WindowActivationTarget)
    func focusApplicationWindow(_ target: WindowActivationTarget)
    func raise(_ target: WindowActivationTarget)
}

@MainActor
struct LiveWindowActivationSystem: WindowActivationSystem {
    func unhideApplication(processID: Int32) {
        NSRunningApplication(processIdentifier: processID)?.unhide()
    }

    func activateApplication(processID: Int32) {
        NSRunningApplication(processIdentifier: processID)?.activate(options: [])
    }

    func setMinimized(_ minimized: Bool, for target: WindowActivationTarget) {
        setAccessibilityAttribute(
            target.element,
            kAXMinimizedAttribute,
            value: minimized ? kCFBooleanTrue : kCFBooleanFalse
        )
    }

    func focusApplicationWindow(_ target: WindowActivationTarget) {
        let application = AXUIElementCreateApplication(target.id.processID)
        setAccessibilityAttribute(
            application,
            kAXFocusedWindowAttribute,
            value: target.element
        )
    }

    func raise(_ target: WindowActivationTarget) {
        AXUIElementPerformAction(target.element, kAXRaiseAction as CFString)
    }
}

@MainActor
struct WindowActivator {
    let system: any WindowActivationSystem

    func activate(_ target: WindowActivationTarget) {
        system.unhideApplication(processID: target.id.processID)
        system.activateApplication(processID: target.id.processID)
        system.setMinimized(false, for: target)
        system.focusApplicationWindow(target)
        system.raise(target)
    }
}

@MainActor
final class LiveDockPreviewSystem: DockPreviewSystem {
    private let panelController = WindowPreviewPanelController()
    private let screenGeometry = ScreenGeometry()
    private let windowActivator: WindowActivator
    private var eventHandler: (@MainActor (DockPreviewEvent) -> Void)?
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var permissionTask: Task<Void, Never>?
    private var windowTask: Task<Void, Never>?
    private var windowElements: [WindowIdentity: AXUIElement] = [:]
    private var activeApplication: PreviewableApplication?

    init(windowActivationSystem: any WindowActivationSystem = LiveWindowActivationSystem()) {
        windowActivator = WindowActivator(system: windowActivationSystem)
    }

    var permissionState: DockPreviewPermissionState {
        let accessibilityMissing = !AXIsProcessTrusted()
        let screenRecordingMissing = !CGPreflightScreenCaptureAccess()
        if accessibilityMissing || screenRecordingMissing {
            return .missing(
                accessibility: accessibilityMissing,
                screenRecording: screenRecordingMissing
            )
        }
        return .granted
    }

    func startObserving(_ handler: @escaping @MainActor (DockPreviewEvent) -> Void) {
        stopObserving()
        eventHandler = handler
        let mask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) { [weak self] event in
            Task { @MainActor in
                self?.handle(event)
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) { [weak self] event in
            self?.handle(event)
            return event
        }

        let initialPermissionState = permissionState
        permissionTask = Task { [weak self] in
            var last = initialPermissionState
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else {
                    return
                }
                let current = permissionState
                if current != last {
                    last = current
                    eventHandler?(.permissionsChanged(current))
                }
            }
        }
    }

    func stopObserving() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
        permissionTask?.cancel()
        permissionTask = nil
        stopWindowObservation(clearElements: true)
        eventHandler = nil
    }

    func switchableWindows(for application: PreviewableApplication) async -> [SwitchableWindow] {
        discoverWindows(for: application)
    }

    func present(
        _ presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void,
        onClose: @escaping @MainActor (WindowIdentity) -> Void
    ) {
        activeApplication = presentation.application
        panelController.present(
            presentation,
            onSelect: onSelect,
            onClose: onClose
        )
        startWindowObservation(for: presentation.application)
    }

    func update(_ presentation: WindowPreviewPresentation) {
        panelController.update(presentation)
    }

    func dismissPanel() {
        activeApplication = nil
        stopWindowObservation(clearElements: true)
        panelController.dismiss()
    }

    func selectWindow(_ id: WindowIdentity) {
        guard let window = windowElements[id] else {
            return
        }
        windowActivator.activate(WindowActivationTarget(id: id, element: window))
    }

    func closeWindow(_ id: WindowIdentity) {
        guard
            let window = windowElements[id],
            let closeButton: AXUIElement = accessibilityAttribute(
                window,
                kAXCloseButtonAttribute
            )
        else {
            return
        }
        AXUIElementPerformAction(closeButton, kAXPressAction as CFString)
    }

    private func handle(_ event: NSEvent) {
        guard let eventHandler else {
            return
        }
        guard event.type == .mouseMoved else {
            if panelController.contains(NSEvent.mouseLocation) {
                eventHandler(.pointerMoved(.panel))
            } else {
                eventHandler(.pointerMoved(.outside))
            }
            return
        }

        if panelController.contains(NSEvent.mouseLocation) {
            eventHandler(.pointerMoved(.panel))
            return
        }
        guard let quartzPoint = CGEvent(source: nil)?.location else {
            eventHandler(.pointerMoved(.outside))
            return
        }
        if let target = dockTarget(at: quartzPoint) {
            eventHandler(.pointerMoved(.dock(target)))
        } else {
            eventHandler(.pointerMoved(.outside))
        }
    }

    private func dockTarget(at quartzPoint: CGPoint) -> DockHoverTarget? {
        guard
            let dock = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.dock"
            ).first
        else {
            return nil
        }
        let dockElement = AXUIElementCreateApplication(dock.processIdentifier)
        var hitElement: AXUIElement?
        guard AXUIElementCopyElementAtPosition(
            dockElement,
            Float(quartzPoint.x),
            Float(quartzPoint.y),
            &hitElement
        ) == .success else {
            return nil
        }
        guard let dockItem = applicationDockItem(from: hitElement) else {
            return nil
        }
        guard
            let bundleURL: URL = accessibilityAttribute(dockItem, kAXURLAttribute),
            let bundle = Bundle(url: bundleURL),
            let bundleIdentifier = bundle.bundleIdentifier,
            bundleIdentifier != Bundle.main.bundleIdentifier,
            let quartzFrame = accessibilityFrame(dockItem),
            let (screen, appKitFrame) = screenGeometry.screenAndAppKitRect(for: quartzFrame)
        else {
            return nil
        }

        let runningApplications = NSRunningApplication.runningApplications(
            withBundleIdentifier: bundleIdentifier
        ).filter { $0.activationPolicy == .regular }
        let processIDs = Set(runningApplications.map(\.processIdentifier))
        guard !processIDs.isEmpty else {
            return nil
        }
        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? bundleURL.deletingPathExtension().lastPathComponent
        let edge = dockEdge(itemFrame: appKitFrame, screenFrame: screen.frame)
        return DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: bundleIdentifier,
                displayName: displayName,
                processIDs: processIDs
            ),
            anchor: DockAnchor(
                itemFrame: appKitFrame,
                screenFrame: screen.frame,
                edge: edge
            )
        )
    }

    private func applicationDockItem(from element: AXUIElement?) -> AXUIElement? {
        var current = element
        for _ in 0..<8 {
            guard let candidate = current else {
                return nil
            }
            let role: String? = accessibilityAttribute(candidate, kAXRoleAttribute)
            let subrole: String? = accessibilityAttribute(candidate, kAXSubroleAttribute)
            if role == "AXDockItem", subrole == "AXApplicationDockItem" {
                return candidate
            }
            current = accessibilityAttribute(candidate, kAXParentAttribute)
        }
        return nil
    }

    private func dockEdge(itemFrame: CGRect, screenFrame: CGRect) -> DockEdge {
        let distances: [(DockEdge, CGFloat)] = [
            (.bottom, abs(itemFrame.minY - screenFrame.minY)),
            (.left, abs(itemFrame.minX - screenFrame.minX)),
            (.right, abs(screenFrame.maxX - itemFrame.maxX))
        ]
        return distances.min { $0.1 < $1.1 }?.0 ?? .bottom
    }

    private func discoverWindows(
        for application: PreviewableApplication
    ) -> [SwitchableWindow] {
        var discovered: [SwitchableWindow] = []
        var elements: [WindowIdentity: AXUIElement] = [:]
        let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let orderedProcessIDs = application.processIDs.sorted {
            if $0 == frontmostPID { return true }
            if $1 == frontmostPID { return false }
            return $0 < $1
        }

        for processID in orderedProcessIDs {
            let applicationElement = AXUIElementCreateApplication(processID)
            guard let windows: [AXUIElement] = accessibilityAttribute(
                applicationElement,
                kAXWindowsAttribute
            ) else {
                continue
            }
            for window in windows {
                guard isSwitchable(window), let frame = accessibilityFrame(window) else {
                    continue
                }
                let title: String = accessibilityAttribute(window, kAXTitleAttribute) ?? ""
                let displayTitle = title.isEmpty
                    ? String(localized: "Untitled", comment: "Fallback title for a window without a title")
                    : title
                let minimized: Bool = accessibilityAttribute(window, kAXMinimizedAttribute) ?? false
                let identity = WindowIdentity(
                    processID: processID,
                    elementID: Int(truncatingIfNeeded: CFHash(window))
                )
                guard elements[identity] == nil else {
                    continue
                }
                elements[identity] = window
                discovered.append(
                    SwitchableWindow(
                        id: identity,
                        title: displayTitle,
                        frame: frame,
                        isMinimized: minimized
                    )
                )
            }
        }
        windowElements = elements
        return discovered
    }

    private func isSwitchable(_ element: AXUIElement) -> Bool {
        let role: String? = accessibilityAttribute(element, kAXRoleAttribute)
        guard role == (kAXWindowRole as String) else {
            return false
        }
        let subrole: String? = accessibilityAttribute(element, kAXSubroleAttribute)
        return subrole == (kAXStandardWindowSubrole as String)
            || subrole == "AXDialog"
    }

    private func startWindowObservation(for application: PreviewableApplication) {
        stopWindowObservation(clearElements: false)
        windowTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                guard let self, !Task.isCancelled else {
                    return
                }
                eventHandler?(
                    .windowsChanged(bundleIdentifier: application.bundleIdentifier)
                )
            }
        }
    }

    private func stopWindowObservation(clearElements: Bool) {
        windowTask?.cancel()
        windowTask = nil
        if clearElements {
            windowElements.removeAll(keepingCapacity: true)
        }
    }
}
