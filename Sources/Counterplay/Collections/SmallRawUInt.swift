/// A value that can be represented as an unsigned integer under a certain bound,
/// used together with `SmallSet`, `SmallCountedSet`, and `InlineMap`.
///
/// - Important: Do not conform to this protocol directly. Instead, conform to
/// `SmallRawUInt8`, `SmallRawUInt16`, `SmallRawUInt32`, or `SmallRawUInt64`,
/// depending on how many distinct values your type has.
///
/// Typically conformed to by enums whose `RawValue` is `UInt`:
///
///     enum Resource: UInt, SmallRawUInt8 {
///         case lumber, wool, grain, brick, ore
///     }
public nonisolated protocol SmallRawUInt: RawRepresentable<UInt> {
    associatedtype SetStorage: UnsignedInteger & FixedWidthInteger
    associatedtype CountedSetStorage: SIMD<UInt16>

    /// The number of distinct values this type may have.
    ///
    /// Raw values must lie in `0..<bound`.
    static var bound: UInt { get }
}

/// A value that can be represented by an unsigned integer in the range `0..<8`.
public protocol SmallRawUInt8: SmallRawUInt
where SetStorage == UInt8, CountedSetStorage == SIMD8<UInt16> {
}

/// A value that can be represented by an unsigned integer in the range `0..<16`.
public protocol SmallRawUInt16: SmallRawUInt
where SetStorage == UInt16, CountedSetStorage == SIMD16<UInt16> {
}

/// A value that can be represented by an unsigned integer in the range `0..<32`.
public protocol SmallRawUInt32: SmallRawUInt
where SetStorage == UInt32, CountedSetStorage == SIMD32<UInt16> {
}

/// A value that can be represented by an unsigned integer in the range `0..<64`.
public protocol SmallRawUInt64: SmallRawUInt
where SetStorage == UInt64, CountedSetStorage == SIMD64<UInt16> {
}

extension SmallRawUInt8 { public static var bound: UInt { 8 } }
extension SmallRawUInt16 { public static var bound: UInt { 16 } }
extension SmallRawUInt32 { public static var bound: UInt { 32 } }
extension SmallRawUInt64 { public static var bound: UInt { 64 } }

extension SmallRawUInt {
    @inlinable
    internal var setMask: SetStorage {
        assert(
            rawValue < Self.bound,
            "\(Self.self) has a case with raw value \(rawValue). SmallRawUInt\(Self.bound) requires raw values in 0..<\(Self.bound)."
        )
        return 1 << rawValue
    }

    @inlinable
    internal var scalarIndex: Int {
        assert(
            rawValue < Self.bound,
            "\(Self.self) has a case with raw value \(rawValue). SmallRawUInt\(Self.bound) requires raw values in 0..<\(Self.bound)."
        )
        return Int(rawValue)
    }
}
