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
                    ForEach(viewStore.$appliance.programs, content: program)
                    Button { viewStore.send(.addProgramButtonTapped) } label: {
                        Label("Add a program", systemImage: "plus.circle")
                    }
                }

                Section("Delays") {
                    // TODO
                    Button { } label: {
                        Label("Add a delay", systemImage: "plus.circle")
                    }
                }
            }
        }
    }

    private func program(_ program: Binding<Program>) -> some View {
        VStack {
            TextField("Name", text: program.name)
            TextField("Duration in minutes", value: program.duration.minutes, format: .number)
        }
    }
}

extension ApplianceType: Identifiable {
    public var id: Self { self }
}

private extension Duration {
    var minutes: Int {
        get { Int(components.seconds) / 60 }
        set { self = .seconds(newValue * 60) }
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
