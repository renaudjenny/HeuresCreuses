@testable import Models
import XCTest

final class ClosedRangeDateOffPeakRangesTests: XCTestCase {
    func testPeriodMinutesInDayForExamples() throws {
        let period1 = Period(start: DateComponents(hour: 2, minute: 2), end: DateComponents(hour: 8, minute: 2))
        XCTAssertEqual(period1.periodMinutes.count, 1)
        XCTAssertEqual(period1.periodMinutes.first?.start, 122)
        XCTAssertEqual(period1.periodMinutes.first?.end, 482)

        let period2 = Period(start: DateComponents(hour: 15, minute: 2), end: DateComponents(hour: 17, minute: 2))
        XCTAssertEqual(period2.periodMinutes.count, 1)
        XCTAssertEqual(period2.periodMinutes.first?.start, 902)
        XCTAssertEqual(period2.periodMinutes.first?.end, 1022)
    }

    func testPeriodMinutesInDayWhenOverlappingMidnight() throws {
        let period = Period(start: DateComponents(hour: 23, minute: 2), end: DateComponents(hour: 6, minute: 2))
        XCTAssertEqual(period.periodMinutes.count, 2)
        XCTAssertEqual(period.periodMinutes[0].start, -58)
        XCTAssertEqual(period.periodMinutes[0].end, 362)
        XCTAssertEqual(period.periodMinutes[1].start, 1382)
        XCTAssertEqual(period.periodMinutes[1].end, 1802)
    }

    func testOffPeakRanges() throws {
        let periods = [Period].example
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T09:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges(periods, now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 2)
    }

    func testOffPeakRangesIgnoringMorning() throws {
        let period = Period(start: DateComponents(hour: 23, minute: 2), end: DateComponents(hour: 6, minute: 2))
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T09:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges([period], now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 1)
    }

    func testOffPeakRangesIncludingCurrentOne() throws {
        let periods = [Period].example
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T07:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges(periods, now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 2)
    }
}
