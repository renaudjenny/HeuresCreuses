import ComposableArchitecture
import Foundation
import Models
import UserNotificationsClientDependency

@Reducer
public struct Delays {
    @ObservableState
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
        @Shared(.periods) var periods: IdentifiedArrayOf<Period>
        var operations: IdentifiedArrayOf<Operation> = []
        var isOffPeakOnlyFilterOn = false
        var notificationOperationsIds: [Operation.ID] = []
        var loadingNotificationOperationsIds: Set<Operation.ID> = []
        @Presents var notificationAlert: AlertState<Action.Alert>?

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case authorizationDenied
        case notificationAlert(PresentationAction<Alert>)
        case sendOperationEndNotification(operationID: Int)
        case onlyShowOffPeakTapped
        case stopLoadingNotificationOperationId(operationID: Int)
        case task
        case updateNotificationOperationIds

        public enum Alert: Equatable { }
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.userNotifications) var userNotifications

    private static let notificationIdPrefix = "com.renaudjenny.heures-creuses.notification.operation-end"

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .authorizationDenied:
                state.notificationAlert = AlertState(
                    title: TextState("Notification authorization denied"),
                    message: TextState("You can modify the notification settings of the app to allow sending you notifications")
                )
                return .none
            case .notificationAlert:
                return .none
            case let .sendOperationEndNotification(operationID):
                guard let operation = state.operations[id: operationID] else { return .none }
                let programName = state.program.name
                let applianceName = state.appliance.name
                let programEndFormatted = operation.startEnd.upperBound.formatted(date: .omitted, time: .shortened)
                let duration = date.now.durationDistance(to: operation.startEnd.upperBound)
                state.loadingNotificationOperationsIds.insert(operationID)

                return .run { send in
                    let status = try await userNotifications.checkAuthorization()
                    if status == .denied {
                        await send(.authorizationDenied)
                    }
                    try await userNotifications.add(UserNotification(
                        id: "\(Self.notificationIdPrefix)-\(operationID)",
                        title: String(localized: "\(applianceName) - \(programName)", comment: "<Appliance name> - <Program name> with <delay name>"),
                        body: String(localized: "This program will finish at \(programEndFormatted)"),
                        creationDate: date.now,
                        duration: duration
                    ))
                    await send(.stopLoadingNotificationOperationId(operationID: operationID), animation: .snappy)
                    await send(.updateNotificationOperationIds, animation: .snappy)
                }
            case .onlyShowOffPeakTapped:
                state.isOffPeakOnlyFilterOn.toggle()
                return refreshItems(&state)
            case let .stopLoadingNotificationOperationId(operationID):
                state.loadingNotificationOperationsIds.remove(operationID)
                return .none
            case .task:
                return .merge(refreshItems(&state), refreshNotificationOperationIds(&state))
            case .updateNotificationOperationIds:
                return refreshNotificationOperationIds(&state)
            }
        }
    }

    private func refreshItems(_ state: inout State) -> Effect<Action> {
        state.operations = IdentifiedArray(uniqueElements: [Operation].nextOperations(
            periods: state.periods.elements,
            program: state.program,
            delays: [Duration.zero] + state.appliance.delays,
            now: date(),
            calendar: calendar
        )
        .filter {
            guard state.isOffPeakOnlyFilterOn else { return true }
            return $0.minutesOffPeak > 0
        })
        return .none
    }

    private func refreshNotificationOperationIds(_ state: inout State) -> Effect<Action> {
        state.notificationOperationsIds = userNotifications.notifications()
            .filter { $0.id.hasPrefix(Self.notificationIdPrefix) }
            .map { $0.id.replacingOccurrences(of: "\(Self.notificationIdPrefix)-", with: "") }
            .compactMap(Int.init)
        return .none
    }
}
