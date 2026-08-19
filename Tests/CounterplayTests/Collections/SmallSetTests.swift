import Testing
import Counterplay

@Suite("SmallSet")
struct SmallSetTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize empty")
        func initEmpty() {
            let set: SmallSet<Resource> = .init()
            #expect(set.isEmpty == true)
        }

        @Test("Initialize with sequence")
        func initWithSequence() {
            let set: SmallSet<Resource> = .init([.wool, .grain, .brick])
            #expect(set.isEmpty == false)
            #expect(set.contains(.lumber) == false)
            #expect(set.contains(.wool) == true)
            #expect(set.contains(.grain) == true)
            #expect(set.contains(.brick) == true)
            #expect(set.contains(.ore) == false)
        }

        @Test("Initialize with literal")
        func initWithLiteral() {
            let set: SmallSet<Resource> = [.wool, .grain, .brick]
            #expect(set.isEmpty == false)
            #expect(set.contains(.lumber) == false)
            #expect(set.contains(.wool) == true)
            #expect(set.contains(.grain) == true)
            #expect(set.contains(.brick) == true)
            #expect(set.contains(.ore) == false)
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable")
        func equatable() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .lumber]
            let set3: SmallSet<Resource> = [.lumber]
            let set4: SmallSet<Resource> = []
            let set5: SmallSet<Resource> = []

            #expect(set1 == set2)
            #expect(set1 != set3)
            #expect(set3 != set4)
            #expect(set4 == set5)
        }

        @Test("Hashable")
        func hashable() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .lumber]
            let set3: SmallSet<Resource> = [.lumber]

            #expect(Set([set1, set2]).count == 1)
            #expect(Set([set1, set3]).count == 2)
        }

        @Test("Comparable")
        func comparable() {
            let set1: SmallSet<Resource> = [.lumber]
            let set2: SmallSet<Resource> = [.wool]
            let set3: SmallSet<Resource> = [.lumber, .wool]
            let set4: SmallSet<Resource> = []

            #expect(set1 < set2)
            #expect(set1 < set3)
            #expect(set4 < set1)
            #expect(set2 <= set2)
            #expect(set3 > set1)
            #expect(set3 >= set2)
        }

        @Test("Description")
        func description() {
            let set1: SmallSet<Resource> = []
            let set2: SmallSet<Resource> = [.lumber]
            let set3: SmallSet<Resource> = [.lumber, .wool]

            #expect(set1.description == "[]")
            #expect(set2.description == "[.lumber]")
            #expect(set3.description == "[.lumber, .wool]")
        }
    }
    
    @Suite("Inserting/removing")
    struct InsertAndRemove {
        @Test("Insert element")
        func insert() {
            var set: SmallSet<Resource> = [.lumber]
            set.insert(.wool)
            #expect(set == [.lumber, .wool])
        }
        
        @Test("Insert element multiple times")
        func insertMultipleTimes() async throws {
            var set: SmallSet<Resource> = [.lumber]
            set.insert(.wool)
            set.insert(.wool)
            set.insert(.wool)
            #expect(set == [.lumber, .wool])
        }
        
        @Test("Remove element")
        func remove() async throws {
            var set: SmallSet<Resource> = [.lumber, .wool]
            set.remove(.wool)
            #expect(set == [.lumber])
        }
        
        @Test("Remove element multiple times")
        func removeMultipleTimes() async throws {
            var set: SmallSet<Resource> = [.lumber, .wool]
            set.remove(.wool)
            set.remove(.wool)
            set.remove(.wool)
            #expect(set == [.lumber])
        }
        
        @Test("Insert with return value")
        func insertWithReturn() async throws {
            var set: SmallSet<Resource> = [.lumber]
            
            // Insert new element
            let (inserted1, memberAfterInsert1) = set.insert(.wool)
            #expect(inserted1 == true)
            #expect(memberAfterInsert1 == .wool)
            #expect(set == [.lumber, .wool])
            
            // Insert existing element
            let (inserted2, memberAfterInsert2) = set.insert(.lumber)
            #expect(inserted2 == false)
            #expect(memberAfterInsert2 == .lumber)
            #expect(set == [.lumber, .wool])
        }
        
        @Test("Remove with return value")
        func removeWithReturn() async throws {
            var set: SmallSet<Resource> = [.lumber, .wool]
            
            // Remove existing element
            let removed1: Resource? = set.remove(.wool)
            #expect(removed1 == .wool)
            #expect(set == [.lumber])
            
            // Remove non-existent element
            let removed2: Resource? = set.remove(.grain)
            #expect(removed2 == nil)
            #expect(set == [.lumber])
        }
        
        @Test("Update with element")
        func update() async throws {
            var set: SmallSet<Resource> = [.lumber]
            
            // Update with new element
            let result1 = set.update(with: .wool)
            #expect(result1 == nil)
            #expect(set == [.lumber, .wool])
            
            // Update with existing element
            let result2 = set.update(with: .lumber)
            #expect(result2 == .lumber)
            #expect(set == [.lumber, .wool])
        }

        @Test("Subscript")
        func subscriptAccess() {
            var set: SmallSet<Resource> = [.lumber, .wool]

            // Test get
            #expect(set[.lumber] == true)
            #expect(set[.wool] == true)
            #expect(set[.grain] == false)

            // Test set to add
            set[.grain] = true
            #expect(set == [.lumber, .wool, .grain])

            // Test set to remove
            set[.wool] = false
            #expect(set == [.lumber, .grain])

            // Test set to false when already absent
            set[.brick] = false
            #expect(set == [.lumber, .grain])

            // Test set to true when already present
            set[.lumber] = true
            #expect(set == [.lumber, .grain])
        }
    }

    @Suite("Set algebra")
    struct SetAlgebra {

        @Test("Contains element")
        func contains() {
            let set: SmallSet<Resource> = [.lumber, .wool, .grain]

            #expect(set.contains(.lumber) == true)
            #expect(set.contains(.wool) == true)
            #expect(set.contains(.grain) == true)
            #expect(set.contains(.brick) == false)
            #expect(set.contains(.ore) == false)
        }

        @Test("Union of two sets")
        func union() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .grain]

            // Non-mutating
            let result = set1.union(set2)
            #expect(result == [.lumber, .wool, .grain])

            // Mutating
            var result2 = set1
            result2.formUnion(set2)
            #expect(result2 == [.lumber, .wool, .grain])
        }

        @Test("Intersection of two sets")
        func intersection() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .grain]

            // Non-mutating
            let result = set1.intersection(set2)
            #expect(result == [.wool])

            // Mutating
            var result2 = set1
            result2.formIntersection(set2)
            #expect(result2 == [.wool])
        }

        @Test("Symmetric difference of two sets")
        func symmetricDifference() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .grain]

            // Non-mutating
            let result = set1.symmetricDifference(set2)
            #expect(result == [.lumber, .grain])

            // Mutating
            var result2 = set1
            result2.formSymmetricDifference(set2)
            #expect(result2 == [.lumber, .grain])
        }

        @Test("Strict subset relationship")
        func isStrictSubset() {
            let set1: SmallSet<Resource> = [.lumber]
            let set2: SmallSet<Resource> = [.lumber, .wool]
            let set3: SmallSet<Resource> = [.lumber]
            let set4: SmallSet<Resource> = [.grain]

            #expect(set1.isStrictSubset(of: set2) == true)
            #expect(set1.isStrictSubset(of: set3) == false) // Equal sets
            #expect(set2.isStrictSubset(of: set1) == false)
            #expect(set4.isStrictSubset(of: set2) == false) // Disjoint
        }

        @Test("Strict superset relationship")
        func isStrictSuperset() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.lumber]
            let set3: SmallSet<Resource> = [.lumber, .wool]
            let set4: SmallSet<Resource> = [.grain]

            #expect(set1.isStrictSuperset(of: set2) == true)
            #expect(set1.isStrictSuperset(of: set3) == false) // Equal sets
            #expect(set2.isStrictSuperset(of: set1) == false)
            #expect(set1.isStrictSuperset(of: set4) == false) // Disjoint
        }

        @Test("Subset relationship")
        func isSubset() {
            let set1: SmallSet<Resource> = [.lumber]
            let set2: SmallSet<Resource> = [.lumber, .wool]
            let set3: SmallSet<Resource> = [.lumber]
            let set4: SmallSet<Resource> = [.grain]
            let emptySet: SmallSet<Resource> = []

            #expect(set1.isSubset(of: set2) == true)
            #expect(set1.isSubset(of: set3) == true) // Equal sets
            #expect(set2.isSubset(of: set1) == false)
            #expect(set4.isSubset(of: set2) == false) // Disjoint
            #expect(emptySet.isSubset(of: set1) == true)
            #expect(set1.isSubset(of: emptySet) == false)
        }

        @Test("Superset relationship")
        func isSuperset() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.lumber]
            let set3: SmallSet<Resource> = [.lumber, .wool]
            let set4: SmallSet<Resource> = [.grain]
            let emptySet: SmallSet<Resource> = []

            #expect(set1.isSuperset(of: set2) == true)
            #expect(set1.isSuperset(of: set3) == true) // Equal sets
            #expect(set2.isSuperset(of: set1) == false)
            #expect(set1.isSuperset(of: set4) == false) // Disjoint
            #expect(set1.isSuperset(of: emptySet) == true)
            #expect(emptySet.isSuperset(of: set1) == false)
        }

        @Test("Disjoint sets")
        func isDisjoint() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.grain, .brick]
            let set3: SmallSet<Resource> = [.wool, .grain]
            let emptySet: SmallSet<Resource> = []

            #expect(set1.isDisjoint(with: set2) == true)
            #expect(set1.isDisjoint(with: set3) == false) // Share .wool
            #expect(set1.isDisjoint(with: emptySet) == true)
            #expect(emptySet.isDisjoint(with: emptySet) == true)
        }

        @Test("Subtraction of two sets")
        func subtraction() {
            let set1: SmallSet<Resource> = [.lumber, .wool]
            let set2: SmallSet<Resource> = [.wool, .grain]

            // Non-mutating
            let result = set1.subtracting(set2)
            #expect(result == [.lumber])

            // Mutating
            var result2 = set1
            result2.subtract(set2)
            #expect(result2 == [.lumber])
        }
    }

    @Suite("Collection")
    struct Collection {

        @Test("Collection conformance")
        func collection() {
            let set1: SmallSet<Resource> = []
            let set2: SmallSet<Resource> = [.lumber, .brick]
            let set3: SmallSet<Resource> = [.wool, .brick, .ore]
            let set4: SmallSet<Resource> = [.lumber, .wool, .grain, .brick, .ore]
            let set5: SmallSet<Resource> = [.lumber, .wool, .grain, .brick, .ore, .gold, .silver, .bronze]
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
            #expect(set1.map { $0 } == [])
            #expect(set2.map { $0 } == [.lumber, .brick])
            #expect(set3.map { $0 } == [.wool, .brick, .ore])
            #expect(set4.map { $0 } == [.lumber, .wool, .grain, .brick, .ore])
            #expect(set5.map { $0 } == [.lumber, .wool, .grain, .brick, .ore, .gold, .silver, .bronze])
        }

        @Test("Filter elements")
        func filter() {
            let set: SmallSet<Resource> = [.lumber, .wool, .grain, .brick]

            // Filter to only lumber and grain
            let filtered = set.filter { $0 == .lumber || $0 == .grain }
            #expect(filtered == [.lumber, .grain])

            // Filter to empty
            let empty = set.filter { _ in false }
            #expect(empty.isEmpty == true)

            // Filter to all
            let all = set.filter { _ in true }
            #expect(all == set)
        }
    }

    @Suite("Characters")
    struct Characters {

        @Test("Initialize from characters")
        func initFromCharacters() {
            let set: SmallSet<Resource> = .init(characters: "🪵🐑🌾")
            #expect(set == [.lumber, .wool, .grain])
        }

        @Test("Initialize from string literal")
        func initFromStringLiteral() {
            let set: SmallSet<Resource> = "🪵🌾"
            #expect(set == [.lumber, .grain])
        }

        @Test("Convert to characters")
        func toCharacters() {
            let set: SmallSet<Resource> = [.lumber, .wool, .grain]
            #expect(set.characters == "🪵🐑🌾")
        }
    }

    @Suite("Combinations")
    struct Combinations {

        @Test("Combinations")
        func combinations() {
            let set1: SmallSet<Resource> = []
            let set2: SmallSet<Resource> = [.grain]
            let set3: SmallSet<Resource> = [.grain, .wool]
            let set4: SmallSet<Resource> = [.grain, .wool, .lumber]
            #expect(set1.combinations(of: 3) == [])
            #expect(set2.combinations(of: 3) == [
                [.grain: 3],
            ])
            #expect(set3.combinations(of: 3) == [
                [.grain: 3],
                [.grain: 2, .wool: 1],
                [.grain: 1, .wool: 2],
                [.wool: 3],
            ])
            #expect(set4.combinations(of: 3) == [
                [.grain: 3],
                [.wool: 1, .grain: 2],
                [.wool: 2, .grain: 1],
                [.wool: 3],
                [.lumber: 1, .grain: 2],
                [.lumber: 1, .wool: 1, .grain: 1],
                [.lumber: 1, .wool: 2],
                [.lumber: 2, .grain: 1],
                [.lumber: 2, .wool: 1],
                [.lumber: 3],
            ])
        }

        @Test("Combinations of zero")
        func combinationsOfZero() {
            let set: SmallSet<Resource> = [.lumber, .wool]
            let combos = set.combinations(of: 0)
            #expect(combos == [])
        }
    }
}
