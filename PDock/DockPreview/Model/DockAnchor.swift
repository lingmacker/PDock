import CoreGraphics
import Foundation

enum DockEdge: Equatable, Sendable {
    case bottom
    case left
    case right
}

struct DockAnchor: Equatable, Sendable {
    let itemFrame: CGRect
    let screenFrame: CGRect
    let edge: DockEdge
}
