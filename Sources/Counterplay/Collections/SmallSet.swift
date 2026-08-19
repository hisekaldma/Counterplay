/// An unordered collection of unique elements, stored inline as a bitmap.
///
/// Elements must conform to one of the `SmallRawUInt` protocols. The variant determines storage size:
///
/// | Element | Distinct values | Backing storage |
/// |---|---|---|
/// | `SmallRawUInt8` | 8 | `UInt8` |
/// | `SmallRawUInt16` | 16 | `UInt16` |
/// | `SmallRawUInt32` | 32 | `UInt32` |
/// | `SmallRawUInt64` | 64 | `UInt64` |
public struct SmallSet<Element>: Equatable, Hashable where Element: SmallRawUInt {
    @usableFromInline
    internal var storage: Element.SetStorage

    /// Creates an empty set.
    @inlinable
    public init() {
        self.storage = .zero
    }

    @inlinable
    internal init(storage: Element.SetStorage) {
        self.storage = storage
    }
}


// MARK: - Conformances

extension SmallSet: Sendable where Element.SetStorage: Sendable {
}

extension SmallSet: Comparable where Element.SetStorage: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.storage < rhs.storage
    }
}

extension SmallSet: CustomStringConvertible {
    public var description: String {
        if self.isEmpty {
            return "[]"
        }

        var result = "["
        var first = true
        for element in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            debugPrint(element, terminator: "", to: &result)
        }
        result += "]"
        return result
    }
}


// MARK: - Creating sets

extension SmallSet {
    /// Creates a new set from a finite sequence of items.
    @inlinable
    public init(_ sequence: some Sequence<Element>) {
        self.init()
        for element in sequence {
            self.insert(element)
        }
    }
}

extension SmallSet: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            self.insert(element)
        }
    }
}

extension SmallSet where Element: Hashable {
    /// Creates a new set from a standard `Set`.
    @inlinable
    public init(_ set: Set<Element>) {
        self.init()
        for element in set {
            self.insert(element)
        }
    }
}


// MARK: - Subscript

extension SmallSet {
    /// Gets or sets whether the given element is in the set.
    @inlinable
    public subscript(_ element: Element) -> Bool {
        get {
            contains(element)
        }
        set {
            if newValue {
                insert(element)
            } else {
                remove(element)
            }
        }
    }
}


// MARK: - Inserting/removing elements

extension SmallSet {
    /// Inserts the given element into the set without checking if it was already present.
    ///
    /// Use this method when you don't need to know whether the element was already in the set.
    /// It's more efficient than the `SetAlgebra`-conforming `insert(_:)` method.
    @inlinable
    public mutating func insert(_ element: Element) {
        storage |= element.setMask
    }

    /// Removes the given element from the set without checking if it was present.
    ///
    /// Use this method when you don't need to know whether the element was in the set.
    /// It's more efficient than the `SetAlgebra`-conforming `remove(_:)` method.
    @inlinable
    public mutating func remove(_ element: Element) {
        storage &= ~element.setMask
    }

    /// Inserts the given element into the set.
    ///
    /// - Parameter newMember: The element to insert.
    /// - Returns: A tuple containing a Boolean value indicating whether the insertion occurred,
    ///   and the element after insertion.
    @_disfavoredOverload
    @inlinable
    public mutating func insert(_ newMember: Element) -> (inserted: Bool, memberAfterInsert: Element) {
        let wasPresent = contains(newMember)
        storage |= newMember.setMask
        return (inserted: !wasPresent, memberAfterInsert: newMember)
    }

    /// Removes the given element from the set.
    ///
    /// - Parameter member: The element to remove.
    /// - Returns: The removed element if it was present, otherwise `nil`.
    @_disfavoredOverload
    @inlinable
    public mutating func remove(_ member: Element) -> Element? {
        let wasPresent = contains(member)
        storage &= ~member.setMask
        return wasPresent ? member : nil
    }

    /// Inserts the given element into the set, replacing any existing equal element.
    ///
    /// - Parameter newMember: The element to insert.
    /// - Returns: The element that was replaced, or `nil` if the element was not already in the set.
    @inlinable
    public mutating func update(with newMember: Element) -> Element? {
        let wasPresent = contains(newMember)
        storage |= newMember.setMask
        return wasPresent ? newMember : nil
    }
}


// MARK: - Algebra

extension SmallSet: SetAlgebra {
    /// Returns a Boolean value that indicates whether the given element is part of the set.
    @inlinable
    public func contains(_ element: Element) -> Bool {
        storage & element.setMask != 0
    }

    /// Returns a new set with the elements of both this and the given set.
    @inlinable
    public func union(_ other: Self) -> Self {
        .init(storage: self.storage | other.storage)
    }

    /// Adds the elements of the given set to the set.
    @inlinable
    public mutating func formUnion(_ other: Self) {
        self.storage |= other.storage
    }

    /// Returns a new set with the elements that are common to both this set and the given set.
    @inlinable
    public func intersection(_ other: Self) -> Self {
        .init(storage: self.storage & other.storage)
    }

    /// Removes the elements of this set that aren’t also in the given set.
    @inlinable
    public mutating func formIntersection(_ other: Self) {
        self.storage &= other.storage
    }

    /// Returns a new set with the elements that are either in this set or in the given set, but not in both.
    @inlinable
    public func symmetricDifference(_ other: Self) -> Self {
        .init(storage: self.storage ^ other.storage)
    }

    /// Removes the elements of the set that are also in the given set and adds the members of the given set that are not already in the set.
    @inlinable
    public mutating func formSymmetricDifference(_ other: Self) {
        self.storage ^= other.storage
    }

    /// Returns a Boolean value that indicates whether this set is a strict subset of the given set.
    @inlinable
    public func isStrictSubset(of other: Self) -> Bool {
        // S ⊂ T <=> S ⊆ T ∧ S ≠ T
        self.storage != other.storage && (self.storage | other.storage) == other.storage
    }

    /// Returns a Boolean value that indicates whether this set is a strict superset of the given set.
    @inlinable
    public func isStrictSuperset(of other: Self) -> Bool {
        // S ⊃ T <=> S ⊇ T ∧ S ≠ T
        self.storage != other.storage && (other.storage | self.storage) == self.storage
    }

    /// Returns a Boolean value that indicates whether this set is a subset of the given set.
    @inlinable
    public func isSubset(of other: Self) -> Bool {
        // S ⊆ T <=> S ∪ T == T
        (self.storage | other.storage) == other.storage
    }

    /// Returns a Boolean value that indicates whether this set is a superset of the given set.
    @inlinable
    public func isSuperset(of other: Self) -> Bool {
        // S ⊇ T <=> S ∪ T == S
        (other.storage | self.storage) == self.storage
    }

    /// Returns a Boolean value that indicates whether the set has no members in common with the given set.
    @inlinable
    public func isDisjoint(with other: Self) -> Bool {
        (self.storage & other.storage) == 0
    }

    /// Removes the elements of the given set from this set.
    @inlinable
    public mutating func subtract(_ other: Self) {
        self.storage &= ~other.storage
    }

    /// Returns a new set containing the elements of this set that do not occur in the given set.
    @inlinable
    public func subtracting(_ other: Self) -> Self {
        .init(storage: self.storage & ~other.storage)
    }
}


// MARK: - Collection

extension SmallSet: Collection {
    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal let wrapped: UInt

        @inlinable
        internal init(wrapped: UInt) {
            self.wrapped = wrapped
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.wrapped < rhs.wrapped
        }
    }

    @inlinable
    public var startIndex: Index {
        Index(wrapped: UInt(storage.trailingZeroBitCount))
    }

    @inlinable
    public var endIndex: Index {
        if storage.bitWidth == storage.leadingZeroBitCount {
            Index(wrapped: UInt(storage.bitWidth))
        } else {
            Index(wrapped: UInt(storage.bitWidth - storage.leadingZeroBitCount))
        }
    }

    @inlinable
    public subscript(index: Index) -> Element {
        Element(rawValue: index.wrapped)!
    }

    @inlinable
    public func index(after i: Index) -> Index {
        var index = i
        repeat {
            index = Index(wrapped: index.wrapped + 1)
            if index >= endIndex {
                return index
            }
        } while storage & (1 << index.wrapped) == 0
        return index
    }

    /// The number of elements in the set.
    @inlinable
    public var count: Int {
        storage.nonzeroBitCount
    }

    /// A Boolean value that indicates whether the set is empty.
    @inlinable
    public var isEmpty: Bool {
        storage == .zero
    }

    /// Returns a set containing the elements of this set that satisfy the given predicate.
    @inlinable
    public func filter(_ isIncluded: (Element) -> Bool) -> SmallSet<Element> {
        var result: Self = []
        for element in self {
            if isIncluded(element) {
                result.insert(element)
            }
        }
        return result
    }
}


// MARK: - Characters

extension SmallSet where Element: CharacterRepresentable {
    /// Creates a set from a string of characters, each representing one element in the set.
    ///
    /// For example:
    ///
    ///     let resources = SmallSet<Resource>(characters: "🪵🐑🌾")
    ///     print(resources.contains(.lumber)) // true
    ///     print(resources.contains(.wool))   // true
    ///     print(resources.contains(.grain))  // true
    ///
    /// - Parameter characters: A string of characters representing elements in the set.
    @inlinable
    public init(characters: String) {
        self.init()
        for character in characters {
            if let element = Element(character: character) {
                self.insert(element)
            }
        }
    }

    /// A string representation of the set, with one character per element.
    ///
    /// For example:
    ///
    ///     let resources: SmallSet<Resource> = [.lumber, .wool, .grain]
    ///     print(resources.characters) // "🪵🐑🌾"
    @inlinable
    public var characters: String {
        var characters = ""
        for element in self {
            characters.append(element.character)
        }
        return characters
    }
}

extension SmallSet: ExpressibleByUnicodeScalarLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(unicodeScalarLiteral value: String) {
        self.init(characters: value)
    }
}

extension SmallSet: ExpressibleByExtendedGraphemeClusterLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(characters: value)
    }
}

extension SmallSet: ExpressibleByStringLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(stringLiteral value: String) {
        self.init(characters: value)
    }
}


// MARK: - Combinations

extension SmallSet {
    /// Returns all possible combinations of the elements in this set,
    /// where each combination has the specified number of elements.
    ///
    /// Each returned `SmallCountedSet` uses elements of `self` as keys and
    /// non-negative counts as values, with all counts summing to `count`.
    /// Useful for enumerating things like "pick 3 resources from {wood, brick,
    /// ore}, possibly with duplicates."
    ///
    /// For example:
    ///
    ///     let combos = [.a, .b].combinations(of: 2)
    ///     print(combos) // [[.b: 2], [.a: 1, .b: 1], [.a: 2]]
    ///
    /// - Parameter count: The total number of picks to distribute. Must be
    ///   non-negative.
    /// - Returns: Every distinct distribution, in unspecified order. Returns
    ///   an empty array if this set is empty.
    /// - Precondition: The count must be non-negative.
    @inlinable
    public func combinations(of count: Int) -> [SmallCountedSet<Element>] {
        precondition(count >= 0, "The count must be non-negative")
        var results: [SmallCountedSet<Element>] = []

        func generate(current: SmallCountedSet<Element>, remainingCount: Int, remainingElements: Self) {
            guard let element = remainingElements.first else {
                if !current.isEmpty {
                    results.append(current)
                }
                return
            }

            var newRemainingElements = remainingElements
            newRemainingElements.remove(element)

            guard !newRemainingElements.isEmpty else {
                var finalCombination = current
                finalCombination[element] = remainingCount
                if !finalCombination.isEmpty {
                    results.append(finalCombination)
                }
                return
            }

            for n in 0...remainingCount {
                var newCombination = current
                newCombination[element] = n
                generate(current: newCombination, remainingCount: remainingCount - n, remainingElements: newRemainingElements)
            }
        }

        generate(current: [:], remainingCount: count, remainingElements: self)
        return results
    }
}
