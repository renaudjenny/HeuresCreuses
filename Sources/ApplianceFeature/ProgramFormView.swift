import ComposableArchitecture
import SwiftUI

struct ProgramFormView: View {
    let store: StoreOf<ProgramForm>

    struct ViewState: Equatable {
        @BindingViewState var program: Program
        @BindingViewState var isExtended: Bool

        init(_ state: BindingViewStore<ProgramForm.State>) {
            _program = state.$program
            _isExtended = state.$isExtended
        }
    }

    var body: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            DisclosureGroup(
                viewStore.program.name.isEmpty ? "New program" : viewStore.program.name,
                isExpanded: viewStore.$isExtended
            ) {
                TextField("Name", text: viewStore.$program.name)
                TextField("Duration in minutes", value: viewStore.$program.duration.minutes, format: .number)
            }
        }
    }
}

private extension Duration {
    var minutes: Int {
        get { Int(components.seconds) / 60 }
        set { self = .seconds(newValue * 60) }
    }
}
