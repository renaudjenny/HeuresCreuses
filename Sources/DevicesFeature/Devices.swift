import ComposableArchitecture
import SwiftUI

public struct Devices: ReducerProtocol {
    public struct State: Equatable {
        var devices: IdentifiedArrayOf<Device> = []
    }

    public struct Action: Equatable {

    }

    public func reduce(into state: inout State, action: Action) -> EffectTask<Action> {
        return .none
    }
}
