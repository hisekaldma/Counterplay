/// The shape and layout of the cells in a grid.
///
/// A geometry decides what shape the cells are, how they are stored in rows and columns,
/// and what the directions out of a cell are called. It is a phantom type:
/// nothing is ever instantiated, and every requirement is static.
///
/// Instead of naming a geometry directly, you can use the `Grid` type aliases:
/// `SquareGrid`, `PointyHexGrid`, `FlatHexGrid`.
public protocol GridGeometry: Sendable {
    /// The coordinate space the grid's cells are addressed in.
    associatedtype Coordinate: GridCoordinate

    /// The directions from one cell to an adjacent one in this geometry.
    associatedtype Direction: GridDirection where Direction.Coordinate == Coordinate

    /// Returns the coordinate of the cell at the given position in the layout.
    static func coordinate(column: Int, row: Int) -> Coordinate

    /// Returns the column the given coordinate sits in.
    static func column(of coord: Coordinate) -> Int

    /// Returns the row the given coordinate sits in.
    static func row(of coord: Coordinate) -> Int
}

/// A geometry whose cells are hexagons.
///
/// The two hex geometries share their coordinate space and differ only in which way
/// their hexes point and, in consequence, whether rows or columns are staggered.
public protocol HexGeometry: GridGeometry where Coordinate == HexCoordinate {}


// MARK: - Square geometry

/// Square cells in rows and columns.
///
/// A coordinate's `x` and `y` are its column and row, so the layout and the
/// coordinate space are the same thing.
public enum SquareGeometry: GridGeometry {
    public typealias Coordinate = SquareCoordinate
    public typealias Direction = SquareDirection

    @inlinable
    public static func coordinate(column: Int, row: Int) -> SquareCoordinate {
        .init(column, row)
    }

    @inlinable
    public static func column(of coord: SquareCoordinate) -> Int {
        coord.x
    }

    @inlinable
    public static func row(of coord: SquareCoordinate) -> Int {
        coord.y
    }
}


// MARK: - Hexagonal geometry

/// Hexagons with a vertex at the top and bottom, in rows staggered half a hex to the east.
public enum PointyHexGeometry: HexGeometry {
    public typealias Coordinate = HexCoordinate
    public typealias Direction = PointyHexDirection

    @inlinable
    public static func coordinate(column: Int, row: Int) -> HexCoordinate {
        .init(column - (row >> 1), row)
    }

    @inlinable
    public static func column(of coord: HexCoordinate) -> Int {
        coord.q + (coord.r >> 1)
    }

    @inlinable
    public static func row(of coord: HexCoordinate) -> Int {
        coord.r
    }
}

/// Hexagons with a flat edge at the top and bottom, in columns staggered half a hex to the south.
public enum FlatHexGeometry: HexGeometry {
    public typealias Coordinate = HexCoordinate
    public typealias Direction = FlatHexDirection

    @inlinable
    public static func coordinate(column: Int, row: Int) -> HexCoordinate {
        .init(column, row - (column >> 1))
    }

    @inlinable
    public static func column(of coord: HexCoordinate) -> Int {
        coord.q
    }

    @inlinable
    public static func row(of coord: HexCoordinate) -> Int {
        coord.r + (coord.q >> 1)
    }
}
