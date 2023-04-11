import AppFeature
import SwiftUI

@main
struct HeuresCreusesApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .live)
        }
    }
}
