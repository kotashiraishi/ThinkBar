#if os(macOS)
import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var globalShortcutController: GlobalShortcutController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = GlobalShortcutController()
        controller.register()
        globalShortcutController = controller
    }
}
#endif
