import XCTest
@testable import PDock

final class WindowPreviewLayoutTests: XCTestCase {
    func testPanelOpensInwardFromEveryDockEdge() {
        let layout = WindowPreviewLayout(gap: 8)
        let screen = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let panelSize = CGSize(width: 400, height: 300)

        let bottom = layout.frame(
            panelSize: panelSize,
            anchor: DockAnchor(
                itemFrame: CGRect(x: 500, y: 0, width: 64, height: 64),
                screenFrame: screen,
                edge: .bottom
            )
        )
        let left = layout.frame(
            panelSize: panelSize,
            anchor: DockAnchor(
                itemFrame: CGRect(x: 0, y: 400, width: 64, height: 64),
                screenFrame: screen,
                edge: .left
            )
        )
        let right = layout.frame(
            panelSize: panelSize,
            anchor: DockAnchor(
                itemFrame: CGRect(x: 1376, y: 400, width: 64, height: 64),
                screenFrame: screen,
                edge: .right
            )
        )

        XCTAssertEqual(bottom.origin, CGPoint(x: 332, y: 72))
        XCTAssertEqual(left.origin, CGPoint(x: 72, y: 282))
        XCTAssertEqual(right.origin, CGPoint(x: 968, y: 282))
    }
}
