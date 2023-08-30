import ApplianceFeature
import ComposableArchitecture
import Models
import SwiftUI

public struct AppView: View {
    struct ViewState: Equatable {
        let peakStatus: App.PeakStatus
        let formattedDuration: String
        let notifications: [UserNotification]

        init(_ state: App.State) {
            self.peakStatus = state.currentPeakStatus
            self.notifications = state.notifications
            switch state.currentPeakStatus {
            case .unavailable:
                self.formattedDuration = ""
            case let .offPeak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            case let .peak(until: duration):
                self.formattedDuration = duration.formatted(.units(allowed: [.hours, .minutes], width: .wide))
            }
        }
    }

    let store: StoreOf<App>

    public init(store: StoreOf<App>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            currentOffPeakStatusView
                .navigationDestination(
                    store: store.scope(state: \.$destination, action: { .destination($0) }),
                    state: /App.Destination.State.applianceSelection,
                    action: { .applianceSelection($0) },
                    destination: ApplianceSelectionView.init
                )
        }
    }

    private var currentOffPeakStatusView: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            VStack {
                switch viewStore.peakStatus {
                case .unavailable:
                    Text("Wait a sec...")
                case .offPeak:
                    Text("Currently **off peak** until \(viewStore.formattedDuration)")
                        .multilineTextAlignment(.center)
                case .peak:
                    Text("Currently **peak** hour until \(viewStore.formattedDuration)")
                        .multilineTextAlignment(.center)
                }

                Section("Planned Notifications") {
                    List {
                        ForEach(viewStore.notifications) { notification in
                            HStack {
                                Text(notification.message).font(.caption)
                                // TODO: improve this "distance" to show a nice formatted time
                                Text("Will be send in \(Date().distance(to: notification.date) / 60, format: .number.precision(.significantDigits(2))) minutes")
                            }
                        }
                    }
                    .listStyle(.inset)
                }

                Button { viewStore.send(.appliancesButtonTapped) } label: {
                    Text("Appliance Selection")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                switch viewStore.peakStatus {
                case .unavailable:
                    Color.clear
                case .peak:
                    Color.red.opacity(20/100).ignoresSafeArea(.all)
                case .offPeak:
                    Color.green.opacity(20/100).ignoresSafeArea(.all)
                }
            }
            .task { @MainActor in viewStore.send(.task) }
        }
    }
}

#if DEBUG
struct AppView_Previews: PreviewProvider {
    static var previews: some View {
        Preview(store: Store(initialState: App.State()) { App() })
        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T23:50:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 23:50")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T00:10:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 00:10")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T02:10:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 02:10")

        Preview(store: Store(initialState: App.State()) {
            App().dependency(\.date, DateGenerator { try! Date("2023-04-10T16:00:00+02:00", strategy: .iso8601) })
        })
        .previewDisplayName("At 16:00")

        Preview(
            store: Store(
                initialState: App.State(notifications: [
                    UserNotification(
                        id: "0",
                        message: "White Dishwasher\nProgram Eco\nDelay 3 hour",
                        date: Date().addingTimeInterval(60 * 60)
                    ),
                    UserNotification(
                        id: "1",
                        message: "Gray Washing machine\nProgram Intense\nDelay 4 hours",
                        date: Date().addingTimeInterval(2 * 60 * 60 + 15 * 60)
                    )
                ])
            ) {
                App()
            }
        )
        .previewDisplayName("With Notifications")
    }

    private struct Preview: View {
        let store: StoreOf<App>

        var body: some View {
            AppView(store: store)
        }
    }
}
#endif
