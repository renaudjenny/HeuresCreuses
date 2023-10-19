#if canImport(NotificationCenter)
import ComposableArchitecture
import HomeWidget
import NotificationCenter
import SendNotification
import SwiftUI
import UserNotificationsDependency

public struct UserNotificationHomeWidget: Reducer {
    public struct State: Equatable {
        var notifications: [UserNotification] = []
        @PresentationState var destination: UserNotificationsList.State?

        var nextNotification: UserNotification? {
            @Dependency(\.date) var date
            return notifications.sorted { $0.date < $1.date }.first { $0.date > date() }
        }

        public init(notifications: [UserNotification] = [], destination: UserNotificationsList.State? = nil) {
            self.notifications = notifications
            self.destination = destination
        }
    }

    public enum Action: Equatable {
        case destination(PresentationAction<UserNotificationsList.Action>)
        case notificationsUpdated([UNNotificationRequest])
        case task
        case widgetTapped
    }

    enum CancelID { case timer }

    public init () {}

    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.continuousClock) var clock

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .destination:
                return .none
            case let .notificationsUpdated(notificationsContents):
                state.notifications = notificationsContents.compactMap {
                    guard
                        let trigger = $0.trigger as? UNTimeIntervalNotificationTrigger,
                        let date = trigger.nextTriggerDate()
                    else { return nil }
                    return UserNotification(id: $0.identifier, message: $0.content.body, date: date)
                }
                return .none
            case .task:
                return .run { send in
                    // TODO: replace this regular polling per something smarter with an extension of this dependency
                    let notifications = await userNotificationCenter.pendingNotificationRequests()
                    await send(.notificationsUpdated(notifications))
                    for await _ in clock.timer(interval: .seconds(5)) {
                        let notifications = await userNotificationCenter.pendingNotificationRequests()
                        await send(.notificationsUpdated(notifications))
                    }
                }
                .cancellable(id: CancelID.timer)
            case .widgetTapped:
                state.destination = UserNotificationsList.State(
                    notifications: IdentifiedArray(uniqueElements: state.notifications)
                )
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            UserNotificationsList()
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
            Button { viewStore.send(.widgetTapped) } label: {
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
            }
            .buttonStyle(.plain)
            .navigationDestination(
                store: store.scope(state: \.$destination, action: { .destination($0) }),
                destination: UserNotificationsListView.init
            )
            .task { @MainActor in await viewStore.send(.task).finish() }
        }
    }

    public init(store: StoreOf<UserNotificationHomeWidget>) {
        self.store = store
    }
}

#Preview {
    NavigationStack {
        List {
            UserNotificationHomeWidgetView(
                store: Store(initialState: UserNotificationHomeWidget.State()) {
                    UserNotificationHomeWidget()
                        .transformDependency(\.userNotificationCenter) { dependency in
                            dependency.$pendingNotificationRequests = { @Sendable in
                                let content = UNMutableNotificationContent()
                                content.body = "Test notification body"
                                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 12345, repeats: false)
                                return [UNNotificationRequest(identifier: "1234", content: content, trigger: trigger)]
                            }
                        }
                }
            )
        }
    }
}
#endif
