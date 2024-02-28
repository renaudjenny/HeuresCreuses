import Models
import ComposableArchitecture
import SwiftUI

@Reducer
struct OffPeakForm {
    @ObservableState
    struct State {
        var startHour = 0
        var endHour = 0

        var period: Period {
            Period(start: (startHour, 0), end: (endHour,0))
        }
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }

    var body: some ReducerOf<Self> {
        BindingReducer()
    }
}

struct OffPeakFormView: View {
    @Bindable var store: StoreOf<OffPeakForm>

    var body: some View {
        Form {
            PeriodView(period: store.period)
            Picker("Start hour", selection: $store.startHour.animation()) {
                ForEach(0..<24) {
                    Text($0.formatted())
                }
            }
            Picker("End hour", selection: $store.endHour.animation()) {
                ForEach(0..<24) {
                    Text($0.formatted())
                }
            }
        }
    }
}

#Preview {
    OffPeakFormView(store: Store(initialState: OffPeakForm.State()) {
        OffPeakForm()
    })
}
