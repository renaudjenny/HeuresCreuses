import Foundation

extension Duration {
    var hourMinute: String { formatted(.units(allowed: [.hours, .minutes], width: .wide)) }
}

#if DEBUG
import SwiftUI

struct DurationHourMinute_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text(Duration.seconds(22 * 60 * 60 + 22 * 60).hourMinute)
            Text(Duration.seconds(6 * 60 * 60).hourMinute)
        }
    }
}
#endif
