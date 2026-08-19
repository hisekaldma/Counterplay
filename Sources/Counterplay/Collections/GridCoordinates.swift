/// A coordinate space that a grid's cells can be addressed in.
///
/// A conforming coordinate supplies the arithmetic for stepping from one cell to
/// another, and the symmetry group of its grid: four rotations for a square grid,
/// six for a hex grid.
public protocol GridCoordinate: Comparable, Hashable, Sendable {
    /// The coordinate that shapes are measured and rotated against.
    static var origin: Self { get }

    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self

    /// Returns the coordinate whose every component is the smaller of the two given ones.
    static func componentwiseMin(_ lhs: Self, _ rhs: Self) -> Self

    /// Returns the coordinate whose every component is the larger of the two given ones.
    static func componentwiseMax(_ lhs: Self, _ rhs: Self) -> Self

    /// The number of rotations that return a shape to its starting orientation.
    static var rotationCount: Int { get }

    /// Returns the coordinate rotated one step clockwise about the origin.
    func rotated() -> Self

    /// Returns the coordinate reflected about the origin.
    func reflected() -> Self
}


// MARK: - Square coordinates

/// A coordinate in a square grid.
///
/// The y axis increases towards the south, so `SquareCoordinate(0, 0)` is the
/// north west corner of a grid.
public struct SquareCoordinate: Sendable, Equatable, Hashable {
    public var x: Int
    public var y: Int

    @inlinable
    public init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

extension SquareCoordinate: CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}

extension SquareCoordinate: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.y, lhs.x) < (rhs.y, rhs.x) }
}

extension SquareCoordinate {
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self { .init(lhs.x + rhs.x, lhs.y + rhs.y) }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self { .init(lhs.x - rhs.x, lhs.y - rhs.y) }
}

extension SquareCoordinate {
    /// Returns the number of steps between this coordinate and the given one,
    /// moving only between cells that share an edge.
    ///
    /// This is the step count for `SquareDirection.orthogonal` movement. For
    /// movement that also allows diagonals, use ``chebyshevDistance(to:)``.
    ///
    ///     SquareCoordinate(0, 0).manhattanDistance(to: .init(2, 3)) // 5
    @inlinable
    public func manhattanDistance(to other: Self) -> Int {
        let difference = self - other
        return abs(difference.x) + abs(difference.y)
    }

    /// Returns the number of steps between this coordinate and the given one,
    /// moving between cells that share either an edge or a corner.
    ///
    /// This is the step count for `SquareDirection.allCases` movement — the way a
    /// king moves in chess. For movement restricted to edges, use
    /// ``manhattanDistance(to:)``.
    ///
    ///     SquareCoordinate(0, 0).chebyshevDistance(to: .init(2, 3)) // 3
    @inlinable
    public func chebyshevDistance(to other: Self) -> Int {
        let difference = self - other
        return Swift.max(abs(difference.x), abs(difference.y))
    }
}

extension SquareCoordinate: GridCoordinate {
    @inlinable
    public static var origin: Self { .init(0, 0) }

    @inlinable
    public static func componentwiseMin(_ lhs: Self, _ rhs: Self) -> Self {
        .init(Swift.min(lhs.x, rhs.x), Swift.min(lhs.y, rhs.y))
    }

    @inlinable
    public static func componentwiseMax(_ lhs: Self, _ rhs: Self) -> Self {
        .init(Swift.max(lhs.x, rhs.x), Swift.max(lhs.y, rhs.y))
    }

    @inlinable
    public static var rotationCount: Int { 4 }

    @inlinable
    public func rotated() -> Self { .init(-y, x) }

    @inlinable
    public func reflected() -> Self { .init(-x, y) }
}


// MARK: - Hex coordinates

/// An axial coordinate in a hex grid.
///
/// `q` and `r` are two of the three axes of the hex, and `s` is implied by the
/// other two: `q + r + s == 0`.
///
/// Both hex geometries use the same axial coordinates, so a coordinate does not say
/// which way its hexes point. Because every other row or column is staggered, the
/// coordinates of a row shift as you move down the grid. Use
/// `Grid.coordinate(column:row:)` to address hexes by their position in the layout
/// instead.
public struct HexCoordinate: Sendable, Equatable, Hashable {
    public var q: Int
    public var r: Int

    @inlinable
    public init(_ q: Int, _ r: Int) {
        self.q = q
        self.r = r
    }
}

extension HexCoordinate: CustomStringConvertible {
    public var description: String {
        "(\(q), \(r))"
    }
}

extension HexCoordinate: Comparable {
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool { (lhs.r, lhs.q) < (rhs.r, rhs.q) }
}

extension HexCoordinate {
    @inlinable
    public static func + (lhs: Self, rhs: Self) -> Self { .init(lhs.q + rhs.q, lhs.r + rhs.r) }

    @inlinable
    public static func - (lhs: Self, rhs: Self) -> Self { .init(lhs.q - rhs.q, lhs.r - rhs.r) }
}

extension HexCoordinate {
    /// The third axis of the hex, implied by `q` and `r`.
    @inlinable
    public var s: Int { -q - r }

    /// Returns the number of steps between this coordinate and the given one.
    @inlinable
    public func distance(to other: Self) -> Int {
        let difference = self - other
        return (abs(difference.q) + abs(difference.r) + abs(difference.s)) / 2
    }
}

extension HexCoordinate: GridCoordinate {
    @inlinable
    public static var origin: Self { .init(0, 0) }

    @inlinable
    public static func componentwiseMin(_ lhs: Self, _ rhs: Self) -> Self {
        .init(Swift.min(lhs.q, rhs.q), Swift.min(lhs.r, rhs.r))
    }

    @inlinable
    public static func componentwiseMax(_ lhs: Self, _ rhs: Self) -> Self {
        .init(Swift.max(lhs.q, rhs.q), Swift.max(lhs.r, rhs.r))
    }

    @inlinable
    public static var rotationCount: Int { 6 }

    @inlinable
    public func rotated() -> Self { .init(-r, q + r) }

    @inlinable
    public func reflected() -> Self { .init(r, q) }
}
