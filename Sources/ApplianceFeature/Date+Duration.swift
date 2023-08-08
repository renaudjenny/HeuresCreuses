import Foundation

extension Date {
    func durationDistance(to date: Date) -> Duration { Duration.seconds(self.distance(to: date)) }
}
