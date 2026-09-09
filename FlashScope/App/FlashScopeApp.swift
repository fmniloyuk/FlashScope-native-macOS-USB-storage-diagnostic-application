import SwiftUI

@main
struct FlashScopeApp: App {
    @State private var preferences: AppPreferences
    @State private var model: AppViewModel

    init() {
        let preferences = AppPreferences()
        let services = AppServices.make()
        _preferences = State(initialValue: preferences)
        _model = State(initialValue: AppViewModel(services: services, preferences: preferences))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .tint(FlashScopeTheme.accent)
                .preferredColorScheme(preferences.appearance.colorScheme)
                .frame(minWidth: 940, minHeight: 650)
        }
        .defaultSize(width: 1240, height: 820)

        Settings {
            SettingsView(preferences: preferences)
                .tint(FlashScopeTheme.accent)
                .preferredColorScheme(preferences.appearance.colorScheme)
        }
    }
}
