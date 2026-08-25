/// A collection of key-value pairs, stored inline in a fixed-size array.
///
/// Keys must conform to `SmallRawUInt` and have raw values in `0..<maxSize`.
/// Values are stored in an inline array of `maxSize` slots, indexed by the key's raw value, so lookups are O(1).
public struct InlineMap<let maxSize: Int, Key, Value> where Key: SmallRawUInt {
    @usableFromInline
    internal var storage: InlineArray<maxSize, Value?>

    /// Creates an empty map.
    @inlinable
    public init() {
        self.storage = .init(repeating: nil)
    }

    @inlinable
    internal init(storage: InlineArray<maxSize, Value?>) {
        self.storage = storage
    }
}


// MARK: - Conformances

extension InlineMap: Sendable where Value: Sendable {}

extension InlineMap: Equatable where Value: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<maxSize {
            guard lhs.storage[i] == rhs.storage[i] else {
                return false
            }
        }
        return true
    }
}

extension InlineMap: Hashable where Value: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        var count = 0
        for i in 0..<maxSize {
            if let value = storage[i] {
                hasher.combine(UInt(i))
                hasher.combine(value)
                count += 1
            }
        }
        hasher.combine(count)
    }
}


// MARK: - Description

extension InlineMap: CustomStringConvertible {
    public var description: String {
        if self.isEmpty {
            return "[:]"
        }

        var result = "["
        var first = true
        for (key, value) in self {
            if first {
                first = false
            } else {
                result += ", "
            }
            debugPrint(key, terminator: "", to: &result)
            result += ": "
            debugPrint(value, terminator: "", to: &result)
        }
        result += "]"
        return result
    }
}


// MARK: - Creating maps

extension InlineMap: ExpressibleByDictionaryLiteral {
    @inlinable
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}

extension InlineMap {
    /// Creates a new inline map from the given dictionary.
    ///
    /// - Precondition: Every key in `dictionary` must have a raw value in `0..<maxSize`.
    @inlinable
    public init(_ dictionary: [Key: Value]) where Key: Hashable {
        self.init(uniqueKeysWithValues: dictionary)
    }

    /// Creates a new inline map from the key-value pairs in the given sequence.
    ///
    /// - Precondition: The sequence must not have duplicate keys.
    /// - Precondition: Every key in the sequence must have a raw value in `0..<maxSize`.
    @inlinable
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S: Sequence, S.Element == (key: Key, value: Value) {
        self.init()
        for (key, value) in keysAndValues {
            let index = key.scalarIndex
            precondition(
                index < maxSize,
                "InlineMap with maxSize \(maxSize) can't contain '\(key)' with raw value \(key.rawValue)."
            )
            precondition(
                storage[index] == nil,
                "Duplicate values for key: '\(key)'."
            )
            storage[index] = value
        }
    }
}


// MARK: - Count

extension InlineMap {
    /// The number of key-value pairs in the map.
    @inlinable
    public var count: Int {
        var count = 0
        for i in 0..<maxSize where storage[i] != nil {
            count += 1
        }
        return count
    }

    /// Whether the map has no key-value pairs.
    @inlinable
    public var isEmpty: Bool {
        for i in 0..<maxSize where storage[i] != nil {
            return false
        }
        return true
    }
}


// MARK: - Subscript

extension InlineMap {
    /// Gets or sets the value associated with the given key, or `nil` if the key is absent.
    ///
    /// - Precondition: The key must have a raw value in `0..<maxSize`.
    @inlinable
    public subscript(key: Key) -> Value? {
        _read {
            let index = key.scalarIndex
            precondition(
                index < maxSize,
                "InlineMap with maxSize \(maxSize) can't contain '\(key)' with raw value \(key.rawValue)."
            )
            yield storage[index]
        }
        _modify {
            let index = key.scalarIndex
            precondition(
                index < maxSize,
                "InlineMap with maxSize \(maxSize) can't contain '\(key)' with raw value \(key.rawValue)."
            )
            yield &storage[index]
        }
    }

    /// Gets or sets the value associated with the given key, falling back to the given default value if the key isn’t found.
    ///
    /// - Precondition: The key must have a raw value in `0..<maxSize`.
    @inlinable
    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            self[key] ?? defaultValue()
        }
        _modify {
            let index = key.scalarIndex
            precondition(
                index < maxSize,
                "InlineMap with maxSize \(maxSize) can't contain '\(key)' with raw value \(key.rawValue)."
            )
            if storage[index] == nil {
                storage[index] = defaultValue()
            }
            yield &storage[index]!
        }
    }
}


// MARK: - Collection

extension InlineMap: Collection {
    public typealias Element = (key: Key, value: Value)

    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal let wrapped: Int

        @inlinable
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
        Index(wrapped: firstOccupiedSlot(after: -1))
    }

    @inlinable
    public var endIndex: Index {
        Index(wrapped: maxSize)
    }

    @inlinable
    public subscript(index: Index) -> Element {
        precondition(index.wrapped >= 0, "Index out of bounds")
        precondition(index.wrapped < maxSize, "Index out of bounds")
        guard let value = storage[index.wrapped] else {
            preconditionFailure("Index does not refer to an entry in the map")
        }
        return (Key(rawValue: UInt(index.wrapped))!, value)
    }

    @inlinable
    public func index(after index: Index) -> Index {
        precondition(index.wrapped >= 0, "Index out of bounds")
        precondition(index.wrapped <= maxSize, "Index out of bounds")
        let slot = firstOccupiedSlot(after: index.wrapped)
        precondition(slot <= maxSize, "Can't get the index after endIndex")
        return Index(wrapped: slot)
    }
}

extension InlineMap: BidirectionalCollection {
    @inlinable
    public func index(before index: Index) -> Index {
        precondition(index.wrapped >= 0, "Index out of bounds")
        precondition(index.wrapped <= maxSize, "Index out of bounds")
        let slot = lastOccupiedSlot(before: index.wrapped)
        precondition(slot >= 0, "Can't get the index before startIndex")
        return Index(wrapped: slot)
    }
}

extension InlineMap {
    @inlinable
    internal func firstOccupiedSlot(after start: Int) -> Int {
        var i = start
        repeat {
            i += 1
        } while i < maxSize && storage[i] == nil
        return i
    }

    @inlinable
    internal func lastOccupiedSlot(before start: Int) -> Int {
        var i = start
        repeat {
            i -= 1
        } while i >= 0 && storage[i] == nil
        return i
    }
}


// MARK: - Keys and values

extension InlineMap {
    /// The keys present in the map, in ascending order of raw value.
    @inlinable
    public var keys: some Collection<Key> {
        lazy.map(\.key)
    }

    /// The values present in the map, in ascending order of their key's raw value.
    @inlinable
    public var values: some Collection<Value> {
        lazy.map(\.value)
    }
}


// MARK: - Mapping

extension InlineMap {
    /// Returns a new inline map containing the keys of this map with the
    /// values transformed by the given closure.
    @inlinable
    public func mapValues<T>(_ transform: (Value) -> T) -> InlineMap<maxSize, Key, T> {
        InlineMap<maxSize, Key, T>(
            storage: .init({ i in
                self.storage[i].map(transform)
            }))
    }

    /// Returns a new inline map containing the entries of this map for which
    /// the given closure returns a value, with the values transformed by the closure.
    @inlinable
    public func compactMapValues<T>(_ transform: (Value) -> T?) -> InlineMap<maxSize, Key, T> {
        InlineMap<maxSize, Key, T>(
            storage: .init({ i in
                self.storage[i].flatMap(transform)
            }))
    }

    /// Returns a new inline map containing the entries that satisfy the given predicate.
    @inlinable
    public func filter(_ isIncluded: (Element) -> Bool) -> Self {
        var result = Self()
        for i in 0..<maxSize {
            if let value = storage[i], isIncluded((Key(rawValue: UInt(i))!, value)) {
                result.storage[i] = value
            }
        }
        return result
    }
}
