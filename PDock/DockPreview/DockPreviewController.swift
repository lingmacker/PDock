import Foundation
import Observation

struct DockPreviewTiming: Equatable, Sendable {
    static let delayRange = 0...2_000
    static let standard = DockPreviewTiming(
        presentationDelayMilliseconds: 300,
        dismissalDelayMilliseconds: 250
    )

    let presentationDelayMilliseconds: Int
    let dismissalDelayMilliseconds: Int

    init(
        presentationDelayMilliseconds: Int,
        dismissalDelayMilliseconds: Int
    ) {
        self.presentationDelayMilliseconds = presentationDelayMilliseconds.clamped(
            to: Self.delayRange
        )
        self.dismissalDelayMilliseconds = dismissalDelayMilliseconds.clamped(
            to: Self.delayRange
        )
    }

    var presentationDelay: Duration {
        .milliseconds(presentationDelayMilliseconds)
    }

    var dismissalDelay: Duration {
        .milliseconds(dismissalDelayMilliseconds)
    }
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}

@MainActor
@Observable
public final class DockPreviewController {
    public private(set) var state: DockPreviewState = .stopped

    @ObservationIgnored
    private let system: DockPreviewSystem

    @ObservationIgnored
    private let sleeper: any DockPreviewSleeping

    @ObservationIgnored
    private let thumbnailCapturer: any WindowThumbnailCapturing

    @ObservationIgnored
    private var timing: DockPreviewTiming

    @ObservationIgnored
    private var hoverTask: Task<Void, Never>?

    @ObservationIgnored
    private var dismissTask: Task<Void, Never>?

    @ObservationIgnored
    private var captureTask: Task<Void, Never>?

    @ObservationIgnored
    private var captureSessionID: UUID?

    @ObservationIgnored
    private var currentTarget: DockHoverTarget?

    @ObservationIgnored
    private var currentPresentation: WindowPreviewPresentation?

    init(
        system: DockPreviewSystem,
        sleeper: any DockPreviewSleeping = ContinuousDockPreviewSleeper(),
        thumbnailCapturer: any WindowThumbnailCapturing = UnavailableWindowThumbnailCapturer(),
        timing: DockPreviewTiming = .standard
    ) {
        self.system = system
        self.sleeper = sleeper
        self.thumbnailCapturer = thumbnailCapturer
        self.timing = timing
    }

    func setTiming(_ timing: DockPreviewTiming) {
        self.timing = timing
    }

    public func start() {
        apply(system.permissionState)
    }

    public func stop() {
        hoverTask?.cancel()
        hoverTask = nil
        dismissTask?.cancel()
        dismissTask = nil
        currentTarget = nil
        closePanel()
        system.stopObserving()
        state = .stopped
    }

    private func apply(_ permissionState: DockPreviewPermissionState) {
        switch permissionState {
        case .granted:
            system.startObserving { [weak self] event in
                self?.handle(event)
            }
            state = .running

        case let .missing(accessibility, screenRecording):
            hoverTask?.cancel()
            hoverTask = nil
            dismissTask?.cancel()
            dismissTask = nil
            currentTarget = nil
            closePanel()
            system.stopObserving()
            state = .needsPermissions(
                accessibility: accessibility,
                screenRecording: screenRecording
            )
        }
    }

    private func handle(_ event: DockPreviewEvent) {
        switch event {
        case let .permissionsChanged(permissionState):
            apply(permissionState)

        case let .pointerMoved(location):
            handlePointerMove(location)

        case let .windowsChanged(bundleIdentifier):
            guard currentTarget?.application.bundleIdentifier == bundleIdentifier else {
                return
            }
            Task { [weak self] in
                await self?.reconcileWindows()
            }
        }
    }

    private func handlePointerMove(_ location: DockPointerLocation) {
        guard state == .running else {
            return
        }

        switch location {
        case let .dock(target):
            dismissTask?.cancel()
            dismissTask = nil
            if currentTarget?.application.bundleIdentifier
                == target.application.bundleIdentifier {
                currentTarget = target
                if var presentation = currentPresentation {
                    presentation.anchor = target.anchor
                    currentPresentation = presentation
                    system.update(presentation)
                }
                return
            }

            hoverTask?.cancel()
            closePanel()
            currentTarget = target
            let presentationDelay = timing.presentationDelay
            hoverTask = Task { [weak self, sleeper] in
                try? await sleeper.sleep(for: presentationDelay)
                guard !Task.isCancelled else {
                    return
                }
                await self?.presentWindows(for: target)
            }

        case .panel:
            dismissTask?.cancel()
            dismissTask = nil
            hoverTask?.cancel()
            hoverTask = nil

        case .outside:
            hoverTask?.cancel()
            hoverTask = nil
            currentTarget = nil
            dismissTask?.cancel()
            let dismissalDelay = timing.dismissalDelay
            dismissTask = Task { [weak self, sleeper] in
                try? await sleeper.sleep(for: dismissalDelay)
                guard !Task.isCancelled else {
                    return
                }
                self?.closePanel()
            }
        }
    }

    private func reconcileWindows() async {
        guard
            let target = currentTarget,
            var presentation = currentPresentation
        else {
            return
        }

        let windows = await system.switchableWindows(for: target.application)
        guard
            let latestTarget = currentTarget,
            latestTarget.application.bundleIdentifier
                == target.application.bundleIdentifier
        else {
            return
        }
        presentation.anchor = latestTarget.anchor

        guard !windows.isEmpty else {
            currentTarget = nil
            closePanel()
            return
        }

        let recordsByID = Dictionary(uniqueKeysWithValues: windows.map { ($0.id, $0) })
        let existingIDs = Set(presentation.cards.map(\.id))
        let newCards = windows
            .filter { !existingIDs.contains($0.id) }
            .map { WindowPreviewCard(id: $0.id, title: $0.title, thumbnail: .loading) }
        let survivingCards = presentation.cards.compactMap { card -> WindowPreviewCard? in
            guard let record = recordsByID[card.id] else {
                return nil
            }
            var updated = card
            updated.title = record.title
            return updated
        }
        presentation.cards = newCards + survivingCards
        currentPresentation = presentation
        system.update(presentation)
        startCapturing(windows)
    }

    private func presentWindows(for target: DockHoverTarget) async {
        guard
            state == .running,
            currentTarget?.application.bundleIdentifier
                == target.application.bundleIdentifier,
            let activeTarget = currentTarget
        else {
            return
        }

        let windows = await system.switchableWindows(for: activeTarget.application)
        guard
            let latestTarget = currentTarget,
            latestTarget.application.bundleIdentifier
                == target.application.bundleIdentifier,
            !windows.isEmpty
        else {
            return
        }

        let presentation = WindowPreviewPresentation(
            application: latestTarget.application,
            anchor: latestTarget.anchor,
            cards: windows.map {
                WindowPreviewCard(id: $0.id, title: $0.title, thumbnail: .loading)
            }
        )
        currentPresentation = presentation
        startCapturing(windows)
        system.present(
            presentation,
            onSelect: { [weak self] id in
                guard let self else {
                    return
                }
                system.selectWindow(id)
                currentTarget = nil
                closePanel()
            },
            onClose: { [weak self] id in
                guard let self else {
                    return
                }
                system.closeWindow(id)
                currentTarget = nil
                closePanel()
            }
        )
    }
    private func startCapturing(_ windows: [SwitchableWindow]) {
        captureTask?.cancel()
        let sessionID = UUID()
        captureSessionID = sessionID
        captureTask = Task { [weak self, thumbnailCapturer] in
            while !Task.isCancelled {
                let thumbnails = await thumbnailCapturer.thumbnails(for: windows)
                guard !Task.isCancelled else {
                    return
                }
                self?.apply(thumbnails, sessionID: sessionID)
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func apply(
        _ thumbnails: [WindowIdentity: WindowThumbnail],
        sessionID: UUID
    ) {
        guard
            captureSessionID == sessionID,
            var presentation = currentPresentation
        else {
            return
        }

        for index in presentation.cards.indices {
            guard let thumbnail = thumbnails[presentation.cards[index].id] else {
                continue
            }
            presentation.cards[index].thumbnail = thumbnail
        }
        currentPresentation = presentation
        system.update(presentation)
    }

    private func closePanel() {
        captureSessionID = nil
        captureTask?.cancel()
        captureTask = nil
        currentPresentation = nil
        system.dismissPanel()
    }

}
