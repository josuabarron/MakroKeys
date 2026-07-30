import Foundation
import Combine

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case german = "de"
    case english = "en"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .german: return "Deutsch"
        case .english: return "English"
        }
    }
}

final class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var language: AppLanguage
    private var translations: [String: String] = [:]

    private init() {
        language = ConfigStore.loadLanguage()
        loadTranslations()
    }

    func setLanguage(_ language: AppLanguage) {
        guard self.language != language else { return }
        self.language = language
        loadTranslations()
    }

    func text(_ key: String, _ arguments: [CVarArg] = []) -> String {
        let format = translations[key] ?? key
        guard !arguments.isEmpty else { return format }
        return String(format: format, locale: Locale(identifier: language.rawValue), arguments: arguments)
    }

    private func loadTranslations() {
        guard let url = Bundle.main.url(forResource: language.rawValue, withExtension: "json", subdirectory: "Localization"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            translations = [:]
            return
        }

        translations = decoded
    }
}

func L(_ key: String, _ arguments: CVarArg...) -> String {
    LocalizationManager.shared.text(key, arguments)
}
