import SwiftUI

struct ClockShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = min(rect.width, rect.height)
        let rect = CGRect(x: rect.minX, y: rect.minY, width: width, height: width)

        var path = Path()
        path.addEllipse(in: rect)
        return path
    }
}

#Preview {
    ClockShape()
}
