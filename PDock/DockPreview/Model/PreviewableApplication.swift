import Foundation

struct PreviewableApplication: Hashable, Sendable {
    let bundleIdentifier: String
    let displayName: String
    let processIDs: Set<Int32>
}

struct DockHoverTarget: Equatable, Sendable {
    let application: PreviewableApplication
    let anchor: DockAnchor
}

enum DockPointerLocation: Equatable, Sendable {
    case dock(DockHoverTarget)
    case panel
    case outside
}
