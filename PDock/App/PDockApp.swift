import AppKit
import SwiftUI

@main
struct PDockApp: App {
    @NSApplicationDelegateAdaptor(PDockAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("PDock", systemImage: "dock.rectangle") {
            MenuBarContent(model: appDelegate.model)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class PDockAppDelegate: NSObject, NSApplicationDelegate {
    let model = PDockApplicationModel()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.accessory)
        model.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.dockPreview.stop()
        model.windowSwitcher.stop()
    }
}
