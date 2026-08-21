import Testing
import Counterplay

@Suite("Grid")
struct GridTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize grid repeating")
        func initRepeating() {
            let grid: SquareGrid<4, 3, Int> = .init(repeating: 0)
            #expect(
                grid
                    == .init(cells: [
                        [0, 0, 0, 0],
                        [0, 0, 0, 0],
                        [0, 0, 0, 0],
                    ]))
        }

        @Test("Initialize grid with cells")
        func initWithCells() {
            do {
                let grid: SquareGrid<4, 3, Int> = .init(cells: [
                    [1, 0, 0, 0],
                    [0, 0, 0, 0],
                    [0, 0, 3, 0],
                ])
                #expect(grid[x: 0, y: 0] == 1)
                #expect(grid[x: 2, y: 2] == 3)
            }
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(cells: [
                    [1, 0, 0, 0],
                    [0, 0, 0, 0],
                    [0, 0, 3, 0],
                ])
                #expect(grid[q: 0, r: 0] == 1)
                #expect(grid[q: 1, r: 2] == 3)
            }
        }

        @Test("Initialize grid with array")
        func initWithArray() {
            let grid: SquareGrid<4, 3, Int> = .init(cells: [
                1, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 3, 0,
            ])
            #expect(
                grid
                    == .init(cells: [
                        [1, 0, 0, 0],
                        [0, 0, 0, 0],
                        [0, 0, 3, 0],
                    ]))
        }

        @Test("Initialize grid with array literal")
        func initWithArrayLiteral() {
            let grid: SquareGrid<4, 3, Int> = [
                1, 0, 0, 0,
                0, 0, 0, 0,
                0, 0, 3, 0,
            ]
            #expect(
                grid
                    == .init(cells: [
                        [1, 0, 0, 0],
                        [0, 0, 0, 0],
                        [0, 0, 3, 0],
                    ]))
        }

        @Test("Initialize grid with dictionary")
        func initWithDictionary() {
            let grid: SquareGrid<4, 3, Int?> = .init(cells: [
                .init(0, 0): 1,
                .init(2, 2): 3,
            ])
            #expect(
                grid
                    == .init(cells: [
                        [1, nil, nil, nil],
                        [nil, nil, nil, nil],
                        [nil, nil, 3, nil],
                    ]))
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable")
        func equatable() {
            let grid1: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 6])
            let grid2: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 6])
            let grid3: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 7])
            #expect(grid1 == grid2)
            #expect(grid1 != grid3)
        }

        @Test("Hashable")
        func hashable() {
            let grid1: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 6])
            let grid2: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 6])
            let grid3: SquareGrid<3, 2, Int> = .init(cells: [1, 2, 3, 4, 5, 7])
            #expect(Set([grid1, grid2]).count == 1)
            #expect(Set([grid1, grid3]).count == 2)
        }

        @Test("Description")
        func description() {
            let grid: SquareGrid<2, 2, Int> = .init(cells: [1, 2, 3, 4])
            #expect(grid.description == "[[1, 2],\n[3, 4]]")
        }
    }

    @Suite("Subscript")
    struct SubscriptAccess {

        @Test("Subscript square grid by coordinate")
        func subscriptSquareGridByCoordinate() {
            var grid: SquareGrid<3, 3, Int> = .init(repeating: 0)
            grid[.init(1, 1)] = 42
            #expect(grid[.init(1, 1)] == 42)
        }

        @Test("Subscript square grid by X and Y")
        func subscriptSquareGridByXY() {
            var grid: SquareGrid<3, 3, Int> = .init(repeating: 0)
            grid[x: 1, y: 1] = 42
            #expect(grid[x: 1, y: 1] == 42)

        }

        @Test("Subscript hex grid by coordinate")
        func subscriptHexGridByCoordinate() {
            var grid: PointyHexGrid<3, 3, Int> = .init(repeating: 0)
            grid[.init(0, 2)] = 42
            #expect(grid[.init(0, 2)] == 42)
        }

        @Test("Subscript hex grid by Q and R")
        func subscriptHexGridByQR() {
            var grid: PointyHexGrid<3, 3, Int> = .init(repeating: 0)
            grid[q: 1, r: 1] = 42
            #expect(grid[q: 1, r: 1] == 42)
        }

        @Test("Subscript by column and row")
        func subscriptByColumnRow() {
            do {
                var grid: SquareGrid<3, 3, Int> = .init(repeating: 0)
                grid[column: 0, row: 2] = 42
                #expect(grid[.init(0, 2)] == 42)
            }
            do {
                var grid: PointyHexGrid<3, 3, Int> = .init(repeating: 0)
                grid[column: 0, row: 2] = 42
                #expect(grid[.init(-1, 2)] == 42)
            }
            do {
                var grid: FlatHexGrid<3, 3, Int> = .init(repeating: 0)
                grid[column: 2, row: 0] = 42
                #expect(grid[.init(2, -1)] == 42)
            }
        }
    }

    @Suite("Square coordinates")
    struct SquareCoordinates {

        @Test("Coordinate addition")
        func coordinateAddition() {
            let a = SquareCoordinate(1, 2)
            let b = SquareCoordinate(2, 1)
            let result = a + b
            #expect(result.x == 3)
            #expect(result.y == 3)
        }

        @Test("Coordinate subtraction")
        func coordinateSubtraction() {
            let a = SquareCoordinate(5, 7)
            let b = SquareCoordinate(2, 3)
            let result = a - b
            #expect(result.x == 3)
            #expect(result.y == 4)
        }

        @Test("Coordinate comparison")
        func coordinateComparison() {
            let a = SquareCoordinate(2, 1)
            let b = SquareCoordinate(1, 2)
            let c = SquareCoordinate(2, 1)
            #expect(a < b)
            #expect(a == c)
            #expect(b > a)
        }

        @Test("Contains coordinate")
        func containsCoordinate() {
            let grid: SquareGrid<4, 3, Int> = .init(repeating: 0)
            #expect(grid.contains(.init(0, 0)) == true)
            #expect(grid.contains(.init(3, 2)) == true)
            #expect(grid.contains(.init(2, 1)) == true)
            #expect(grid.contains(.init(-1, 0)) == false)
            #expect(grid.contains(.init(4, 0)) == false)
            #expect(grid.contains(.init(0, 3)) == false)
            #expect(grid.contains(.init(5, 5)) == false)
        }

        @Test("Manhattan distance")
        func manhattanDistance() {
            #expect(SquareCoordinate(0, 0).manhattanDistance(to: .init(0, 0)) == 0)
            #expect(SquareCoordinate(0, 0).manhattanDistance(to: .init(2, 3)) == 5)
            #expect(SquareCoordinate(2, 3).manhattanDistance(to: .init(0, 0)) == 5)
            #expect(SquareCoordinate(-2, -3).manhattanDistance(to: .init(1, 1)) == 7)
        }

        @Test("Chebyshev distance")
        func chebyshevDistance() {
            #expect(SquareCoordinate(0, 0).chebyshevDistance(to: .init(0, 0)) == 0)
            #expect(SquareCoordinate(0, 0).chebyshevDistance(to: .init(2, 3)) == 3)
            #expect(SquareCoordinate(2, 3).chebyshevDistance(to: .init(0, 0)) == 3)
            #expect(SquareCoordinate(-2, -3).chebyshevDistance(to: .init(1, 1)) == 4)
        }

        @Test("Coordinates")
        func coordinates() {
            let grid: SquareGrid<2, 3, Int> = .init(repeating: 0)
            let coords = Array(grid.coordinates)
            #expect(coords.count == 6)
            #expect(coords.contains(.init(0, 0)))
            #expect(coords.contains(.init(1, 0)))
            #expect(coords.contains(.init(0, 1)))
            #expect(coords.contains(.init(1, 1)))
            #expect(coords.contains(.init(0, 2)))
            #expect(coords.contains(.init(1, 2)))
        }
    }

    @Suite("Hex coordinates")
    struct HexCoordinates {

        @Test("Coordinate addition")
        func coordinateAddition() {
            let a = HexCoordinate(1, 2)
            let b = HexCoordinate(2, 1)
            let result = a + b
            #expect(result.q == 3)
            #expect(result.r == 3)
        }

        @Test("Coordinate subtraction")
        func coordinateSubtraction() {
            let a = HexCoordinate(5, 7)
            let b = HexCoordinate(2, 3)
            let result = a - b
            #expect(result.q == 3)
            #expect(result.r == 4)
        }

        @Test("Coordinate comparison")
        func coordinateComparison() {
            let a = HexCoordinate(2, 1)
            let b = HexCoordinate(1, 2)
            let c = HexCoordinate(2, 1)
            #expect(a < b)
            #expect(a == c)
            #expect(b > a)
        }

        @Test("Implied third axis")
        func impliedThirdAxis() {
            let coord = HexCoordinate(2, -3)
            #expect(coord.s == 1)
            #expect(coord.q + coord.r + coord.s == 0)
        }

        @Test("Distance")
        func distance() {
            let origin = HexCoordinate(0, 0)
            #expect(origin.distance(to: .init(0, 0)) == 0)
            #expect(origin.distance(to: .init(2, 0)) == 2)
            #expect(origin.distance(to: .init(0, 2)) == 2)
            #expect(origin.distance(to: .init(-2, 1)) == 2)
            #expect(origin.distance(to: .init(1, 1)) == 2)
        }

        @Test("Convert to and from layout position")
        func layoutPosition() {
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.coordinate(column: 1, row: 0) == .init(1, 0))
                #expect(grid.coordinate(column: 1, row: 2) == .init(0, 2))
                #expect(grid.column(of: .init(1, 0)) == 1)
                #expect(grid.column(of: .init(0, 2)) == 1)
                #expect(grid.row(of: .init(0, 2)) == 2)
            }
            do {
                let grid: FlatHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.coordinate(column: 0, row: 1) == .init(0, 1))
                #expect(grid.coordinate(column: 2, row: 1) == .init(2, 0))
                #expect(grid.column(of: .init(0, 1)) == 0)
                #expect(grid.column(of: .init(2, 0)) == 2)
                #expect(grid.row(of: .init(2, 0)) == 1)
            }
        }

        @Test("Contains coordinate")
        func containsCoordinate() {
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.contains(.init(0, 0)) == true)
                #expect(grid.contains(.init(3, 0)) == true)
                #expect(grid.contains(.init(-1, 2)) == true)
                #expect(grid.contains(.init(2, 2)) == true)
                #expect(grid.contains(.init(-1, 0)) == false)
                #expect(grid.contains(.init(4, 0)) == false)
                #expect(grid.contains(.init(3, 2)) == false)
                #expect(grid.contains(.init(0, 3)) == false)
            }
            do {
                let grid: FlatHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.contains(.init(0, 0)) == true)
                #expect(grid.contains(.init(0, 2)) == true)
                #expect(grid.contains(.init(2, -1)) == true)
                #expect(grid.contains(.init(3, 1)) == true)
                #expect(grid.contains(.init(0, -1)) == false)
                #expect(grid.contains(.init(0, 3)) == false)
                #expect(grid.contains(.init(2, 2)) == false)
                #expect(grid.contains(.init(4, 0)) == false)
            }
        }

        @Test("Coordinates")
        func coordinates() {
            do {
                let grid: PointyHexGrid<2, 3, Int> = .init(repeating: 0)
                #expect(
                    Array(grid.coordinates) == [
                        .init(0, 0), .init(1, 0),
                        .init(0, 1), .init(1, 1),
                        .init(-1, 2), .init(0, 2),
                    ])
            }
            do {
                let grid: FlatHexGrid<3, 2, Int> = .init(repeating: 0)
                #expect(
                    Array(grid.coordinates) == [
                        .init(0, 0), .init(1, 0), .init(2, -1),
                        .init(0, 1), .init(1, 1), .init(2, 0),
                    ])
            }
        }
    }

    @Suite("Properties")
    struct Properties {

        @Test("Width property")
        func widthProperty() {
            let grid: SquareGrid<7, 3, Int> = .init(repeating: 0)
            #expect(grid.width == 7)
        }

        @Test("Height property")
        func heightProperty() {
            let grid: SquareGrid<4, 9, Int> = .init(repeating: 0)
            #expect(grid.height == 9)
        }
    }

    @Suite("Square directions")
    struct SquareDirections {

        @Test("Direction offsets")
        func offsets() {
            #expect(SquareDirection.north.offset == .init(0, -1))
            #expect(SquareDirection.northEast.offset == .init(1, -1))
            #expect(SquareDirection.east.offset == .init(1, 0))
            #expect(SquareDirection.southEast.offset == .init(1, 1))
            #expect(SquareDirection.south.offset == .init(0, 1))
            #expect(SquareDirection.southWest.offset == .init(-1, 1))
            #expect(SquareDirection.west.offset == .init(-1, 0))
            #expect(SquareDirection.northWest.offset == .init(-1, -1))
        }

        @Test("Opposite directions")
        func opposites() {
            for direction in SquareDirection.allCases {
                #expect(direction.opposite.opposite == direction)
                #expect(direction.offset + direction.opposite.offset == .init(0, 0))
            }
        }

        @Test("Each direction is one step away")
        func everyDirectionIsOneStep() {
            let origin = SquareCoordinate(0, 0)
            for direction in SquareDirection.orthogonal {
                #expect(origin.manhattanDistance(to: origin + direction.offset) == 1)
            }
            for direction in SquareDirection.allCases {
                #expect(origin.chebyshevDistance(to: origin + direction.offset) == 1)
            }
        }

        @Test("Orthogonal directions share an edge, diagonal ones only a corner")
        func adjacencyKinds() {
            for direction in SquareDirection.orthogonal {
                let offset = direction.offset
                #expect(abs(offset.x) + abs(offset.y) == 1)
            }
            for direction in SquareDirection.diagonal {
                let offset = direction.offset
                #expect(abs(offset.x) == 1 && abs(offset.y) == 1)
            }
        }
    }

    @Suite("Hex directions")
    struct HexDirections {

        @Test("Direction offsets")
        func directionOffsets() {
            #expect(PointyHexDirection.east.offset == .init(1, 0))
            #expect(PointyHexDirection.southEast.offset == .init(0, 1))
            #expect(PointyHexDirection.southWest.offset == .init(-1, 1))
            #expect(PointyHexDirection.west.offset == .init(-1, 0))
            #expect(PointyHexDirection.northWest.offset == .init(0, -1))
            #expect(PointyHexDirection.northEast.offset == .init(1, -1))

            #expect(FlatHexDirection.north.offset == .init(0, -1))
            #expect(FlatHexDirection.northEast.offset == .init(1, -1))
            #expect(FlatHexDirection.southEast.offset == .init(1, 0))
            #expect(FlatHexDirection.south.offset == .init(0, 1))
            #expect(FlatHexDirection.southWest.offset == .init(-1, 1))
            #expect(FlatHexDirection.northWest.offset == .init(-1, 0))
        }

        @Test("Opposite directions")
        func oppositeDirections() {
            for direction in PointyHexDirection.allCases {
                #expect(direction.opposite.opposite == direction)
                #expect(direction.offset + direction.opposite.offset == .init(0, 0))
            }
            for direction in FlatHexDirection.allCases {
                #expect(direction.opposite.opposite == direction)
                #expect(direction.offset + direction.opposite.offset == .init(0, 0))
            }
        }

        @Test("Every direction is one step away")
        func everyDirectionIsOneStep() {
            let origin = HexCoordinate(0, 0)
            for direction in PointyHexDirection.allCases {
                #expect(origin.distance(to: origin + direction.offset) == 1)
            }
            for direction in FlatHexDirection.allCases {
                #expect(origin.distance(to: origin + direction.offset) == 1)
            }
        }

        @Test("Stepping along the unstaggered axis stays in the same row or column")
        func steppingAlongUnstaggeredAxis() {
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(repeating: 0)
                let start = grid.coordinate(column: 0, row: 2)
                let next = start + PointyHexDirection.east.offset
                #expect(grid.row(of: next) == 2)
                #expect(grid.column(of: next) == 1)
            }
            do {
                let grid: FlatHexGrid<4, 3, Int> = .init(repeating: 0)
                let start = grid.coordinate(column: 2, row: 0)
                let next = start + FlatHexDirection.south.offset
                #expect(grid.column(of: next) == 2)
                #expect(grid.row(of: next) == 1)
            }
        }
    }

    @Suite("Neighbors")
    struct Neighbors {
        @Test("Neighbor in direction")
        func neighborInDirection() {
            do {
                let grid: SquareGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.neighbor(of: .init(1, 1), .south) == .init(1, 2))
                #expect(grid.neighbor(of: .init(0, 0), .west) == nil)
                #expect(grid.neighbor(of: .init(0, 0), .northWest) == nil)
            }
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.neighbor(of: .init(1, 1), .east) == .init(2, 1))
                #expect(grid.neighbor(of: .init(0, 0), .west) == nil)
                #expect(grid.neighbor(of: .init(0, 0), .northWest) == nil)
            }
            do {
                let grid: FlatHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(grid.neighbor(of: .init(1, 1), .south) == .init(1, 2))
                #expect(grid.neighbor(of: .init(0, 0), .north) == nil)
                #expect(grid.neighbor(of: .init(0, 0), .northWest) == nil)
            }
        }

        @Test("Neighbors can include diagonals")
        func neighborsWithDiagonals() {
            let grid: SquareGrid<4, 4, Int> = .init(repeating: 0)
            #expect(
                Array(grid.neighbors(of: .init(1, 1), in: SquareDirection.allCases)) == [
                    .init(1, 0), .init(2, 0), .init(2, 1), .init(2, 2),
                    .init(1, 2), .init(0, 2), .init(0, 1), .init(0, 0),
                ])
            #expect(
                Array(grid.neighbors(of: .init(1, 1), in: SquareDirection.diagonal)) == [
                    .init(2, 0), .init(2, 2), .init(0, 2), .init(0, 0),
                ])
        }

        @Test("Neighbors outside the grid are left out")
        func neighborsWithinBounds() {
            do {
                let grid: SquareGrid<4, 4, Int> = .init(repeating: 0)
                #expect(Array(grid.neighbors(of: .init(0, 0))) == [.init(1, 0), .init(0, 1)])
                #expect(Array(grid.neighbors(of: .init(3, 3))) == [.init(3, 2), .init(2, 3)])
                #expect(
                    Array(grid.neighbors(of: .init(0, 0), in: SquareDirection.allCases)) == [
                        .init(1, 0), .init(1, 1), .init(0, 1),
                    ])
            }
            do {
                let grid: PointyHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(
                    grid.neighbors(of: .init(0, 0)).map { $0 } == [
                        .init(1, 0),
                        .init(0, 1),
                    ])
                #expect(
                    grid.neighbors(of: .init(1, 1)).map { $0 } == [
                        .init(2, 1),
                        .init(1, 2),
                        .init(0, 2),
                        .init(0, 1),
                        .init(1, 0),
                        .init(2, 0),
                    ])
            }
            do {
                let grid: FlatHexGrid<4, 3, Int> = .init(repeating: 0)
                #expect(
                    grid.neighbors(of: .init(0, 0)).map { $0 } == [
                        .init(1, 0),
                        .init(0, 1),
                    ])
                #expect(
                    grid.neighbors(of: .init(1, 1)).map { $0 } == [
                        .init(1, 0),
                        .init(2, 0),
                        .init(2, 1),
                        .init(1, 2),
                        .init(0, 2),
                        .init(0, 1),
                    ])
            }
        }
    }
}
