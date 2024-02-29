import Models
import ComposableArchitecture
import SwiftUI

@Reducer
public struct OffPeakForm {
    @ObservableState
    public struct State: Equatable {
        public var startHour = 0
        public var startMinute = 0
        public var endHour = 0
        public var endMinute = 0

        public var period: Period {
            Period(start: (startHour, startMinute), end: (endHour, endMinute))
        }

        init(period: Period) {
            startHour = period.startHour
            startMinute = period.startMinute
            endHour = period.endHour
            endMinute = period.endMinute
        }
    }

    public enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
        case save
    }

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

struct OffPeakFormView: View {
    @Bindable var store: StoreOf<OffPeakForm>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                PeriodView(period: store.period)
            }

            Section("Start") {
                Picker("Hour", selection: $store.startHour.animation()) {
                    ForEach(0..<24) {
                        Text($0.formatted())
                    }
                }
                Picker("Minute", selection: $store.startMinute.animation()) {
                    ForEach(0..<59) {
                        Text($0.formatted())
                    }
                }
            }

            Section("End") {
                Picker("Hour", selection: $store.endHour.animation()) {
                    ForEach(0..<24) {
                        Text($0.formatted())
                    }
                }
                Picker("Minute", selection: $store.endMinute.animation()) {
                    ForEach(0..<59) {
                        Text($0.formatted())
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Text("Cancel") }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { store.send(.save) } label: { Text("Save") }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OffPeakFormView(store: Store(initialState: OffPeakForm.State(period: Period(start: (0,0), end: (0,0)))) {
            OffPeakForm()
        })
    }
}
