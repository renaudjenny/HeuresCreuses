import ComposableArchitecture
import SwiftUI

struct UserNotificationsList: Reducer {
    struct State: Equatable {
        let notifications: IdentifiedArrayOf<UserNotification> = []
    }

    enum Action: Equatable {
        case task
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return .none
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

            }
        }
    }
}

#Preview {
    UserNotificationsListView(store: Store(initialState: UserNotificationsList.State()) {
        UserNotificationsList()
    })
}
