public struct Delay: Identifiable {
    public let hour: Int
    public let minute: Int

    public var id: Int { hour * 60 + minute }

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }
}
