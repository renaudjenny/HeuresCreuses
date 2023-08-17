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
                TextField("Name", text: viewStore.$appliance.name)
            }
        }
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
