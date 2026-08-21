import Testing
import Counterplay

@Suite("SmallCountedSet")
struct SmallCountedSetTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize empty")
        func initEmpty() {
            let set: SmallCountedSet<Resource> = .init()
            #expect(set.isEmpty == true)
        }

        @Test("Initialize with sequence")
        func initWithSequence() {
            let set: SmallCountedSet<Resource> = .init([.wool, .grain, .grain, .brick, .brick, .brick])
            #expect(set.isEmpty == false)
            #expect(set[.lumber] == 0)
            #expect(set[.wool] == 1)
            #expect(set[.grain] == 2)
            #expect(set[.brick] == 3)
            #expect(set[.ore] == 0)
        }

        @Test("Initialize with array literal")
        func initWithArrayLiteral() {
            let set: SmallCountedSet<Resource> = [.wool, .grain, .grain, .brick, .brick, .brick]
            #expect(set.isEmpty == false)
            #expect(set[.lumber] == 0)
            #expect(set[.wool] == 1)
            #expect(set[.grain] == 2)
            #expect(set[.brick] == 3)
            #expect(set[.ore] == 0)
        }

        @Test("Initialize with dictionary literal")
        func initWithDictionaryLiteral() {
            let set: SmallCountedSet<Resource> = [.wool: 1, .grain: 2, .brick: 3]
            #expect(set.isEmpty == false)
            #expect(set[.lumber] == 0)
            #expect(set[.wool] == 1)
            #expect(set[.grain] == 2)
            #expect(set[.brick] == 3)
            #expect(set[.ore] == 0)
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable")
        func equatable() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.wool: 2, .lumber: 1]
            let set3: SmallCountedSet<Resource> = [.lumber: 1]
            let set4: SmallCountedSet<Resource> = [:]
            let set5: SmallCountedSet<Resource> = [:]

            #expect(set1 == set2)
            #expect(set1 != set3)
            #expect(set3 != set4)
            #expect(set4 == set5)
        }

        @Test("Hashable")
        func hashable() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.wool: 2, .lumber: 1]
            let set3: SmallCountedSet<Resource> = [.lumber: 1]

            #expect(Set([set1, set2]).count == 1)
            #expect(Set([set1, set3]).count == 2)
        }

        @Test("Comparable")
        func comparable() {
            let set1: SmallCountedSet<Resource> = []
            let set2: SmallCountedSet<Resource> = [.wool: 1]
            let set3: SmallCountedSet<Resource> = [.lumber: 1]
            let set4: SmallCountedSet<Resource> = [.lumber: 1, .wool: 1]
            let set5: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]

            #expect(set1 < set2)
            #expect(set2 < set3)
            #expect(set3 < set4)
            #expect(set4 < set5)
            #expect(set1 <= set1)
            #expect(set2 <= set2)
            #expect(set3 <= set3)
            #expect(set4 <= set4)
            #expect(set5 <= set5)
        }

        @Test("Description")
        func description() {
            let set1: SmallCountedSet<Resource> = [:]
            let set2: SmallCountedSet<Resource> = [.lumber: 1]
            let set3: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]

            #expect(set1.description == "[:]")
            #expect(set2.description == "[.lumber: 1]")
            #expect(set3.description == "[.lumber: 1, .wool: 2]")
        }
    }

    @Suite("Inserting/removing")
    struct InsertAndRemove {

        @Test("Insert element")
        func insert() {
            var set: SmallCountedSet<Resource> = [.lumber: 1]
            set.insert(.wool)
            #expect(set == [.lumber: 1, .wool: 1])
        }

        @Test("Insert element multiple times")
        func insertMultipleTimes() {
            var set: SmallCountedSet<Resource> = [.lumber: 1]
            set.insert(.wool)
            set.insert(.wool, count: 2)
            #expect(set == [.lumber: 1, .wool: 3])
            #expect(set.count == 2)
        }

        @Test("Insert element clamps at the maximum count")
        func insertClampsToMax() {
            var set: SmallCountedSet<Resource> = [.lumber: SmallCountedSet<Resource>.maxCount - 2]
            set.insert(.lumber, count: 1000)
            #expect(set == [.lumber: SmallCountedSet<Resource>.maxCount])
            #expect(set.count == 1)
        }

        @Test("Remove element")
        func remove() {
            var set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            set.remove(.wool)
            #expect(set == [.lumber: 1, .wool: 1])
            #expect(set.count == 2)
        }

        @Test("Remove element multiple times")
        func removeMultipleTimes() {
            var set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            set.remove(.wool)
            set.remove(.wool)
            #expect(set == [.lumber: 1])
            #expect(set.count == 1)
        }

        @Test("Remove element clamps to zero")
        func removeClampsToZero() {
            var set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            set.remove(.wool, count: 1000)
            #expect(set == [.lumber: 1])
            #expect(set.count == 1)
        }

        @Test("Subscript")
        func subscriptAccess() {
            var set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]

            // Test get
            #expect(set[.lumber] == 1)
            #expect(set[.wool] == 2)
            #expect(set[.grain] == 0)

            // Test set to add
            set[.grain] = 1
            #expect(set == [.lumber: 1, .wool: 2, .grain: 1])

            // Test set to remove
            set[.wool] = 0
            #expect(set == [.lumber: 1, .grain: 1])

            // Test set to 0 when already absent
            set[.brick] = 0
            #expect(set == [.lumber: 1, .grain: 1])

            // Test set to 1 when already present
            set[.lumber] = 1
            #expect(set == [.lumber: 1, .grain: 1])

            // Test clamps to 0
            set[.lumber] = -1
            #expect(set[.lumber] == 0)

            // Test clamps to max
            set[.lumber] = SmallCountedSet<Resource>.maxCount + 1
            #expect(set[.lumber] == SmallCountedSet<Resource>.maxCount)
        }
    }

    @Suite("Set algebra")
    struct SetAlgebra {

        @Test("Contains element")
        func contains() {
            let set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2, .grain: 1]

            #expect(set.contains(.lumber) == true)
            #expect(set.contains(.wool) == true)
            #expect(set.contains(.grain) == true)
            #expect(set.contains(.brick) == false)
            #expect(set.contains(.ore) == false)
        }

        @Test("Union of two sets")
        func union() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.wool: 1, .grain: 1]

            // Non-mutating
            let result = set1.union(set2)
            #expect(result == [.lumber: 1, .wool: 2, .grain: 1])

            // Mutating
            var result2 = set1
            result2.formUnion(set2)
            #expect(result2 == [.lumber: 1, .wool: 2, .grain: 1])
        }

        @Test("Intersection of two sets")
        func intersection() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.wool: 1, .grain: 1]

            // Non-mutating
            let result = set1.intersection(set2)
            #expect(result == [.wool: 1])

            // Mutating
            var result2 = set1
            result2.formIntersection(set2)
            #expect(result2 == [.wool: 1])
        }

        @Test("Subset relationship")
        func isSubset() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set3: SmallCountedSet<Resource> = [.lumber: 1]
            let set4: SmallCountedSet<Resource> = [.grain: 1]
            let emptySet: SmallCountedSet<Resource> = []

            #expect(set1.isSubset(of: set2) == true)
            #expect(set1.isSubset(of: set3) == true) // Equal sets
            #expect(set2.isSubset(of: set1) == false)
            #expect(set4.isSubset(of: set2) == false) // Disjoint
            #expect(emptySet.isSubset(of: set1) == true)
            #expect(set1.isSubset(of: emptySet) == false)
        }

        @Test("Superset relationship")
        func isSuperset() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.lumber: 1]
            let set3: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set4: SmallCountedSet<Resource> = [.grain]
            let emptySet: SmallCountedSet<Resource> = []

            #expect(set1.isSuperset(of: set2) == true)
            #expect(set1.isSuperset(of: set3) == true) // Equal sets
            #expect(set2.isSuperset(of: set1) == false)
            #expect(set1.isSuperset(of: set4) == false) // Disjoint
            #expect(set1.isSuperset(of: emptySet) == true)
            #expect(emptySet.isSuperset(of: set1) == false)
        }

        @Test("Disjoint sets")
        func isDisjoint() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.grain: 1, .brick: 2]
            let set3: SmallCountedSet<Resource> = [.wool: 1, .grain: 2]
            let emptySet: SmallCountedSet<Resource> = []

            #expect(set1.isDisjoint(with: set2) == true)
            #expect(set1.isDisjoint(with: set3) == false) // Share .wool
            #expect(set1.isDisjoint(with: emptySet) == true)
            #expect(emptySet.isDisjoint(with: emptySet) == true)
        }
    }

    @Suite("Arithmetic")
    struct Arithmetic {

        @Test("Addition")
        func addition() {
            let set1: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.wool: 3, .brick: 2]
            let set = set1 + set2
            #expect(set == [.lumber: 1, .wool: 5, .brick: 2])
        }

        @Test("Addition clamps to the maximum count")
        func additionClampsToMax() {
            let set1: SmallCountedSet<Resource> = [.lumber: SmallCountedSet<Resource>.maxCount, .wool: 40000]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .wool: 40000]
            let set = set1 + set2
            #expect(set == [.lumber: SmallCountedSet<Resource>.maxCount, .wool: SmallCountedSet<Resource>.maxCount])
        }

        @Test("Subtraction")
        func subtraction() {
            let set1: SmallCountedSet<Resource> = [.lumber: 4, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.lumber: 2, .wool: 1]
            let set = set1 - set2
            #expect(set == [.lumber: 2, .wool: 1])
        }

        @Test("Subtraction clamps to zero")
        func subtractionClampsToZero() {
            let set1: SmallCountedSet<Resource> = [.lumber: 3, .wool: 2]
            let set2: SmallCountedSet<Resource> = [.lumber: 10, .grain: 5]
            let set = set1 - set2
            #expect(set == [.wool: 2])
        }

        @Test("Multiplication")
        func multiplication() {
            let set: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2]
            let set1 = set * 2
            let set2 = 2 * set
            #expect(set1 == [.lumber: 2, .wool: 4])
            #expect(set2 == [.lumber: 2, .wool: 4])
        }

        @Test("Multiplication clamps to the maximum count")
        func multiplicationClampsToMax() {
            let set: SmallCountedSet<Resource> = [.lumber: 40000, .wool: 32767]
            let set1 = set * 2
            let set2 = 2 * set
            #expect(set1 == [.lumber: SmallCountedSet<Resource>.maxCount, .wool: SmallCountedSet<Resource>.maxCount - 1])
            #expect(set2 == [.lumber: SmallCountedSet<Resource>.maxCount, .wool: SmallCountedSet<Resource>.maxCount - 1])
        }

        @Test("Multiplication by zero or less empties the set")
        func multiplicationByZeroOrLess() {
            let set: SmallCountedSet<Resource> = [.lumber: 3, .wool: SmallCountedSet<Resource>.maxCount]
            #expect(set * 0 == [:])
            #expect(set * -1 == [:])
        }
    }

    @Suite("Collection")
    struct Collection {

        @Test("Collection conformance")
        func collection() {
            let set1: SmallCountedSet<Resource> = [:]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .brick: 2]
            let set3: SmallCountedSet<Resource> = [.wool: 1, .brick: 2, .ore: 3]
            let set4: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5]
            let set5: SmallCountedSet<Resource> = [.lumber: 1, .wool: 2, .grain: 3, .brick: 4, .ore: 5, .gold: 1, .silver: 1, .bronze: 1]
            #expect(set1.count == 0)
            #expect(set2.count == 2)
            #expect(set3.count == 3)
            #expect(set4.count == 5)
            #expect(set5.count == 8)
            #expect(set1.isEmpty == true)
            #expect(set2.isEmpty == false)
            #expect(set3.isEmpty == false)
            #expect(set4.isEmpty == false)
            #expect(set5.isEmpty == false)
            #expect(set1.map { $0.element } == [])
            #expect(set1.map { $0.count } == [])
            #expect(set2.map { $0.element } == [.lumber, .brick])
            #expect(set2.map { $0.count } == [1, 2])
            #expect(set3.map { $0.element } == [.wool, .brick, .ore])
            #expect(set3.map { $0.count } == [1, 2, 3])
            #expect(set4.map { $0.element } == [.lumber, .wool, .grain, .brick, .ore])
            #expect(set4.map { $0.count } == [1, 2, 3, 4, 5])
            #expect(set5.map { $0.element } == [.lumber, .wool, .grain, .brick, .ore, .gold, .silver, .bronze])
            #expect(set5.map { $0.count } == [1, 2, 3, 4, 5, 1, 1, 1])
        }
    }

    @Suite("Characters")
    struct Characters {

        @Test("Initialize from characters")
        func initFromCharacters() {
            let set: SmallCountedSet<Resource> = .init(characters: "🪵🪵🐑🌾🌾🌾")
            #expect(set == [.lumber: 2, .wool: 1, .grain: 3])
        }

        @Test("Initialize from string literal")
        func initFromStringLiteral() {
            let set: SmallCountedSet<Resource> = "🪵🪵🌾🌾🌾"
            #expect(set == [.lumber: 2, .grain: 3])
        }

        @Test("Convert to characters")
        func toCharacters() {
            let set: SmallCountedSet<Resource> = [.lumber: 2, .wool: 1, .grain: 3]
            #expect(set.characters == "🪵🪵🐑🌾🌾🌾")
        }
    }

    @Suite("Reductions")
    struct Reductions {

        @Test("Total count")
        func totalCount() {
            let set1: SmallCountedSet<Resource> = [:]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .brick: 2]
            let set3: SmallCountedSet<Resource> = [.lumber: 3, .wool: 5, .grain: 2]

            #expect(set1.totalCount == 0)
            #expect(set2.totalCount == 3)
            #expect(set3.totalCount == 10)
        }

        @Test("Highest count")
        func highestCount() {
            let set1: SmallCountedSet<Resource> = [:]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .brick: 2]
            let set3: SmallCountedSet<Resource> = [.lumber: 3, .wool: 10, .grain: 2]

            #expect(set1.highestCount == 0)
            #expect(set2.highestCount == 2)
            #expect(set3.highestCount == 10)
        }

        @Test("Lowest count")
        func lowestCount() {
            let set1: SmallCountedSet<Resource> = [:]
            let set2: SmallCountedSet<Resource> = [.lumber: 1, .brick: 2]
            let set3: SmallCountedSet<Resource> = [.lumber: 3, .wool: 10, .grain: 2]

            #expect(set1.lowestCount == 0)
            #expect(set2.lowestCount == 1)
            #expect(set3.lowestCount == 2)
        }
    }
}
