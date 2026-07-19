import Foundation

protocol DockPreviewSleeping: Sendable {
    func sleep(for duration: Duration) async throws
}

struct ContinuousDockPreviewSleeper: DockPreviewSleeping {
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
