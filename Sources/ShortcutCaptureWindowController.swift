import SwiftUI
import AppKit
import Carbon

// MARK: - Shortcut Capture Window Controller

final class ShortcutCaptureWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let shortcutBinding: Binding<Shortcut>
    private let onSave: () -> Void
    private let onDismiss: () -> Void

    init(shortcutBinding: Binding<Shortcut>, onSave: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.shortcutBinding = shortcutBinding
        self.onSave = onSave
        self.onDismiss = onDismiss
        super.init()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        HotKeyManager.shared.unregisterAll()

        let view = ShortcutCaptureView(
            shortcut: shortcutBinding,
            onSave: onSave,
            onDismiss: { [weak self] in
                self?.close()
            }
        )
        let hostingController = NSHostingController(rootView: view)

        let win = NSWindow(contentViewController: hostingController)
        win.title = L("window.change_shortcut")
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 380, height: 210))
        win.center()
        win.delegate = self
        self.window = win

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close() {
        window?.close()
        window = nil
    }

    func windowWillClose(_ notification: Notification) {
        onSave()
        window = nil
        onDismiss()
    }
}

// MARK: - Shortcut Capture View

struct ShortcutCaptureView: View {
    @Binding var shortcut: Shortcut
    let onSave: () -> Void
    let onDismiss: () -> Void

    @State private var capturedHotKey: HotKey?
    @State private var eventMonitor: Any?
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(shortcut.label.isEmpty ? L("shortcut.default_name", shortcut.keyNumber) : shortcut.label)
                .font(.system(size: 15, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text(L("shortcut.current"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(shortcut.keyLabel)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L("shortcut.press_new"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                Text(capturedHotKey?.displayName ?? L("shortcut.listening"))
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()

            HStack {
                Spacer()
                Button(L("button.back")) { onDismiss() }
                    .buttonStyle(.bordered)
                Button(L("button.save")) {
                    if let capturedHotKey {
                        shortcut.hotKey = capturedHotKey
                        onSave()
                        onDismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(capturedHotKey == nil)
            }
        }
        .padding(18)
        .frame(width: 380, height: 210)
        .onAppear {
            startListening()
        }
        .onDisappear {
            stopListening()
        }
    }

    private func startListening() {
        stopListening()
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            capturedHotKey = hotKey(from: event)
            return nil
        }
    }

    private func stopListening() {
        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }

    private func hotKey(from event: NSEvent) -> HotKey {
        HotKey(
            keyCode: UInt32(event.keyCode),
            modifiers: carbonModifiers(from: event.modifierFlags),
            keyEquivalent: keyEquivalent(from: event)
        )
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var modifiers: UInt32 = 0
        if flags.contains(.command) { modifiers |= UInt32(cmdKey) }
        if flags.contains(.option) { modifiers |= UInt32(optionKey) }
        if flags.contains(.control) { modifiers |= UInt32(controlKey) }
        if flags.contains(.shift) { modifiers |= UInt32(shiftKey) }
        return modifiers
    }

    private func keyEquivalent(from event: NSEvent) -> String {
        if let namedKey = namedKey(for: event.keyCode) {
            return namedKey
        }
        if let characterKey = characterKey(for: event.keyCode) {
            return characterKey
        }
        let raw = event.charactersIgnoringModifiers ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? L("hotkey.key", event.keyCode) : trimmed.uppercased()
    }

    private func characterKey(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 50: return "`"
        default: return nil
        }
    }

    private func namedKey(for keyCode: UInt16) -> String? {
        switch keyCode {
        case 36: return "Return"
        case 48: return "Tab"
        case 49: return "Space"
        case 51: return "Delete"
        case 53: return "Esc"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 109: return "F10"
        case 111: return "F12"
        case 118: return "F4"
        case 120: return "F2"
        case 122: return "F1"
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        default: return nil
        }
    }
}
