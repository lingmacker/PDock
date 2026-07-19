import ApplicationServices
import CoreGraphics

func accessibilityAttribute<T>(
    _ element: AXUIElement,
    _ attribute: String,
    as type: T.Type = T.self
) -> T? {
    var value: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
        return nil
    }
    return value as? T
}

func accessibilityFrame(_ element: AXUIElement) -> CGRect? {
    guard
        let positionValue: AXValue = accessibilityAttribute(element, kAXPositionAttribute),
        let sizeValue: AXValue = accessibilityAttribute(element, kAXSizeAttribute)
    else {
        return nil
    }

    var position = CGPoint.zero
    var size = CGSize.zero
    guard
        AXValueGetValue(positionValue, .cgPoint, &position),
        AXValueGetValue(sizeValue, .cgSize, &size)
    else {
        return nil
    }
    return CGRect(origin: position, size: size)
}

@discardableResult
func setAccessibilityAttribute(
    _ element: AXUIElement,
    _ attribute: String,
    value: CFTypeRef
) -> Bool {
    AXUIElementSetAttributeValue(element, attribute as CFString, value) == .success
}
