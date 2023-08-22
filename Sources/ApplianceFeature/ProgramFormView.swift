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
                isExpanded: viewStore.$isExtended.animation()
            ) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Name").font(.headline)
                    TextField(text: viewStore.$program.name, axis: .vertical) {
                        Label("Name", systemImage: "dishwasher.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 0) {
                    Text("Duration in minutes").font(.headline)
                    TextField(value: viewStore.$program.duration.minutes, format: .number) {
                        Label("Duration in minutes", systemImage: "timer")
                    }
                    .keyboardType(.numberPad)
                }
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
