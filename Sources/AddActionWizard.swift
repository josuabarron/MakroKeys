import SwiftUI

// MARK: - Add Action Button

struct AddActionButton: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Label(L("button.add_action"), systemImage: "plus.circle")
        }
    }
}

// MARK: - Add Action Wizard Content

struct AddActionWizardView: View {
    @Binding var step: Int
    @Binding var configuredAction: Action?
    @Binding var category: String?

    @State private var enteringConfigStep = false
    @ObservedObject private var l10n = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 0) {
            Group {
                switch step {
                case 0: categoryView
                case 1: actionListView
                case 2: configView
                default: EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        }
    }

    private var categoryView: some View {
        VStack(spacing: 20) {
            Text(L("wizard.choose_category"))
                .font(.system(size: 15, weight: .medium))
                .padding(.top, 20)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                CategoryCard(
                    title: "ProPresenter",
                    subtitle: L("wizard.pp_subtitle"),
                    icon: "display",
                    color: .blue
                ) {
                    category = "pp"
                    step = 1
                }

                CategoryCard(
                    title: "X32 Mixer",
                    subtitle: L("wizard.x32_subtitle"),
                    icon: "slider.horizontal.3",
                    color: .orange
                ) {
                    category = "x32"
                    step = 1
                }

                CategoryCard(
                    title: "Lightkey",
                    subtitle: L("wizard.lightkey_subtitle"),
                    icon: "lightbulb",
                    color: .yellow
                ) {
                    category = "lightkey"
                    step = 1
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    private var actionListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L("wizard.choose_action_type"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ScrollView {
                LazyVStack(spacing: 6) {
                    if category == "pp" {
                        ForEach(ProPresenterActionType.allCases, id: \.self) { type in
                            ActionTypeRow(title: type.displayName, description: type.description) {
                                configuredAction = type.defaultAction
                                enteringConfigStep = true
                                step = 2
                            }
                        }
                    } else if category == "x32" {
                        ForEach(X32ActionType.allCases, id: \.self) { type in
                            ActionTypeRow(title: type.displayName, description: type.description) {
                                configuredAction = type.defaultAction
                                enteringConfigStep = true
                                step = 2
                            }
                        }
                    } else {
                        ForEach(LightkeyActionType.allCases, id: \.self) { type in
                            ActionTypeRow(title: type.displayName, description: type.description) {
                                configuredAction = type.defaultAction
                                enteringConfigStep = true
                                step = 2
                            }
                        }
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }

    private var configView: some View {
        VStack(spacing: 0) {
            if configuredAction != nil {
                ActionConfigForm(action: $configuredAction)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Category Card

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180, height: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Action Type Row

struct ActionTypeRow: View {
    let title: String
    let description: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
        }
        .buttonStyle(.plain)
    }
}
