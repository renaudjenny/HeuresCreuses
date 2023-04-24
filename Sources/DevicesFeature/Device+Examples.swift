import Foundation

extension Device {
    static let dishwasher = Self(
        id: UUID(uuidString: "0D5ECE01-D16C-4F14-B37E-94824C461334")!,
        name: "Dishwasher Example",
        type: .dishWasher,
        delay: .timers([
            (hour: 2, minute: 0),
            (hour: 4, minute: 0),
            (hour: 8, minute: 0),
        ]),
        programs: [
            Program(name: "Eco", duration: .seconds(240 * 60)),
        ]
    )

    static let washingMachine = Self(
        id: UUID(uuidString: "11746DF1-C676-48D4-BD97-F5770A386604")!,
        name: "Washing Machine Example",
        type: .washingMachine,
        delay: .timers([
            (hour: 2, minute: 0),
            (hour: 4, minute: 0),
            (hour: 8, minute: 0),
        ]),
        programs: [
            Program(name: "Eco 20º", duration: .seconds(98 * 60)),
            Program(name: "Cotton 40º", duration: .seconds(190 * 60)),
            Program(name: "Hand wash", duration: .seconds(91 * 60)),
            Program(name: "Mixed", duration: .seconds(87 * 60)),
        ]
    )
}
