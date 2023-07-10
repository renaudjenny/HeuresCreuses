import ComposableArchitecture
import SwiftUI

public struct ApplianceSelectionView: View {

    struct ViewState: Equatable {
        let appliances: IdentifiedArrayOf<Appliance>
    }

    public var body: some View {
        let viewState = ViewState(
            appliances: [.washingMachine, .dishwasher]
        )
        List {
            ForEach(viewState.appliances) { appliance in
                Label(appliance.name, systemImage: appliance.systemImage)
            }
        }
        .navigationTitle("Choose your appliance")
    }
}

extension Appliance {
    var systemImage: String {
        switch type {
        case .dishWasher: return "dishwasher"
        case .washingMachine: return "washer"
        }
    }
}

#if DEBUG
struct ApplianceSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ApplianceSelectionView()
        }
    }
}
#endif
