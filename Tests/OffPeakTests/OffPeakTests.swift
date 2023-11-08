import ComposableArchitecture
import OffPeak
import XCTest

@MainActor
final class OffPeakTests: XCTestCase {
    func testTimeChangedAndItIsPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let date = Date(timeIntervalSince1970: 12345689)
        let store = TestStore(initialState: OffPeakHomeWidget.State()) {
            OffPeakHomeWidget()
        } withDependencies: {
            $0.calendar = calendar
            $0.continuousClock = ImmediateClock()
            $0.date = .constant(date)
        }
        let offPeakRanges: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let closestOffPeak = try XCTUnwrap(offPeakRanges.first { date.distance(to: $0.lowerBound) > 0 })
        await store.send(.task) {
            $0.offPeakRanges = offPeakRanges
        }
        await store.send(.cancelTimer)
        await store.send(.timeChanged(date)) {
            let duration: Duration = .seconds(date.distance(to: closestOffPeak.lowerBound))
            $0.peakStatus = .peak(until: duration)
        }
        await store.finish()
    }

    func testTimeChangedAndItOffPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let date = Date(timeIntervalSince1970: 12345689 + 4 * 60 * 60)
        let store = TestStore(initialState: OffPeakHomeWidget.State()) {
            OffPeakHomeWidget()
        } withDependencies: {
            $0.calendar = calendar
            $0.continuousClock = ImmediateClock()
            $0.date = .constant(date)
        }

        let offPeakRanges: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let currentOffPeak = try XCTUnwrap(offPeakRanges.first { $0.contains(date) })
        await store.send(.task) {
            $0.offPeakRanges = offPeakRanges
        }
        await store.send(.cancelTimer)
        await store.send(.timeChanged(date)) {
            $0.peakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
        }
        await store.finish()
    }
}
