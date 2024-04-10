import Models
import SwiftUI

struct ClockView: View {
    let minute: Double
    let periods: [Period]

    var body: some View {
        ZStack {
            ClockShape().fill(Color.primary.opacity(15/100))
            IndicatorsShape().fill(Color.primary.opacity(50/100))
            ForEach(periods) { period in
                PeriodShape(
                    startMinute: period.startHour * 60 + period.startMinute,
                    endMinute: period.endHour * 60 + period.endMinute
                )
                .fill(Color.green)
            }
            CurrentTimeShape(minute: minute).fill(Color.accentColor)
            GeometryReader { geometryProxy in
                let width = min(geometryProxy.size.width, geometryProxy.size.height)
                if width > 200 {
                    ClockHoursView(isHoursLimited: false)
                } else if width > 100 {
                    ClockHoursView(isHoursLimited: true)
                }
            }
        }
    }
}

private struct ClockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)
        let rect = CGRect(x: rect.minX, y: rect.minY, width: width, height: width)

        var path = Path()
        path.addEllipse(in: rect)
        path.addEllipse(in: rect.insetBy(dx: width * 10/100, dy: width * 10/100))

        return path.normalized(eoFill: true)
    }
}

private struct IndicatorsShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)

        var path = Path()
        for i in 0..<96 {
            let angle: Double = (2.0 * .pi)/96.0 * Double(i) - .pi/2.0
            let radius1: Double = 38/100.0 * width
            let radius2: Double = 37/100.0 * width
            let radius2P: Double = 36/100.0 * width
            let addAngle: Double = .pi/720
            let point1 = CGPoint(
                x: cos(angle - addAngle) * radius1 + width/2,
                y: sin(angle - addAngle) * radius1 + width/2
            )
            let point2 = CGPoint(
                x: cos(angle + addAngle) * radius1 + width/2,
                y: sin(angle + addAngle) * radius1 + width/2
            )
            let point3 = CGPoint(
                x: cos(angle + addAngle) * (i % 4 == 0 ? radius2P : radius2) + width/2,
                y: sin(angle + addAngle) * (i % 4 == 0 ? radius2P : radius2) + width/2
            )
            let point4 = CGPoint(
                x: cos(angle - addAngle) * (i % 4 == 0 ? radius2P : radius2) + width/2,
                y: sin(angle - addAngle) * (i % 4 == 0 ? radius2P : radius2) + width/2
            )

            path.move(to: point1)
            path.addLines([point2, point3, point4, point1])
        }
        return path
    }
}

private struct CurrentTimeShape: Shape {
    let minute: Double

    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)

        var path = Path()

        let angle: Double = (2.0 * .pi)/1440 * minute - .pi/2.0
        let radius1: Double = 48/100.0 * width
        let radius2: Double = 42/100.0 * width
        let addAngle: Double = .pi/300
        let point1 = CGPoint(
            x: cos(angle - addAngle) * radius1 + width/2,
            y: sin(angle - addAngle) * radius1 + width/2
        )
        let point2 = CGPoint(
            x: cos(angle + addAngle) * radius1 + width/2,
            y: sin(angle + addAngle) * radius1 + width/2
        )
        let point3 = CGPoint(
            x: cos(angle + addAngle) * radius2 + width/2,
            y: sin(angle + addAngle) * radius2 + width/2
        )
        let point4 = CGPoint(
            x: cos(angle - addAngle) * radius2 + width/2,
            y: sin(angle - addAngle) * radius2 + width/2
        )

        path.move(to: point1)
        path.addLines([point2, point3, point4, point1])

        return path
    }
}

private struct PeriodShape: Shape {
    let startMinute: Int
    let endMinute: Int

    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)
        let center = CGPoint(x: width/2, y: width/2)

        var path = Path()

        let startAngle: Double = (2.0 * .pi)/1440 * Double(startMinute) - .pi/2.0
        let endAngle: Double = (2.0 * .pi)/1440 * Double(endMinute) - .pi/2.0
        let radius1: Double = 49/100.0 * width
        let radius2: Double = 41/100.0 * width

        path.addArc(
            center: center,
            radius: radius1,
            startAngle: .radians(startAngle),
            endAngle: .radians(endAngle),
            clockwise: false
        )

        path.addArc(
            center: center,
            radius: radius2,
            startAngle: .radians(endAngle),
            endAngle: .radians(startAngle),
            clockwise: true
        )

        let radius3 = (radius1 + radius2)/2
        let radius4 = 4/100.0 * width

        let startRoundCenter = CGPoint(
            x: cos(startAngle) * radius3 + width/2,
            y: sin(startAngle) * radius3 + width/2
        )

        path.addRelativeArc(
            center: startRoundCenter,
            radius: radius4,
            startAngle: .radians(startAngle + .pi),
            delta: .radians(.pi)
        )

        let endRoundCenter = CGPoint(
            x: cos(endAngle) * radius3 + width/2,
            y: sin(endAngle) * radius3 + width/2
        )

        path.move(to: center)

        path.addRelativeArc(
            center: endRoundCenter,
            radius: radius4,
            startAngle: .radians(endAngle),
            delta: .radians(.pi)
        )

        return path
    }
}

struct ClockHoursView: View {
    let isHoursLimited: Bool

    private var hours: [Int] { isHoursLimited ? [0, 6, 12, 18] : (0..<23).map { $0 } }

    var body: some View {
        GeometryReader { geometryProxy in
            ForEach(hours, id: \.self) { hour in
                if hour % 2 == 0 {
                    let angle: Double = (2.0 * .pi)/24.0 * Double(hour) - .pi/2.0
                    let radius = min(geometryProxy.size.width, geometryProxy.size.height)/2

                    Text("\(hour)")
                        #if os(watchOS)
                        .font(.caption2)
                        #else
                        .font(isHoursLimited ? .caption2 : .body)
                        #endif
                        .position(
                            x: cos(angle) * radius * 0.60 + radius,
                            y: sin(angle) * radius * 0.60 + radius
                        )
                        .foregroundStyle(hour % 6 == 0 ? Color.primary : Color.secondary)
                }
            }
        }
    }
}

#Preview("ClockView") {
    ClockView(minute: 2 * 60, periods: .example)
        .frame(minWidth: 50, maxWidth: 250, minHeight: 50, maxHeight: 250)
}

#Preview("ClockShape") {
    ClockShape()
}

#Preview("IndicatorsShape") {
    IndicatorsShape()
}

#Preview("CurrentTimeShape") {
    ZStack {
        CurrentTimeShape(minute: 0)
        CurrentTimeShape(minute: 1 * 60)
        CurrentTimeShape(minute: 3 * 60)
        CurrentTimeShape(minute: 12 * 60)
        CurrentTimeShape(minute: 20 * 60)
    }
}

#Preview("PeriodShape") {
    ZStack {
        PeriodShape(startMinute: 1 * 60, endMinute: 2 * 60)
        PeriodShape(startMinute: 21 * 60, endMinute: 22 * 60)
        PeriodShape(startMinute: 7 * 60, endMinute: 17 * 60)
    }
}

#Preview("ClockHoursView") {
    ClockHoursView(isHoursLimited: false)
}
