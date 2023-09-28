#if os(iOS) || os(macOS)
import ComposableArchitecture
import SwiftUI

struct ApplianceFormView: View {
    let store: StoreOf<ApplianceForm>

    struct ViewState: Equatable {
        @BindingViewState var appliance: Appliance

        init(_ state: BindingViewStore<ApplianceForm.State>) {
            _appliance = state.$appliance
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            Form {
                Section {
                    TextField("Name", text: viewStore.$appliance.name)
                    Picker("Type", selection: viewStore.$appliance.type) {
                        ForEach(ApplianceType.allCases) {
                            switch $0 {
                            case .washingMachine: Label("Washing machine", systemImage: "washer")
                            case .dishWasher: Label("Dishwasher", systemImage: "dishwasher")
                            }
                        }
                    }
                }

                Section("Programs") {
                    ForEachStore(store.scope(state: \.programs, action: { .programs(id: $0, action: $1) })) { store in
                        ProgramFormView(store: store)
                    }
                    .onDelete { viewStore.send(.deletePrograms($0)) }

                    Button { viewStore.send(.addProgramButtonTapped, animation: .default) } label: {
                        Label("Add a program", systemImage: "plus.circle")
                    }
                }

                Section("Delays") {
                    ForEach(Array(viewStore.appliance.delays.enumerated()), id: \.0) { index, duration in
                        Stepper(
                            "^[\(duration.hours) hours](inflect: true)",
                            value: viewStore.$appliance.delays[index].hours,
                            in: 1...48
                        )

                    }
                    .onDelete { viewStore.send(.deleteDelays($0)) }

                    Button { viewStore.send(.addDelayButtonTapped, animation: .default) } label: {
                        Label("Add a delay", systemImage: "plus.circle")
                    }
                }
            }
        }
    }
}

extension ApplianceType: Identifiable {
    public var id: Self { self }
}

private extension Duration {
    var hours: Int {
        get { Int(components.seconds / 60 / 60) }
        set { self = .seconds(newValue * 60 * 60) }
    }
}

#if DEBUG
struct ApplianceFormView_Previews: PreviewProvider {
    static var previews: some View {
        @Dependency(\.uuid) var uuid
        ApplianceFormView(store: Store(initialState: ApplianceForm.State(appliance: Appliance(id: uuid()))) {
            ApplianceForm()
        })
    }
}
#endif
#endif
