import AppKit
import SwiftUI

@MainActor
final class OnboardingWindowController {
    private var window: NSWindow?
    private var windowDelegate: WindowReleaseDelegate?

    func show(model: PDockApplicationModel) {
        if let window {
            present(window)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = String(localized: "Set Up PDock", comment: "Onboarding window title")
        window.contentViewController = NSHostingController(rootView: OnboardingView(model: model))
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PDockOnboarding")
        let delegate = WindowReleaseDelegate { [weak self] in
            self?.window = nil
            self?.windowDelegate = nil
        }
        window.delegate = delegate
        windowDelegate = delegate
        self.window = window
        present(window)
    }

    private func present(_ window: NSWindow) {
        NSApplication.shared.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

private final class WindowReleaseDelegate: NSObject, NSWindowDelegate {
    private let didClose: () -> Void

    init(didClose: @escaping () -> Void) {
        self.didClose = didClose
    }

    func windowWillClose(_ notification: Notification) {
        didClose()
    }
}
