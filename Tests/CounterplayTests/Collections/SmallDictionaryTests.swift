import Testing
import Counterplay

@Suite("SmallDictionary")
struct SmallDictionaryTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize empty")
        func initEmpty() {
            let dictionary: SmallDictionary<5, Resource, Int> = [:]
            #expect(dictionary.isEmpty)
            #expect(dictionary.count == 0)
            #expect(dictionary[.lumber] == nil)
        }

        @Test("Initialize with literal")
        func initWithLiteral() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.wool: 2, .ore: 5]
            #expect(dictionary.count == 2)
            #expect(dictionary[.lumber] == nil)
            #expect(dictionary[.wool] == 2)
            #expect(dictionary[.grain] == nil)
            #expect(dictionary[.brick] == nil)
            #expect(dictionary[.ore] == 5)
        }

        @Test("Initialize with unique keys and values")
        func initWithUniqueKeysWithValues() {
            let pairs: [(Resource, Int)] = [
                (.lumber, 1), (.wool, 2), (.grain, 3), (.brick, 4), (.ore, 5),
            ]
            let dictionary = SmallDictionary<5, Resource, Int>(uniqueKeysWithValues: pairs)
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
            let dictionary1: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 0]
            let dictionary2: SmallDictionary<5, Resource, Int> = [.wool: 2, .lumber: 1, .grain: 0]
            let dictionary3: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 9, .grain: 0]
            let dictionary4: SmallDictionary<5, Resource, Int> = [.lumber: 0, .wool: 0, .grain: 0]
            let dictionary5: SmallDictionary<5, Resource, Int> = [.lumber: 0, .wool: 0, .grain: 0]

            #expect(dictionary1 == dictionary2)
            #expect(dictionary1 != dictionary3)
            #expect(dictionary3 != dictionary4)
            #expect(dictionary4 == dictionary5)
        }

        @Test("Hashable")
        func hashable() {
            let dictionary1: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 0]
            let dictionary2: SmallDictionary<5, Resource, Int> = [.wool: 2, .lumber: 1, .grain: 0]
            let dictionary3: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 9, .grain: 0]
            let dictionary4: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2]

            #expect(Set([dictionary1, dictionary2]).count == 1)
            #expect(Set([dictionary1, dictionary3]).count == 2)
            #expect(Set([dictionary1, dictionary4]).count == 2)
        }

        @Test("Description")
        func description() {
            let empty: SmallDictionary<5, Resource, Int> = [:]
            let dictionary: SmallDictionary<5, Resource, Int> = [.wool: 2, .ore: 5]
            #expect(empty.description == "[:]")
            #expect(dictionary.description == "[.wool: 2, .ore: 5]")
        }
    }

    @Suite("Subscript")
    struct Subscript {

        @Test("Get value")
        func get() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            #expect(dictionary[.lumber] == 1)
        }

        @Test("Get absent value")
        func getAbsent() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            #expect(dictionary[.grain] == nil)
        }

        @Test("Set value")
        func set() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.lumber] = 7
            #expect(dictionary == [.lumber: 7, .ore: 2])
        }

        @Test("Set absent value")
        func setAbsent() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.grain] = 7
            #expect(dictionary == [.lumber: 1, .grain: 7, .ore: 2])
        }

        @Test("Set value to nil")
        func remove() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.lumber] = nil
            #expect(dictionary == [.ore: 2])
        }

        @Test("Set absent value to nil")
        func removeAbsent() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.grain] = nil
            #expect(dictionary == [.lumber: 1, .ore: 2])
        }

        @Test("Set value with default")
        func setWithDefault() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.lumber, default: 3] += 7
            #expect(dictionary == [.lumber: 8, .ore: 2])
        }

        @Test("Set absent value with default")
        func setAbsentWithDefault() {
            var dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .ore: 2]
            dictionary[.grain, default: 3] += 7
            #expect(dictionary == [.lumber: 1, .grain: 10, .ore: 2])
        }
    }

    @Suite("Collection")
    struct Collection {

        @Test("Collection conformance")
        func collection() {
            let dictionary1: SmallDictionary<5, Resource, Int> = [:]
            let dictionary2: SmallDictionary<5, Resource, Int> = [.lumber: 1, .brick: 2]
            let dictionary3: SmallDictionary<5, Resource, Int> = [.wool: 1, .brick: 2, .ore: 3]
            let dictionary4: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            #expect(dictionary1.count == 0)
            #expect(dictionary2.count == 2)
            #expect(dictionary3.count == 3)
            #expect(dictionary4.count == 5)
            #expect(dictionary1.isEmpty == true)
            #expect(dictionary2.isEmpty == false)
            #expect(dictionary3.isEmpty == false)
            #expect(dictionary4.isEmpty == false)
            #expect(dictionary1.map { $0.key } == [])
            #expect(dictionary1.map { $0.value } == [])
            #expect(dictionary2.map { $0.key } == [.lumber, .brick])
            #expect(dictionary2.map { $0.value } == [1, 2])
            #expect(dictionary3.map { $0.key } == [.wool, .brick, .ore])
            #expect(dictionary3.map { $0.value } == [1, 2, 3])
            #expect(dictionary4.map { $0.key } == [.lumber, .wool, .grain, .brick, .ore])
            #expect(dictionary4.map { $0.value } == [1, 2, 3, 4, 5])
        }

        @Test("Bidirectional collection conformance")
        func bidirectional() {
            let dictionary1: SmallDictionary<5, Resource, Int> = [:]
            let dictionary2: SmallDictionary<5, Resource, Int> = [.lumber: 1, .brick: 2]
            let dictionary3: SmallDictionary<5, Resource, Int> = [.wool: 1, .brick: 2, .ore: 3]
            let dictionary4: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            #expect(dictionary1.reversed().map { $0.key } == [])
            #expect(dictionary1.reversed().map { $0.value } == [])
            #expect(dictionary2.reversed().map { $0.key } == [.brick, .lumber])
            #expect(dictionary2.reversed().map { $0.value } == [2, 1])
            #expect(dictionary3.reversed().map { $0.key } == [.ore, .brick, .wool])
            #expect(dictionary3.reversed().map { $0.value } == [3, 2, 1])
            #expect(dictionary4.reversed().map { $0.key } == [.ore, .brick, .grain, .wool, .lumber])
            #expect(dictionary4.reversed().map { $0.value } == [5, 4, 3, 2, 1])
        }
    }

    @Suite("Mapping")
    struct Mapping {

        @Test("Map values")
        func mapValues() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let mapped = dictionary.mapValues { $0 * 2 }
            #expect(mapped == [.lumber: 2, .wool: 4, .grain: 6, .brick: 8, .ore: 10])
        }

        @Test("Map values to a different type")
        func mapValuesToDifferentType() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let mapped = dictionary.mapValues { "\($0)" }
            #expect(mapped == [.lumber: "1", .wool: "2", .grain: "3", .brick: "4", .ore: "5"])
        }

        @Test("Compact map values")
        func compactMapValues() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let mapped = dictionary.compactMapValues { $0.isMultiple(of: 2) ? $0 : nil }
            #expect(mapped == [.wool: 2, .brick: 4])
        }

        @Test("Filter")
        func filter() {
            let dictionary: SmallDictionary<5, Resource, Int> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let filtered = dictionary.filter { $0.value > 1 }
            #expect(filtered == [.wool: 2, .grain: 3, .brick: 4, .ore: 5])
        }
    }
}
