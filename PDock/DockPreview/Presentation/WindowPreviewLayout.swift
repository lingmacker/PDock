import CoreGraphics

struct WindowPreviewLayout {
    let gap: CGFloat

    func panelSize(cardCount: Int, screenSize: CGSize) -> CGSize {
        let count = max(cardCount, 1)
        let maximumColumns = max(1, Int((screenSize.width * 0.75) / 224))
        let columns = min(count, min(maximumColumns, 4))
        let rows = Int(ceil(Double(count) / Double(columns)))
        let width = min(screenSize.width * 0.75, CGFloat(columns * 224 + 16))
        let height = min(
            screenSize.height * 0.7,
            CGFloat(rows * 196 + max(rows - 1, 0) * 8 + 16)
        )
        return CGSize(width: width, height: height)
    }

    func frame(panelSize: CGSize, anchor: DockAnchor) -> CGRect {
        let item = anchor.itemFrame
        let screen = anchor.screenFrame
        var origin: CGPoint

        switch anchor.edge {
        case .bottom:
            origin = CGPoint(
                x: item.midX - panelSize.width / 2,
                y: item.maxY + gap
            )
        case .left:
            origin = CGPoint(
                x: item.maxX + gap,
                y: item.midY - panelSize.height / 2
            )
        case .right:
            origin = CGPoint(
                x: item.minX - gap - panelSize.width,
                y: item.midY - panelSize.height / 2
            )
        }

        origin.x = min(
            max(origin.x, screen.minX + gap),
            screen.maxX - panelSize.width - gap
        )
        origin.y = min(
            max(origin.y, screen.minY + gap),
            screen.maxY - panelSize.height - gap
        )
        return CGRect(origin: origin, size: panelSize)
    }
}
