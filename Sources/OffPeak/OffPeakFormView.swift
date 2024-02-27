import ComposableArchitecture
import SwiftUI

@Reducer
struct OffPeakForm {
    @ObservableState
    struct State {
        var startHour = 0
    }

    enum Action: BindableAction, Equatable {
        case binding(BindingAction<State>)
    }
}

struct OffPeakFormView: View {
    @Bindable var store: StoreOf<OffPeakForm>

    var body: some View {
        Form {
            Picker("Start hour", selection: $store.startHour) {
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
