import AppKit
import SwiftUI

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var configWindow: NSWindow!
    private var config: AppConfig = ConfigStore.load()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure executor
        ActionExecutor.shared.configure(connections: config.connections)

        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MacroKeys")
        }
        statusItem.menu = buildMenu()

        // Setup hotkeys
        HotKeyManager.shared.register(shortcuts: config.shortcuts)
        HotKeyManager.shared.onHotKey = { [weak self] keyNumber in
            self?.triggerShortcut(keyNumber: keyNumber)
        }

        // Open config window
        openConfigWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterAll()
    }

    // MARK: - Actions

    private func triggerShortcut(keyNumber: Int) {
        guard let shortcut = config.shortcuts.first(where: { $0.keyNumber == keyNumber && $0.enabled }),
              !shortcut.actions.isEmpty else { return }

        Task { @MainActor in
            ShortcutOverlayController.shared.show(shortcut: shortcut)
            await ActionExecutor.shared.execute(actions: shortcut.actions)
        }
    }

    private func openConfigWindow() {
        if configWindow == nil {
            let binding = Binding(
                get: { self.config },
                set: { self.config = $0 }
            )
            let view = ConfigView(config: binding, onSave: saveAndReregister)
            configWindow = NSWindow(contentViewController: NSHostingController(rootView: view))
            configWindow.title = L("window.configuration")
            configWindow.styleMask = [.titled, .closable, .resizable, .miniaturizable]
            configWindow.setContentSize(NSSize(width: 680, height: 640))
            configWindow.minSize = NSSize(width: 640, height: 560)
        }
        configWindow.title = L("window.configuration")
        configWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func saveAndReregister() {
        _ = ConfigStore.save(config)
        Task { @MainActor in
            ActionExecutor.shared.configure(connections: config.connections)
        }

        HotKeyManager.shared.unregisterAll()
        HotKeyManager.shared.register(shortcuts: config.shortcuts)
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "MacroKeys", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        for shortcut in config.shortcuts where shortcut.enabled {
            let item = NSMenuItem(
                title: "\(shortcut.keyLabel) — \(shortcut.label)",
                action: #selector(menuTriggerShortcut(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = shortcut.keyNumber
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.settings"), action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        return menu
    }

    @objc private func menuTriggerShortcut(_ sender: NSMenuItem) {
        if let keyNumber = sender.representedObject as? Int {
            triggerShortcut(keyNumber: keyNumber)
        }
    }

    @objc private func openSettings() {
        openConfigWindow()
    }
}
