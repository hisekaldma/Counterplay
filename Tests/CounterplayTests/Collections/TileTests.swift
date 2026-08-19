import Testing
import Counterplay

@Suite("Tile")
struct TileTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize tile with cells")
        func initWithCells() {
            let tile: Polyomino<4, Int> = .init([
                (.init(0, 0), 1),
                (.init(1, 0), 2),
            ])
            #expect(tile.size == 2)
            #expect(tile[0].cell == 1)
            #expect(tile[1].cell == 2)
        }

        @Test("Initialize tile with coordinates")
        func initWithCoordinates() {
            let tile: Polyomino<4, Empty> = .init([
                SquareCoordinate(0, 0),
                SquareCoordinate(1, 0),
            ])
            #expect(tile.size == 2)
            #expect(Array(tile.coordinates) == [.init(0, 0), .init(1, 0)])
        }

        @Test("Initialize tile with array literal")
        func initWithArrayLiteral() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.size == 3)
        }

        @Test("Initialize tile with dictionary literal")
        func initWithDictionaryLiteral() {
            let tile: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            #expect(tile.size == 2)
        }

        @Test("A tile must have at least one cell")
        func rejectEmptyTile() async {
            await #expect(processExitsWith: .failure) {
                let coordinates: [SquareCoordinate] = []
                _ = Polyomino<4, Empty>(coordinates)
            }
        }

        @Test("A tile cannot have more cells than its maximum size")
        func rejectOversizedTile() async {
            await #expect(processExitsWith: .failure) {
                _ = Polyomino<2, Empty>([
                    SquareCoordinate(0, 0),
                    SquareCoordinate(1, 0),
                    SquareCoordinate(2, 0),
                ])
            }
        }

        @Test("A tile cannot have two cells at the same coordinate")
        func rejectRepeatedCoordinate() async {
            await #expect(processExitsWith: .failure) {
                _ = Polyomino<4, Empty>([
                    SquareCoordinate(0, 0),
                    SquareCoordinate(1, 0),
                    SquareCoordinate(0, 0),
                ])
            }
        }
    }

    @Suite("Order")
    struct Order {

        @Test("A tile keeps the order its cells were given")
        func initPreservesOrder() {
            let tile: Polyomino<4, Int> = [.init(2, 2): 30, .init(0, 0): 10, .init(1, 1): 20]
            #expect(tile.map(\.cell) == [30, 10, 20])
            #expect(Array(tile.coordinates) == [.init(2, 2), .init(0, 0), .init(1, 1)])
        }

        @Test("Tiles differing only in cell order are not equal")
        func orderIsPartOfTheValue() {
            let a: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let b: Polyomino<4, Int> = [.init(1, 0): 2, .init(0, 0): 1]
            #expect(a != b)
            #expect(a.canonicalized() == b.canonicalized())
        }

        @Test("Canonicalizing puts cells in ascending coordinate order")
        func canonicalizeSorts() {
            var tile: Polyomino<4, Int> = [.init(2, 2): 30, .init(0, 0): 10, .init(1, 1): 20]
            tile.canonicalize()
            #expect(tile.map(\.cell) == [10, 20, 30])
            #expect(Array(tile.coordinates) == [.init(0, 0), .init(1, 1), .init(2, 2)])
        }

        @Test("Cells travel with their coordinates when sorted")
        func cellsFollowCoordinates() {
            let tile: Polyomino<4, String> = [
                .init(1, 0): "b",
                .init(0, 0): "a",
                .init(0, 1): "c",
            ]
            for (coordinate, cell) in tile.canonicalized() {
                #expect(tile[tile.index(ofCoordinate: coordinate)!].cell == cell)
            }
        }
    }

    @Suite("Order stability")
    struct OrderStability {

        @Test("Rotation does not change the order of cells")
        func rotationPreservesOrder() {
            let tile: Polyomino<4, String> = [
                .init(0, 0): "a",
                .init(1, 0): "b",
                .init(0, 1): "c",
            ]
            let rotated = tile.rotated()
            #expect(rotated.map(\.cell) == ["a", "b", "c"])
            #expect(Array(rotated.coordinates) == [.init(0, 0), .init(0, 1), .init(-1, 0)])
        }

        @Test("Reflection does not change the order of cells")
        func reflectionPreservesOrder() {
            let tile: Polyomino<4, String> = [
                .init(0, 0): "a",
                .init(1, 0): "b",
                .init(0, 1): "c",
            ]
            #expect(tile.reflected().map(\.cell) == ["a", "b", "c"])
        }

        @Test("Translation does not change the order of cells")
        func translationPreservesOrder() {
            let tile: Polyomino<4, String> = [
                .init(6, 5): "a",
                .init(5, 5): "b",
                .init(5, 6): "c",
            ]
            #expect(tile.normalized().map(\.cell) == ["a", "b", "c"])
            #expect(Array(tile.normalized().coordinates) == [
                .init(1, 0), .init(0, 0), .init(0, 1),
            ])
        }

        @Test("A cell can be paired with its image under a rotation")
        func cellsPairWithTheirImages() {
            let tile: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2, .init(0, 1): 3]
            for (before, after) in zip(tile, tile.rotated()) {
                #expect(before.cell == after.cell)
                #expect(after.coordinate == before.coordinate.rotated())
            }
        }
    }

    @Suite("Transformations")
    struct Transformations {

        @Test("Translate by an offset")
        func translate() {
            var tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0)]
            tile.translate(by: .init(3, 2))
            #expect(Array(tile.coordinates) == [.init(3, 2), .init(4, 2)])
        }

        @Test("Translating by the origin changes nothing")
        func translateByOrigin() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.translated(by: .origin) == tile)
        }

        @Test("Normalizing moves the shape against both axes")
        func normalizeTouchesBothAxes() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let moved = tile.translated(by: .init(7, -3)).normalized()
            #expect(moved.corner == .origin)
            #expect(moved.normalized() == moved)
        }

        @Test("Four quarter turns return a square tile to where it started")
        func squareFullTurn() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.rotated(0) == tile)
            #expect(tile.rotated(4) == tile)
            #expect(tile.rotated(2).rotated(2) == tile)
        }

        @Test("Six steps return a hex tile to where it started")
        func hexFullTurn() {
            let tile: Polyhex<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.rotated(6) == tile)
            #expect(tile.rotated(3).rotated(3) == tile)
        }

        @Test("A negative rotation counts the other way")
        func negativeRotation() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.rotated(-1) == tile.rotated(3))
            #expect(tile.rotated(-5) == tile.rotated(3))
        }

        @Test("Reflecting twice returns the tile to where it started")
        func doubleReflection() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(tile.reflected().reflected() == tile)
        }

        @Test("The pivot stays where it is")
        func pivotStaysFixed() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let pivot = SquareCoordinate(1, 0)
            #expect(tile.rotated(about: pivot).coordinates.contains(pivot))
            #expect(tile.reflected(about: pivot).coordinates.contains(pivot))
        }

        @Test("Rotating then reflecting maps each coordinate once")
        func transformsCompose() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            for (before, after) in zip(tile, tile.rotated().reflected()) {
                #expect(after.coordinate == before.coordinate.rotated().reflected())
            }
        }

        @Test("Mutating and non-mutating forms agree")
        func mutatingFormsAgree() {
            let tile: Polyomino<4, Int> = [.init(2, 2): 30, .init(0, 0): 10]

            var rotated = tile
            rotated.rotate(2, about: .init(1, 1))
            #expect(rotated == tile.rotated(2, about: .init(1, 1)))

            var canonical = tile
            canonical.canonicalize()
            #expect(canonical == tile.canonicalized())
        }
    }

    @Suite("Canonical form")
    struct CanonicalForm {

        @Test("A shape and its rotation share a canonical form up to symmetry")
        func rotationsShareCanonicalForm() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let rotated: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(1, 1)]
            #expect(tile.canonicalizedUpToSymmetry() == rotated.canonicalizedUpToSymmetry())
            #expect(tile.canonicalizedUpToSymmetry() == tile)
        }

        @Test("Every rotation and reflection shares one canonical form")
        func allVariantsAgree() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let forms = Set(tile.rotationsAndReflections.map { $0.canonicalizedUpToSymmetry() })
            #expect(forms.count == 1)
        }

        @Test("Position and cell order do not affect the canonical form")
        func canonicalFormIgnoresPositionAndOrder() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let scattered: Polyomino<4, Empty> = [.init(9, 9), .init(8, 9), .init(8, 8)]
            #expect(scattered.canonicalizedUpToSymmetry() == tile.canonicalizedUpToSymmetry())
        }

        @Test("Canonicalizing is idempotent")
        func canonicalFormIsIdempotent() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let once = tile.canonicalizedUpToSymmetry()
            #expect(once.canonicalizedUpToSymmetry() == once)
            #expect(tile.canonicalized().canonicalized() == tile.canonicalized())
        }

        @Test("Mirror images differ under rotation but agree under reflection")
        func chiralShapes() {
            let s: Polyomino<4, Empty> = [.init(1, 0), .init(2, 0), .init(0, 1), .init(1, 1)]
            let z: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(1, 1), .init(2, 1)]
            let sRotations = Set(s.rotations.map { $0.canonicalized() })
            let zRotations = Set(z.rotations.map { $0.canonicalized() })
            #expect(sRotations.isDisjoint(with: zRotations))
            #expect(s.canonicalizedUpToSymmetry() == z.canonicalizedUpToSymmetry())
        }

        @Test("A symmetric tile repeats one shape across its rotations")
        func symmetryCollapsesRotations() {
            let square: Polyomino<4, Empty> = [
                .init(0, 0), .init(1, 0), .init(0, 1), .init(1, 1),
            ]
            let s: Polyomino<4, Empty> = [.init(1, 0), .init(2, 0), .init(0, 1), .init(1, 1)]
            let l: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(Set(square.rotations.map { $0.canonicalized() }).count == 1)
            #expect(Set(s.rotations.map { $0.canonicalized() }).count == 2)
            #expect(Set(l.rotations.map { $0.canonicalized() }).count == 4)
        }

        @Test("The symmetry group is four turns on a square grid and six on a hex grid")
        func variantCounts() {
            let square: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let hex: Polyhex<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(Array(square.rotations).count == 4)
            #expect(Array(square.reflections).count == 2)
            #expect(Array(square.rotationsAndReflections).count == 8)
            #expect(Array(hex.rotations).count == 6)
            #expect(Array(hex.rotationsAndReflections).count == 12)
        }
    }

    @Suite("Collection")
    struct CollectionAccess {

        @Test("Start and end index")
        func indices() {
            let tile: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2, .init(0, 1): 3]
            #expect(tile.startIndex == 0)
            #expect(tile.endIndex == 3)
            #expect(tile.count == 3)
            #expect(tile.size == 3)
        }

        @Test("Subscript by position")
        func subscriptByPosition() {
            let tile: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            #expect(tile[0].coordinate == .init(0, 0))
            #expect(tile[0].cell == 1)
            #expect(tile[1].coordinate == .init(1, 0))
            #expect(tile[1].cell == 2)
        }

        @Test("Index of a coordinate")
        func indexOfCoordinate() {
            let tile: Polyomino<4, Int> = [.init(2, 2): 30, .init(0, 0): 10]
            #expect(tile.index(ofCoordinate: .init(2, 2)) == 0)
            #expect(tile.index(ofCoordinate: .init(0, 0)) == 1)
            #expect(tile.index(ofCoordinate: .init(5, 5)) == nil)
        }

        @Test("The corner is the componentwise minimum, not necessarily a cell")
        func corner() {
            let tile: Polyomino<4, Empty> = [.init(1, 0), .init(0, 1)]
            #expect(tile.corner == .init(0, 0))
            #expect(tile.coordinates.contains(.init(0, 0)) == false)
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable")
        func equatable() {
            let tile1: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let tile2: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let tile3: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 9]
            #expect(tile1 == tile2)
            #expect(tile1 != tile3)
        }

        @Test("Hashable")
        func hashable() {
            let tile1: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let tile2: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let tile3: Polyomino<4, Int> = [.init(1, 0): 2, .init(0, 0): 1]
            #expect(Set([tile1, tile2]).count == 1)
            #expect(Set([tile1, tile3]).count == 2)
        }

        @Test("Comparable")
        func comparable() {
            let tile1: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            let tile2: Polyomino<4, Int> = [.init(0, 1): 1, .init(1, 1): 2]
            #expect(tile1 < tile2)
            #expect(tile2 > tile1)
        }
    }

    @Suite("Placement")
    struct Placement {

        @Test("A tile fits only where every cell lands on an empty square")
        func fitsChecksBoundsAndContents() {
            var grid: SquareGrid<4, 4, Int?> = .init(repeating: nil)
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            #expect(grid.fits(tile, at: .init(0, 0)) == true)
            #expect(grid.fits(tile, at: .init(3, 3)) == false)
            grid[.init(1, 0)] = 1
            #expect(grid.fits(tile, at: .init(0, 0)) == false)
        }

        @Test("Placing writes every cell the tile covers")
        func placeWritesEveryCell() {
            var grid: SquareGrid<4, 4, Int?> = .init(repeating: nil)
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            grid.place(tile, at: .init(1, 1), with: 7)
            #expect(grid == .init(cells: [
                [nil, nil, nil, nil],
                [nil, 7, 7, nil],
                [nil, 7, nil, nil],
                [nil, nil, nil, nil],
            ]))
        }

        @Test("Placing carries the tile's own cells")
        func placeCarriesCells() {
            var grid: SquareGrid<3, 3, Int> = .init(repeating: 0)
            let tile: Polyomino<4, Int> = [.init(0, 0): 1, .init(1, 0): 2]
            grid.place(tile, at: .init(1, 1))
            #expect(grid == .init(cells: [
                [0, 0, 0],
                [0, 1, 2],
                [0, 0, 0],
            ]))
        }

        @Test("Placement does not depend on the tile's cell order")
        func placementIgnoresOrder() {
            let tile: Polyomino<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let shuffled: Polyomino<4, Empty> = [.init(0, 1), .init(0, 0), .init(1, 0)]
            var grid1: SquareGrid<4, 4, Int?> = .init(repeating: nil)
            var grid2: SquareGrid<4, 4, Int?> = .init(repeating: nil)
            grid1.place(tile, at: .init(0, 0), with: 1)
            grid2.place(shuffled, at: .init(0, 0), with: 1)
            #expect(grid1 == grid2)
        }

        @Test("A polyhex fits on a hex grid")
        func placeOnHexGrid() {
            var grid: PointyHexGrid<4, 4, Int?> = .init(repeating: nil)
            let tile: Polyhex<4, Empty> = [.init(0, 0), .init(1, 0), .init(0, 1)]
            let origin = grid.coordinate(column: 1, row: 1)
            #expect(grid.fits(tile, at: origin) == true)
            grid.place(tile, at: origin, with: 5)
            #expect(grid[origin] == 5)
            #expect(grid[origin + .init(1, 0)] == 5)
            #expect(grid[origin + .init(0, 1)] == 5)
        }
    }
}
