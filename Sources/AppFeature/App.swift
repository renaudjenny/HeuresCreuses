import ApplianceFeature
import ComposableArchitecture
import Models
import OffPeak
import UserNotification

public struct App: Reducer {
    public struct State: Equatable {
        var applianceHomeWidget = ApplianceHomeWidget.State()
        var offPeakHomeWidget = OffPeakHomeWidget.State()
        var userNotificationHomeWidget = UserNotificationHomeWidget.State()

        public init(
            applianceHomeWidget: ApplianceHomeWidget.State = ApplianceHomeWidget.State(),
            offPeakHomeWidget: OffPeakHomeWidget.State = OffPeakHomeWidget.State(),
            userNotificationHomeWidget: UserNotificationHomeWidget.State = UserNotificationHomeWidget.State()
        ) {
            self.applianceHomeWidget = applianceHomeWidget
            self.offPeakHomeWidget = offPeakHomeWidget
            self.userNotificationHomeWidget = userNotificationHomeWidget
        }
    }

    public enum Action: Equatable {
        case applianceHomeWidget(ApplianceHomeWidget.Action)
        case offPeakHomeWidget(OffPeakHomeWidget.Action)
        case userNotificationHomeWidget(UserNotificationHomeWidget.Action)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.applianceHomeWidget, action: /App.Action.applianceHomeWidget) {
            ApplianceHomeWidget()
        }

        Scope(state: \.offPeakHomeWidget, action: /App.Action.offPeakHomeWidget) {
            OffPeakHomeWidget()
        }

        Scope(state: \.userNotificationHomeWidget, action: /App.Action.userNotificationHomeWidget) {
            UserNotificationHomeWidget()
        }

        Reduce { state, action in
            switch action {
            case .applianceHomeWidget:
                return .none
            case .offPeakHomeWidget:
                return .none
            case .userNotificationHomeWidget:
                return .none
            }
        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State()) { App() }
    }
}
