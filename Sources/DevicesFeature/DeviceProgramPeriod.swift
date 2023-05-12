import ComposableArchitecture
import SwiftUI

public struct DeviceProgramPeriod: Reducer {
    public struct State: Equatable, Identifiable {
        public var id: String { device.id.uuidString + program.id.uuidString }
        public let device: Device
        public let program: Program
        public var start: Date
        public var end: Date
        public var offPeakRatio: Double
        @BindingState public var isTimersShown = false


        public init(
            device: Device,
            program: Program,
            start: Date,
            end: Date,
            offPeakRatio: Double
        ) {
            self.device = device
            self.program = program
            self.start = start
            self.end = end
            self.offPeakRatio = offPeakRatio
        }
    }

    public enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        BindingReducer()
    }
}
