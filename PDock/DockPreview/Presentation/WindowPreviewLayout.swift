import CoreGraphics

struct WindowPreviewLayout {
    let gap: CGFloat

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
