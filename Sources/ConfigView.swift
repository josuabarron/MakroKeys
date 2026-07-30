import SwiftUI
import AppKit

// MARK: - Main Config View

struct ConfigView: View {
    @Binding var config: AppConfig
    let onSave: () -> Void
    @ObservedObject private var l10n = LocalizationManager.shared
    @State private var _refresh: Int = 0
    @State private var editorControllers: [Int: EditorWindowController] = [:]
    @State private var shortcutCaptureControllers: [Int: ShortcutCaptureWindowController] = [:]
    @State private var settingsWindowController: SettingsWindowController?
    @State private var logWindowController: LogWindowController?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("MacroKeys")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
                Button(action: {
                    openLogWindow()
                }) {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .buttonStyle(.plain)
                .help(L("help.open_log"))
                Button(action: {
                    openSettingsWindow()
                }) {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .help(L("help.open_settings"))
            }
            .padding()

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach($config.shortcuts) { $shortcut in
                        ShortcutCardView(
                            shortcut: $shortcut,
                            onSave: saveWithRefresh,
                            onEdit: openEditorWindow,
                            onChangeHotKey: openShortcutCaptureWindow
                        )
                    }
                }
                .padding()
            }
            .id(_refresh)
            .id(l10n.language)

            Divider()
        }
        .frame(minWidth: 640, minHeight: 600)
    }

    private func saveWithRefresh() {
        onSave()
        _refresh += 1
    }

    private func openEditorWindow(shortcut: Binding<Shortcut>) {
        let keyNumber = shortcut.wrappedValue.keyNumber

        if let controller = editorControllers[keyNumber] {
            controller.show()
            return
        }

        let controller = EditorWindowController(
            shortcutBinding: shortcut,
            onSave: saveWithRefresh,
            onDismiss: {
                editorControllers[keyNumber] = nil
            }
        )
        editorControllers[keyNumber] = controller
        controller.show()
    }

    private func openShortcutCaptureWindow(shortcut: Binding<Shortcut>) {
        let keyNumber = shortcut.wrappedValue.keyNumber

        if let controller = shortcutCaptureControllers[keyNumber] {
            controller.show()
            return
        }

        let controller = ShortcutCaptureWindowController(
            shortcutBinding: shortcut,
            onSave: saveWithRefresh,
            onDismiss: {
                shortcutCaptureControllers[keyNumber] = nil
            }
        )
        shortcutCaptureControllers[keyNumber] = controller
        controller.show()
    }

    private func openSettingsWindow() {
        if let controller = settingsWindowController {
            controller.show()
            return
        }

        let controller = SettingsWindowController(
            configBinding: $config,
            onSave: saveWithRefresh,
            onDismiss: {
                settingsWindowController = nil
            }
        )
        settingsWindowController = controller
        controller.show()
    }

    private func openLogWindow() {
        if let controller = logWindowController {
            controller.show()
            return
        }

        let controller = LogWindowController(
            onDismiss: {
                logWindowController = nil
            }
        )
        logWindowController = controller
        controller.show()
    }
}

// MARK: - Shortcut Card

struct ShortcutCardView: View {
    @Binding var shortcut: Shortcut
    let onSave: () -> Void
    let onEdit: (Binding<Shortcut>) -> Void
    let onChangeHotKey: (Binding<Shortcut>) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onChangeHotKey($shortcut)
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(shortcut.enabled ? Color.accentColor : Color.gray.opacity(0.4))
                        .frame(width: 72, height: 52)
                    Text(shortcut.keyLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 6)
                }
            }
            .buttonStyle(.plain)
            .help(L("help.change_shortcut"))

            VStack(alignment: .leading, spacing: 4) {
                Text(shortcut.label.isEmpty ? L("shortcut.default_name", shortcut.keyNumber) : shortcut.label)
                    .font(.system(size: 13, weight: .semibold))
                Text(shortcut.actions.isEmpty ? L("shortcut.no_actions") : shortcut.actions.map(\.displayName).joined(separator: "\n"))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            Spacer()

            Button {
                shortcut.actions = []
                onSave()
            } label: {
                Image(systemName: "trash")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)

            Button {
                onEdit($shortcut)
            } label: {
                Image(systemName: "pencil")
            }
            .buttonStyle(.bordered)

            Button {
                Task {
                    await ActionExecutor.shared.execute(actions: shortcut.actions)
                }
            } label: {
                Image(systemName: "play.fill")
                    .foregroundStyle(shortcut.actions.isEmpty ? .gray : .green)
            }
            .buttonStyle(.bordered)
            .disabled(shortcut.actions.isEmpty)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.06), radius: 2, y: 1)
        )
        .opacity(shortcut.enabled ? 1 : 0.6)
    }
}
