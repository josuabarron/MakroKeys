import SwiftUI
import AppKit

// MARK: - Editor Window Controller

final class EditorWindowController: NSObject, NSWindowDelegate {
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

        let editorView = ShortcutEditorSheet(
            shortcut: shortcutBinding,
            onSave: onSave,
            onDismiss: { [weak self] in
                self?.close()
            }
        )

        let hostingController = NSHostingController(rootView: editorView)

        let win = NSWindow(contentViewController: hostingController)
        win.title = L("window.edit_shortcut", shortcutBinding.wrappedValue.keyLabel)
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        win.setContentSize(NSSize(width: 640, height: 620))
        win.minSize = NSSize(width: 560, height: 520)
        win.center()
        win.delegate = self
        self.window = win

        win.makeKeyAndOrderFront(nil)
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
