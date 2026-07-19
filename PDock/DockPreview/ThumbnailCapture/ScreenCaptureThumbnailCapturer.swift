import CoreGraphics
import ScreenCaptureKit

actor ScreenCaptureThumbnailCapturer: WindowThumbnailCapturing {
    private let matcher = WindowCaptureMatcher()

    func thumbnails(
        for windows: [SwitchableWindow]
    ) async -> [WindowIdentity: WindowThumbnail] {
        guard !windows.isEmpty else {
            return [:]
        }

        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false,
                onScreenWindowsOnly: false
            )
            let candidates = content.windows.compactMap { window -> WindowCaptureCandidate? in
                guard let application = window.owningApplication else {
                    return nil
                }
                return WindowCaptureCandidate(
                    windowID: window.windowID,
                    processID: application.processID,
                    title: window.title ?? "",
                    frame: window.frame
                )
            }
            let matches = matcher.match(windows: windows, candidates: candidates)
            let windowsByID = Dictionary(
                uniqueKeysWithValues: content.windows.map { ($0.windowID, $0) }
            )

            var result = Dictionary(
                uniqueKeysWithValues: windows.map { ($0.id, WindowThumbnail.unavailable) }
            )
            for window in windows {
                guard
                    !Task.isCancelled,
                    let captureID = matches[window.id],
                    let source = windowsByID[captureID]
                else {
                    continue
                }

                do {
                    result[window.id] = .available(
                        try await capture(source)
                    )
                } catch {
                    result[window.id] = .unavailable
                }
            }
            return result
        } catch {
            return Dictionary(
                uniqueKeysWithValues: windows.map { ($0.id, WindowThumbnail.unavailable) }
            )
        }
    }

    private func capture(_ window: SCWindow) async throws -> CGImage {
        let configuration = SCStreamConfiguration()
        let scale = min(2.0, 640.0 / max(window.frame.width, 1.0))
        configuration.width = max(1, Int(window.frame.width * scale))
        configuration.height = max(1, Int(window.frame.height * scale))
        configuration.showsCursor = false
        configuration.ignoreShadowsSingleWindow = true

        return try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(desktopIndependentWindow: window),
            configuration: configuration
        )
    }
}
