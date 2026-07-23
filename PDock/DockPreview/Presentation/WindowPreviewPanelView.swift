import Observation
import SwiftUI

@MainActor
@Observable
final class WindowPreviewPanelModel {
    var presentation: WindowPreviewPresentation
    private let onSelect: @MainActor (WindowIdentity) -> Void
    private let onClose: @MainActor (WindowIdentity) -> Void

    init(
        presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void,
        onClose: @escaping @MainActor (WindowIdentity) -> Void
    ) {
        self.presentation = presentation
        self.onSelect = onSelect
        self.onClose = onClose
    }

    func select(_ id: WindowIdentity) {
        onSelect(id)
    }

    func close(_ id: WindowIdentity) {
        onClose(id)
    }
}

struct WindowPreviewPanelView: View {
    @Bindable var model: WindowPreviewPanelModel

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 200, maximum: 280), spacing: 8)],
                spacing: 8
            ) {
                ForEach(model.presentation.cards) { card in
                    WindowPreviewCardView(
                        card: card,
                        select: { model.select(card.id) },
                        close: { model.close(card.id) }
                    )
                }
            }
            .padding(8)
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
    let close: () -> Void
    @State private var isThumbnailHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 7) {
                if let applicationIcon = card.applicationIcon {
                    Image(nsImage: applicationIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .accessibilityHidden(true)
                }
                Text(card.title)
                    .font(.system(.body, design: .default, weight: .medium))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ZStack(alignment: .topTrailing) {
                Button(action: select) {
                    thumbnail
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(card.title))

                if isThumbnailHovered {
                    Button(action: close) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.primary)
                            .frame(width: 22, height: 22)
                            .background(.regularMaterial, in: Circle())
                            .overlay {
                                Circle()
                                    .stroke(.separator.opacity(0.5), lineWidth: 1)
                            }
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        Text(
                            "Close window",
                            comment: "Accessibility label for a preview card close button"
                        )
                    )
                    .help(
                        Text(
                            "Close window",
                            comment: "Help text for a preview card close button"
                        )
                    )
                    .padding(6)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 176)
            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.12)) {
                    isThumbnailHovered = hovering
                }
            }
        }
        .frame(minWidth: 200, maxWidth: .infinity)
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
