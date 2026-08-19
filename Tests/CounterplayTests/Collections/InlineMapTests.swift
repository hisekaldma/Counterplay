import Testing
import Counterplay

@Suite("InlineMap")
struct InlineMapTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize repeating a value")
        func initRepeating() {
            let dictionary: InlineMap<5, Resource, Int> = .init(repeating: 0)
            #expect(dictionary[.lumber] == 0)
            #expect(dictionary[.wool] == 0)
            #expect(dictionary[.grain] == 0)
            #expect(dictionary[.brick] == 0)
            #expect(dictionary[.ore] == 0)
        }

        @Test("Initialize with literal")
        func initWithLiteral() {
            let dictionary: InlineMap<5, Resource, Int> = [
                .lumber: 1,
                .wool:   2,
                .grain:  3,
                .brick:  4,
                .ore:    5,
            ]
            #expect(dictionary[.lumber] == 1)
            #expect(dictionary[.wool] == 2)
            #expect(dictionary[.grain] == 3)
            #expect(dictionary[.brick] == 4)
            #expect(dictionary[.ore] == 5)
        }

        @Test("Initialize with literal in arbitrary key order")
        func initWithUnorderedLiteral() {
            let dictionary: InlineMap<5, Resource, Int> = [
                .ore:    5,
                .lumber: 1,
                .brick:  4,
                .grain:  3,
                .wool:   2,
            ]
            #expect(dictionary[.lumber] == 1)
            #expect(dictionary[.wool] == 2)
            #expect(dictionary[.grain] == 3)
            #expect(dictionary[.brick] == 4)
            #expect(dictionary[.ore] == 5)
        }

        @Test("Initialize with unique keys and values")
        func initWithUniqueKeysWithValues() {
            let pairs: [(Resource, Int)] = [
                (.lumber, 1), (.wool, 2), (.grain, 3), (.brick, 4), (.ore, 5),
            ]
            let dictionary = InlineMap<5, Resource, Int>(uniqueKeysWithValues: pairs)
            #expect(dictionary[.lumber] == 1)
            #expect(dictionary[.wool] == 2)
            #expect(dictionary[.grain] == 3)
            #expect(dictionary[.brick] == 4)
            #expect(dictionary[.ore] == 5)
        }

        @Test("Initialize with unique keys and values in arbitrary order")
        func initWithUnorderedUniqueKeysWithValues() {
            let pairs: [(Resource, Int)] = [
                (.brick, 4), (.ore, 5), (.wool, 2), (.lumber, 1), (.grain, 3),
            ]
            let dictionary = InlineMap<5, Resource, Int>(uniqueKeysWithValues: pairs)
            #expect(dictionary[.lumber] == 1)
            #expect(dictionary[.wool] == 2)
            #expect(dictionary[.grain] == 3)
            #expect(dictionary[.brick] == 4)
            #expect(dictionary[.ore] == 5)
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable")
        func equatable() {
            let dictionary1: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 2, .grain: 0, .brick: 0, .ore: 0,
            ]
            let dictionary2: InlineMap<5, Resource, Int> = [
                .wool: 2, .lumber: 1, .ore: 0, .brick: 0, .grain: 0,
            ]
            let dictionary3: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 9, .grain: 0, .brick: 0, .ore: 0,
            ]
            let dictionary4: InlineMap<5, Resource, Int> = .init(repeating: 0)
            let dictionary5: InlineMap<5, Resource, Int> = .init(repeating: 0)

            #expect(dictionary1 == dictionary2)
            #expect(dictionary1 != dictionary3)
            #expect(dictionary3 != dictionary4)
            #expect(dictionary4 == dictionary5)
        }

        @Test("Hashable")
        func hashable() {
            let dictionary1: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 2, .grain: 0, .brick: 0, .ore: 0,
            ]
            let dictionary2: InlineMap<5, Resource, Int> = [
                .wool: 2, .lumber: 1, .ore: 0, .brick: 0, .grain: 0,
            ]
            let dictionary3: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 9, .grain: 0, .brick: 0, .ore: 0,
            ]

            #expect(Set([dictionary1, dictionary2]).count == 1)
            #expect(Set([dictionary1, dictionary3]).count == 2)
        }

        @Test("Description")
        func description() {
            let dictionary: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5,
            ]
            #expect(dictionary.description == "[.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]")
        }
    }

    @Suite("Subscript")
    struct Subscript {

        @Test("Get value")
        func get() {
            let dictionary: InlineMap<5, Resource, Int> = [
                .lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5,
            ]
            #expect(dictionary[.lumber] == 1)
            #expect(dictionary[.ore] == 5)
        }

        @Test("Set value")
        func set() {
            var dictionary: InlineMap<5, Resource, Int> = .init(repeating: 0)
            dictionary[.grain] = 7
            #expect(dictionary[.grain] == 7)
            #expect(dictionary[.lumber] == 0)

            dictionary[.grain] = 8
            #expect(dictionary[.grain] == 8)
        }
    }

    @Suite("Collection")
    struct Collection {

        @Test("Collection conformance")
        func collection() {
            let dictionary1: InlineMap<5, Resource, Int> = .init(repeating: 0)
            let dictionary2: InlineMap<5, Resource, Int> = [.ore: 5, .lumber: 1, .brick: 4, .grain: 3, .wool: 2]
            #expect(dictionary1.map { $0.key } == [.lumber, .wool, .grain, .brick, .ore])
            #expect(dictionary1.map { $0.value } == [0, 0, 0, 0, 0])
            #expect(dictionary1.count == 5)
            #expect(dictionary2.map { $0.key } == [.lumber, .wool, .grain, .brick, .ore])
            #expect(dictionary2.map { $0.value } == [1, 2, 3, 4, 5])
            #expect(dictionary2.count == 5)
        }
    }

    @Suite("Mapping")
    struct Mapping {

        @Test("Map values")
        func mapValues() {
            let dictionary: InlineMap<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let mapped = dictionary.mapValues { $0 * 2 }
            #expect(mapped[.lumber] == 2)
            #expect(mapped[.wool] == 4)
            #expect(mapped[.grain] == 6)
            #expect(mapped[.brick] == 8)
            #expect(mapped[.ore] == 10)
        }

        @Test("Map values to a different type")
        func mapValuesToDifferentType() {
            let dictionary: InlineMap<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let mapped: InlineMap<5, Resource, String> = dictionary.mapValues { "\($0)" }
            #expect(mapped[.lumber] == "1")
            #expect(mapped[.ore] == "5")
        }
    }
}
