#if os(iOS) || os(macOS)
import ComposableArchitecture
import SwiftUI

struct ProgramFormView: View {
    @Bindable var store: StoreOf<ProgramForm>

    var body: some View {
        DisclosureGroup(isExpanded: $store.isExtended.animation()) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Name").font(.headline)
                TextField(text: $store.program.name, axis: .vertical) {
                    Label("Name", systemImage: "dishwasher.fill")
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Duration in minutes").font(.headline)
                TextField(value: $store.program.duration.minutes, format: .number) {
                    Label("Duration in minutes", systemImage: "timer")
                }
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif

            }
        } label: {
            if store.program.name.isEmpty {
                Text("*New program*").foregroundColor(.secondary)
            } else {
                Text(store.program.name)
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
#endif
