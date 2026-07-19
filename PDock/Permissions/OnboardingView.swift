import SwiftUI

struct OnboardingView: View {
    @Bindable var model: PDockApplicationModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to PDock", comment: "Onboarding title")
                    .font(.largeTitle.bold())
                Text(
                    "PDock shows live previews of your Switchable Windows when you hover over a Previewable Application in the system Dock.",
                    comment: "Onboarding product explanation"
                )
                .foregroundStyle(.secondary)
            }

            permissionStep(
                number: 1,
                title: String(localized: "Accessibility", comment: "Accessibility permission title"),
                explanation: String(
                    localized: "Required to identify Dock application items and perform Window Selection.",
                    comment: "Accessibility permission explanation"
                ),
                granted: model.permissions.accessibilityGranted,
                request: model.requestAccessibility,
                openSettings: model.permissions.openAccessibilitySettings
            )

            permissionStep(
                number: 2,
                title: String(localized: "Screen Recording", comment: "Screen Recording permission title"),
                explanation: String(
                    localized: "Required to create Window Preview Card thumbnails. Images stay in memory and are never uploaded.",
                    comment: "Screen Recording permission explanation"
                ),
                granted: model.permissions.screenRecordingGranted,
                enabled: model.permissions.accessibilityGranted,
                request: model.requestScreenRecording,
                openSettings: model.permissions.openScreenRecordingSettings
            )

            if model.permissions.screenRecordingRestartRecommended {
                Label(
                    "Quit and reopen PDock if Screen Recording does not become active immediately.",
                    systemImage: "arrow.clockwise"
                )
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            HStack {
                Button("Refresh Status", action: model.refreshPermissions)
                Spacer()
                if model.permissions.allGranted {
                    Button("Done") {
                        NSApplication.shared.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(28)
        .frame(width: 560)
    }

    private func permissionStep(
        number: Int,
        title: String,
        explanation: String,
        granted: Bool,
        enabled: Bool = true,
        request: @escaping () -> Void,
        openSettings: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(.quaternary, in: Circle())

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    Label(
                        granted ? "Granted" : "Required",
                        systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.circle"
                    )
                    .foregroundStyle(granted ? .green : .secondary)
                }
                Text(explanation)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                HStack {
                    Button(granted ? "Request Again" : "Grant Access", action: request)
                        .disabled(!enabled)
                    Button("Open System Settings", action: openSettings)
                        .disabled(!enabled)
                }
            }
        }
        .padding(14)
        .background(.quaternary.opacity(0.25), in: RoundedRectangle(cornerRadius: 12))
    }
}
