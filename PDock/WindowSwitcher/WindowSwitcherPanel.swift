import AppKit
import Observation
import SwiftUI

@MainActor
@Observable
private final class WindowSwitcherPanelModel {
    var cards: [WindowSwitcherCard]
    var selectedID: WindowIdentity
    let onSelect: (WindowIdentity) -> Void

    init(
        cards: [WindowSwitcherCard],
        selectedID: WindowIdentity,
        onSelect: @escaping (WindowIdentity) -> Void
    ) {
        self.cards = cards
        self.selectedID = selectedID
        self.onSelect = onSelect
    }
}

private struct WindowSwitcherPanelView: View {
    @Bindable var model: WindowSwitcherPanelModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 220, maximum: 280), spacing: 12)],
                    spacing: 12
                ) {
                    ForEach(model.cards) { card in
                        Button { model.onSelect(card.id) } label: {
                            cardView(card)
                        }
                        .buttonStyle(.plain)
                        .id(card.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: model.selectedID) { _, id in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.08)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(.separator.opacity(0.6), lineWidth: 1)
        }
    }

    private func cardView(_ card: WindowSwitcherCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(nsImage: card.applicationIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(card.title)
                    .font(.system(.body, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Group {
                switch card.thumbnail {
                case .loading:
                    ProgressView()
                case let .available(image):
                    Image(decorative: image, scale: 1)
                        .resizable()
                        .scaledToFit()
                case .unavailable:
                    VStack(spacing: 6) {
                        Image(systemName: "rectangle.slash")
                        Text("Preview unavailable")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 154)
        }
        .padding(10)
        .background(
            card.id == model.selectedID
                ? Color.accentColor.opacity(0.18)
                : Color.primary.opacity(0.04),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    card.id == model.selectedID
                        ? Color.accentColor
                        : Color(nsColor: .separatorColor).opacity(0.35),
                    lineWidth: card.id == model.selectedID ? 3 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityLabel("\(card.applicationName), \(card.title)")
    }
}

@MainActor
final class WindowSwitcherPanelController {
    private var panel: NSPanel?
    private var model: WindowSwitcherPanelModel?

    func present(
        cards: [WindowSwitcherCard],
        selectedID: WindowIdentity,
        screen: NSScreen,
        onSelect: @escaping (WindowIdentity) -> Void
    ) {
        let model = WindowSwitcherPanelModel(
            cards: cards,
            selectedID: selectedID,
            onSelect: onSelect
        )
        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentViewController = NSHostingController(
            rootView: WindowSwitcherPanelView(model: model)
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        let size = panelSize(cardCount: cards.count, screen: screen.visibleFrame.size)
        panel.setFrame(
            CGRect(
                x: screen.visibleFrame.midX - size.width / 2,
                y: screen.visibleFrame.midY - size.height / 2,
                width: size.width,
                height: size.height
            ),
            display: true
        )
        self.model = model
        self.panel = panel
        panel.orderFrontRegardless()
    }

    func update(cards: [WindowSwitcherCard], selectedID: WindowIdentity) {
        guard let model else { return }
        let thumbnails = Dictionary(
            uniqueKeysWithValues: model.cards.map { ($0.id, $0.thumbnail) }
        )
        model.cards = cards.map { card in
            var updated = card
            updated.thumbnail = thumbnails[card.id] ?? .loading
            return updated
        }
        model.selectedID = selectedID
    }

    func select(_ id: WindowIdentity) {
        model?.selectedID = id
    }

    func apply(_ thumbnails: [WindowIdentity: WindowThumbnail]) {
        guard let model else { return }
        for index in model.cards.indices {
            if let thumbnail = thumbnails[model.cards[index].id] {
                model.cards[index].thumbnail = thumbnail
            }
        }
    }

    func contains(_ point: CGPoint) -> Bool {
        panel?.frame.contains(point) == true
    }

    func dismiss() {
        panel?.orderOut(nil)
        panel = nil
        model = nil
    }

    private func panelSize(cardCount: Int, screen: CGSize) -> CGSize {
        let columns = min(max(cardCount, 1), max(1, min(4, Int(screen.width / 250))))
        let rows = Int(ceil(Double(max(cardCount, 1)) / Double(columns)))
        return CGSize(
            width: min(screen.width * 0.85, CGFloat(columns * 244 + 32)),
            height: min(screen.height * 0.8, CGFloat(rows * 216 + 32))
        )
    }
}
