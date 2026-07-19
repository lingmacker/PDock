import SwiftUI

struct MenuBarContent: View {
    @Bindable var model: PDockApplicationModel

    var body: some View {
        Text(model.statusText)

        Toggle(
            "Enable Dock Previews",
            isOn: Binding(
                get: { model.previewsEnabled },
                set: model.setPreviewsEnabled
            )
        )

        if !model.permissions.allGranted {
            Button("Complete Permission Setup", action: model.showOnboarding)
        }

        Divider()

        SettingsLink {
            Text("Settings…")
        }

        Button("About PDock") {
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
            NSApplication.shared.activate()
        }

        Divider()

        Button("Quit PDock", action: model.quit)
            .keyboardShortcut("q")
    }
}
