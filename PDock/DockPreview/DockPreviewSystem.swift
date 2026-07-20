import Foundation

@MainActor
protocol DockPreviewSystem: AnyObject {
    var permissionState: DockPreviewPermissionState { get }

    func startObserving(_ handler: @escaping @MainActor (DockPreviewEvent) -> Void)
    func stopObserving()
    func switchableWindows(for application: PreviewableApplication) async -> [SwitchableWindow]
    func present(
        _ presentation: WindowPreviewPresentation,
        onSelect: @escaping @MainActor (WindowIdentity) -> Void,
        onClose: @escaping @MainActor (WindowIdentity) -> Void
    )
    func update(_ presentation: WindowPreviewPresentation)
    func dismissPanel()
    func selectWindow(_ id: WindowIdentity)
    func closeWindow(_ id: WindowIdentity)
}
