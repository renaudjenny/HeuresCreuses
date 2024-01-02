import ComposableArchitecture
import Foundation

@Reducer
public struct ApplianceForm {
    @ObservableState
    public struct State: Equatable {
        public var appliance: Appliance
        public var programs: IdentifiedArrayOf<ProgramForm.State>

        public init(appliance: Appliance) {
            self.appliance = appliance
            self.programs = IdentifiedArrayOf(uniqueElements: appliance.programs.map {
                ProgramForm.State(program: $0, isExtended: appliance.programs.first?.id == $0.id)
            })
        }
    }
    public enum Action: BindableAction, Equatable {
        case addDelayButtonTapped
        case addProgramButtonTapped
        case binding(BindingAction<State>)
        case deleteDelays(IndexSet)
        case deletePrograms(IndexSet)
        case programs(id: ProgramForm.State.ID, action: ProgramForm.Action)
    }

    @Dependency(\.uuid) var uuid

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
        Reduce { state, action in
            switch action {
            case .addDelayButtonTapped:
                state.appliance.delays.append(.seconds(2 * 60 * 60))
                return .none
            case .addProgramButtonTapped:
                state.appliance.programs.append(Program(id: uuid()))
                return .none
            case .binding:
                return .none
            case let .deleteDelays(indexSet):
                state.appliance.delays.remove(atOffsets: indexSet)
                return .none
            case let .deletePrograms(indexSet):
                state.programs.remove(atOffsets: indexSet)
                return .none
            case .programs:
                return .none
            }
        }
        .forEach(\.programs, action: /Action.programs) {
            ProgramForm()
        }
        .onChange(of: \.appliance.programs) { _, newValue in
            Reduce { state, action in
                state.programs.append(contentsOf: newValue.map { ProgramForm.State(program: $0) })
                return .none
            }
        }
        .onChange(of: \.programs) { oldValue, newValue in
            Reduce { state, action in
                state.appliance.programs = newValue.map(\.program)
                return .none
            }
        }
    }
}
