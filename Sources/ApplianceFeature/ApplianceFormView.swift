#if os(iOS) || os(macOS)
import ComposableArchitecture
import SwiftUI

struct ApplianceFormView: View {
    @Bindable var store: StoreOf<ApplianceForm>

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $store.appliance.name)
                Picker("Type", selection: $store.appliance.type) {
                    ForEach(ApplianceType.allCases) {
                        switch $0 {
                        case .washingMachine: Label("Washing machine", systemImage: "washer")
                        case .dishWasher: Label("Dishwasher", systemImage: "dishwasher")
                        }
                    }
                }
            }

            Section("Programs") {
                ForEach(store.scope(state: \.programs, action: \.programs)) { store in
                    ProgramFormView(store: store)
                }
                .onDelete { store.send(.deletePrograms($0)) }

                Button { store.send(.addProgramButtonTapped, animation: .default) } label: {
                    Label("Add a program", systemImage: "plus.circle")
                }
            }

            Section("Delays") {
                ForEach(Array(store.appliance.delays.enumerated()), id: \.0) { index, duration in
                    Stepper(
                        "^[\(duration.hours) hours](inflect: true)",
                        value: $store.appliance.delays[index].hours,
                        in: 1...48
                    )

                }
                .onDelete { store.send(.deleteDelays($0)) }

                Button { store.send(.addDelayButtonTapped, animation: .default) } label: {
                    Label("Add a delay", systemImage: "plus.circle")
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

#Preview {
    VStack {
        @Dependency(\.uuid) var uuid
        ApplianceFormView(store: Store(initialState: ApplianceForm.State(appliance: Appliance(id: uuid()))) {
            ApplianceForm()
        })
    }
}
#endif
