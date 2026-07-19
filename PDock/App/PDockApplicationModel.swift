import AppKit
import Observation

@MainActor
@Observable
final class PDockApplicationModel {
    let permissions = PermissionController()
    let launchAtLogin = LaunchAtLoginController()
    let dockPreview: DockPreviewController

    private(set) var previewsEnabled: Bool
    private var hasStarted = false
    private var permissionPollingTask: Task<Void, Never>?
    private let onboarding = OnboardingWindowController()
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: "previewsEnabled") == nil {
            previewsEnabled = true
        } else {
            previewsEnabled = defaults.bool(forKey: "previewsEnabled")
        }
        dockPreview = DockPreviewController(
            system: LiveDockPreviewSystem(),
            thumbnailCapturer: ScreenCaptureThumbnailCapturer()
        )
    }

    var statusText: String {
        if !previewsEnabled {
            return String(localized: "Paused", comment: "Menu bar status when previews are disabled")
        }
        if !permissions.allGranted {
            return String(localized: "Permissions required", comment: "Menu bar permission status")
        }
        switch dockPreview.state {
        case .running:
            return String(localized: "Running", comment: "Menu bar status when previews are active")
        case .failed:
            return String(localized: "Error", comment: "Menu bar status when previews failed")
        case .stopped, .needsPermissions:
            return String(localized: "Paused", comment: "Menu bar status when previews are inactive")
        }
    }

    func start() {
        guard !hasStarted else {
            return
        }
        hasStarted = true
        permissions.refresh()
        synchronizePreviewState()
        if !permissions.allGranted {
            showOnboarding()
        }
        permissionPollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self, !Task.isCancelled else {
                    return
                }
                let wasGranted = permissions.allGranted
                permissions.refresh()
                if permissions.allGranted != wasGranted {
                    synchronizePreviewState()
                }
            }
        }
    }

    func setPreviewsEnabled(_ enabled: Bool) {
        previewsEnabled = enabled
        defaults.set(enabled, forKey: "previewsEnabled")
        synchronizePreviewState()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        launchAtLogin.setEnabled(enabled)
    }

    func showOnboarding() {
        onboarding.show(model: self)
    }

    func requestAccessibility() {
        permissions.requestAccessibility()
        synchronizePreviewState()
    }

    func requestScreenRecording() {
        permissions.requestScreenRecording()
    }

    func refreshPermissions() {
        permissions.refresh()
        synchronizePreviewState()
    }

    func quit() {
        dockPreview.stop()
        NSApplication.shared.terminate(nil)
    }

    private func synchronizePreviewState() {
        if previewsEnabled, permissions.allGranted {
            dockPreview.start()
        } else {
            dockPreview.stop()
        }
    }
}
