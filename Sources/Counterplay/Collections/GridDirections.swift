/// A direction from one cell to an adjacent one.
///
/// Each grid geometry has a corresponding direction type. See ``SquareDirection``,
/// ``PointyHexDirection``, and ``FlatHexDirection``.
public protocol GridDirection<Coordinate>: Sendable, Hashable, CaseIterable {
    /// The coordinate space the direction steps through.
    associatedtype Coordinate: GridCoordinate

    /// The change in coordinate from taking one step in this direction.
    var offset: Coordinate { get }

    /// The direction pointing the opposite way.
    var opposite: Self { get }

    /// The directions towards the cells that count as adjacent.
    ///
    /// Cells that share an edge are adjacent; cells that meet only at a point are not.
    static var adjacent: [Self] { get }
}


// MARK: - Square

/// A direction from one square cell to an adjacent one, clockwise from north.
///
/// The y axis increases towards the south, so `north` is `(0, -1)`.
///
/// Square cells have two useful notions of adjacency: the four cells that share
/// an edge, and the eight that share an edge or a corner. Use ``orthogonal``,
/// ``diagonal``, or `allCases` to choose between them.
public enum SquareDirection: GridDirection {
    public typealias Coordinate = SquareCoordinate

    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest

    /// The four directions towards cells that share an edge, clockwise from north.
    public static let orthogonal: [Self] = [.north, .east, .south, .west]

    /// The four directions towards cells that share only a corner, clockwise from north east.
    public static let diagonal: [Self] = [.northEast, .southEast, .southWest, .northWest]

    /// The four directions towards cells that share an edge, clockwise from north.
    ///
    /// This is the same as ``orthogonal``. Pass `allCases` to include the diagonals.
    @inlinable
    public static var adjacent: [Self] { orthogonal }

    /// The change in coordinate from taking one step in this direction.
    @inlinable
    public var offset: SquareCoordinate {
        switch self {
        case .north: .init(0, -1)
        case .northEast: .init(1, -1)
        case .east: .init(1, 0)
        case .southEast: .init(1, 1)
        case .south: .init(0, 1)
        case .southWest: .init(-1, 1)
        case .west: .init(-1, 0)
        case .northWest: .init(-1, -1)
        }
    }

    /// The direction pointing the opposite way.
    @inlinable
    public var opposite: Self {
        switch self {
        case .north: .south
        case .northEast: .southWest
        case .east: .west
        case .southEast: .northWest
        case .south: .north
        case .southWest: .northEast
        case .west: .east
        case .northWest: .southEast
        }
    }
}


// MARK: - Pointy-topped hexes

/// A direction from one pointy-topped hex to an adjacent one, clockwise from east.
public enum PointyHexDirection: GridDirection {
    public typealias Coordinate = HexCoordinate

    case east
    case southEast
    case southWest
    case west
    case northWest
    case northEast

    /// Every direction, clockwise from east.
    ///
    /// Every hex that touches another shares an edge with it, so all six count.
    @inlinable
    public static var adjacent: [Self] { allCases }

    /// The change in coordinate from taking one step in this direction.
    @inlinable
    public var offset: HexCoordinate {
        switch self {
        case .east: .init(1, 0)
        case .southEast: .init(0, 1)
        case .southWest: .init(-1, 1)
        case .west: .init(-1, 0)
        case .northWest: .init(0, -1)
        case .northEast: .init(1, -1)
        }
    }

    /// The direction pointing the opposite way.
    @inlinable
    public var opposite: Self {
        switch self {
        case .east: .west
        case .southEast: .northWest
        case .southWest: .northEast
        case .west: .east
        case .northWest: .southEast
        case .northEast: .southWest
        }
    }
}


// MARK: - Flat-topped hexes

/// A direction from one flat-topped hex to an adjacent one, clockwise from north.
public enum FlatHexDirection: GridDirection {
    public typealias Coordinate = HexCoordinate

    case north
    case northEast
    case southEast
    case south
    case southWest
    case northWest

    /// Every direction, clockwise from north.
    @inlinable
    public static var adjacent: [Self] { allCases }

    /// The change in coordinate from taking one step in this direction.
    @inlinable
    public var offset: HexCoordinate {
        switch self {
        case .north: .init(0, -1)
        case .northEast: .init(1, -1)
        case .southEast: .init(1, 0)
        case .south: .init(0, 1)
        case .southWest: .init(-1, 1)
        case .northWest: .init(-1, 0)
        }
    }

    /// The direction pointing the opposite way.
    @inlinable
    public var opposite: Self {
        switch self {
        case .north: .south
        case .northEast: .southWest
        case .southEast: .northWest
        case .south: .north
        case .southWest: .northEast
        case .northWest: .southEast
        }
    }
}
