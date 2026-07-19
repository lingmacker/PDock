import AppKit
import ApplicationServices
import CoreGraphics
import Observation

@MainActor
@Observable
final class PermissionController {
    private(set) var accessibilityGranted = false
    private(set) var screenRecordingGranted = false
    private(set) var screenRecordingRestartRecommended = false

    var allGranted: Bool {
        accessibilityGranted && screenRecordingGranted
    }

    func refresh() {
        accessibilityGranted = AXIsProcessTrusted()
        screenRecordingGranted = CGPreflightScreenCaptureAccess()
    }

    func requestAccessibility() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        refresh()
    }

    func requestScreenRecording() {
        Task {
            let granted = await Task.detached {
                CGRequestScreenCaptureAccess()
            }.value
            screenRecordingGranted = granted || CGPreflightScreenCaptureAccess()
            screenRecordingRestartRecommended = screenRecordingGranted
        }
    }

    func openAccessibilitySettings() {
        openPrivacySettings(pane: "Privacy_Accessibility")
    }

    func openScreenRecordingSettings() {
        openPrivacySettings(pane: "Privacy_ScreenCapture")
    }

    private func openPrivacySettings(pane: String) {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        ) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
