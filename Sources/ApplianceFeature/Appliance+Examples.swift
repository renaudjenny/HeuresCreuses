import Foundation

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
                id: UUID(uuidString: "904701A5-78E1-4065-801B-C54CDC2A9FFF")!,
                name: "Hand wash",
                duration: .seconds(91 * 60)
            ),
            Program(
                id: UUID(uuidString: "08C1B039-C444-4DBB-B81C-C6B1F88AC373")!,
                name: "Mixed",
                duration: .seconds(87 * 60)
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
