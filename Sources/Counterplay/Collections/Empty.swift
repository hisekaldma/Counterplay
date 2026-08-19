/// A type that only has one possible value.
///
/// Use `Empty` for a tile or grid whose cells carry no value, where only the shape matters.
///
///     let lTromino: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
public struct Empty: Sendable, Hashable, Comparable, CustomStringConvertible {
    @inlinable
    public init() {}

    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool { false }

    @inlinable
    public var description: String { "()" }
}
