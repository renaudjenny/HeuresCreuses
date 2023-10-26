import ComposableArchitecture
import SendNotification
import SwiftUI
import UserNotificationsDependency

@Reducer
public struct UserNotificationsList {
    public struct State: Equatable {
        var notifications: IdentifiedArrayOf<UserNotification> = []
    }

    public enum Action: Equatable {
        case delete(IndexSet)
        case notificationsUpdated([UNNotificationRequest])
        case task
    }

    @Dependency(\.continuousClock) var clock
    @Dependency(\.userNotificationCenter) var userNotificationCenter

    private enum CancelID { case timer }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .delete(indexSet):
                let ids = indexSet.map { state.notifications[$0].id }
                userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
                return .run { send in
                    let notifications = await userNotificationCenter.pendingNotificationRequests()
                    await send(.notificationsUpdated(notifications))
                }
            case let .notificationsUpdated(notifications):
                state.notifications = IdentifiedArrayOf(uniqueElements: notifications.map(\.userNotification))
                return .none
            case .task:
                return .run { send in
                    let notifications = await userNotificationCenter.pendingNotificationRequests()
                    await send(.notificationsUpdated(notifications))
                    
                    for await _ in clock.timer(interval: .seconds(5)) {
                        let notifications = await userNotificationCenter.pendingNotificationRequests()
                        await send(.notificationsUpdated(notifications))
                    }
                }
                .cancellable(id: CancelID.timer)
            }
        }
    }
}

struct UserNotificationsListView: View {
    let store: StoreOf<UserNotificationsList>

    private struct ViewState: Equatable {
        let notifications: IdentifiedArrayOf<UserNotification>

        init(_ state: UserNotificationsList.State) {
            notifications = state.notifications
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            List {
                ForEach(viewStore.notifications) { notification in
                    Text(notification.message)
                }
                .onDelete(perform: { viewStore.send(.delete($0)) })
            }
            .navigationTitle("^[\(viewStore.notifications.count) pending notifications](inflect: true)")
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
    }
}

extension UNNotificationRequest {

    var userNotification: UserNotification {
        let date = (trigger as? UNTimeIntervalNotificationTrigger)?.nextTriggerDate()
        @Dependency(\.date.now) var now
        return UserNotification(id: identifier, message: content.body, date: date ?? now)
    }
}

#Preview {
    NavigationStack {
        UserNotificationsListView(store: Store(initialState: UserNotificationsList.State()) {
            UserNotificationsList()
                .transformDependency(\.userNotificationCenter) { dependency in
                    dependency.$pendingNotificationRequests = { @Sendable in
                        let content = UNMutableNotificationContent()
                        content.body = "Test notification body"
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12345, repeats: false)
                        return [UNNotificationRequest(identifier: "1234", content: content, trigger: trigger)]
                    }
                }
        })
    }
}
