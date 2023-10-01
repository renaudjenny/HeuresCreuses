import SwiftUI

public struct HomeWidgetView<Description: View>: View {
    public let title: String
    public let icon: Image
    public let description: () -> Description

    public init(
        title: String,
        icon: Image,
        description: @escaping () -> Description
    ) {
        self.title = title
        self.icon = icon
        self.description = description
    }

    public var body: some View {
        VStack(alignment: .leading) {
            HStack {
                icon
                Text(title).font(.title3)
            }
            Spacer()
            description()
        }
        .frame(maxWidth: .infinity, idealHeight: 80, alignment: .leading)
        .background(alignment: .topTrailing) {
            Image(systemName: "chevron.right")
        }
        .padding(.vertical)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    List {
        Button {} label: {
            HomeWidgetView(title: "Off peak hours",icon: Image(systemName: "arrow.up.circle.badge.clock")) {
                VStack(alignment: .leading) {
                    Text("Current **peak** hour")
                    Text("Until 11 hours, 4 minutes")
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.red.opacity(20/100))

        Button {} label: {
            HomeWidgetView(title: "Your appliances", icon: Image(systemName: "washer")) {
                Text("**2** appliances")
            }
        }
        .buttonStyle(.plain)

        HomeWidgetView(title: "Your planned notifications", icon: Image(systemName: "bell.badge")) {
            Text("No notifications planned")
        }
    }
    .listRowSpacing(8)
}
