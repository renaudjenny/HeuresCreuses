import Models
import ComposableArchitecture
import SwiftUI

@Reducer
public struct PeriodForm {
    @ObservableState
    public struct State: Equatable {
        public var period: Period

        init(period: Period) {
            self.period = period
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

struct PeriodFormView: View {
    @Bindable var store: StoreOf<PeriodForm>
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section {
                PeriodView(period: store.period)
            }

            Section("Start") {
                Picker("Hour", selection: $store.period.startHour.animation()) {
                    ForEach(0..<24) {
                        Text($0.formatted())
                    }
                }
                Picker("Minute", selection: $store.period.startMinute.animation()) {
                    ForEach(0..<59) {
                        Text($0.formatted())
                    }
                }
            }

            Section("End") {
                Picker("Hour", selection: $store.period.endHour.animation()) {
                    ForEach(0..<24) {
                        Text($0.formatted())
                    }
                }
                Picker("Minute", selection: $store.period.endMinute.animation()) {
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
        PeriodFormView(store: Store(initialState: PeriodForm.State(period: Period(
            id: UUID(),
            startHour: 0,
            startMinute: 0,
            endHour: 0,
            endMinute: 0
        ))) {
            PeriodForm()
        })
    }
}
