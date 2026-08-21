/// An unordered collection of elements with per-element counts, stored inline as a SIMD vector.
///
/// Elements must conform to one of the `SmallRawUInt` protocols. The variant determines storage size:
///
/// | Element | Distinct values | Backing storage |
/// |---|---|---|
/// | `SmallRawUInt8` | 8 | `SIMD8<UInt16>` |
/// | `SmallRawUInt16` | 16 | `SIMD16<UInt16>` |
/// | `SmallRawUInt32` | 32 | `SIMD32<UInt16>` |
/// | `SmallRawUInt64` | 64 | `SIMD64<UInt16>` |
public struct SmallCountedSet<Element>: Equatable, Hashable where Element: SmallRawUInt {
    @usableFromInline
    internal var storage: Element.CountedSetStorage

    /// Creates an empty set.
    @inlinable
    public init() {
        self.storage = .zero
    }

    @inlinable
    internal init(storage: Element.CountedSetStorage) {
        self.storage = storage
    }
}

extension SmallCountedSet {
    /// The maximum possible count for each element in the set.
    @inlinable
    public static var maxCount: Int { Int(UInt16.max) }
}


// MARK: - Conformances

extension SmallCountedSet: Sendable where Element.CountedSetStorage: Sendable {
}

extension SmallCountedSet: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        for i in lhs.storage.indices {
            if lhs.storage[i] < rhs.storage[i] {
                return true
            } else if lhs.storage[i] > rhs.storage[i] {
                return false
            }
        }
        return false
    }
}


// MARK: - Description

extension SmallCountedSet: CustomStringConvertible {
    public var description: String {
        if self.isEmpty {
            return "[:]"
        }

        var result = "["
        var first = true
        for (element, count) in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            debugPrint(element, terminator: "", to: &result)
            result += ": "
            debugPrint(count, terminator: "", to: &result)
        }
        result += "]"
        return result
    }
}


// MARK: - Creating counted sets

extension SmallCountedSet {
    /// Creates a new set from a finite sequence of items.
    @inlinable
    public init(_ sequence: some Sequence<Element>) {
        self.init()
        for element in sequence {
            self.insert(element)
        }
    }

    /// Creates a counted set from a `SmallSet`, with each element having a count of 1.
    @inlinable
    public init(_ set: SmallSet<Element>) {
        self.init()
        for element in set {
            self.insert(element)
        }
    }
}

extension SmallCountedSet where Element: Hashable {
    /// Creates a counted set from a standard `Set`, with each element having a count of 1.
    @inlinable
    public init(_ set: Set<Element>) {
        self.init()
        for element in set {
            self.insert(element)
        }
    }
}

extension SmallCountedSet: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (Element, Int)...) {
        self.init()
        for (element, count) in elements {
            self.insert(element, count: count)
        }
    }
}

extension SmallCountedSet: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            self.insert(element, count: 1)
        }
    }
}

extension SmallCountedSet where Element: CaseIterable {
    /// Creates a set with the given count for each element.
    @inlinable
    public init(repeating count: Int) {
        self.init()
        for element in Element.allCases {
            self[element] = count
        }
    }

    /// The set with count 1 for each element.
    @inlinable
    public static var one: Self {
        Self(repeating: 1)
    }
}


// MARK: - Subscript

extension SmallCountedSet {
    /// Gets or sets the count of the given element in the set.
    ///
    /// - Note: The count for an element can never be less than 0.
    @inlinable
    public subscript(_ element: Element) -> Int {
        get {
            Int(storage[element.scalarIndex])
        }
        set {
            storage[element.scalarIndex] = UInt16(clamping: newValue)
        }
    }
}


// MARK: - Inserting/removing elements

extension SmallCountedSet {
    /// Increases the count of the given element in the set by the given count.
    ///
    /// - Note: The count for an element can never be more than `SmallCountedSet.maxCount`.
    @inlinable
    public mutating func insert(_ element: Element, count: Int = 1) {
        let index = element.scalarIndex
        let count = count.clamped(to: -Self.maxCount...Self.maxCount)
        storage[index] = UInt16(clamping: Int(storage[index]) + count)
    }

    /// Decreases the count of the given element in the set by the given count.
    ///
    /// - Note: The count for an element can never be less than 0.
    @inlinable
    public mutating func remove(_ element: Element, count: Int = 1) {
        let index = element.scalarIndex
        let count = count.clamped(to: -Self.maxCount...Self.maxCount)
        storage[index] = UInt16(clamping: Int(storage[index]) - count)
    }

    /// Decreases the count of the given element in the set to 0.
    @inlinable
    public mutating func removeAll(_ element: Element) {
        let index = element.scalarIndex
        storage[index] = 0
    }
}


// MARK: - Arithmetic

extension SmallCountedSet: AdditiveArithmetic {
    @inlinable
    public static var zero: SmallCountedSet<Element> {
        [:]
    }

    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self {
        let max = Element.CountedSetStorage(repeating: .max)
        let addend = rhs.storage.clamped(lowerBound: .zero, upperBound: max &- lhs.storage)
        return .init(storage: lhs.storage &+ addend)
    }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self {
        let subtrahend = rhs.storage.clamped(lowerBound: .zero, upperBound: lhs.storage)
        return .init(storage: lhs.storage &- subtrahend)
    }

    @inlinable
    public static func += (lhs: inout Self, rhs: Self) {
        lhs = lhs + rhs
    }

    @inlinable
    public static func -= (lhs: inout Self, rhs: Self) {
        lhs = lhs - rhs
    }
}

extension SmallCountedSet {
    @inlinable
    public static func * (lhs: Self, rhs: Int) -> Self {
        let multiplier = UInt16(clamping: rhs)
        guard multiplier > 0 else {
            return .zero
        }
        let product = lhs.storage &* .init(repeating: multiplier)
        let overflow = lhs.storage .> .init(repeating: UInt16.max / multiplier)
        return .init(storage: product.replacing(with: .max, where: overflow))
    }

    @inlinable
    public static func * (lhs: Int, rhs: Self) -> Self {
        rhs * lhs
    }

    @inlinable
    public static func *= (lhs: inout Self, rhs: Int) {
        lhs = lhs * rhs
    }
}


// MARK: - Algebra

extension SmallCountedSet {
    /// Returns a Boolean value that indicates whether the given element is part of the set.
    @inlinable
    public func contains(_ element: Element) -> Bool {
        storage[element.scalarIndex] > 0
    }

    /// Returns a Boolean value that indicates whether the set contains the given set, i.e. has at least the given counts of the given elements.
    ///
    /// - Note: This is the same as `isSuperset(of:)`.
    @inlinable
    public func contains(_ other: Self) -> Bool {
        isSuperset(of: other)
    }

    /// Returns a new counted set with the **maximum** count of each element from this set and the given set.
    ///
    /// For example:
    ///
    ///     let a: SmallCountedSet<Resource> = [.lumber: 3, .brick: 1]
    ///     let b: SmallCountedSet<Resource> = [.lumber: 2, .brick: 5]
    ///     print(a.union(b)) // [.lumber: 3, .brick: 5]
    ///
    /// - Note: To sum counts instead, use the `+` operator.
    @inlinable
    public func union(_ other: Self) -> Self {
        .init(storage: pointwiseMax(self.storage, other.storage))
    }

    /// Updates each element's count to the **maximum** of its count in this set and the given set.
    ///
    /// For example:
    ///
    ///     var a: SmallCountedSet<Resource> = [.lumber: 3, .brick: 1]
    ///     let b: SmallCountedSet<Resource> = [.lumber: 2, .brick: 5]
    ///     a.formUnion(b)
    ///     print(a) // [.lumber: 3, .brick: 5]
    ///
    /// - Note: To sum counts instead, use the `+` operator.
    @inlinable
    public mutating func formUnion(_ other: Self) {
        self.storage = pointwiseMax(self.storage, other.storage)
    }

    /// Returns a new counted set with the **minimum** count of each element from this set and the given set.
    ///
    /// For example:
    ///
    ///     let a: SmallCountedSet<Resource> = [.lumber: 3, .brick: 1]
    ///     let b: SmallCountedSet<Resource> = [.lumber: 2, .brick: 5]
    ///     print(a.intersection(b)) // [.lumber: 2, .brick: 1]
    @inlinable
    public func intersection(_ other: Self) -> Self {
        .init(storage: pointwiseMin(self.storage, other.storage))
    }

    /// Updates each element's count to the **minimum** of its count in this set and the given set.
    ///
    /// For example:
    ///
    ///     var a: SmallCountedSet<Resource> = [.lumber: 3, .brick: 1]
    ///     let b: SmallCountedSet<Resource> = [.lumber: 2, .brick: 5]
    ///     a.formIntersection(b)
    ///     print(a) // [.lumber: 2, .brick: 1]
    @inlinable
    public mutating func formIntersection(_ other: Self) {
        self.storage = pointwiseMin(self.storage, other.storage)
    }

    /// Returns a Boolean value that indicates whether the count of every element in this set
    /// is less than or equal to its count in the given set.
    @inlinable
    public func isSubset(of other: Self) -> Bool {
        pointwiseMin(storage, other.storage) == storage
    }

    /// Returns a Boolean value that indicates whether the count of every element in this set
    /// is greater than or equal to its count in the given set.
    @inlinable
    public func isSuperset(of other: Self) -> Bool {
        pointwiseMax(storage, other.storage) == storage
    }

    /// Returns a Boolean value that indicates whether the set has no elements in common with the given set.
    @inlinable
    public func isDisjoint(with other: Self) -> Bool {
        pointwiseMin(storage, other.storage) == .zero
    }

    /// Returns a Boolean value that indicates whether this set intersects the given set, i.e. the sets have at least one common element.
    @inlinable
    public func intersects(_ other: Self) -> Bool {
        pointwiseMin(storage, other.storage) != .zero
    }
}


// MARK: - Reductions

extension SmallCountedSet {
    /// The total number of elements in the set.
    @inlinable
    public var totalCount: Int {
        storage.indices.reduce(into: 0) { $0 += Int(storage[$1]) }
    }

    /// The highest count in the set.
    @inlinable
    public var highestCount: Int {
        Int(storage.max())
    }

    /// The lowest non-zero count in the set.
    @inlinable
    public var lowestCount: Int {
        if isEmpty {
            return 0
        } else {
            let withoutZeros = storage.replacing(with: .max, where: storage .== Element.CountedSetStorage.zero)
            return Int(withoutZeros.min())
        }
    }
}


// MARK: - Collection

extension SmallCountedSet: Collection {
    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal let wrapped: Int

        @usableFromInline
        internal init(wrapped: Int) {
            self.wrapped = wrapped
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.wrapped < rhs.wrapped
        }
    }

    @inlinable
    public var startIndex: Index {
        if isEmpty {
            Index(wrapped: 0)
        } else {
            Index(wrapped: storage.leadingZeroScalarCount)
        }
    }

    @inlinable
    public var endIndex: Index {
        if isEmpty {
            Index(wrapped: 0)
        } else {
            Index(wrapped: storage.scalarCount - storage.trailingZeroScalarCount)
        }
    }

    @inlinable
    public subscript(index: Index) -> (element: Element, count: Int) {
        let element = Element(rawValue: UInt(index.wrapped))!
        return (element, self[element])
    }

    @inlinable
    public func index(after i: Index) -> Index {
        var index = i.wrapped + 1
        let endIndex = endIndex.wrapped
        while index < endIndex, storage[index] == 0 {
            index += 1
        }
        return Index(wrapped: index)
    }

    /// The total number of distinct element values in the set.
    ///
    /// - Note: This returns the number of distinct elements with non-zero counts, not the sum of all counts.
    ///   For the total count of all elements, use `totalCount`.
    @inlinable
    public var count: Int {
        storage.nonzeroScalarCount
    }

    /// A Boolean value that indicates whether the set is empty.
    @inlinable
    public var isEmpty: Bool {
        storage == .zero
    }
}

extension SIMD where Scalar: FixedWidthInteger {
    @inlinable
    internal var nonzeroScalarCount: Int {
        Int(
            Self(repeating: 1)
                .replacing(with: 0, where: self .== .zero)
                .wrappedSum())
    }

    @inlinable
    internal var leadingZeroScalarCount: Int {
        let mask = (self .!= .zero)
        for index in mask.indices {
            if mask[index] {
                return index
            }
        }
        return scalarCount
    }

    @inlinable
    internal var trailingZeroScalarCount: Int {
        let mask = (self .!= .zero)
        for index in mask.indices.reversed() {
            if mask[index] {
                return scalarCount - index - 1
            }
        }
        return scalarCount
    }
}


// MARK: - Characters

extension SmallCountedSet where Element: CharacterRepresentable {
    /// Creates a counted set from a string of characters, each representing one element in the set.
    ///
    /// For example:
    ///
    ///     let resources = SmallCountedSet<Resource>(characters: "🪵🪵🐑🌾🌾🌾")
    ///     print(resources[.lumber]) // 2
    ///     print(resources[.wool])   // 1
    ///     print(resources[.grain])  // 3
    ///
    /// - Parameter characters: A string of characters representing elements in the set. Each occurrence of a character increments the count for that element.
    @inlinable
    public init(characters: String) {
        self.init()
        for character in characters {
            if let element = Element(character: character) {
                self.insert(element)
            }
        }
    }

    /// A string representation of the counted set, with each element repeated according to its count.
    ///
    /// For example:
    ///
    ///     var resources: SmallCountedSet<Resource> = [.lumber: 2, .wool: 1, .grain: 3]
    ///     print(resources.characters) // "🪵🪵🐑🌾🌾🌾"
    @inlinable
    public var characters: String {
        var characters = ""
        for (element, count) in self {
            for _ in 0..<count {
                characters.append(element.character)
            }
        }
        return characters
    }
}

extension SmallCountedSet: ExpressibleByUnicodeScalarLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(unicodeScalarLiteral value: String) {
        self.init(characters: value)
    }
}

extension SmallCountedSet: ExpressibleByExtendedGraphemeClusterLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(extendedGraphemeClusterLiteral value: String) {
        self.init(characters: value)
    }
}

extension SmallCountedSet: ExpressibleByStringLiteral where Element: CharacterRepresentable {
    @inlinable
    public init(stringLiteral value: String) {
        self.init(characters: value)
    }
}
