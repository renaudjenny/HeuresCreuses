import AppFeature
import SwiftUI

@main
struct HeuresCreuses_Watch_AppApp: SwiftUI.App {
    var body: some Scene {
        WindowGroup {
            AppView(store: .live)
        }
    }
}
