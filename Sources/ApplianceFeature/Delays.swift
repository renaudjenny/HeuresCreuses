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
        var operations: IdentifiedArrayOf<Operation> = []
        var isOffPeakOnlyFilterOn = false

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case sendOperationEndNotification(operationID: Int)
        case onlyShowOffPeakTapped
        case task
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.periodProvider) var periodProvider
    @Dependency(\.userNotifications) var userNotifications

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .sendOperationEndNotification(operationID):
                guard let operation = state.operations[id: operationID] else { return .none }
                let programName = state.program.name
                let applianceName = state.appliance.name

                // TODO: check authorizations via the `userNotifications` dependency. Try to avoid code duplication with SendNotification
                return .run { send in
                    try await userNotifications.add(UserNotification(
                        id: "com.renaudjenny.heures-creuses.notification.operation-end-\(operationID)",
                        title: String(localized: "\(applianceName) - \(programName) operation", comment: "<Appliance name> - <Program name> operation"),
                        body: String(localized: "Your operation is planned to end at TODO"), // TODO: find the end of the program
                        creationDate: date.now,
                        duration: .seconds(20) // TODO: compute the real duration
                    ))
                }
            case .onlyShowOffPeakTapped:
                state.isOffPeakOnlyFilterOn.toggle()
                return refreshItems(&state)
            case .task:
                return refreshItems(&state)
            }
        }
    }

    private func refreshItems(_ state: inout State) -> Effect<Action> {
        state.operations = IdentifiedArray(uniqueElements: [Operation].nextOperations(
            periods: periodProvider.get(),
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
}
