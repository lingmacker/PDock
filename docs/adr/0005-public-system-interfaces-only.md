# Integrate through Public System Interfaces Only

PDock will use public Accessibility, AppKit, NSWorkspace, ServiceManagement, and ScreenCaptureKit interfaces only. It will not inject into Dock, use private SkyLight or `CGS*` symbols, alter Dock preferences, or automate applications with AppleScript; accepting graceful degradation for unusual applications is preferable to the signing, stability, and OS-upgrade risk of private integration.
