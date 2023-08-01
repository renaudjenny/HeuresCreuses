import Foundation
import SwiftUI

extension Delay {
    var formatted: String {
        String(localized: "\(hour) hours\(minute > 0 ? " and \(minute) minutes" : "")")
    }
}
