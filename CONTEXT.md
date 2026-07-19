# Dock Enhancement

This context covers adding window-oriented interactions to the existing macOS Dock without replacing or reimplementing the Dock itself.

## Language

**System Dock Enhancement**:
A capability layered on top of the existing macOS Dock while leaving the Dock responsible for launching, pinning, ordering, and displaying applications.
_Avoid_: Dock replacement, custom Dock

**Switchable Window**:
A user-facing top-level application window that can be selected and brought forward, including minimized, hidden, full-screen, and other-Space windows. Tabs and attached sheets belong to their containing window rather than becoming separate Switchable Windows.
_Avoid_: visible window, on-screen window, tab, every window

**Window Selection**:
The act of activating an application and bringing one specific Switchable Window forward, restoring it or changing Spaces when necessary without altering its size or position.
_Avoid_: application activation, opening a window

**Previewable Application**:
The application identity represented by one system Dock application item, with at least one associated running process owning a Switchable Window. Multiple instances represented by the same Dock item belong to the same Previewable Application.
_Avoid_: Dock item, process, running instance

**Window Preview Card**:
The selectable representation of one Switchable Window, consisting of its current visual thumbnail and window title.
_Avoid_: app preview, window list item

**Window Preview Panel**:
The transient, nonactivating collection of Window Preview Cards shown for one Previewable Application while the pointer interaction remains active.
_Avoid_: preview window, app switcher, popover
