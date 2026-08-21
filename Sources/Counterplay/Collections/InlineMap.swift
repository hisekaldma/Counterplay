/// A collection of key-value pairs, stored inline in a fixed-size array.
///
/// Keys must conform to `SmallRawUInt8` (up to 8 distinct values).
/// Values are stored in an inline array of size `size`, indexed by the
/// key's raw value, so lookups are O(1).
///
/// - Important: `Key` must have a case for every raw value in `0..<size`.
///   An `InlineMap<3, Key, Value>` stores a value for keys with raw values
///   0, 1, and 2; keys with higher raw values can't be stored, and
///   subscripting with one is a programmer error.
public struct InlineMap<let size: Int, Key, Value> where Key: SmallRawUInt8 {
    @usableFromInline
    internal var storage: InlineArray<size, Value>

    /// Creates an inline map with the given initial value.
    @inlinable
    public init(repeating initialValue: Value) {
        for i in 0..<size {
            assert(
                Key(rawValue: UInt(i)) != nil,
                "InlineMap<\(size), \(Key.self), \(Value.self)> requires \(Key.self) to have a case for every raw value in 0..<\(size), but there is none for \(i)."
            )
        }
        self.storage = .init(repeating: initialValue)
    }

    @inlinable
    internal init(storage: InlineArray<size, Value>) {
        self.storage = storage
    }
}


// MARK: - Conformances

extension InlineMap: Sendable where Value: Sendable {}

extension InlineMap: Equatable where Value: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for i in lhs.storage.indices {
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
        for i in storage.indices {
            hasher.combine(UInt(i))
            hasher.combine(storage[i])
        }
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
    /// - Precondition: `dictionary` must contain exactly one entry for each
    ///   key with a raw value in `0..<size`.
    @inlinable
    public init(_ dictionary: [Key: Value]) where Key: Hashable {
        self.init(uniqueKeysWithValues: dictionary)
    }

    /// Creates a new inline map from the key-value pairs in the given sequence.
    ///
    /// - Precondition: `keysAndValues` must contain exactly one entry for each
    ///   key with a raw value in `0..<size`.
    @inlinable
    public init<S>(uniqueKeysWithValues keysAndValues: S) where S: Sequence, S.Element == (key: Key, value: Value) {
        let sorted = keysAndValues.sorted { $0.key.scalarIndex < $1.key.scalarIndex }
        precondition(
            sorted.count == size,
            "InlineMap<\(size), \(Key.self), \(Value.self)> requires exactly \(size) entries, but \(sorted.count) were given."
        )
        self.storage = .init(initializingWith: { span in
            var i = 0
            for (key, value) in sorted {
                precondition(
                    Int(key.scalarIndex) == i,
                    "InlineMap<\(size), \(Key.self), \(Value.self)> requires exactly one entry for each raw value in 0..<\(size), but found \(key.scalarIndex) at position \(i)."
                )
                span.append(value)
                i += 1
            }
        })
    }
}


// MARK: - Count

extension InlineMap {
    /// The number of key-value pairs in the map.
    @inlinable
    public var count: Int {
        storage.count
    }
}


// MARK: - Subscript

extension InlineMap {
    /// Gets or sets the value associated with the given key.
    ///
    /// - Precondition: The key must have a raw value in `0..<size`
    @inlinable
    public subscript(_ key: Key) -> Value {
        _read {
            precondition(key.scalarIndex < size, "\(key) has raw value \(key.rawValue), which is outside 0..<\(size).")
            yield storage[key.scalarIndex]
        }
        _modify {
            precondition(key.scalarIndex < size, "\(key) has raw value \(key.rawValue), which is outside 0..<\(size).")
            yield &storage[key.scalarIndex]
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
        Index(wrapped: storage.startIndex)
    }

    @inlinable
    public var endIndex: Index {
        Index(wrapped: storage.endIndex)
    }

    @inlinable
    public subscript(index: Index) -> Element {
        precondition(index.wrapped >= storage.startIndex, "Index out of bounds")
        precondition(index.wrapped < storage.endIndex, "Index out of bounds")
        return (Key(rawValue: UInt(index.wrapped))!, storage[index.wrapped])
    }

    @inlinable
    public func index(after index: Index) -> Index {
        precondition(index.wrapped < storage.endIndex, "Can't advance past endIndex")
        return Index(wrapped: index.wrapped + 1)
    }
}


// MARK: - Mapping

extension InlineMap {
    /// Returns a new inline map containing the keys of this map with the
    /// values transformed by the given closure.
    @inlinable
    public func mapValues<T>(_ transform: (Value) -> T) -> InlineMap<size, Key, T> {
        InlineMap<size, Key, T>(
            storage: .init({ i in
                transform(self.storage[i])
            }))
    }
}
