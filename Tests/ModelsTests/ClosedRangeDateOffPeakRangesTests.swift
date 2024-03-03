@testable import Models
import XCTest

final class ClosedRangeDateOffPeakRangesTests: XCTestCase {
    func testOffPeakRanges() throws {
        let periods = [Period].example
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T09:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges(periods, now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 2)
        let firstDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T15:02:00+02:00"))
        let firstDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T17:02:00+02:00"))
        XCTAssertEqual(ranges[0], firstDateStart...firstDateEnd)
        let secondDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T02:02:00+02:00"))
        let secondDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T08:02:00+02:00"))
        XCTAssertEqual(ranges[1], secondDateStart...secondDateEnd)
    }

    func testOffPeakRangesIncludingCurrentOne() throws {
        let periods = [Period].example
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T07:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges(periods, now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 3)
        let firstDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T02:02:00+02:00"))
        let firstDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T08:02:00+02:00"))
        XCTAssertEqual(ranges[0], firstDateStart...firstDateEnd)
        let secondDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T15:02:00+02:00"))
        let secondDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T17:02:00+02:00"))
        XCTAssertEqual(ranges[1], secondDateStart...secondDateEnd)
        let thirdDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T02:02:00+02:00"))
        let thirdDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T08:02:00+02:00"))
        XCTAssertEqual(ranges[2], thirdDateStart...thirdDateEnd)
    }

    func testOffPeakRangesIgnoringMorning() throws {
        let period = Period(id: UUID(), startHour: 23, startMinute: 2, endHour: 6, endMinute: 2)
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T09:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges([period], now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 1)
        let dateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T23:02:00+02:00"))
        let dateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T06:02:00+02:00"))
        XCTAssertEqual(ranges[0], dateStart...dateEnd)
    }

    func testOffPeakRangesStartInEveAndCurrentOne() throws {
        let period = Period(id: UUID(), startHour: 23, startMinute: 2, endHour: 6, endMinute: 2)
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T01:00:00+02:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].nextOffPeakRanges([period], now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 2)
        let firstDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-13T23:02:00+02:00"))
        let firstDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T06:02:00+02:00"))
        XCTAssertEqual(ranges[0], firstDateStart...firstDateEnd)
        let secondDateStart = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T23:02:00+02:00"))
        let secondDateEnd = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-15T06:02:00+02:00"))
        XCTAssertEqual(ranges[1], secondDateStart...secondDateEnd)
    }
}
