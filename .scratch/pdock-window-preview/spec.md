# Add Window Preview Cards to the System Dock

Status: ready-for-agent

## Problem Statement

macOS users who work with several windows from the same application cannot identify or select a specific window directly from that application's system Dock item. Clicking the item activates the application, but it does not provide a visual inventory of minimized, hidden, full-screen, other-Space, or other-display windows. Users must instead cycle through windows, use Mission Control, or activate the application and search manually, which interrupts pointer-driven workflows.

PDock must solve this without replacing the system Dock, changing its established launch and organization behavior, persisting sensitive window imagery, or relying on private system integration.

## Solution

PDock will provide a System Dock Enhancement that runs as a menu-bar utility. When the pointer rests on a Previewable Application for approximately 300 ms, PDock will present a transient, nonactivating Window Preview Panel adjacent to the Dock item. The panel will contain one Window Preview Card for every Switchable Window associated with that Dock application identity. Each card will show a proportionally scaled live thumbnail and title, and selecting it will perform Window Selection for that exact target.

The enhancement will work with all system Dock positions, automatic hiding, Dock magnification, multiple displays, Spaces, and full-screen Spaces. It will require explicit Accessibility and Screen Recording consent, capture only while the panel is visible, keep imagery only in memory, remain fully offline, and use public Apple interfaces exclusively.

## User Stories

1. As a macOS user, I want to hover over a running application's Dock item, so that I can inspect its open windows without first activating the application.
2. As a macOS user, I want the preview to appear only after a short dwell, so that merely moving across the Dock does not produce distracting panels.
3. As a macOS user, I want a brief grace period when moving from the Dock item to the panel, so that the panel does not disappear while I cross the gap.
4. As a macOS user, I want the panel to remain visible while my pointer is over either the Dock item or the panel, so that I can inspect and select a card reliably.
5. As a macOS user, I want the panel to close after I leave both the Dock item and panel, so that it does not remain on screen after the interaction ends.
6. As a macOS user, I want clicks on ordinary Dock items to preserve system behavior, so that PDock does not replace launching or activation semantics.
7. As a macOS user, I want previews only for running applications with Switchable Windows, so that folders, files, Trash, non-running applications, and standalone minimized-window Dock items behave normally.
8. As a macOS user, I want one Window Preview Card per top-level window, so that the preview matches the windows I can actually select.
9. As a browser user, I want tabs to remain part of their containing window, so that dozens of tabs do not become dozens of Dock cards.
10. As a user of native tabbed windows, I want the card to represent the current tab of the containing window, so that the panel preserves the system distinction between tabs and windows.
11. As a macOS user, I want attached sheets to remain part of their containing window, so that transient child interfaces do not appear as independent targets.
12. As a macOS user, I want menus, tooltips, popovers, utility panels, desktop elements, and helper processes excluded, so that the panel contains meaningful targets only.
13. As a macOS user, I want minimized windows included, so that I can restore and select them directly.
14. As a macOS user, I want windows from hidden applications included, so that hiding an application does not make its open work undiscoverable.
15. As a macOS user, I want full-screen windows included, so that I can select them without entering Mission Control.
16. As a macOS user, I want windows from other Spaces included, so that the Dock item provides one complete application-level inventory.
17. As a multi-display user, I want windows from every display included, so that the panel is not limited to the display where the Dock currently appears.
18. As a multi-display user, I want the panel on the display containing the active Dock item, so that it appears next to the pointer interaction that invoked it.
19. As a multi-display user, I want selected windows to remain on their existing display, so that PDock does not rearrange my workspace.
20. As a macOS user, I want Window Selection to activate the owning application and bring the chosen window forward, so that clicking a card reaches the exact target.
21. As a macOS user, I want a minimized selection restored, so that the selected content becomes usable immediately.
22. As a macOS user, I want selection to change Spaces when necessary, so that windows outside the current Space remain actionable.
23. As a macOS user, I want selection to preserve window size and position, so that previewing does not mutate my layout.
24. As a macOS user, I want the most recently used windows first, so that likely targets are easiest to reach.
25. As a macOS user, I want card order stable while a panel is open, so that refreshing thumbnails does not move click targets.
26. As a macOS user, I want a newly created window inserted first, so that it becomes immediately discoverable without closing the panel.
27. As a macOS user, I want a closed window removed immediately, so that stale cards cannot be selected.
28. As a macOS user, I want title and visual changes reflected on the existing card, so that the preview remains current without reordering everything.
29. As a macOS user, I want the panel to close when the application exits or has no Switchable Windows, so that an empty or obsolete panel is never left visible.
30. As a macOS user, I want the first thumbnail captured immediately and refreshed at a low rate while visible, so that dynamic content is recognizable without continuous background capture.
31. As a privacy-conscious user, I want capture to stop when the panel closes, so that PDock observes content only during an explicit preview interaction.
32. As a privacy-conscious user, I want thumbnails kept only in short-lived memory, so that sensitive screen contents are never persisted.
33. As a privacy-conscious user, I want window imagery and titles excluded from logs and diagnostics, so that troubleshooting cannot leak application content.
34. As a privacy-conscious user, I want PDock to remain offline and telemetry-free, so that its privileged observations cannot leave my Mac.
35. As a user viewing protected content, I want an unavailable-preview placeholder instead of a missing target, so that I can still select the window safely.
36. As a user with visually indistinguishable windows, I want PDock to refuse ambiguous thumbnail associations, so that it never shows another window's content on the wrong card.
37. As a user with many windows, I want every Switchable Window retained in an adaptive grid, so that the feature does not silently hide targets after an arbitrary limit.
38. As a user with many windows, I want the panel constrained to the active display and internally scrollable, so that it never extends beyond usable screen space.
39. As a user with unusually wide or tall windows, I want thumbnails scaled proportionally without cropping or distortion, so that their contents remain recognizable.
40. As a user with the Dock at the bottom, I want the panel above the hovered item, so that it opens inward from the screen edge.
41. As a user with the Dock on the left, I want the panel to the right of the hovered item, so that it remains visible on screen.
42. As a user with the Dock on the right, I want the panel to the left of the hovered item, so that it remains visible on screen.
43. As a user of automatic Dock hiding, I want previews available after the Dock appears and closed when it hides, so that PDock follows the system interaction lifecycle.
44. As a user of Dock magnification, I want hit detection and panel placement to follow the item's current frame, so that enlarged icons remain accurate targets.
45. As a full-screen user, I want the panel to appear in the current full-screen Space without activating PDock, so that previewing does not exit or interrupt the full-screen application.
46. As a user who is typing in another application, I want the panel not to take keyboard focus, so that hovering over the Dock never interrupts input.
47. As a user running multiple instances of one application, I want windows grouped according to the single Dock application identity, so that the panel mirrors the Dock's grouping model.
48. As a user running multiple instances, I want each card to retain its exact process and Accessibility window target, so that selection reaches the correct instance.
49. As a new user, I want a guided explanation of Accessibility and Screen Recording access, so that I understand why both permissions are necessary.
50. As a new user, I want permissions requested sequentially, so that each system prompt has clear context.
51. As a user who revokes a permission, I want the enhancement to stop safely and show a recoverable status, so that PDock never pretends privileged behavior still works.
52. As a user whose Screen Recording grant needs a process restart, I want explicit restart guidance, so that I can complete setup without guessing.
53. As a macOS user, I want PDock to run from the menu bar without its own Dock item, so that it does not consume Dock space or preview itself.
54. As a macOS user, I want to enable or pause all previews from the menu bar, so that capture can be stopped immediately.
55. As a macOS user, I want an optional login-start setting that is off by default, so that PDock runs automatically only after explicit consent.
56. As a macOS user, I want permission status and System Settings links available from PDock, so that authorization problems are easy to repair.
57. As a Chinese-speaking user, I want a Simplified Chinese interface, so that onboarding and settings are understandable.
58. As an English-speaking user, I want an English interface, so that PDock is usable without Chinese localization.
59. As a user of light or dark appearance, I want the panel to follow system appearance, so that it belongs visually on macOS.
60. As a user who enables reduced transparency, reduced motion, or increased contrast, I want PDock to honor those settings, so that its transient interface remains accessible.
61. As a security-conscious user, I want PDock built with public Apple interfaces, Developer ID signing, Hardened Runtime, and notarization, so that the distributed utility follows macOS security expectations.
62. As an Apple Silicon user on macOS 14 or later, I want a native arm64 application, so that PDock runs without translation.
63. As a maintainer, I want Xcode Groups to mirror the on-disk feature structure, so that Xcode, Git, Finder, and command-line navigation agree.
64. As a maintainer, I want complex Dock behavior behind one small module Interface, so that callers do not need to coordinate Accessibility, capture, ordering, or presentation details.
65. As a maintainer, I want stale capture sessions cancelled and ignored, so that asynchronous results cannot corrupt a newer panel session.
66. As a maintainer, I want deterministic behavior covered at the highest practical seam, so that tests defend user-observable contracts rather than internal plumbing.

## Implementation Decisions

- The product name is PDock and its stable bundle identifier is `com.lingmacker.PDock`.
- The deployment target is macOS 14 or later. The initial release supports Apple Silicon arm64 only.
- PDock is a menu-bar utility and does not show its own system Dock item.
- The project is a standard native macOS Xcode project with an application target and a unit-test target. The checked-in project uses ordinary Xcode Groups that mirror physical directories.
- Source organization is feature-first. Generic global groupings such as Managers, Helpers, Utilities, and Services are prohibited.
- DockPreview is the core deep Module. Its external Interface is a concrete, main-actor controller exposing only start, stop, and an observable lifecycle state: stopped, needs permissions, running, or failed.
- Dock observation, pointer hit detection, window discovery, thumbnail capture, matching, ordering, panel presentation, and Window Selection remain internal to DockPreview.
- Public protocols are not created speculatively for each subsystem. Internal Seams are introduced only where a real production adapter and deterministic test adapter both exist.
- Swift 6 is used throughout. AppKit owns the nonactivating panel, pointer tracking, application lifecycle integration, and screen/Dock geometry. SwiftUI owns onboarding, settings, menu-bar content, and Window Preview Card content.
- The app uses Apple frameworks directly and has no third-party runtime, UI, analytics, crash-reporting, architecture, project-generation, or window-management dependency.
- Accessibility is the authoritative source for Switchable Windows and exact Window Selection targets.
- ScreenCaptureKit is the source for visual thumbnails. A ScreenCaptureKit window is associated with an Accessibility window only when process identity, title, position, and size produce a unique match.
- Ambiguous or failed visual association produces an unavailable-preview placeholder. PDock never guesses and never uses a private window-number bridge.
- A Previewable Application is identified according to the application identity represented by one system Dock item. Multiple corresponding running instances contribute their Switchable Windows to the same panel; helper and renderer processes do not become applications.
- Window discovery includes user-facing top-level standard windows and excludes tabs, attached sheets, menus, tooltips, popovers, transient utility surfaces, desktop elements, and helper-process surfaces.
- The most-recently-used order is calculated when a panel opens. Existing cards retain relative order for that session. New windows insert first; closed windows are removed; title, state, and image changes update in place.
- Pointer observation is event-driven through public NSEvent monitoring plus local tracking areas. Events are throttled, Accessibility hit-testing is limited to the Dock vicinity, and input is observed without interception, modification, or replay.
- Hover presentation begins after approximately 300 ms over the same Previewable Application. Leaving both the Dock item and panel starts an approximately 250 ms dismissal grace period.
- The panel closes on completed pointer exit, outside click, Dock hiding, target application exit, loss of all Switchable Windows, global pause, permission loss, or application termination.
- The panel is nonactivating, does not become the key application, does not change the menu bar, and does not establish global keyboard interception. The initial release is pointer-driven.
- The panel can join all Spaces and appear as a full-screen auxiliary panel. It opens inward from the current Dock edge and is constrained to the display containing the active Dock item.
- The panel uses an adaptive grid with a readable minimum card size and internal scrolling when necessary. No arbitrary window-count cap is applied.
- Thumbnails preserve source aspect ratio, fit completely within bounded card imagery, and are neither cropped nor stretched. Titles are single-line and truncated when necessary.
- Visual presentation uses native macOS materials, typography, corner treatment, shadow, and accent colors, and adapts to light/dark appearance, reduced transparency, reduced motion, and increased contrast.
- Window Selection activates the owning application and exact Accessibility window, unhides or restores it when necessary, raises it, and changes Spaces when necessary. It does not resize, reposition, or move the target between displays.
- The initial image capture occurs when a panel opens. Images refresh only while the panel is visible, at approximately two updates per second, and all capture stops immediately when the session ends.
- The core controller and AppKit/Accessibility state are main-actor isolated. An internal thumbnail pipeline actor performs bounded concurrent ScreenCaptureKit work.
- Every panel session has an identity. Closing or replacing a session cancels outstanding work, and results from a stale identity are discarded.
- Captured images exist only in volatile memory for the visible session. They are released on panel close, global pause, permission loss, or application exit and are never written to persistent storage.
- PDock makes no network requests, collects no telemetry, submits no crash reports, downloads no remote configuration, and performs no automatic update check.
- Local logs may contain technical state and error categories but must not contain window images, window titles, or target-application content.
- Accessibility and Screen Recording are mandatory for the core enhancement. First launch uses sequential permission guidance. Missing or revoked permission stops Dock observation and capture, closes the panel, and exposes a recoverable status without repeatedly prompting.
- Login start uses ServiceManagement and is opt-in. It is disabled by default and can be changed without affecting the current process.
- User settings in the initial release are limited to global preview enablement, login start, permission status/actions, and application/version information. Hover timing, dismissal grace, refresh rate, layout, and animation are fixed product behavior.
- User-visible text is localized through a String Catalog in English and Simplified Chinese. Code identifiers, resource keys, and technical logs use English. Target-application window titles remain unchanged.
- Distribution uses Developer ID signing, Hardened Runtime, least-privilege declarations, Apple notarization, and stapling. App Sandbox is disabled for the initial Developer ID build.
- Integration is limited to public Accessibility, AppKit, NSWorkspace, ServiceManagement, CoreGraphics permission checks, and ScreenCaptureKit interfaces. Dock injection, private SkyLight or CGS symbols, preference mutation, and AppleScript automation are prohibited.

## Testing Decisions

- The highest automated Seam is the external Interface of the DockPreview Module. Tests should start and stop the module, supply deterministic system observations through internal adapters where necessary, and assert lifecycle state and user-visible panel models rather than call internal matching or state-machine helpers directly.
- A good automated test defends an observable contract and fails for a plausible product bug. Tests must not assert source text, private type layout, exact helper call order, framework wrapper existence, or incidental implementation details.
- DockPreview contract tests cover the hover dwell and dismissal grace behavior, application-target changes during the dwell, panel closure conditions, stable ordering, insertion and removal, exact selection identity, session cancellation, stale-result rejection, and bounded thumbnail lifecycle.
- Window-behavior fixtures cover minimized, hidden, full-screen, other-Space, multi-display, titleless, protected, capture-failed, duplicate-title, duplicate-frame, and ambiguous-correlation scenarios.
- Matching tests assert only that unique matches receive the correct thumbnail and ambiguous matches receive the unavailable state; they do not test a particular scoring implementation.
- Layout tests cover bottom, left, and right Dock edges; display-bound clamping; automatic-hiding geometry changes; magnified item frames; adaptive wrapping; internal scrolling; and extreme thumbnail aspect ratios.
- Permission-state tests cover initial denial, sequential grant, grant requiring restart, runtime revocation, restoration, global pause, and the guarantee that no observation or capture remains active while prerequisites are unmet.
- Privacy tests cover image release at session end and verify that diagnostic event payloads exclude window titles and image data.
- Menu-bar and settings tests cover global enablement, default-disabled login start, permission repair actions, and persistence of the supported settings only.
- Localization validation confirms that every user-visible PDock string has English and Simplified Chinese entries while target-provided window titles remain untouched.
- Real-Mac end-to-end acceptance is required for TCC prompts, system Dock hit detection, exact Window Selection, minimized and hidden restoration, Space switching, full-screen presentation, Dock automatic hiding and magnification, multiple displays, protected content, permission revocation, login start, pause, and quit.
- End-to-end acceptance must exercise the running application, not merely a test executable. It must observe a real Window Preview Panel and select a real target window.
- Automated tests do not claim to prove TCC, Dock, Spaces, or other-application behavior. Those contracts require the real-Mac acceptance matrix.
- There is no existing source or test suite in the repository, so no local test implementation provides prior art. New tests should follow the single high Seam established by this spec rather than inventing multiple shallow public interfaces.

## Out of Scope

- Replacing or reimplementing the system Dock.
- Managing Dock pinning, ordering, application launching, folders, files, Trash, or standalone minimized-window items.
- Showing previews for non-running applications or running applications with no Switchable Windows.
- Treating browser tabs, native window tabs, sheets, menus, popovers, tooltips, or utility panels as independent cards.
- Window close, minimize, maximize, resize, reposition, move-to-display, or drag-and-drop controls in the panel.
- Keyboard-first panel activation, global shortcuts, or global key interception.
- Per-application allowlists, denylists, or custom behavior.
- User-configurable hover delays, grace periods, refresh rates, card sizes, layouts, animations, or themes.
- Persistent or disk-backed thumbnail caching.
- Network access, telemetry, analytics, remote crash reporting, advertisements, remote configuration, or automatic update checking.
- Mac App Store distribution, an App Sandbox build, or simultaneous store and direct-distribution variants.
- Intel x86_64 support, Universal 2 packaging, or deployment below macOS 14.
- Private APIs, Dock injection, SIMBL-style extensions, SkyLight or CGS symbols, Dock preference mutation, or AppleScript control.
- Third-party libraries, project generators, or preemptive Swift Package decomposition.
- Guaranteed visual thumbnails where public Accessibility and ScreenCaptureKit metadata cannot establish a unique association.

## Further Notes

- The repository currently contains the Dock Enhancement glossary and five accepted ADRs but no application source, Xcode project, or tests. This specification defines the initial product implementation.
- The agreed testing Seam was already confirmed during domain grilling: one small DockPreview controller Interface, with internal replacement points only where deterministic testing genuinely requires a second adapter.
- The public Accessibility SDK does not expose a supported ScreenCaptureKit window identifier. Exact Accessibility target selection therefore takes precedence over showing a potentially incorrect image.
- Full implementation and release verification require a complete Xcode installation selected as the active developer directory. The current workstation exposes Swift 6.4 Command Line Tools but `xcodebuild` is unavailable through the active developer path.
- Developer ID signing, notarization, permission reset scenarios, Intel exclusion, and the real-Mac acceptance matrix must be validated using release-like builds rather than inferred from unit tests.
