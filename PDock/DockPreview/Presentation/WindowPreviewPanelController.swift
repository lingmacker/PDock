import AppKit
import SwiftUI

@MainActor
final class WindowPreviewPanelController {
    private let layout = WindowPreviewLayout(gap: 8)
    private var panel: NonactivatingPreviewPanel?
    private var model: WindowPreviewPanelModel?

    var isVisible: Bool {
        panel?.isVisible == true
    }

    func contains(_ appKitScreenPoint: CGPoint) -> Bool {
        panel?.frame.contains(appKitScreenPoint) == true
    }

    func present(
        _ presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void,
        onClose: @escaping @MainActor (WindowIdentity) -> Void
    ) {
        let model = WindowPreviewPanelModel(
            presentation: presentation,
            onSelect: onSelect,
            onClose: onClose
        )
        let panel = makePanel(rootView: WindowPreviewPanelView(model: model))
        self.model = model
        self.panel?.orderOut(nil)
        self.panel = panel
        resizeAndPlace(panel, for: presentation)
        panel.orderFrontRegardless()
    }

    func update(_ presentation: WindowPreviewPresentation) {
        guard let panel, let model else {
            return
        }
        model.presentation = presentation
        resizeAndPlace(panel, for: presentation)
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        model = nil
    }

    private func makePanel(rootView: WindowPreviewPanelView) -> NonactivatingPreviewPanel {
        let panel = NonactivatingPreviewPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = NSHostingController(rootView: rootView)
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = true
        panel.hidesOnDeactivate = false
        panel.level = .popUpMenu
        panel.isReleasedWhenClosed = false
        panel.acceptsMouseMovedEvents = true
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]
        return panel
    }

    private func resizeAndPlace(
        _ panel: NSPanel,
        for presentation: WindowPreviewPresentation
    ) {
        let panelSize = layout.panelSize(
            cardCount: presentation.cards.count,
            screenSize: presentation.anchor.screenFrame.size
        )
        let frame = layout.frame(
            panelSize: panelSize,
            anchor: presentation.anchor
        )
        panel.setFrame(frame, display: true)
    }
}

private final class NonactivatingPreviewPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
