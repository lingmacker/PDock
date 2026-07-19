import AppKit
import CoreGraphics

struct ScreenGeometry {
    func screenAndAppKitRect(for quartzRect: CGRect) -> (NSScreen, CGRect)? {
        guard let screen = screen(containingQuartzPoint: CGPoint(x: quartzRect.midX, y: quartzRect.midY)) else {
            return nil
        }
        guard let displayID = displayID(for: screen) else {
            return nil
        }
        let quartzBounds = CGDisplayBounds(displayID)
        let appKitFrame = screen.frame
        let rect = CGRect(
            x: appKitFrame.minX + quartzRect.minX - quartzBounds.minX,
            y: appKitFrame.maxY - (quartzRect.minY - quartzBounds.minY) - quartzRect.height,
            width: quartzRect.width,
            height: quartzRect.height
        )
        return (screen, rect)
    }

    func appKitPoint(for quartzPoint: CGPoint) -> CGPoint? {
        guard let screen = screen(containingQuartzPoint: quartzPoint) else {
            return nil
        }
        guard let displayID = displayID(for: screen) else {
            return nil
        }
        let quartzBounds = CGDisplayBounds(displayID)
        return CGPoint(
            x: screen.frame.minX + quartzPoint.x - quartzBounds.minX,
            y: screen.frame.maxY - (quartzPoint.y - quartzBounds.minY)
        )
    }

    private func screen(containingQuartzPoint point: CGPoint) -> NSScreen? {
        NSScreen.screens.first { screen in
            guard let displayID = displayID(for: screen) else {
                return false
            }
            return CGDisplayBounds(displayID).contains(point)
        }
    }

    private func displayID(for screen: NSScreen) -> CGDirectDisplayID? {
        guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
