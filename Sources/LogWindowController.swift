import SwiftUI
import AppKit

// MARK: - Log Window Controller

final class LogWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let onDismiss: () -> Void

    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
        super.init()
    }

    func show() {
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(rootView: LogWindowView())

        let win = NSWindow(contentViewController: hostingController)
        win.title = L("window.log")
        win.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        win.setContentSize(NSSize(width: 680, height: 320))
        win.minSize = NSSize(width: 520, height: 240)
        win.center()
        win.delegate = self
        self.window = win

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        window = nil
        onDismiss()
    }
}

// MARK: - Log Window

struct LogWindowView: View {
    @StateObject private var executor = ActionExecutor.shared
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("log.title"))
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Button {
                    executor.lastLog = []
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
                .disabled(executor.lastLog.isEmpty)
                .help(L("help.clear_log"))
            }

            Divider()

            if executor.lastLog.isEmpty {
                Text(L("log.empty"))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(executor.lastLog.enumerated()), id: \.offset) { _, entry in
                            Text(entry)
                                .font(.system(size: 12, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .frame(minWidth: 520, minHeight: 240)
    }
}
