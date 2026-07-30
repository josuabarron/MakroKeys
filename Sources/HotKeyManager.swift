import Foundation
import Carbon

// MARK: - Carbon HotKey Manager

class HotKeyManager {
    static let shared = HotKeyManager()

    private var hotKeyRefs: [Int: EventHotKeyRef?] = [:]
    private var eventHandler: EventHandlerRef?
    var onHotKey: ((Int) -> Void)?

    private init() {}

    func register(shortcuts: [Shortcut]) {
        // Remove existing
        unregisterAll()

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handler: EventHandlerUPP = { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
            if status == noErr {
                DispatchQueue.main.async {
                    HotKeyManager.shared.onHotKey?(Int(hotKeyID.id))
                }
            }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)

        // Register each hotkey
        for shortcut in shortcuts where shortcut.enabled {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: OSType(0x4D4B4559), id: UInt32(shortcut.keyNumber))  // 'MKEY'

            let status = RegisterEventHotKey(shortcut.hotKey.keyCode, shortcut.hotKey.modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
            if status == noErr {
                hotKeyRefs[shortcut.keyNumber] = hotKeyRef
            } else {
                print("HotKey registration failed for \(shortcut.keyLabel): \(status)")
            }
        }

        print("Registered \(hotKeyRefs.count) hotkeys")
    }

    func unregisterAll() {
        for (_, ref) in hotKeyRefs {
            if let ref = ref {
                UnregisterEventHotKey(ref)
            }
        }
        hotKeyRefs.removeAll()
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    deinit {
        unregisterAll()
    }
}
