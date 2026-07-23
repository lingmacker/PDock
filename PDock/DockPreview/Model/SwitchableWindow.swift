import AppKit
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

func activeWindowsCollapsingTabGroups(
    _ windows: [SwitchableWindow]
) -> [SwitchableWindow] {
    var result: [SwitchableWindow] = []
    for window in windows {
        if let index = result.firstIndex(where: {
            $0.id.processID == window.id.processID
                && framesRepresentSameTabGroup($0.frame, window.frame)
        }) {
            if result[index].isMinimized, !window.isMinimized {
                result[index] = window
            }
        } else {
            result.append(window)
        }
    }
    return result
}

private func framesRepresentSameTabGroup(_ lhs: CGRect, _ rhs: CGRect) -> Bool {
    let tolerance = 2.0
    return abs(lhs.minX - rhs.minX) <= tolerance
        && abs(lhs.minY - rhs.minY) <= tolerance
        && abs(lhs.width - rhs.width) <= tolerance
        && abs(lhs.height - rhs.height) <= tolerance
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
    var applicationIcon: NSImage? = nil
}

struct WindowPreviewPresentation: @unchecked Sendable {
    let application: PreviewableApplication
    var anchor: DockAnchor
    var cards: [WindowPreviewCard]
}
