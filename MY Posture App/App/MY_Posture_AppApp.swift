import SwiftUI
import SwiftData

@main
struct MY_Posture_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [PatientEntity.self, SessionEntity.self])
    }
}
