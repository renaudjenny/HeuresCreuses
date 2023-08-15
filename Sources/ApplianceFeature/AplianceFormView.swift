import ComposableArchitecture
import SwiftUI

struct ApplianceFormView: View {
    let store: StoreOf<ApplianceForm>

    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
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
