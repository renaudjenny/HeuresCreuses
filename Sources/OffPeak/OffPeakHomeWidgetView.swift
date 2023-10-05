import ComposableArchitecture
import HomeWidget
import SwiftUI

public enum PeakStatus: Equatable {
    case offPeak(until: Duration)
    case peak(until: Duration)
    case unavailable
}

public struct OffPeakHomeWidgetView: View {
//    let peakStatus = PeakStatus.offPeak(until: .seconds(4.5 * 60 * 60))
    let peakStatus = PeakStatus.unavailable

    public var body: some View {
        HomeWidgetView(title: "Off Peak hours", icon: Image(systemName: "arrow.up.circle.badge.clock")) {
            peakStatusView
        }
        .listRowBackground(color)
    }

    @ViewBuilder
    var peakStatusView: some View {
        switch peakStatus {
        case .unavailable:
            Text("Wait a sec...").font(.body)
        case let .offPeak(duration):
            VStack(alignment: .leading) {
                Text("Currently **off peak**")
                Text(relativeNextChange(duration)).font(.headline)
            }
        case let .peak(duration):
            VStack(alignment: .leading) {
                Text("Currently **peak** hour")
                Text(relativeNextChange(duration)).font(.headline)
            }
        }
    }

    private func relativeNextChange(_ duration: Duration) -> String {
        "Until \(duration.formatted(.units(allowed: [.hours, .minutes], width: .wide)))"
    }

    private var color: Color? {
        switch peakStatus {
        case .offPeak: .green.opacity(20/100)
        case .peak: .red.opacity(20/100)
        case .unavailable: nil
        }
    }
}

#Preview {
    List {
        OffPeakHomeWidgetView()
    }
}
