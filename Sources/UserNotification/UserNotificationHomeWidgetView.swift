import ComposableArchitecture
import HomeWidget
import SwiftUI

public struct UserNotificationHomeWidgetView: View {
    public var body: some View {
        HomeWidgetView(title: "Notifications", icon: Image(systemName: "bell.badge")) {
            VStack(alignment: .leading) {
                Text("**Programmed notifications**: 2")
                Text("""
                **Next**: Gray diswasher
                Program 30º Eco
                Delay 4 hours
                """)
                .font(.footnote)
                .multilineTextAlignment(.leading)
            }
        }
    }

    public init() {}
}

#Preview {
    List {
        UserNotificationHomeWidgetView()
    }
}
