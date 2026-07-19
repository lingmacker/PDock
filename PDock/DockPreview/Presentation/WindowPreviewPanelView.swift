import Observation
import SwiftUI

@MainActor
@Observable
final class WindowPreviewPanelModel {
    var presentation: WindowPreviewPresentation
    private let onSelect: @MainActor (WindowIdentity) -> Void

    init(
        presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void
    ) {
        self.presentation = presentation
        self.onSelect = onSelect
    }

    func select(_ id: WindowIdentity) {
        onSelect(id)
    }
}

struct WindowPreviewPanelView: View {
    @Bindable var model: WindowPreviewPanelModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 12)],
                spacing: 12
            ) {
                ForEach(model.presentation.cards) { card in
                    WindowPreviewCardView(card: card) {
                        model.select(card.id)
                    }
                }
            }
            .padding(12)
        }
        .scrollIndicators(.automatic)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.separator.opacity(0.5), lineWidth: 1)
        }
        .accessibilityLabel(
            Text(
                "Windows for \(model.presentation.application.displayName)",
                comment: "Accessibility label for the window preview panel"
            )
        )
    }
}

private struct WindowPreviewCardView: View {
    let card: WindowPreviewCard
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 8) {
                thumbnail
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .frame(height: 140)
                    .clipped()

                Text(card.title)
                    .font(.system(.body, design: .default, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(8)
            .frame(minWidth: 200, maxWidth: .infinity)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(card.title))
    }

    @ViewBuilder
    private var thumbnail: some View {
        switch card.thumbnail {
        case .loading:
            ProgressView()
                .controlSize(.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case let .available(image):
            Image(decorative: image, scale: 1)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .unavailable:
            VStack(spacing: 6) {
                Image(systemName: "rectangle.slash")
                    .font(.title2)
                Text("Preview unavailable", comment: "Unavailable window thumbnail label")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
