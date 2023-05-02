import Foundation

public extension Device {
    static let dishwasher = Self(
        id: UUID(uuidString: "0D5ECE01-D16C-4F14-B37E-94824C461334")!,
        name: "Dishwasher Example",
        type: .dishWasher,
        delay: .timers([
            Delay.Timer(hour: 2, minute: 0),
            Delay.Timer(hour: 4, minute: 0),
            Delay.Timer(hour: 8, minute: 0),
        ]),
        programs: [
            Program(
                id: UUID(uuidString: "3E1C48C3-6FBC-4731-8A73-B1378827747C")!,
                name: "Eco",
                duration: .seconds(240 * 60)
            ),
        ]
    )

    static let washingMachine = Self(
        id: UUID(uuidString: "11746DF1-C676-48D4-BD97-F5770A386604")!,
        name: "Washing Machine Example",
        type: .washingMachine,
        delay: .timers([
            Delay.Timer(hour: 2, minute: 0),
            Delay.Timer(hour: 4, minute: 0),
            Delay.Timer(hour: 8, minute: 0),
        ]),
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
        ]
    )
}
