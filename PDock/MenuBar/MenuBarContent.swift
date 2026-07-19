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
                }
            }

            Divider()
                .padding(.vertical, 4)

            Button(action: model.showSettings) {
                Text("Settings…")
            }

            Button {
                NSApplication.shared.orderFrontStandardAboutPanel(nil)
                NSApplication.shared.activate()
            } label: {
                Text("About PDock")
            }

            Divider()
                .padding(.vertical, 4)

            Button(action: model.quit) {
                Text("Quit PDock")
            }
            .keyboardShortcut("q")
        }
        .padding(6)
        .frame(width: 220)
    }
}
