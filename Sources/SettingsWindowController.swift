import SwiftUI
import AppKit

// MARK: - Settings Window Controller

final class SettingsWindowController: NSObject, NSWindowDelegate {
    private var window: NSWindow?
    private let configBinding: Binding<AppConfig>
    private let onSave: () -> Void
    private let onDismiss: () -> Void

    init(configBinding: Binding<AppConfig>, onSave: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.configBinding = configBinding
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

        let settingsView = ConnectionSettingsView(config: configBinding, onSave: onSave)
        let hostingController = NSHostingController(rootView: settingsView)

        let win = NSWindow(contentViewController: hostingController)
        win.title = L("window.settings")
        win.styleMask = [.titled, .closable]
        win.setContentSize(NSSize(width: 500, height: 500))
        win.center()
        win.delegate = self
        self.window = win

        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        onSave()
        window = nil
        onDismiss()
    }
}

// MARK: - Connection Settings

struct ConnectionSettingsView: View {
    @StateObject private var executor = ActionExecutor.shared
    @ObservedObject private var l10n = LocalizationManager.shared
    @Binding var config: AppConfig
    let onSave: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("settings.title"))
                .font(.system(size: 16, weight: .semibold))

            GroupBox {
                HStack {
                    Text(L("settings.language"))
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Picker("", selection: languageBinding) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.nativeName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }

            GroupBox {
                HStack {
                    Text(L("settings.button_count"))
                        .font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Stepper(L("settings.buttons_value", config.buttonCount), value: buttonCountBinding, in: AppConfig.minimumButtonCount...AppConfig.maximumButtonCount)
                        .frame(width: 170)
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("ProPresenter")
                            .font(.system(size: 13, weight: .semibold))
                        Button {
                            openProPresenterDocs()
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .buttonStyle(.plain)
                        .help(L("help.pp_docs"))
                        Spacer()
                        Circle()
                            .fill(executor.isConnectedPP ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                    }

                    HStack(spacing: 14) {
                        LabeledContent("IP") {
                            TextField("Host", text: ppHostBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        LabeledContent("Port") {
                            TextField("Port", text: ppPortBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 74)
                        }
                    }
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("X32 Mixer")
                            .font(.system(size: 13, weight: .semibold))
                        Button {
                            openX32Docs()
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .buttonStyle(.plain)
                        .help(L("help.x32_docs"))
                        Spacer()
                        Circle()
                            .fill(executor.isConnectedX32 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                    }

                    HStack(spacing: 14) {
                        LabeledContent("IP") {
                            TextField("IP", text: x32IPBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        LabeledContent("OSC Port") {
                            TextField("Port", text: x32PortBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 74)
                        }
                    }
                }
            }

            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Lightkey")
                            .font(.system(size: 13, weight: .semibold))
                        Button {
                            openLightkeyDocs()
                        } label: {
                            Image(systemName: "questionmark.circle")
                        }
                        .buttonStyle(.plain)
                        .help(L("help.lightkey_docs"))
                        Spacer()
                        Circle()
                            .fill(executor.isConnectedLightkey ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                    }

                    HStack(spacing: 14) {
                        LabeledContent("URL") {
                            TextField("Host", text: lightkeyHostBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 170)
                        }
                        LabeledContent("OSC Port") {
                            TextField("Port", text: lightkeyPortBinding)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 74)
                        }
                    }
                }
            }

        }
        .font(.system(size: 12))
        .padding(18)
        .frame(width: 500, height: 500)
        .onAppear {
            config.normalize()
            triggerProPresenterTest()
            triggerX32Test()
            triggerLightkeyTest()
        }
    }

    private var ppHostBinding: Binding<String> {
        Binding(
            get: { config.connections.ppHost },
            set: { newHost in
                config.connections.ppHost = newHost
                saveAndTestProPresenter()
            }
        )
    }

    private var languageBinding: Binding<AppLanguage> {
        Binding(
            get: { config.language },
            set: { language in
                config.language = language
                l10n.setLanguage(language)
                onSave()
            }
        )
    }

    private var buttonCountBinding: Binding<Int> {
        Binding(
            get: { config.buttonCount },
            set: { newCount in
                config.buttonCount = min(max(newCount, AppConfig.minimumButtonCount), AppConfig.maximumButtonCount)
                config.ensureShortcutCapacity()
                onSave()
            }
        )
    }

    private var ppPortBinding: Binding<String> {
        Binding(
            get: { String(config.connections.ppPort) },
            set: { newPort in
                if let port = Int(newPort) {
                    config.connections.ppPort = port
                    saveAndTestProPresenter()
                }
            }
        )
    }

    private var x32IPBinding: Binding<String> {
        Binding(
            get: { config.connections.x32IP },
            set: { newIP in
                config.connections.x32IP = newIP
                saveAndTestX32()
            }
        )
    }

    private var x32PortBinding: Binding<String> {
        Binding(
            get: { String(config.connections.x32Port) },
            set: { newPort in
                if let port = Int(newPort) {
                    config.connections.x32Port = port
                    saveAndTestX32()
                }
            }
        )
    }

    private var lightkeyHostBinding: Binding<String> {
        Binding(
            get: { config.connections.lightkeyHost },
            set: { newHost in
                config.connections.lightkeyHost = newHost
                saveAndTestLightkey()
            }
        )
    }

    private var lightkeyPortBinding: Binding<String> {
        Binding(
            get: { String(config.connections.lightkeyPort) },
            set: { newPort in
                if let port = Int(newPort) {
                    config.connections.lightkeyPort = port
                    saveAndTestLightkey()
                }
            }
        )
    }

    private func saveAndTestProPresenter() {
        onSave()
        triggerProPresenterTest()
    }

    private func triggerProPresenterTest() {
        executor.configure(connections: config.connections)
        Task { await executor.testConnection() }
    }

    private func saveAndTestX32() {
        onSave()
        triggerX32Test()
    }

    private func triggerX32Test() {
        executor.configure(connections: config.connections)
        Task { await executor.testX32Connection() }
    }

    private func saveAndTestLightkey() {
        onSave()
        triggerLightkeyTest()
    }

    private func triggerLightkeyTest() {
        executor.configure(connections: config.connections)
        Task { await executor.testLightkeyConnection() }
    }

    private func openProPresenterDocs() {
        let url = "http://\(config.connections.ppHost):\(config.connections.ppPort)/v1/doc/index.html"
        openURL(url)
    }

    private func openX32Docs() {
        openURL("https://wiki.munichmakerlab.de/images/1/17/UNOFFICIAL_X32_OSC_REMOTE_PROTOCOL_%281%29.pdf")
    }

    private func openLightkeyDocs() {
        openURL("https://lightkeyapp.com/media/pages/help/manual/0def2c007d-1779439202/Lightkey%20User%20Guide.pdf")
    }

    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
