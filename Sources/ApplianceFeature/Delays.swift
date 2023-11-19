import ComposableArchitecture
import Foundation
import Models

@Reducer
public struct Delays {
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
        var operations: [Operation] = []
        var isOffPeakOnlyFilterOn = false

        public init(program: Program, appliance: Appliance) {
            self.program = program
            self.appliance = appliance
        }
    }
    public enum Action: Equatable {
        case task
        case onlyShowOffPeakTapped
    }

    @Dependency(\.date) var date
    @Dependency(\.calendar) var calendar
    @Dependency(\.periodProvider) var periodProvider

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .task:
                return refreshItems(&state)
            case .onlyShowOffPeakTapped:
                state.isOffPeakOnlyFilterOn.toggle()
                return refreshItems(&state)
            }
        }
    }

    private func refreshItems(_ state: inout State) -> Effect<Action> {
        state.operations = .nextOperations(
            periods: periodProvider.get(),
            program: state.program,
            delays: [Duration.zero] + state.appliance.delays,
            now: date(),
            calendar: calendar
        )
        .filter {
            guard state.isOffPeakOnlyFilterOn else { return true }
            return $0.minutesOffPeak > 0
        }
        return .none
    }
}
