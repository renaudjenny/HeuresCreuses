import SwiftUI

struct ClockView: View {
    var body: some View {
        ZStack {
            ClockShape().fill(Color.primary.opacity(15/100))
            IndicatorsShape().fill(Color.primary.opacity(50/100))
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
            let angle: Double = (2.0 * .pi)/(96.0) * Double(i) - .pi/2.0
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

#Preview("ClockView") {
    ClockView()
}

#Preview("ClockShape") {
    ClockShape()
}

#Preview("IndicatorsShape") {
    IndicatorsShape()
}
