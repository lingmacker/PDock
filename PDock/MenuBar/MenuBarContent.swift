import SwiftUI

struct MenuBarContent: View {
    @Bindable var model: PDockApplicationModel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(model.statusText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

            Toggle(
                    "Enable Dock Previews",
                    isOn: Binding(
                        get: { model.previewsEnabled },
                        set: model.setPreviewsEnabled
                    )
                )

            if !model.permissions.allGranted {
                Button(action: model.showOnboarding) {
                    Text("Complete Permission Setup")
                        .menuBarRow()
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.vertical, 4)

            SettingsLink {
                Text("Settings…")
                    .menuBarRow()
            }
            .buttonStyle(.plain)

            Button {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
                NSApplication.shared.activate()
            } label: {
                Text("About PDock")
                    .menuBarRow()
            }
            .buttonStyle(.plain)

            Divider()
                .padding(.vertical, 4)

            Button(action: model.quit) {
                Text("Quit PDock")
                    .menuBarRow()
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")
        }
        .padding(6)
        .frame(width: 220)
    }
}

private struct MenuBarRowModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
            .foregroundStyle(isHovered ? Color.white : Color.primary)
            .background(
                isHovered ? Color.accentColor : Color.clear,
                in: RoundedRectangle(cornerRadius: 6)
            )
            .onHover { isHovered = $0 }
            .transaction { transaction in
                transaction.animation = nil
            }
    }
}

private extension View {
    func menuBarRow() -> some View {
        modifier(MenuBarRowModifier())
    }
}
