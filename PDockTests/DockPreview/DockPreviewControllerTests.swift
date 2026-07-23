import XCTest
import ApplicationServices
@testable import PDock

@MainActor
final class DockPreviewControllerTests: XCTestCase {
    func testStartWithoutRequiredPermissionsReportsNeedsPermissions() {
        let system = TestDockPreviewSystem(permissionState: .missing(accessibility: true, screenRecording: true))
        let controller = DockPreviewController(system: system)

        controller.start()

        XCTAssertEqual(
            controller.state,
            .needsPermissions(accessibility: true, screenRecording: true)
        )
    }

    func testHoverPresentsOneCardForEachSwitchableWindowAfterDwell() async {
        let firstWindow = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 7),
            title: "Quarterly Plan",
            frame: CGRect(x: 100, y: 100, width: 900, height: 700),
            isMinimized: false
        )
        let secondWindow = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 8),
            title: "Meeting Notes",
            frame: CGRect(x: 140, y: 140, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(
            permissionState: .granted,
            windows: [firstWindow, secondWindow]
        )
        let sleeper = TestDockPreviewSleeper()
        let controller = DockPreviewController(system: system, sleeper: sleeper)
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        let presented = expectation(description: "Window Preview Panel presented")
        system.nextPresentExpectation = presented
        controller.start()
        system.send(.pointerMoved(.dock(target)))
        await sleeper.resumeNextSleep()
        await fulfillment(of: [presented], timeout: 1)

        XCTAssertEqual(
            system.presentedPanel?.cards.map(\.title),
            ["Quarterly Plan", "Meeting Notes"]
        )
    }

    func testClosingPreviewsRemovesOnlyTargetUntilLastWindowCloses() async {
        let firstWindow = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 10),
            title: "Draft",
            frame: CGRect(x: 100, y: 100, width: 900, height: 700),
            isMinimized: false
        )
        let secondWindow = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 11),
            title: "Reference",
            frame: CGRect(x: 140, y: 140, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(
            permissionState: .granted,
            windows: [firstWindow, secondWindow]
        )
        let controller = DockPreviewController(
            system: system,
            sleeper: ImmediateDockPreviewSleeper()
        )
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        let presented = expectation(description: "Window Preview Panel presented")
        system.nextPresentExpectation = presented
        controller.start()
        system.send(.pointerMoved(.dock(target)))
        await fulfillment(of: [presented], timeout: 1)

        system.closePresentedWindow(firstWindow.id)

        XCTAssertEqual(system.closedWindowIDs, [firstWindow.id])
        XCTAssertEqual(system.presentedPanel?.cards.map(\.id), [secondWindow.id])

        system.closePresentedWindow(secondWindow.id)

        XCTAssertEqual(system.closedWindowIDs, [firstWindow.id, secondWindow.id])
        XCTAssertNil(system.presentedPanel)
    }

    func testLeavingDockAndPanelDismissesPresentedWindows() async {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 9),
            title: "Release Notes",
            frame: CGRect(x: 80, y: 80, width: 800, height: 600),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(permissionState: .granted, windows: [window])
        let controller = DockPreviewController(
            system: system,
            sleeper: ImmediateDockPreviewSleeper()
        )
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        controller.start()
        system.send(.pointerMoved(.dock(target)))
        await Task.yield()
        system.send(.pointerMoved(.outside))
        await Task.yield()

        XCTAssertNil(system.presentedPanel)
    }

    func testWindowChangesInsertNewCardsFirstAndRemoveClosedCards() async {
        let first = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 1),
            title: "First",
            frame: CGRect(x: 40, y: 40, width: 700, height: 500),
            isMinimized: false
        )
        let second = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 2),
            title: "Second",
            frame: CGRect(x: 80, y: 80, width: 700, height: 500),
            isMinimized: false
        )
        let replacement = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 3),
            title: "Replacement",
            frame: CGRect(x: 120, y: 120, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(
            permissionState: .granted,
            windows: [first, second]
        )
        let capturer = ControlledThumbnailCapturer()
        let controller = DockPreviewController(
            system: system,
            sleeper: ImmediateDockPreviewSleeper(),
            thumbnailCapturer: capturer
        )
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        let presented = expectation(description: "Window Preview Panel presented")
        system.nextPresentExpectation = presented
        controller.start()
        system.send(.pointerMoved(.dock(target)))
        await fulfillment(of: [presented], timeout: 1)
        system.windows = [second, replacement]
        let updated = expectation(description: "Window Preview Panel updated")
        system.nextUpdateExpectation = updated
        system.send(.windowsChanged(bundleIdentifier: "com.apple.TextEdit"))
        await fulfillment(of: [updated], timeout: 1)

        XCTAssertEqual(
            system.presentedPanel?.cards.map(\.title),
            ["Replacement", "Second"]
        )
    }

    func testThumbnailFromClosedSessionIsDiscarded() async {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 11),
            title: "Sensitive Draft",
            frame: CGRect(x: 60, y: 60, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(permissionState: .granted, windows: [window])
        let capturer = ControlledThumbnailCapturer()
        let controller = DockPreviewController(
            system: system,
            sleeper: ImmediateDockPreviewSleeper(),
            thumbnailCapturer: capturer
        )
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        controller.start()
        system.send(.pointerMoved(.dock(target)))
        await Task.yield()
        system.send(.pointerMoved(.outside))
        await Task.yield()
        await capturer.complete([window.id: .unavailable])
        await Task.yield()

        XCTAssertNil(system.presentedPanel)
    }

    func testMovingToWindowlessApplicationDismissesPreviousPreviewImmediately() async {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 12),
            title: "TextEdit Document",
            frame: CGRect(x: 50, y: 50, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(permissionState: .granted, windows: [window])
        let sleeper = TestDockPreviewSleeper()
        let controller = DockPreviewController(system: system, sleeper: sleeper)
        let textEditTarget = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )
        let windowlessTarget = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.ActivityMonitor",
                displayName: "Activity Monitor",
                processIDs: [73]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 570, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        controller.start()
        system.send(.pointerMoved(.dock(textEditTarget)))
        await sleeper.resumeNextSleep()
        await Task.yield()
        XCTAssertEqual(system.presentedPanel?.application, textEditTarget.application)

        system.windows = []
        system.send(.pointerMoved(.dock(windowlessTarget)))
        await sleeper.waitUntilSleepPending()
        XCTAssertNil(system.presentedPanel)

        await sleeper.resumeNextSleep()
        await Task.yield()
        XCTAssertNil(system.presentedPanel)
    }

    func testDockMagnificationUpdatesAnchorWithoutRestartingDwell() async {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 12),
            title: "Magnified",
            frame: CGRect(x: 50, y: 50, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(permissionState: .granted, windows: [window])
        let sleeper = TestDockPreviewSleeper()
        let controller = DockPreviewController(system: system, sleeper: sleeper)
        let application = PreviewableApplication(
            bundleIdentifier: "com.apple.TextEdit",
            displayName: "TextEdit",
            processIDs: [42]
        )
        let initialTarget = DockHoverTarget(
            application: application,
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )
        let magnifiedTarget = DockHoverTarget(
            application: application,
            anchor: DockAnchor(
                itemFrame: CGRect(x: 492, y: 0, width: 80, height: 80),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        controller.start()
        system.send(.pointerMoved(.dock(initialTarget)))
        await sleeper.waitUntilSleepPending()
        system.send(.pointerMoved(.dock(magnifiedTarget)))
        await sleeper.resumeNextSleep()
        await Task.yield()

        XCTAssertEqual(system.presentedPanel?.anchor.itemFrame.width, 80)
    }
    func testConfiguredTimingControlsPresentationAndDismissalDelays() async {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 42, elementID: 13),
            title: "Timing",
            frame: CGRect(x: 50, y: 50, width: 700, height: 500),
            isMinimized: false
        )
        let system = TestDockPreviewSystem(permissionState: .granted, windows: [window])
        let sleeper = TestDockPreviewSleeper()
        let controller = DockPreviewController(
            system: system,
            sleeper: sleeper,
            timing: DockPreviewTiming(
                presentationDelayMilliseconds: 700,
                dismissalDelayMilliseconds: 900
            )
        )
        let target = DockHoverTarget(
            application: PreviewableApplication(
                bundleIdentifier: "com.apple.TextEdit",
                displayName: "TextEdit",
                processIDs: [42]
            ),
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: CGRect(x: 0, y: 0, width: 1440, height: 900),
                edge: .bottom
            )
        )

        controller.start()
        system.send(.pointerMoved(.dock(target)))
        let presentationDelay = await sleeper.requestedDuration(at: 0)
        XCTAssertEqual(presentationDelay, .milliseconds(700))

        await sleeper.resumeNextSleep()
        await Task.yield()
        system.send(.pointerMoved(.outside))
        let dismissalDelay = await sleeper.requestedDuration(at: 1)
        XCTAssertEqual(dismissalDelay, .milliseconds(900))
        await sleeper.resumeNextSleep()
    }

    func testPreviewTimingPersistsInUserDefaults() {
        let suiteName = "PDockTests.PreviewTiming.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let model = PDockApplicationModel(defaults: defaults)

        model.setPreviewPresentationDelayMilliseconds(650)
        model.setPreviewDismissalDelayMilliseconds(800)
        let restoredModel = PDockApplicationModel(defaults: defaults)

        XCTAssertEqual(restoredModel.previewTiming.presentationDelayMilliseconds, 650)
        XCTAssertEqual(restoredModel.previewTiming.dismissalDelayMilliseconds, 800)
    }

    func testWindowSwitcherPreferenceDefaultsOffAndPersists() {
        let suiteName = "PDockTests.WindowSwitcher.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let model = PDockApplicationModel(defaults: defaults)
        XCTAssertFalse(model.windowSwitcherEnabled)

        model.setWindowSwitcherEnabled(true)
        let restoredModel = PDockApplicationModel(defaults: defaults)

        XCTAssertTrue(restoredModel.windowSwitcherEnabled)
    }

    func testWindowActivatorFocusesTheSelectedWindowAtApplicationLevel() {
        let firstID = WindowIdentity(processID: 42, elementID: 1)
        let secondID = WindowIdentity(processID: 42, elementID: 2)
        let secondTarget = WindowActivationTarget(
            id: secondID,
            element: AXUIElementCreateApplication(secondID.processID)
        )
        let system = RecordingWindowActivationSystem()
        let activator = WindowActivator(system: system)

        activator.activate(secondTarget)

        XCTAssertFalse(system.operations.contains(.focusApplicationWindow(firstID)))
        XCTAssertTrue(system.operations.contains(.focusApplicationWindow(secondID)))
    }

}

private enum WindowActivationOperation: Equatable {
    case unhide(Int32)
    case activate(Int32)
    case minimized(WindowIdentity, Bool)
    case focusApplicationWindow(WindowIdentity)
    case raise(WindowIdentity)
}

@MainActor
private final class RecordingWindowActivationSystem: WindowActivationSystem {
    private(set) var operations: [WindowActivationOperation] = []

    func unhideApplication(processID: Int32) {
        operations.append(.unhide(processID))
    }

    func activateApplication(processID: Int32) {
        operations.append(.activate(processID))
    }

    func setMinimized(_ minimized: Bool, for target: WindowActivationTarget) {
        operations.append(.minimized(target.id, minimized))
    }

    func focusApplicationWindow(_ target: WindowActivationTarget) {
        operations.append(.focusApplicationWindow(target.id))
    }

    func raise(_ target: WindowActivationTarget) {
        operations.append(.raise(target.id))
    }
}

@MainActor
private final class TestDockPreviewSystem: DockPreviewSystem {
    let permissionState: DockPreviewPermissionState
    var windows: [SwitchableWindow]
    private var handler: (@MainActor (DockPreviewEvent) -> Void)?
    private var onClose: (@MainActor (WindowIdentity) -> Void)?
    private(set) var presentedPanel: WindowPreviewPresentation?
    private(set) var closedWindowIDs: [WindowIdentity] = []
    var nextUpdateExpectation: XCTestExpectation?
    var nextPresentExpectation: XCTestExpectation?

    init(
        permissionState: DockPreviewPermissionState,
        windows: [SwitchableWindow] = []
    ) {
        self.permissionState = permissionState
        self.windows = windows
    }

    func startObserving(_ handler: @escaping @MainActor (DockPreviewEvent) -> Void) {
        self.handler = handler
    }

    func stopObserving() {
        handler = nil
    }

    func switchableWindows(for application: PreviewableApplication) async -> [SwitchableWindow] {
        windows
    }

    func present(
        _ presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void,
        onClose: @escaping @MainActor (WindowIdentity) -> Void
    ) {
        presentedPanel = presentation
        self.onClose = onClose
        nextPresentExpectation?.fulfill()
        nextPresentExpectation = nil
    }

    func update(_ presentation: WindowPreviewPresentation) {
        presentedPanel = presentation
        nextUpdateExpectation?.fulfill()
        nextUpdateExpectation = nil
    }

    func dismissPanel() {
        presentedPanel = nil
    }

    func selectWindow(_ id: WindowIdentity) {}

    func closeWindow(_ id: WindowIdentity) {
        closedWindowIDs.append(id)
    }

    func closePresentedWindow(_ id: WindowIdentity) {
        onClose?(id)
    }

    func send(_ event: DockPreviewEvent) {
        handler?(event)
    }
}

private actor TestDockPreviewSleeper: DockPreviewSleeping {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var requestedDurations: [Duration] = []

    func sleep(for duration: Duration) async throws {
        requestedDurations.append(duration)
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func waitUntilSleepPending() async {
        while continuations.isEmpty {
            await Task.yield()
        }
    }

    func requestedDuration(at index: Int) async -> Duration {
        while requestedDurations.indices.contains(index) == false {
            await Task.yield()
        }
        return requestedDurations[index]
    }

    func resumeNextSleep() async {
        while continuations.isEmpty {
            await Task.yield()
        }
        continuations.removeFirst().resume()
    }
}

private struct ImmediateDockPreviewSleeper: DockPreviewSleeping {
    func sleep(for duration: Duration) async throws {}
}

private actor ControlledThumbnailCapturer: WindowThumbnailCapturing {
    private var continuation:
        CheckedContinuation<[WindowIdentity: WindowThumbnail], Never>?

    func thumbnails(
        for windows: [SwitchableWindow]
    ) async -> [WindowIdentity: WindowThumbnail] {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func complete(_ thumbnails: [WindowIdentity: WindowThumbnail]) async {
        while continuation == nil {
            await Task.yield()
        }
        continuation?.resume(returning: thumbnails)
        continuation = nil
    }
}
