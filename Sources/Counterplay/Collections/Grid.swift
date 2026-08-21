/// A fixed-size grid of cells, stored inline.
///
/// The `Geometry` decides what shape the cells are and how they are laid out.
///
///     var board = Grid<8, 8, SquareGeometry, Piece?>(repeating: nil)
///     var map = Grid<16, 16, PointyHexGeometry, Terrain>(repeating: .grass)
///
/// Instead of naming the geometry directly, you can use the typealiases
/// ``SquareGrid``, ``PointyHexGrid``, ``FlatHexGrid``:
///
///     var board = SquareGrid<8, 8, Piece?>(repeating: nil)
///     var map = PointyHexGrid<16, 16, Terrain>(repeating: .grass)
public struct Grid<let width: Int, let height: Int, Geometry: GridGeometry, Cell> {
    /// The coordinate space this grid's cells are addressed in.
    public typealias Coordinate = Geometry.Coordinate

    /// The directions from one of this grid's cells to an adjacent one.
    public typealias Direction = Geometry.Direction

    @usableFromInline
    internal var storage: [height of [width of Cell]]

    /// Creates a new grid with the given cells.
    @inlinable
    public init(cells: [height of [width of Cell]]) {
        self.storage = cells
    }

    /// Creates a new grid with each cell set to the given value.
    @inlinable
    public init(repeating value: Cell) {
        self.storage = .init(repeating: .init(repeating: value))
    }
}


// MARK: - Typealiases

/// A fixed-size grid of square cells, stored inline.
public typealias SquareGrid<let width: Int, let height: Int, Cell> =
    Grid<width, height, SquareGeometry, Cell>

/// A fixed-size grid of pointy-topped hexagonal cells, stored inline.
///
/// The hexes are laid out in `height` rows of `width` hexes, staggered by row.
public typealias PointyHexGrid<let width: Int, let height: Int, Cell> =
    Grid<width, height, PointyHexGeometry, Cell>

/// A fixed-size grid of flat-topped hexagonal cells, stored inline.
///
/// The hexes are laid out in `height` rows of `width` hexes, staggered by column.
public typealias FlatHexGrid<let width: Int, let height: Int, Cell> =
    Grid<width, height, FlatHexGeometry, Cell>


// MARK: - Conformances

extension Grid: Sendable where Cell: Sendable {}

extension Grid: Equatable where Cell: Equatable {
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        for row in 0..<Self.height {
            for column in 0..<Self.width {
                guard lhs.storage[row][column] == rhs.storage[row][column] else {
                    return false
                }
            }
        }
        return true
    }
}

extension Grid: Hashable where Cell: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        for row in 0..<Self.height {
            for column in 0..<Self.width {
                hasher.combine(storage[row][column])
            }
        }
    }
}

extension Grid: CustomStringConvertible where Cell: CustomStringConvertible {
    public var description: String {
        "["
            + (0..<Self.height).map { row in
                "["
                    + (0..<Self.width).map { column in
                        storage[row][column].description
                    }.joined(separator: ", ") + "]"
            }.joined(separator: ",\n") + "]"
    }
}


// MARK: - Creating grids

extension Grid {
    /// Creates a new grid with the given cells in row-major order.
    @inlinable
    public init(cells: [Cell]) {
        precondition(
            cells.count == Self.width * Self.height,
            "Cell count must equal width * height"
        )
        self.storage = .init(initializingWith: { rows in
            for row in 0..<Self.height {
                rows.append(
                    .init(initializingWith: { cols in
                        for column in 0..<Self.width {
                            cols.append(cells[row * Self.width + column])
                        }
                    }))
            }
        })
    }

    /// Creates a new grid with the given values at the given coordinates, and all
    /// other cells set to `nil`.
    @inlinable
    public init<E>(cells: [Coordinate: E?]) where Cell == Optional<E> {
        self.init(repeating: nil)
        for (coord, element) in cells {
            self[coord] = element
        }
    }
}

extension Grid: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral cells: Cell...) {
        self.init(cells: cells)
    }
}


// MARK: - Bounds and layout

extension Grid {
    @usableFromInline
    internal static func contains(_ coord: Coordinate) -> Bool {
        let column = Geometry.column(of: coord)
        let row = Geometry.row(of: coord)
        return column >= 0 && column < Self.width && row >= 0 && row < Self.height
    }

    /// Returns whether the coordinate is within the grid bounds.
    @inlinable
    public func contains(_ coord: Coordinate) -> Bool {
        Self.contains(coord)
    }

    /// Returns the coordinate of the cell at the given position in the layout.
    ///
    /// For a square grid the column and row are the coordinate's `x` and `y`. For a
    /// hex grid every other row or column is staggered, so the two differ.
    @inlinable
    public func coordinate(column: Int, row: Int) -> Coordinate {
        Geometry.coordinate(column: column, row: row)
    }

    /// Returns the column the given coordinate sits in, counting from the west edge
    /// of the grid.
    @inlinable
    public func column(of coord: Coordinate) -> Int {
        Geometry.column(of: coord)
    }

    /// Returns the row the given coordinate sits in, counting from the north edge of
    /// the grid.
    @inlinable
    public func row(of coord: Coordinate) -> Int {
        Geometry.row(of: coord)
    }

    /// All coordinates in the grid, in row-major order.
    @inlinable
    public var coordinates: some RandomAccessCollection<Coordinate> {
        (0..<(Self.width * Self.height)).lazy.map { i in
            Geometry.coordinate(column: i % Self.width, row: i / Self.width)
        }
    }

    /// The index of every column in the grid, from west to east.
    @inlinable
    public var columnIndices: Range<Int> {
        0..<Self.width
    }

    /// The index of every row in the grid, from north to south.
    @inlinable
    public var rowIndices: Range<Int> {
        0..<Self.height
    }

    /// The width of the grid, in columns.
    @inlinable
    public var width: Int {
        Self.width
    }

    /// The height of the grid, in rows.
    @inlinable
    public var height: Int {
        Self.height
    }
}


// MARK: - Neighbors

extension Grid {
    /// Returns the coordinate one step in the given direction, or `nil` if it falls
    /// outside the grid.
    @inlinable
    public func neighbor(of coord: Coordinate, _ direction: Direction) -> Coordinate? {
        let neighbor = coord + direction.offset
        return Self.contains(neighbor) ? neighbor : nil
    }

    /// Returns the coordinates of the adjacent cells that are within the grid bounds,
    /// in the order of the given directions.
    ///
    /// Only cells that share an edge are considered by default, which is what
    /// movement and connectivity usually mean. Every hex that touches another shares
    /// an edge with it, so on a hex grid that is all six neighbors; on a square grid
    /// it is the four orthogonal ones. Pass `Direction.allCases` to include a square
    /// grid's diagonals, or any other set of directions for irregular adjacency:
    ///
    ///     board.neighbors(of: .init(3, 3))                          // 4 cells
    ///     board.neighbors(of: .init(3, 3), in: SquareDirection.allCases) // 8 cells
    @inlinable
    public func neighbors(
        of coord: Coordinate,
        in directions: [Direction] = Direction.adjacent
    ) -> some Collection<Coordinate> {
        directions.lazy.map { coord + $0.offset }.filter { Self.contains($0) }
    }
}


// MARK: - Subscripts

extension Grid {
    /// Gets or sets the value of the cell at the given coordinate.
    @inlinable
    public subscript(_ coord: Coordinate) -> Cell {
        _read {
            yield self[column: Geometry.column(of: coord), row: Geometry.row(of: coord)]
        }
        _modify {
            yield &self[column: Geometry.column(of: coord), row: Geometry.row(of: coord)]
        }
    }

    /// Gets or sets the value of the cell at the given position in the layout.
    @inlinable
    public subscript(column column: Int, row row: Int) -> Cell {
        _read {
            precondition(
                column >= 0 && column < Self.width,
                "Column \(column) out of bounds for grid \(Self.width) wide"
            )
            precondition(
                row >= 0 && row < Self.height,
                "Row \(row) out of bounds for grid \(Self.height) high"
            )
            yield storage[row][column]
        }
        _modify {
            precondition(
                column >= 0 && column < Self.width,
                "Column \(column) out of bounds for grid \(Self.width) wide"
            )
            precondition(
                row >= 0 && row < Self.height,
                "Row \(row) out of bounds for grid \(Self.height) high"
            )
            yield &storage[row][column]
        }
    }
}

extension Grid where Geometry == SquareGeometry {
    /// Gets or sets the value of the cell at the given coordinates.
    @inlinable
    public subscript(x x: Int, y y: Int) -> Cell {
        _read {
            yield self[column: x, row: y]
        }
        _modify {
            yield &self[column: x, row: y]
        }
    }
}

extension Grid where Geometry: HexGeometry {
    /// Gets or sets the value of the cell at the given axial coordinates.
    @inlinable
    public subscript(q q: Int, r r: Int) -> Cell {
        _read {
            yield self[HexCoordinate(q, r)]
        }
        _modify {
            yield &self[HexCoordinate(q, r)]
        }
    }
}
