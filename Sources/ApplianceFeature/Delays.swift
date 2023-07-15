import ComposableArchitecture

public struct Delays: Reducer {
    public struct State: Equatable {
        var program: Program
        var appliance: Appliance
    }
    public enum Action: Equatable {}
    public var body: some ReducerOf<Self> {
        EmptyReducer()
    }
}

extension Delays.State {
    struct Item: Identifiable, Equatable {
        let delay: Delay
        let minutesOffPeak: Int
        let minutesInPeak: Int

        var id: Delay.ID { delay.id }
    }

    var items: [Item] {
        ([Delay(hour: 0, minute: 0)] + appliance.delays).map {
            Item(
                delay: $0,
                minutesOffPeak: Int(program.duration/60 * 20/100),
                minutesInPeak: Int(program.duration/60 * 80/100)
            )
        }
    }
}
