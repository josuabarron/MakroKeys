import AppKit
import SwiftUI

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var configWindow: NSWindow!
    private var config: AppConfig = ConfigStore.load()

    func applicationDidFinishLaunching(_ notification: Notification) {
        config.normalize()
        configureApplicationMenu()

        // Configure executor
        ActionExecutor.shared.configure(connections: config.connections)

        // Setup status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let btn = statusItem.button {
            btn.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MacroKeys")
        }
        statusItem.menu = buildMenu()

        // Setup hotkeys
        HotKeyManager.shared.register(shortcuts: config.activeShortcuts)
        HotKeyManager.shared.onHotKey = { [weak self] keyNumber in
            self?.triggerShortcut(keyNumber: keyNumber)
        }

        // Open config window
        openConfigWindow()
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterAll()
    }

    private func configureApplicationMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)

        let appMenu = NSMenu(title: "MacroKeys")
        appMenuItem.submenu = appMenu
        appMenu.addItem(NSMenuItem(title: "About MacroKeys", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: L("menu.quit"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let editMenuItem = NSMenuItem()
        mainMenu.addItem(editMenuItem)

        let editMenu = NSMenu(title: "Edit")
        editMenuItem.submenu = editMenu
        editMenu.addItem(NSMenuItem(title: "Undo", action: Selector(("undo:")), keyEquivalent: "z"))
        editMenu.addItem(NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
        editMenu.addItem(NSMenuItem(title: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
        editMenu.addItem(NSMenuItem(title: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        editMenu.addItem(NSMenuItem(title: "Paste and Match Style", action: #selector(NSTextView.pasteAsPlainText(_:)), keyEquivalent: "V"))
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(NSMenuItem(title: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a"))

        NSApp.mainMenu = mainMenu
    }

    // MARK: - Actions

    private func triggerShortcut(keyNumber: Int) {
        guard keyNumber <= config.buttonCount,
              let shortcut = config.activeShortcuts.first(where: { $0.keyNumber == keyNumber && $0.enabled }),
              !shortcut.actions.isEmpty else { return }

        Task { @MainActor in
            let succeeded = await ActionExecutor.shared.execute(actions: shortcut.actions)
            ShortcutOverlayController.shared.show(shortcut: shortcut, failed: !succeeded)
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
        config.normalize()
        _ = ConfigStore.save(config)
        Task { @MainActor in
            ActionExecutor.shared.configure(connections: config.connections)
        }

        HotKeyManager.shared.unregisterAll()
        HotKeyManager.shared.register(shortcuts: config.activeShortcuts)
        statusItem.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        menu.addItem(NSMenuItem(title: "MacroKeys", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        for shortcut in config.activeShortcuts where shortcut.enabled {
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
