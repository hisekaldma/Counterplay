import Testing
import Counterplay

@Suite("Graph")
struct GraphTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize empty")
        func initEmpty() {
            let graph: Graph<Int, (), ()> = .init()
            #expect(graph.isEmpty == true)
        }

        @Test("Initialize with sequence")
        func initWithSequence() {
            let graph: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            #expect(graph.isEmpty == false)
            #expect(graph.nodes == [1, 2, 3, 4])
            #expect(graph.edges == [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"])
            #expect(graph.faces == [[1, 2, 3]: "L", [2, 4, 3]: "R"])
        }

        @Test("Nodes cannot have duplicates")
        func rejectDuplicateNodes() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 2],
                    edges: [:],
                    faces: [:]
                )
            }
        }

        @Test("Edges cannot have duplicates")
        func rejectDuplicateEdges() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2],
                    edges: [(1, 2): "A", (2, 1): "B"],
                    faces: [:]
                )
            }
        }

        @Test("Edges cannot loop back")
        func rejectLoops() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2],
                    edges: [(1, 2): "A", (2, 2): "B"],
                    faces: [:]
                )
            }
        }

        @Test("Edges cannot refer to nodes not in the graph")
        func rejectEdgesToUnknownNodes() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2],
                    edges: [(2, 3): "A"],
                    faces: [:]
                )
            }
        }

        @Test("Faces cannot have duplicates")
        func rejectDuplicateFaces() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[1, 2, 3]: "L", [3, 2, 1]: "R"]
                )
            }
        }

        @Test("Faces cannot have fewer than three nodes")
        func rejectSmallFaces() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[1, 2]: "L"]
                )
            }
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[1]: "L"]
                )
            }
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[]: "L"]
                )
            }
        }

        @Test("Faces cannot visit the same node twice")
        func rejectFacesWithRepeatedNodes() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[1, 2, 1, 3]: "L"]
                )
            }
        }

        @Test("Faces cannot refer to nodes not in the graph")
        func rejectFacesWithUnknownNodes() async {
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                    faces: [[1, 2, 4]: "L"]
                )
            }
        }

        @Test("Faces cannot have bounding edges not in the graph")
        func rejectUnclosedFaces() async {
            // 3-1 is missing, so [1, 2, 3] doesn't enclose a face.
            await #expect(processExitsWith: .failure) {
                _ = Graph<Int, String, String>(
                    nodes: [1, 2, 3],
                    edges: [(1, 2): "A", (2, 3): "B"],
                    faces: [[1, 2, 3]: "L"]
                )
            }
        }
    }

    @Suite("Canonicalization")
    struct Canonicalization {

        @Test(
            "Faces are the same face under rotation and reflection",
            arguments: [[1, 2, 3], [2, 3, 1], [3, 1, 2], [3, 2, 1], [2, 1, 3], [1, 3, 2]]
        )
        func faceWinding(face: [Int]) {
            let graph: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C"],
                faces: [face: "L"]
            )
            #expect(graph.faces == [[1, 2, 3]: "L"])
        }

        @Test(
            "Edges are undirected",
            arguments: [(1, 2), (2, 1)]
        )
        func edgeDirection(edge: (Int, Int)) {
            let graph: Graph<Int, String, String> = .init(
                nodes: [1, 2],
                edges: [edge: "A"],
                faces: [:]
            )
            #expect(graph.edges[between: 1, and: 2] == "A")
            #expect(graph.edges[between: 2, and: 1] == "A")
            #expect(graph.edges == [(1, 2): "A"])
        }
    }

    @Suite("Conformances")
    struct Conformances {

        @Test("Equatable ignores declaration order")
        func equatable() {
            let graph1: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            let graph2: Graph<Int, String, String> = .init(
                nodes: [4, 3, 2, 1],
                edges: [(4, 3): "E", (2, 4): "D", (3, 1): "C", (2, 3): "B", (1, 2): "A"],
                faces: [[2, 4, 3]: "R", [1, 2, 3]: "L"]
            )
            let graph3: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "Z"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )

            #expect(graph1 == graph2)
            #expect(graph1 != graph3)
        }

        @Test("Hashable ignores declaration order")
        func hashable() {
            let graph1: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            let graph2: Graph<Int, String, String> = .init(
                nodes: [4, 3, 2, 1],
                edges: [(4, 3): "E", (2, 4): "D", (3, 1): "C", (2, 3): "B", (1, 2): "A"],
                faces: [[2, 4, 3]: "R", [1, 2, 3]: "L"]
            )

            #expect(Set([graph1, graph2]).count == 1)
        }
    }

    @Suite("Adjacency")
    struct Adjacency {

        @Test("Edges from a node, ordered by node")
        func edgesFromNode() {
            let graph: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            let edges = graph.edges(from: 2)

            #expect(edges.map(\.node) == [1, 3, 4])
            #expect(edges.map(\.edge) == ["A", "B", "D"])
            #expect(graph.edges(from: 99).isEmpty == true)
        }

        @Test("Faces adjacent to a node, ordered by nodes")
        func facesAdjacentToNode() {
            let graph: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            let faces = graph.faces(adjacentTo: 2)

            #expect(faces.map(\.nodes) == [[1, 2, 3], [2, 3, 4]])
            #expect(faces.map(\.face) == ["L", "R"])
            #expect(graph.faces(adjacentTo: 99).isEmpty == true)
        }

        @Test("Adjacency order ignores declaration order")
        func adjacencyOrder() {
            let graph1: Graph<Int, String, String> = .init(
                nodes: [1, 2, 3, 4],
                edges: [(1, 2): "A", (2, 3): "B", (3, 1): "C", (2, 4): "D", (4, 3): "E"],
                faces: [[1, 2, 3]: "L", [2, 4, 3]: "R"]
            )
            let graph2: Graph<Int, String, String> = .init(
                nodes: [4, 3, 2, 1],
                edges: [(4, 3): "E", (2, 4): "D", (3, 1): "C", (2, 3): "B", (1, 2): "A"],
                faces: [[2, 4, 3]: "R", [1, 2, 3]: "L"]
            )

            for node in [1, 2, 3, 4] {
                #expect(graph1.edges(from: node).map(\.node) == graph2.edges(from: node).map(\.node))
                #expect(graph1.edges(from: node).map(\.edge) == graph2.edges(from: node).map(\.edge))
                #expect(graph1.faces(adjacentTo: node).map(\.face) == graph2.faces(adjacentTo: node).map(\.face))
            }
        }
    }
}
