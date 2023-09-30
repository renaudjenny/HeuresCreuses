import ApplianceFeature
import ComposableArchitecture
import Models
import SwiftUI

public struct AppView: View {
    struct ViewState: Equatable {
        let peakStatus: App.PeakStatus
        let duration: Duration
        let notifications: [UserNotification]

        init(_ state: App.State) {
            self.peakStatus = state.currentPeakStatus
            self.notifications = state.notifications
            switch state.currentPeakStatus {
            case .unavailable: self.duration = .zero
            case let .offPeak(duration), let .peak(until: duration): self.duration = duration
            }
        }
    }

    let store: StoreOf<App>

    public init(store: StoreOf<App>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationDestination(
                    store: store.scope(state: \.$destination, action: { .destination($0) }),
                    state: /App.Destination.State.applianceSelection,
                    action: { .applianceSelection($0) },
                    destination: ApplianceSelectionView.init
                )
        }
    }

    private var content: some View {
        WithViewStore(store, observe: ViewState.init) { viewStore in
            VStack {
                ScrollView {
                    viewStore.peakStatusView
                        .padding()
                        .background { viewStore.backgroundColor }
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    #if canImport(NotificationCenter)
                    if case .peak = viewStore.peakStatus {
                        VStack {
                            Text("Do you want to be notified when it's the next off peak?")
                                .multilineTextAlignment(.center)

                            #if canImport(NotificationCenter)
                            Button { viewStore.send(.offPeakNotificationButtonTapped) } label: {
                                Label("Send me a notification", systemImage: "bell.badge")
                            }
                            #endif
                        }
                        .padding()
                    }

                    Divider()
                        .padding()

                    Section("Planned Notifications") {
                        if viewStore.notifications.isEmpty {
                            Text("""
                        When you want to be rembered by a notification to when it's optimum to start your appliance.
                        You'll find here all the "to be sent" notifications. You'll also be able to remove them, so \
                        you won't be spammed.
                        """)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                            .padding()
                        } else {
                            List {
                                ForEach(viewStore.notifications) { notification in
                                    HStack {
                                        HStack(alignment: .top) {
                                            Text(notification.message)
                                                .font(.caption)
                                                .frame(maxWidth: .infinity, alignment: .leading)


                                            let relativeDateFormatted = notification.date
                                                .formatted(.relative(presentation: .numeric))
                                            Text("Will be sent \(relativeDateFormatted)")
                                                .font(.caption.bold())
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .padding()
                                    }
                                }
                                .onDelete { viewStore.send(.deleteNotifications($0)) }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                            .listStyle(.plain)
                        }
                    }
                    #endif
                }

                Button { viewStore.send(.appliancesButtonTapped) } label: {
                    Text("Appliance Selection")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { viewStore.backgroundColor.ignoresSafeArea(.all) }
            .task { await viewStore.send(.task).finish() }
        }
    }
}

private extension AppView.ViewState {
    var backgroundColor: Color {
        switch peakStatus {
        case .unavailable: return Color.clear
        case .peak: return Color.red.opacity(20/100)
        case .offPeak:  return Color.green.opacity(20/100)
        }
    }

    @ViewBuilder
    var peakStatusView: some View {
        let relativeNextChange = "Until \(duration.formatted(.units(allowed: [.hours, .minutes], width: .wide)))"
        Group {
            switch peakStatus {
            case .unavailable:
                Text("Wait a sec...")
                    .font(.body)
            case .offPeak:
                VStack {
                    Text("Currently **off peak**")
                        .font(.title3)
                    Text(relativeNextChange)
                        .font(.headline)
                }
            case .peak:
                VStack {
                    Text("Currently **peak** hour")
                        .font(.title3)
                    Text(relativeNextChange)
                        .font(.headline)
                }
            }
        }
        .multilineTextAlignment(.center)
        .padding()
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
