#if canImport(NotificationCenter)
import ComposableArchitecture
import DependenciesAdditions
import HomeWidget
import NotificationCenter
import SwiftUI

public struct UserNotificationHomeWidget: Reducer {
    public struct State: Equatable {
        var notifications: [UserNotification] = []

        var nextNotification: UserNotification? {
            @Dependency(\.date) var date
            return notifications.sorted { $0.date < $1.date }.first { $0.date > date() }
        }

        public init(notifications: [UserNotification] = []) {
            self.notifications = notifications
        }
    }

    public enum Action: Equatable {
        case notificationsUpdated([UNNotificationContent])
        case task
    }

    public init () {}

    @Dependency(\.userNotificationCenter) var userNotificationCenter

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .notificationsUpdated(notificationsContents):
                state.notifications = notificationsContents.compactMap {
                    guard 
                        let id = $0.userInfo["heures-creuses-id"] as? String,
                        let date = $0.userInfo["heures-creuses-date"] as? Date
                    else { return nil }
                    return UserNotification(id: id, message: $0.body, date: date)
                }
                return .none
            case .task:
                return .run { send in
                    await send(.notificationsUpdated([]))
                }
            }
        }
    }
}

public struct UserNotificationHomeWidgetView: View {
    let store: StoreOf<UserNotificationHomeWidget>

    private struct ViewState: Equatable {
        let notificationsCount: Int
        let nextNotificationMessage: String?

        init(_ state: UserNotificationHomeWidget.State) {
            notificationsCount = state.notifications.count
            nextNotificationMessage = state.nextNotification?.message
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            HomeWidgetView(title: "Notifications", icon: Image(systemName: "bell.badge")) {
                VStack(alignment: .leading) {
                    Text("**Programmed notifications**: \(viewStore.notificationsCount)")
                    if let nextNotificationMessage = viewStore.nextNotificationMessage {
                        Text("**Next**: \(nextNotificationMessage)")
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
    }

    public init(store: StoreOf<UserNotificationHomeWidget>) {
        self.store = store
    }
}

#Preview {
    List {
        UserNotificationHomeWidgetView(
            store: Store(initialState: UserNotificationHomeWidget.State()) {
                UserNotificationHomeWidget()
            }
        )
    }
}
#endif
