import Models
import XCTest

final class ClosedRangeDateOffPeakRangesTests: XCTestCase {
    func testOffPeakRanges() throws {
        let periods = [Period].example
        let now = try XCTUnwrap(ISO8601DateFormatter().date(from: "2023-07-14T14:00:00+01:00"))
        var calendar = Calendar.current
        calendar.timeZone = try XCTUnwrap(TimeZone(abbreviation: "CEST"))

        let ranges = [ClosedRange<Date>].offPeakRanges(periods, now: now, calendar: calendar)

        XCTAssertEqual(ranges.count, 3)
    }
}
