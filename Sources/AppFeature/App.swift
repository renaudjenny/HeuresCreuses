import ApplianceFeature
import ComposableArchitecture
import DataManagerDependency
import Foundation
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

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.continuousClock) var clock
    @Dependency(\.userNotificationCenter) var userNotificationCenter
    @Dependency(\.dataManager.save) var saveData

    private enum CancelID { case timer }

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

        // TODO: add the save/load logic back in Appliance module directly
//        Reduce { state, _ in
//            let appliances = (/App.Destination.State.applianceSelection).extract(from: state.destination)?.appliances
//            return .run { [appliances] _ in
//                enum CancelID { case saveDebounce }
//                try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
//                    try await self.clock.sleep(for: .seconds(1))
//                    try self.saveData(try JSONEncoder().encode(appliances), .appliances)
//                }
//            }
//        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State()) { App() }
    }
}
