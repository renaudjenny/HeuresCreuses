import Foundation

public struct Period: Equatable {
    public let start: DateComponents
    public let end: DateComponents

    public init(start: DateComponents, end: DateComponents) {
        self.start = start
        self.end = end
    }
}

public struct OffPeakPeriod: Equatable {
    public let start: Date
    public let end: Date

    public init(start: Date, end: Date) {
        self.start = start
        self.end = end
    }
}
