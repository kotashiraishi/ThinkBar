import Foundation

#if os(macOS)
import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalShortcutController {
    private var eventHandler: EventHandlerRef?
    private var hotKey: EventHotKeyRef?

    func register() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else {
                    return OSStatus(eventNotHandledErr)
                }

                let controller = Unmanaged<GlobalShortcutController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                Task { @MainActor in
                    controller.toggleWindow()
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandler
        )

        let hotKeyID = EventHotKeyID(
            signature: 0x54484B42,
            id: 1
        )

        RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey | cmdKey),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKey
        )
    }

    func toggleWindow() {
        guard let window = NSApp.windows.first else { return }

        if window.isVisible && NSApp.isActive {
            NSApp.hide(nil)
            return
        }

        NSApp.unhide(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        Task { @MainActor in
            await Task.yield()
            NotificationCenter.default.post(name: .focusThinkBarInput, object: nil)
        }
    }

    deinit {
        if let hotKey {
            UnregisterEventHotKey(hotKey)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
#endif

extension Notification.Name {
    static let focusThinkBarInput = Notification.Name("focusThinkBarInput")
}
