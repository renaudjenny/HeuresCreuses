import Foundation

/*
 Chemise
 Quotidien 60 min
 Rapide 15 min
*/

public extension Appliance {
    static let washingMachine = Self(
        id: UUID(uuidString: "11746DF1-C676-48D4-BD97-F5770A386604")!,
        name: "Grey Washing Machine",
        type: .washingMachine,
        programs: [
            Program(
                id: UUID(uuidString: "63C16AB1-5700-4178-9DB3-415F3475EBD8")!,
                name: "Eco 20º",
                duration: .seconds(98 * 60)
            ),
            Program(
                id: UUID(uuidString: "5177EB41-7CD3-4FD7-B5BA-CE7568AEDC2F")!,
                name: "Cotton 40º",
                duration: .seconds(190 * 60)
            ),
            Program(
                id: UUID(uuidString: "4EB700D7-DF41-47F4-9F2A-12F98238F1B2")!,
                name: "Cotton 60º",
                duration: .seconds(200 * 60)
            ),
            Program(
                id: UUID(uuidString: "0FC5EE68-9422-48C4-AE6D-D8A39321EAE8")!,
                name: "Cotton 90º",
                duration: .seconds(194 * 60)
            ),
            Program(
                id: UUID(uuidString: "904701A5-78E1-4065-801B-C54CDC2A9FFF")!,
                name: "Hand wash",
                duration: .seconds(91 * 60)
            ),
            Program(
                id: UUID(uuidString: "08C1B039-C444-4DBB-B81C-C6B1F88AC373")!,
                name: "Mixed",
                duration: .seconds(87 * 60)
            ),
            Program(
                id: UUID(uuidString: "BAC5364C-260E-43E1-BD03-9E90A07BFF86")!,
                name: "Intensive",
                duration: .seconds(160 * 60)
            ),
            Program(
                id: UUID(uuidString: "6234CA3B-8993-457A-9E3C-E1014FCB3ED1")!,
                name: "Synthetics",
                duration: .seconds(89 * 60)
            ),
            Program(
                id: UUID(uuidString: "AD371E7C-0454-4524-B3B7-2A8C74531377")!,
                name: "Wool",
                duration: .seconds(40 * 60)
            ),
            Program(
                id: UUID(uuidString: "43EC2978-DF4F-42BB-9031-736DF5589676")!,
                name: "Rinse",
                duration: .seconds(36 * 60)
            ),
            Program(
                id: UUID(uuidString: "6524C78B-B0AA-4765-BA71-9D3DEB1CE83A")!,
                name: "Spin",
                duration: .seconds(15 * 60)
            ),
            Program(
                id: UUID(uuidString: "B721886B-2925-441D-9B96-2335F2E0A4CF")!,
                name: "Sports wear",
                duration: .seconds(80 * 60)
            ),
            Program(
                id: UUID(uuidString: "883091A8-32F4-44C7-AB23-FC2FE513CDA4")!,
                name: "Shirts",
                duration: .seconds(106 * 60)
            ),
            Program(
                id: UUID(uuidString: "12256FAE-03F1-4F88-807E-25E6BA47E6D8")!,
                name: "Daily 60'",
                duration: .seconds(60 * 60)
            ),
            Program(
                id: UUID(uuidString: "FCBD1E1F-1696-4681-8901-F8137C80C69A")!,
                name: "Quick 15'",
                duration: .seconds(15 * 60)
            ),
        ],
        delays: [
            Duration.hours(3),
            Duration.hours(6),
            Duration.hours(9),
            Duration.hours(12),
        ]
    )

    static let dishwasher = Self(
        id: UUID(uuidString: "0D5ECE01-D16C-4F14-B37E-94824C461334")!,
        name: "White Dishwasher",
        type: .dishWasher,
        programs: [
            Program(
                id: UUID(uuidString: "3E1C48C3-6FBC-4731-8A73-B1378827747C")!,
                name: "Eco",
                duration: .seconds(240 * 60)
            ),
            Program(
                id: UUID(uuidString: "E1467751-BBD9-4E9C-8FF0-579E9F13A149")!,
                name: "Prewash",
                duration: .seconds(15 * 60)
            ),
            Program(
                id: UUID(uuidString: "A4800539-B772-4DD9-9651-3A1C31F78D8E")!,
                name: "Fragile",
                duration: .seconds(114 * 60)
            ),
            Program(
                id: UUID(uuidString: "08CA212D-B49C-4D71-A770-1D280A38D7CF")!,
                name: "Quick",
                duration: .seconds(50 * 60)
            ),
            Program(
                id: UUID(uuidString: "6E4CDDB3-E5BC-4975-A272-0C7EEA851948")!,
                name: "Intense",
                duration: .seconds(175 * 60)
            ),
        ],
        delays: [
            Duration.hours(2),
            Duration.hours(4),
            Duration.hours(8),
        ]
    )
}

private extension Duration {
    static func hours(_ hours: Int) -> Self { seconds(hours * 60 * 60) }
}
