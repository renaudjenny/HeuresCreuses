import ApplianceFeature
import ComposableArchitecture
import DataManagerDependency
import Foundation
import Models
import OffPeak

#if canImport(NotificationCenter)
import NotificationCenter
#endif

public struct App: Reducer {
    public struct State: Equatable {
        public var applianceHomeWidget = ApplianceHomeWidget.State()
        public var periods: [Period] = .example
        public var currentPeakStatus: PeakStatus = .unavailable
        public var offPeakHomeWidget = OffPeakHomeWidget.State()
        public var offPeakRanges: [ClosedRange<Date>] = []
        public var notifications: [UserNotification] = []
        @PresentationState public var destination: Destination.State?

        #if canImport(NotificationCenter)
        var notificationAuthorizationStatus: UNAuthorizationStatus

        public init(
            applianceHomeWidget: ApplianceHomeWidget.State = ApplianceHomeWidget.State(),
            periods: [Period] = .example,
            currentPeakStatus: PeakStatus = .unavailable,
            offPeakHomeWidget: OffPeakHomeWidget.State = OffPeakHomeWidget.State(),
            offPeakRanges: [ClosedRange<Date>] = [],
            notifications: [UserNotification] = [],
            destination: Destination.State? = nil,
            notificationAuthorizationStatus: UNAuthorizationStatus = .notDetermined
        ) {
            self.applianceHomeWidget = applianceHomeWidget
            self.currentPeakStatus = currentPeakStatus
            self.offPeakHomeWidget = offPeakHomeWidget
            self.offPeakRanges = offPeakRanges
            self.notifications = notifications
            self.destination = destination
            self.notificationAuthorizationStatus = notificationAuthorizationStatus
        }
        #else
        public init(
            applianceHomeWidget: ApplianceHomeWidget.State = ApplianceHomeWidget.State(),
            periods: [Period] = .example,
            currentPeakStatus: PeakStatus = .unavailable,
            offPeakHomeWidget: OffPeakHomeWidget.State = OffPeakHomeWidget.State(),
            offPeakRanges: [ClosedRange<Date>] = [],
            notifications: [UserNotification] = [],
            destination: Destination.State? = nil
        ) {
            self.applianceHomeWidget = applianceHomeWidget
            self.currentPeakStatus = currentPeakStatus
            self.offPeakHomeWidget = offPeakHomeWidget
            self.offPeakRanges = offPeakRanges
            self.notifications = notifications
            self.destination = destination
        }
        #endif
    }

    public struct Destination: Reducer {
        public enum State: Equatable {
            case applianceSelection(ApplianceSelection.State)
        }

        public enum Action: Equatable {
            case applianceSelection(ApplianceSelection.Action)
        }

        public var body: some ReducerOf<Self> {
            Scope(state: /State.applianceSelection, action: /Action.applianceSelection) {
                ApplianceSelection()
            }
        }
    }

    public enum Action: Equatable {
        case appliancesButtonTapped
        case applianceHomeWidget(ApplianceHomeWidget.Action)
        case cancel
        case deleteNotifications(IndexSet)
        case destination(PresentationAction<Destination.Action>)
        case offPeakHomeWidget(OffPeakHomeWidget.Action)
        case task
        case timeChanged(Date)
        #if canImport(NotificationCenter)
        case notificationStatusChanged(UNAuthorizationStatus)
        case offPeakNotificationAdded(UserNotification)
        case offPeakNotificationButtonTapped
        #endif
    }

    public enum PeakStatus: Equatable {
        case offPeak(until: Duration)
        case peak(until: Duration)
        case unavailable
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

        Reduce { state, action in
            switch action {
            case .applianceHomeWidget:
                return .none

            case .appliancesButtonTapped:
                state.destination = .applianceSelection(ApplianceSelection.State())
                return .none
            case .cancel:
                return .cancel(id: CancelID.timer)
            case let .deleteNotifications(indexSet):
                let ids = indexSet.map { state.notifications[$0].id }
                userNotificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
                state.notifications.remove(atOffsets: indexSet)
                return .none
            #if canImport(NotificationCenter)
            case let .destination(.presented(.applianceSelection(.destination(.presented(.selection(.destination(.presented(.optimum(.sendNotification(.delegate(action))))))))))):
                switch action {
                case let .notificationAdded(notification):
                    state.notifications.append(notification)
                    return .none
                }
            #endif
            case .destination:
                return .none
            case .offPeakHomeWidget:
                return .none
            case .task:
                state.offPeakRanges = .offPeakRanges(state.periods, now: date(), calendar: calendar)
                return .run { send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timeChanged(date()), animation: .default)
                    }
                }
                .cancellable(id: CancelID.timer)
            case let .timeChanged(date):
                if let currentOffPeak = state.offPeakRanges.first(where: { $0.contains(self.date()) }) {
                    state.currentPeakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
                    return .none
                } else {
                    guard let closestOffPeak = state.offPeakRanges
                        .first(where: { date.distance(to: $0.lowerBound) > 0 })
                    else { return .none }
                    state.currentPeakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.lowerBound)))
                    return .none
                }
            #if canImport(NotificationCenter)
            case let .notificationStatusChanged(status):
                state.notificationAuthorizationStatus = status
                guard [.authorized, .ephemeral].contains(status),
                      case let .peak(durationBeforeOffPeak) = state.currentPeakStatus
                else { return .none }

                return .run { send in
                    let identifier = "com.renaudjenny.heures-creuses.notification.next-off-peak"
                    let requests = await userNotificationCenter.pendingNotificationRequests()
                    guard !requests.contains(where: { $0.identifier == identifier }) else { return }

                    let content = UNMutableNotificationContent()
                    content.title = "Off peak period is starting"
                    content.body = "Optimise your electricity bill by starting your appliance now."
                    let timeInterval = TimeInterval(durationBeforeOffPeak.components.seconds)
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

                    try await self.userNotificationCenter.add(
                        .init(
                            identifier: identifier,
                            content: content,
                            trigger: trigger
                        )
                    )

                    let date = date().addingTimeInterval(timeInterval)
                    let notification = UserNotification(id: identifier, message: content.body, date: date)
                    await send(.offPeakNotificationAdded(notification))
                }

            case let .offPeakNotificationAdded(notification):
                state.notifications.append(notification)
                return .none

            case .offPeakNotificationButtonTapped:
                return .run { send in
                    let notificationSettings = await userNotificationCenter.notificationSettings()
                    let status = notificationSettings.authorizationStatus
                    await send(.notificationStatusChanged(status))

                    if status == .notDetermined {
                        guard try await self.userNotificationCenter.requestAuthorization(options: [.alert])
                        else { return }
                        await send(.notificationStatusChanged(userNotificationCenter.notificationSettings().authorizationStatus))
                    }
                }
            #endif
            }
        }
        .ifLet(\.$destination, action: /App.Action.destination) {
            Destination()
        }

        Reduce { state, _ in
            let appliances = (/App.Destination.State.applianceSelection).extract(from: state.destination)?.appliances
            return .run { [appliances] _ in
                enum CancelID { case saveDebounce }
                try await withTaskCancellation(id: CancelID.saveDebounce, cancelInFlight: true) {
                    try await self.clock.sleep(for: .seconds(1))
                    try self.saveData(try JSONEncoder().encode(appliances), .appliances)
                }
            }
        }
    }
}

public extension Store where State == App.State, Action == App.Action {
    static var live: StoreOf<App> {
        Store(initialState: State()) { App() }
    }
}
