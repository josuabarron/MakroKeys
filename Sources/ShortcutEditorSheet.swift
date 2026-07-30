import SwiftUI

// MARK: - Shortcut Editor Sheet

struct ShortcutEditorSheet: View {
    @Binding private var shortcut: Shortcut
    @State private var draft: Shortcut
    let onSave: () -> Void
    let onDismiss: () -> Void
    @State private var renderKey: Int = 0
    @State private var isAddingAction = false
    @State private var addActionStep = 0
    @State private var addActionCategory: String?
    @State private var configuredAction: Action?
    @ObservedObject private var l10n = LocalizationManager.shared

    init(shortcut: Binding<Shortcut>, onSave: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self._shortcut = shortcut
        self._draft = State(initialValue: shortcut.wrappedValue)
        self.onSave = onSave
        self.onDismiss = onDismiss
    }

    var body: some View {
        VStack(spacing: 0) {
            if isAddingAction {
                AddActionWizardView(
                    step: $addActionStep,
                    configuredAction: $configuredAction,
                    category: $addActionCategory
                )
            } else {
                editorForm
            }

            Divider()
            footer
        }
        .frame(minWidth: 560, minHeight: 520)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Spacer()

            if isAddingAction {
                Button(L("button.back")) {
                    goBackInAddAction()
                }
                .buttonStyle(.bordered)

                if addActionStep == 2, let finalAction = configuredAction {
                    Button(L("button.add_action")) {
                        actionsBinding.wrappedValue.append(finalAction)
                        renderKey += 1
                        exitAddAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            } else {
                Button(L("button.done")) {
                    commitDraft()
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }

    private var editorForm: some View {
        Form {
            Section(L("editor.label")) {
                TextField(L("editor.short_description"), text: labelBinding)
            }

            Section(L("editor.actions_count", draft.actions.count)) {
                ForEach(Array(draft.actions.enumerated()), id: \.offset) { idx, action in
                    HStack {
                        Text(action.displayName)
                            .font(.system(size: 12))
                        Spacer()
                        Button {
                            guard draft.actions.indices.contains(idx) else { return }
                            draft.actions.remove(at: idx)
                            commitDraft()
                            renderKey += 1
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }
                .id(renderKey)

                AddActionButton {
                    enterAddAction()
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }

    private var actionsBinding: Binding<[Action]> {
        Binding(
            get: { draft.actions },
            set: { newActions in
                draft.actions = newActions
                commitDraft()
            }
        )
    }

    private var labelBinding: Binding<String> {
        Binding(
            get: { draft.label },
            set: { newLabel in
                draft.label = newLabel
                commitDraft()
            }
        )
    }

    private func commitDraft() {
        shortcut = draft
        onSave()
    }

    private func enterAddAction() {
        addActionStep = 0
        addActionCategory = nil
        configuredAction = nil
        isAddingAction = true
    }

    private func exitAddAction() {
        addActionStep = 0
        addActionCategory = nil
        configuredAction = nil
        isAddingAction = false
    }

    private func goBackInAddAction() {
        if addActionStep == 0 {
            exitAddAction()
        } else {
            addActionStep -= 1
            if addActionStep < 2 {
                configuredAction = nil
            }
        }
    }
}
