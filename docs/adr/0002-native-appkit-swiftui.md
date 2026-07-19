# Use AppKit and SwiftUI Together

The app will use Swift 6 with AppKit for the nonactivating preview panel, pointer tracking, and system geometry, while SwiftUI owns onboarding, settings, menu-bar content, and preview-card views. This keeps system-level behavior on the mature AppKit interfaces without paying the maintenance cost of implementing every ordinary interface in AppKit; the app will use Apple frameworks directly and add no third-party UI or architecture dependency.
