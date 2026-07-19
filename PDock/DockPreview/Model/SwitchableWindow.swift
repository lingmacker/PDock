import CoreGraphics
import Foundation

struct WindowIdentity: Hashable, Sendable {
    let processID: Int32
    let elementID: Int
}

struct SwitchableWindow: Identifiable, Sendable {
    let id: WindowIdentity
    var title: String
    var frame: CGRect
    var isMinimized: Bool
}

enum WindowThumbnail: @unchecked Sendable {
    case loading
    case available(CGImage)
    case unavailable
}

struct WindowPreviewCard: Identifiable, @unchecked Sendable {
    let id: WindowIdentity
    var title: String
    var thumbnail: WindowThumbnail
}

struct WindowPreviewPresentation: @unchecked Sendable {
    let application: PreviewableApplication
    var anchor: DockAnchor
    var cards: [WindowPreviewCard]
}
