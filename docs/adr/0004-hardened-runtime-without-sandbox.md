# Use Hardened Runtime without App Sandbox

The Developer ID build will enable Hardened Runtime but not App Sandbox. PDock's core module must inspect the system Dock and other applications through user-authorized Accessibility and Screen Recording access; avoiding sandbox constraints reduces cross-process integration risk while code signing, least-privilege entitlements, notarization, and explicit TCC consent retain the applicable macOS security controls.
