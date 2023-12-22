import ComposableArchitecture
import SwiftUI

public struct ProgramSelectionView: View {
    let store: StoreOf<ProgramSelection>

    struct ViewState: Equatable {
        var appliance: Appliance

        init(_ state: ProgramSelection.State) {
            self.appliance = state.appliance
        }
    }

    public var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            ScrollView {
                Text(viewStore.appliance.name)
                    .font(.title)
                    .padding(.bottom, 20)
                VStack(alignment: .leading) {
                    ForEach(viewStore.appliance.programs) { program in
                        Button { viewStore.send(.programTapped(program)) } label: {
                            VStack(alignment: .leading) {
                                Text(program.name)
                                    .font(.title3)
                                Label(
                                    program.duration
                                        .formatted(.units(allowed: [.minutes], width: .wide)),
                                    systemImage: "timer"
                                )
                            }
                            #if os(iOS) || os(macOS)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Material.thin)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            #endif
                        }
                        .padding(.horizontal)
                    }
                    .sheet(
                        store: store.scope(state: \.$destination.optimum, action: \.destination.optimum),
                        content: OptimumView.init
                    )
                    .navigationDestination(
                        store: store.scope(state: \.$destination.delays, action: \.destination.delays),
                        destination: DelaysView.init
                    )
                    #if os(iOS) || os(macOS)
                    .sheet(
                        store: store.scope(state: \.$destination.edit, action: \.destination.edit),
                        content: { store in
                            NavigationStack {
                                ApplianceFormView(store: store)
                                    .navigationTitle("Edit appliance")
                                    .toolbar {
                                        ToolbarItem {
                                            Button { viewStore.send(.editApplianceSaveButtonTapped) } label: {
                                                Text("Save")
                                            }
                                        }
                                        ToolbarItem(placement: .cancellationAction) {
                                            Button { viewStore.send(.editApplianceCancelButtonTapped) } label: {
                                                Text("Cancel")
                                            }
                                        }
                                    }
                            }
                        }
                    )
                    #endif
                    .alert(store: store.scope(state: \.$destination.alert, action: \.destination.alert))
                }
                .toolbar {
                    #if os(iOS) || os(macOS)
                    ToolbarItem {
                        Button { viewStore.send(.editApplianceButtonTapped) } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }
                    #endif

                    ToolbarItem(placement: .destructiveAction) {
                        Button(role: .destructive) { viewStore.send(.deleteButtonTapped) } label: {
                            Label("Delete \(viewStore.appliance.name)", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle("Choose your program")
    }
}

#Preview {
    NavigationStack {
        ProgramSelectionView(store: Store(initialState: ProgramSelection.State(appliance: .dishwasher)) {
            ProgramSelection()
        })
    }
}
