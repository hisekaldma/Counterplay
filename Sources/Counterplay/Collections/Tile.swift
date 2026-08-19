/// An ordered list of cells in a grid’s coordinate space.
///
/// Use `Tile` to represent the pieces in a tile-laying game:
/// polyominoes on a square grid, or polyhexes on a hex grid.
///
/// A tile keeps its cells in the order they were given. Because the order is part of the value,
/// two tiles are equal when they hold the same cells at the same coordinates *in the same order*.
/// Use ``canonicalized()`` to match tiles by shape and orientation, and
/// ``canonicalizedUpToSymmetry()`` to match them up to rotation and reflection too.
///
///     let a: Polyomino<2, Int> = [.init(0, 0): 1, .init(1, 0): 2]
///     let b: Polyomino<2, Int> = [.init(1, 0): 2, .init(0, 0): 1]
///     let c: Polyomino<2, Int> = [.init(4, 7): 1, .init(5, 7): 2]
///     a == b                                    // false: different order
///     a == c                                    // false: different place
///
///     a.canonicalized() == b.canonicalized()    // true
///     a.canonicalized() == c.canonicalized()    // true
public struct Tile<let maxSize: Int, Coordinate: GridCoordinate, Cell> {
    /// A cell of the tile, paired with the coordinate it sits at.
    public typealias Element = (coordinate: Coordinate, cell: Cell)

    /// The tile's cells in order, followed by `nil` in every slot from `size` to `maxSize`.
    ///
    /// Read through ``element(at:)`` rather than subscripting directly, so that a
    /// slot past the end of the tile traps instead of yielding `nil`.
    @usableFromInline
    internal var storage: InlineArray<maxSize, Element?>

    /// The number of cells in the tile.
    ///
    /// No transformation adds or removes cells, so this never changes once the tile
    /// is created.
    public let size: Int

    @usableFromInline
    internal init(storage: InlineArray<maxSize, Element?>, size: Int) {
        self.storage = storage
        self.size = size
    }

    /// Returns the coordinate and cell at the given position.
    ///
    /// - Precondition: `position` must be in `0..<size`.
    @usableFromInline
    internal func element(at position: Int) -> Element {
        precondition(
            position >= 0 && position < size,
            "Index \(position) out of bounds for tile of size \(size)"
        )
        return storage[position]!
    }

    /// Creates a tile with the given cells at the given coordinates, in the given order.
    ///
    /// - Precondition: `cells` must not be empty, must contain no more than
    ///   `maxSize` cells, and must not repeat a coordinate.
    /// - Complexity: O(*n*²) in the number of cells, to reject repeated coordinates.
    @inlinable
    public init(_ cells: some Sequence<(Coordinate, Cell)>) {
        var storage = InlineArray<maxSize, Element?>(repeating: nil)
        var size = 0

        for (coordinate, cell) in cells {
            precondition(size < maxSize, "Tile has more than \(maxSize) cells")
            for i in 0..<size {
                precondition(
                    storage[i]!.coordinate != coordinate,
                    "Tile has two cells at \(coordinate)"
                )
            }
            storage[size] = (coordinate: coordinate, cell: cell)
            size += 1
        }
        precondition(size > 0, "A tile must have at least one cell")

        self.init(storage: storage, size: size)
    }

    /// Replaces every coordinate with the result of the given transform, leaving each
    /// cell at its own index.
    @usableFromInline
    internal mutating func mapCoordinates(_ transform: (Coordinate) -> Coordinate) {
        for i in 0..<size {
            storage[i]!.coordinate = transform(storage[i]!.coordinate)
        }
    }
}


// MARK: - Typealiases

/// A tile made of square cells, for placing on a `SquareGrid`.
///
/// See ``Tile`` for how a tile's order, shape, and position bear on equality.
public typealias Polyomino<let maxSize: Int, Cell> = Tile<maxSize, SquareCoordinate, Cell>

/// A tile made of hexagonal cells, for placing on a `PointyHexGrid` or `FlatHexGrid`.
///
/// See ``Tile`` for how a tile's order, shape, and position bear on equality.
public typealias Polyhex<let maxSize: Int, Cell> = Tile<maxSize, HexCoordinate, Cell>


// MARK: - Conformances

extension Tile: Sendable where Cell: Sendable {}

extension Tile: Equatable where Cell: Equatable {
    /// Returns whether the two tiles hold the same cells at the same coordinates in
    /// the same order.
    ///
    /// Compare ``canonicalized()`` forms to disregard order and position.
    @inlinable
    public static func == (lhs: Self, rhs: Self) -> Bool {
        guard lhs.size == rhs.size else { return false }
        for i in 0..<lhs.size {
            let (lhsCoordinate, lhsCell) = lhs.element(at: i)
            let (rhsCoordinate, rhsCell) = rhs.element(at: i)
            guard lhsCoordinate == rhsCoordinate, lhsCell == rhsCell else {
                return false
            }
        }
        return true
    }
}

extension Tile: Hashable where Cell: Hashable {
    @inlinable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(size)
        for i in 0..<size {
            let (coordinate, cell) = element(at: i)
            hasher.combine(coordinate)
            hasher.combine(cell)
        }
    }
}

extension Tile: Comparable where Cell: Comparable {
    /// Orders tiles by their cells, in the order each tile holds them.
    ///
    /// This exists so that a set of tiles has a smallest member, which is how
    /// ``canonicalizedUpToSymmetry()`` picks one orientation out of the symmetry
    /// group. It is not a meaningful ranking of two arbitrary tiles.
    @inlinable
    public static func < (lhs: Self, rhs: Self) -> Bool {
        for i in 0..<Swift.min(lhs.size, rhs.size) {
            let (lhsCoordinate, lhsCell) = lhs.element(at: i)
            let (rhsCoordinate, rhsCell) = rhs.element(at: i)
            if lhsCoordinate != rhsCoordinate {
                return lhsCoordinate < rhsCoordinate
            }
            if lhsCell != rhsCell {
                return lhsCell < rhsCell
            }
        }
        return lhs.size < rhs.size
    }
}

extension Tile: CustomStringConvertible {
    public var description: String {
        "[" + map { "\($0.coordinate): \($0.cell)" }.joined(separator: ", ") + "]"
    }
}


// MARK: - Creating tiles

extension Tile where Cell == Empty {
    /// Creates a tile with cells at the given coordinates, in the given order.
    @inlinable
    public init(_ coordinates: some Sequence<Coordinate>) {
        self.init(coordinates.lazy.map { ($0, Empty()) })
    }
}

extension Tile: ExpressibleByArrayLiteral where Cell == Empty {
    /// Creates a tile with cells at the given coordinates, in the given order.
    @inlinable
    public init(arrayLiteral coordinates: Coordinate...) {
        self.init(coordinates)
    }
}

extension Tile: ExpressibleByDictionaryLiteral {
    /// Creates a tile with the given cells, in the given order.
    @inlinable
    public init(dictionaryLiteral cells: (Coordinate, Cell)...) {
        self.init(cells)
    }
}


// MARK: - Collection

extension Tile: RandomAccessCollection {
    public typealias Index = Int

    @inlinable
    public var startIndex: Int { 0 }

    @inlinable
    public var endIndex: Int { size }

    @inlinable
    public func index(after i: Int) -> Int { i + 1 }

    @inlinable
    public func index(before i: Int) -> Int { i - 1 }

    @inlinable
    public subscript(position: Int) -> Element {
        element(at: position)
    }
}


// MARK: - Coordinates

extension Tile {
    /// The coordinates of the tile’s cells, in order.
    @inlinable
    public var coordinates: some RandomAccessCollection<Coordinate> {
        lazy.map(\.coordinate)
    }

    /// The componentwise minimum of the tile’s coordinates.
    ///
    /// This is the corner of the tile’s bounding box nearest the origin. It is not
    /// necessarily one of the tile’s own coordinates.
    @inlinable
    public var corner: Coordinate {
        var corner = element(at: 0).coordinate
        for i in 1..<size {
            corner = Coordinate.componentwiseMin(corner, element(at: i).coordinate)
        }
        return corner
    }

    /// Returns the position of the tile's cell at the given coordinate, or `nil` if the
    /// tile has no cell there.
    ///
    /// - Complexity: O(*n*) in the size of the tile. The cells are not kept in
    ///   coordinate order, so this cannot binary search.
    @inlinable
    public func index(ofCoordinate coordinate: Coordinate) -> Int? {
        for i in 0..<size where element(at: i).coordinate == coordinate {
            return i
        }
        return nil
    }
}


// MARK: - Transformations

extension Tile {
    /// Moves every cell by the given offset.
    ///
    /// Cells keep their order and their own indices.
    @inlinable
    public mutating func translate(by offset: Coordinate) {
        guard offset != Coordinate.origin else { return }
        mapCoordinates { $0 + offset }
    }

    /// Moves the tile so that its shape touches both axes.
    ///
    /// Where the tile ends up depends on its shape but not on where it started, so
    /// tiles that differ only in position normalize to the same place.
    ///
    /// Cells keep their order and their own indices.
    @inlinable
    public mutating func normalize() {
        translate(by: Coordinate.origin - corner)
    }

    /// Rotates the tile the given number of steps clockwise about the given coordinate.
    ///
    /// One step is a quarter turn on a square grid and a sixth of a turn on a hex
    /// grid. Negative counts rotate anticlockwise.
    ///
    /// Every cell turns around `pivot`, which itself stays where it is. Pass one of
    /// the tile’s own coordinates to turn the tile about that cell:
    ///
    ///     let anchor = tile[0].coordinate
    ///     tile.rotate(about: anchor)
    ///
    /// Cells keep their order and their own indices, so a cell can be paired with its
    /// image under the rotation.
    @inlinable
    public mutating func rotate(_ steps: Int = 1, about pivot: Coordinate = .origin) {
        let turns = Coordinate.rotationCount
        var steps = steps % turns
        if steps < 0 { steps += turns }
        guard steps > 0 else { return }

        mapCoordinates { coordinate in
            var rotated = coordinate - pivot
            for _ in 0..<steps {
                rotated = rotated.rotated()
            }
            return rotated + pivot
        }
    }

    /// Reflects the tile about the given coordinate.
    ///
    /// Every cell mirrors across `pivot`, which itself stays where it is. Cells keep
    /// their order and their own indices.
    @inlinable
    public mutating func reflect(about pivot: Coordinate = .origin) {
        mapCoordinates { ($0 - pivot).reflected() + pivot }
    }

    /// Returns the tile translated by the given offset.
    @inlinable
    public func translated(by offset: Coordinate) -> Self {
        guard offset != Coordinate.origin else { return self }
        var tile = self
        tile.translate(by: offset)
        return tile
    }

    /// Returns the tile moved so that its shape touches both axes.
    ///
    /// See ``normalize()``.
    @inlinable
    public func normalized() -> Self {
        translated(by: Coordinate.origin - corner)
    }

    /// Returns the tile rotated the given number of steps clockwise about the given coordinate.
    ///
    /// See ``rotate(_:about:)``.
    @inlinable
    public func rotated(_ steps: Int = 1, about pivot: Coordinate = .origin) -> Self {
        var tile = self
        tile.rotate(steps, about: pivot)
        return tile
    }

    /// Returns the tile reflected about the given coordinate.
    ///
    /// See ``reflect(about:)``.
    @inlinable
    public func reflected(about pivot: Coordinate = .origin) -> Self {
        var tile = self
        tile.reflect(about: pivot)
        return tile
    }
}


// MARK: - Symmetry

extension Tile {
    /// The tile in each of its rotations about the origin, starting from the tile itself.
    @inlinable
    public var rotations: some Collection<Self> {
        (0..<Coordinate.rotationCount).lazy.map { self.rotated($0) }
    }

    /// The tile and its reflection about the origin.
    @inlinable
    public var reflections: some Collection<Self> {
        (0..<2).lazy.map { $0 == 0 ? self : self.reflected() }
    }

    /// The tile in each of its rotations about the origin, then each of those reflected.
    @inlinable
    public var rotationsAndReflections: some Collection<Self> {
        let turns = Coordinate.rotationCount
        return (0..<(2 * turns)).lazy.map { i in
            var tile = self
            tile.rotate(i % turns)
            if i >= turns {
                tile.reflect()
            }
            return tile
        }
    }
}


// MARK: - Canonical form

extension Tile {
    /// Puts the cells in ascending order of coordinate.
    ///
    /// - Complexity: O(*n*²) in the size of the tile.
    @usableFromInline
    internal mutating func sort() {
        // Insertion sort: in place, no allocation, and linear on nearly sorted input,
        // which is what a tile usually is.
        for i in 1..<size {
            let element = storage[i]!
            var j = i - 1
            while j >= 0, storage[j]!.coordinate > element.coordinate {
                storage[j + 1] = storage[j]
                j -= 1
            }
            storage[j + 1] = element
        }
    }

    /// Sorts the tile’s cells and moves the tile so that its shape touches both axes.
    ///
    /// Two tiles have the same canonical form exactly when they hold the same cells in
    /// the same arrangement, whatever order those cells were given in and wherever the
    /// tiles sit. Use ``canonicalizedUpToSymmetry()`` to disregard orientation as well.
    @inlinable
    public mutating func canonicalize() {
        sort()
        normalize()
    }

    /// Returns the tile with its cells sorted and its shape moved to touch both axes.
    ///
    /// See ``canonicalize()``.
    @inlinable
    public func canonicalized() -> Self {
        var tile = self
        tile.canonicalize()
        return tile
    }
}

extension Tile where Cell: Comparable {
    /// Replaces the tile with the smallest of its rotations and reflections,
    /// canonicalized.
    ///
    /// Two tiles share this form exactly when one can be translated, rotated, and
    /// reflected onto the other, whatever order their cells were given in.
    @inlinable
    public mutating func canonicalizeUpToSymmetry() {
        self = canonicalizedUpToSymmetry()
    }

    /// Returns the smallest of the tile’s rotations and reflections, canonicalized.
    ///
    /// Two tiles share this form exactly when one can be translated, rotated, and
    /// reflected onto the other, whatever order their cells were given in.
    @inlinable
    public func canonicalizedUpToSymmetry() -> Self {
        rotationsAndReflections.lazy.map { $0.canonicalized() }.min()!
    }
}


// MARK: - Placing tiles

extension Grid {
    /// Returns whether the tile, placed with its origin at the given coordinate,
    /// lies entirely within the grid on cells that the given predicate accepts.
    ///
    /// The order of the tile's cells does not affect the result.
    @inlinable
    public func fits<let n: Int, Contents>(
        _ tile: Tile<n, Coordinate, Contents>,
        at coord: Coordinate,
        where isEmpty: (Cell) -> Bool
    ) -> Bool {
        for offset in tile.coordinates {
            let target = coord + offset
            guard Self.contains(target), isEmpty(self[target]) else { return false }
        }
        return true
    }

    /// Returns whether the tile, placed with its origin at the given coordinate,
    /// lies entirely within the grid on empty cells.
    @inlinable
    public func fits<let n: Int, Contents, Wrapped>(
        _ tile: Tile<n, Coordinate, Contents>,
        at coord: Coordinate
    ) -> Bool where Cell == Optional<Wrapped> {
        fits(tile, at: coord, where: { $0 == nil })
    }

    /// Writes each of the tile's cells into the grid, with its origin at the given
    /// coordinate.
    ///
    /// A tile has no repeated coordinates, so the order it writes in does not affect
    /// the result.
    ///
    /// - Precondition: every cell of the tile must lie within the grid.
    @inlinable
    public mutating func place<let n: Int>(
        _ tile: Tile<n, Coordinate, Cell>,
        at coord: Coordinate
    ) {
        for (offset, cell) in tile {
            self[coord + offset] = cell
        }
    }

    /// Sets every cell the tile covers to the given value, with its origin at the
    /// given coordinate.
    ///
    /// - Precondition: every cell of the tile must lie within the grid.
    @inlinable
    public mutating func place<let n: Int>(
        _ tile: Tile<n, Coordinate, Empty>,
        at coord: Coordinate,
        with cell: Cell
    ) {
        for offset in tile.coordinates {
            self[coord + offset] = cell
        }
    }
}
