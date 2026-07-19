import Foundation

protocol WindowThumbnailCapturing: Sendable {
    func thumbnails(
        for windows: [SwitchableWindow]
    ) async -> [WindowIdentity: WindowThumbnail]
}

actor UnavailableWindowThumbnailCapturer: WindowThumbnailCapturing {
    func thumbnails(
        for windows: [SwitchableWindow]
    ) -> [WindowIdentity: WindowThumbnail] {
        Dictionary(uniqueKeysWithValues: windows.map { ($0.id, .unavailable) })
    }
}
