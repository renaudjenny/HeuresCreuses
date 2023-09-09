import AppFeature
import ComposableArchitecture
import XCTest

typealias App = AppFeature.App

@MainActor
final class AppFeatureTests: XCTestCase {
    func testTimeChangedAndItIsPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let date = Date(timeIntervalSince1970: 12345689)
        let clock = TestClock()
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.calendar = calendar
            $0.date = .constant(date)
            $0.continuousClock = clock
        }
        let offPeakRanges: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let closestOffPeak = try XCTUnwrap(offPeakRanges.first { date.distance(to: $0.lowerBound) > 0 })
        await store.send(.task) {
            $0.offPeakRanges = offPeakRanges
        }
        await store.send(.cancel)
        await store.send(.timeChanged(date)) {
            $0.currentPeakStatus = .peak(until: .seconds(date.distance(to: closestOffPeak.lowerBound)))
        }
    }

    // TODO:
    func testTimeChangedAndItOffPeakHour() async throws {
        let calendar = Calendar(identifier: .iso8601)
        let store = TestStore(initialState: App.State()) {
            App()
        } withDependencies: {
            $0.calendar = calendar
        }
        // TODO: find a correct off peak date
        let date = Date(timeIntervalSince1970: 12345689)
        let offPeaks: [ClosedRange<Date>] = .offPeakRanges(store.state.periods, now: date, calendar: calendar)
        let currentOffPeak = try XCTUnwrap(offPeaks.first { $0.contains(date) })
        await store.send(.timeChanged(date)) {
            $0.currentPeakStatus = .offPeak(until: .seconds(date.distance(to: currentOffPeak.upperBound)))
        }
    }
}
