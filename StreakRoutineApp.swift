import SwiftUI

@main
struct StreakRoutineApp: App {
    @StateObject private var store = Store()
    @Environment(\.scenePhase) private var phase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .onAppear { Notifier.requestAuth() }
                .onChange(of: phase) { _, new in
                    if new == .active { store.evaluatePastDays() }
                }
        }
    }
}
