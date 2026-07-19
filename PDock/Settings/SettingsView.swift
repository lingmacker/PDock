import SwiftUI

struct SettingsView: View {
    @Bindable var model: PDockApplicationModel

    var body: some View {
        Form {
            Section("Dock Preview") {
                Toggle(
                    "Enable Dock Previews",
                    isOn: Binding(
                        get: { model.previewsEnabled },
                        set: model.setPreviewsEnabled
                    )
                )
                LabeledContent("Status", value: model.statusText)
            }

            Section("Preview Timing") {
                timingControl(
                    title: "Show Delay",
                    milliseconds: Binding(
                        get: {
                            Double(model.previewTiming.presentationDelayMilliseconds)
                        },
                        set: model.setPreviewPresentationDelayMilliseconds
                    )
                )
                timingControl(
                    title: "Hide Delay",
                    milliseconds: Binding(
                        get: {
                            Double(model.previewTiming.dismissalDelayMilliseconds)
                        },
                        set: model.setPreviewDismissalDelayMilliseconds
                    )
                )
                Text("Changes apply to the next Dock interaction.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permissions") {
                permissionRow(
                    title: "Accessibility",
                    granted: model.permissions.accessibilityGranted,
                    openSettings: model.permissions.openAccessibilitySettings
                )
                permissionRow(
                    title: "Screen Recording",
                    granted: model.permissions.screenRecordingGranted,
                    openSettings: model.permissions.openScreenRecordingSettings
                )
                Button("Open Permission Setup", action: model.showOnboarding)
                Button("Refresh Permission Status", action: model.refreshPermissions)
            }

            Section("General") {
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { model.launchAtLogin.isEnabled },
                        set: model.setLaunchAtLoginEnabled
                    )
                )
                if let errorMessage = model.launchAtLogin.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("About") {
                LabeledContent("Application", value: "PDock")
                LabeledContent(
                    "Version",
                    value: Bundle.main.object(
                        forInfoDictionaryKey: "CFBundleShortVersionString"
                    ) as? String ?? "1.0"
                )
                Text("Window previews are captured only while visible, held only in memory, and never sent over the network.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520, height: 590)
        .task {
            model.refreshPermissions()
            model.launchAtLogin.refresh()
        }
    }

    private func timingControl(
        title: LocalizedStringKey,
        milliseconds: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            LabeledContent {
                Text(verbatim: "\(Int(milliseconds.wrappedValue.rounded())) ms")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            } label: {
                Text(title)
            }
            Slider(
                value: milliseconds,
                in: Double(DockPreviewTiming.delayRange.lowerBound)
                    ... Double(DockPreviewTiming.delayRange.upperBound),
                step: 50
            )
            .accessibilityLabel(Text(title))
        }
    }

    private func permissionRow(
        title: LocalizedStringKey,
        granted: Bool,
        openSettings: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Label(
                granted ? "Granted" : "Required",
                systemImage: granted ? "checkmark.circle.fill" : "exclamationmark.circle"
            )
            .foregroundStyle(granted ? .green : .secondary)
            Button("Open Settings", action: openSettings)
        }
    }
}
