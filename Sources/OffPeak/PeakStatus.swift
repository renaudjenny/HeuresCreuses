public enum PeakStatus: Equatable {
    case offPeak(until: Duration)
    case peak(until: Duration)
    case unavailable
}
