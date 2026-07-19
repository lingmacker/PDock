import Foundation

public enum DockPreviewState: Equatable, Sendable {
    case stopped
    case needsPermissions(accessibility: Bool, screenRecording: Bool)
    case running
    case failed(String)
}

public enum DockPreviewPermissionState: Equatable, Sendable {
    case granted
    case missing(accessibility: Bool, screenRecording: Bool)
}

enum DockPreviewEvent: Sendable {
    case permissionsChanged(DockPreviewPermissionState)
    case pointerMoved(DockPointerLocation)
    case windowsChanged(bundleIdentifier: String)
}
