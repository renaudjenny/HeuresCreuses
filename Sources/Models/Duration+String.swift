import Foundation

public extension Duration {
    var hourMinute: String { formatted(.units(allowed: [.hours, .minutes], width: .wide)) }
}

#if DEBUG
import SwiftUI

#Preview {
    VStack(spacing: 20) {
        Text(Duration.seconds(22 * 60 * 60 + 22 * 60).hourMinute)
        Text(Duration.seconds(6 * 60 * 60).hourMinute)
    }
}
#endif
