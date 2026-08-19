/// An immutable graph of nodes, edges, and faces — sufficient to model most game boards.
///
/// - Performance: Adjacency lookups (`edges(from:)`, `faces(adjacentTo:)`,
///   etc.) are precomputed at initialization so that queries during search are O(1) in
///   the number of neighbors. Build the graph once at game start, not per turn.
public struct Graph<Node, Edge, Face> where Node: Hashable & Comparable {
    @usableFromInline
    internal struct NodePair: Hashable {
        @usableFromInline
        internal let lowest:  Node

        @usableFromInline
        internal let highest: Node

        @inlinable
        internal init(_ a: Node, _ b: Node) {
            self.lowest  = min(a, b)
            self.highest = max(a, b)
        }
    }

    @usableFromInline
    internal struct NodeList: Hashable {
        @usableFromInline
        internal let nodes: [Node]

        @inlinable
        internal init(_ nodes: [Node]) {
            self.nodes = nodes.canonicalized()
        }
    }

    /// An adjacent edge in a graph.
    public typealias AdjacentEdge = (edge: Edge, node: Node)

    /// An adjacent face in a graph.
    public typealias AdjacentFace = (face: Face, nodes: [Node])

    @usableFromInline
    internal let _nodes: Set<Node>

    @usableFromInline
    internal let _edges: [NodePair: Edge]

    @usableFromInline
    internal let _faces: [NodeList: Face]

    @usableFromInline
    internal let adjacentEdges: [Node: [AdjacentEdge]]

    @usableFromInline
    internal let adjacentFaces: [Node: [AdjacentFace]]

    /// Creates an empty graph.
    public init() {
        self._nodes = []
        self._edges = [:]
        self._faces = [:]
        self.adjacentEdges = [:]
        self.adjacentFaces = [:]
    }
}


// MARK: - Conformances

extension Graph: Equatable where Edge: Equatable, Face: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs._nodes == rhs._nodes &&
        lhs._edges == rhs._edges &&
        lhs._faces == rhs._faces
    }
}

extension Graph: Hashable where Edge: Hashable, Face: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_nodes)
        hasher.combine(_edges)
        hasher.combine(_faces)
    }
}

extension Graph: Sendable where Node: Sendable, Edge: Sendable, Face: Sendable {}
extension Graph.NodePair: Sendable where Node: Sendable {}
extension Graph.NodeList: Sendable where Node: Sendable {}


// MARK: - Creating graphs

extension Graph {
    /// Creates a new graph with the given nodes, and the given edges and faces between them.
    ///
    /// - Precondition: No node appears more than once.
    /// - Precondition: No edge appears more than once.
    /// - Precondition: No face appears more than once.
    /// - Precondition: No edge connects a node to itself.
    /// - Precondition: Every node referenced by an edge or a face is in `nodes`.
    /// - Precondition: Every face has at least three nodes, and visits each of them once.
    /// - Precondition: Every edge bounding a face is in `edges`.
    public init(
        nodes: Nodes,
        edges: Edges,
        faces: Faces
    ) {
        // Insert nodes
        let _nodes: Set<Node> = nodes.nodes

        // Validate and insert edges
        var _edges: [NodePair: Edge] = [:]
        for (pair, edge) in edges.edges {
            let (a, b) = (pair.lowest, pair.highest)
            precondition(
                a != b,
                "The edge between \(a) and \(b) connects a node to itself."
            )
            precondition(
                _nodes.contains(a),
                "The edge between \(a) and \(b) refers to node \(a), which isn't in the graph."
            )
            precondition(
                _nodes.contains(b),
                "The edge between \(a) and \(b) refers to node \(b), which isn't in the graph."
            )
            _edges[pair] = edge
        }

        // Validate and insert faces
        var _faces: [NodeList: Face] = [:]
        for (list, face) in faces.faces {
            let nodes = list.nodes
            precondition(
                nodes.count >= 3,
                "The face \(nodes) has \(nodes.count) node(s). A face must have at least 3."
            )
            precondition(
                Set(nodes).count == nodes.count,
                "The face \(nodes) visits the same node more than once."
            )
            for node in nodes {
                precondition(
                    _nodes.contains(node),
                    "The face \(nodes) refers to node \(node), which isn't in the graph."
                )
            }
            for (a, b) in nodes.edges() {
                precondition(
                    _edges[NodePair(a, b)] != nil,
                    "The face \(nodes) is bounded by an edge between \(a) and \(b), which isn't in the graph."
                )
            }
            _faces[list] = face
        }

        // Precompute adjacency, sorted so that lookups are reproducible
        var adjacentEdges: [Node: [AdjacentEdge]] = [:]
        var adjacentFaces: [Node: [AdjacentFace]] = [:]
        for node in _nodes {
            adjacentEdges[node] = _edges.compactMap { nodes, edge in
                if nodes.highest == node {
                    (edge, nodes.lowest)
                } else if nodes.lowest == node {
                    (edge, nodes.highest)
                } else {
                    nil
                }
            }.sorted { lhs, rhs in
                // Sort adjacent edges by the node on the far end
                lhs.node < rhs.node
            }
            adjacentFaces[node] = _faces.compactMap { nodes, face in
                if nodes.nodes.contains(node) {
                    (face, nodes.nodes)
                } else {
                    nil
                }
            }.sorted { lhs, rhs in
                // Sort adjacent faces lexicographically by their nodes
                lhs.nodes.lexicographicallyPrecedes(rhs.nodes)
            }
        }

        // Init
        self._nodes = _nodes
        self._edges = _edges
        self._faces = _faces
        self.adjacentEdges = adjacentEdges
        self.adjacentFaces = adjacentFaces
    }

    /// Creates a new graph with the given nodes, and the given edges and faces between them.
    ///
    /// - Precondition: No node appears more than once.
    /// - Precondition: No edge appears more than once.
    /// - Precondition: No face appears more than once.
    /// - Precondition: No edge connects a node to itself.
    /// - Precondition: Every node referenced by an edge or a face is in `nodes`.
    /// - Precondition: Every face has at least three nodes, and visits each of them once.
    /// - Precondition: Every edge bounding a face is in `edges`.
    public init(
        nodes: some Sequence<Node>,
        edges: some Sequence<((Node, Node), Edge)>,
        faces: some Sequence<([Node], Face)>
    ) {
        self.init(nodes: Nodes(nodes), edges: Edges(edges), faces: Faces(faces))
    }
}

extension Array {
    internal func edges() -> [(Element, Element)] {
        guard count > 1 else { return [] }
        return (0..<count).map { (self[$0], self[($0 + 1) % count]) }
    }
}

extension Array where Element: Hashable & Comparable {
    /// The lexicographically smallest rotation of the cycle or its reversal.
    @usableFromInline
    internal func canonicalized() -> [Element] {
        guard count > 1 else { return self }
        var best: [Element] = self
        for direction in [self, self.reversed()] {
            for index in direction.indices {
                let rotation = Array(direction[index...] + direction[..<index])
                if rotation.lexicographicallyPrecedes(best) {
                    best = rotation
                }
            }
        }
        return best
    }
}


// MARK: - Empty

extension Graph {
    /// A Boolean value that indicates whether the graph is empty.
    public var isEmpty: Bool {
        _nodes.isEmpty // A graph with no nodes has no edges or faces
    }
}


// MARK: - Nodes

extension Graph {
    /// A collection of nodes in a graph.
    public struct Nodes {
        @usableFromInline
        internal var nodes: Set<Node>

        @inlinable
        internal init(nodes: Set<Node>) {
            self.nodes = nodes
        }
    }

    /// The nodes in this graph.
    @inlinable
    public var nodes: Nodes {
        Nodes(nodes: _nodes)
    }
}

extension Graph.Nodes: Collection {
    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal var wrapped: Set<Node>.Index

        @inlinable
        init(wrapped: Set<Node>.Index) {
            self.wrapped = wrapped
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.wrapped < rhs.wrapped
        }
    }

    @inlinable
    public var startIndex: Index {
        Index(wrapped: nodes.startIndex)
    }

    @inlinable
    public var endIndex: Index {
        Index(wrapped: nodes.endIndex)
    }

    @inlinable
    public subscript(index: Index) -> Node {
        nodes[index.wrapped]
    }

    @inlinable
    public func index(after i: Index) -> Index {
        Index(wrapped: nodes.index(after: i.wrapped))
    }
}

extension Graph.Nodes: Equatable {
}

extension Graph.Nodes {
    @inlinable
    internal init(_ elements: some Sequence<Node>) {
        var nodes: Set<Node> = []
        for node in elements {
            precondition(
                !nodes.contains(node),
                "The node \(node) appears more than once."
            )
            nodes.insert(node)
        }
        self.init(nodes: nodes)
    }
}

extension Graph.Nodes: ExpressibleByArrayLiteral {
    /// Creates a collection of nodes from an array literal.
    ///
    /// - Precondition: No node appears more than once.
    public init(arrayLiteral elements: Node...) {
        self.init(elements)
    }
}


// MARK: - Edges

extension Graph {
    /// A collection of edges in a graph.
    public struct Edges {
        @usableFromInline
        internal var edges: [NodePair: Edge]

        @inlinable
        internal init(edges: [NodePair: Edge]) {
            self.edges = edges
        }

        /// Returns the edge between the given nodes, if any.
        @inlinable
        public subscript(between a: Node, and b: Node) -> Edge? {
            edges[NodePair(a, b)]
        }
    }

    /// The edges in this graph.
    @inlinable
    public var edges: Edges {
        Edges(edges: _edges)
    }
}

extension Graph.Edges: Collection {
    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal var wrapped: Dictionary<Graph.NodePair, Edge>.Index

        @inlinable
        init(wrapped: Dictionary<Graph.NodePair, Edge>.Index) {
            self.wrapped = wrapped
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.wrapped < rhs.wrapped
        }
    }

    @inlinable
    public var startIndex: Index {
        Index(wrapped: edges.startIndex)
    }

    @inlinable
    public var endIndex: Index {
        Index(wrapped: edges.endIndex)
    }

    @inlinable
    public subscript(index: Index) -> (a: Node, b: Node, edge: Edge) {
        let (key, value) = edges[index.wrapped]
        return (key.lowest, key.highest, value)
    }

    @inlinable
    public func index(after i: Index) -> Index {
        Index(wrapped: edges.index(after: i.wrapped))
    }
}

extension Graph.Edges: Equatable where Edge: Equatable {
}

extension Graph.Edges {
    @inlinable
    internal init(_ elements: some Sequence<((Node, Node), Edge)>) {
        var edges: [Graph.NodePair: Edge] = [:]
        for ((a, b), edge) in elements {
            let pair = Graph.NodePair(a, b)
            precondition(
                edges[pair] == nil,
                "The edge between \(a) and \(b) appears more than once. An edge is undirected, so (a, b) and (b, a) are the same edge."
            )
            edges[pair] = edge
        }
        self.init(edges: edges)
    }
}

extension Graph.Edges: ExpressibleByDictionaryLiteral {
    /// Creates a collection of edges from a dictionary literal.
    ///
    /// An edge is undirected, so `(a, b)` and `(b, a)` describe the same edge.
    ///
    /// - Precondition: No edge appears more than once.
    public init(dictionaryLiteral elements: ((Node, Node), Edge)...) {
        self.init(elements)
    }
}

extension Graph.Edges: ExpressibleByArrayLiteral where Edge == () {
    /// Creates a collection of valueless edges from an array literal.
    ///
    /// An edge is undirected, so `(a, b)` and `(b, a)` describe the same edge.
    ///
    /// - Precondition: No edge appears more than once.
    public init(arrayLiteral elements: (Node, Node)...) {
        self.init(elements.map { ($0, ()) })
    }
}


// MARK: - Faces

extension Graph {
    /// A collection of faces in a graph.
    public struct Faces {
        @usableFromInline
        internal var faces: [NodeList: Face]

        @inlinable
        internal init(faces: [NodeList: Face]) {
            self.faces = faces
        }
    }

    /// The faces in this graph.
    @inlinable
    public var faces: Faces {
        Faces(faces: _faces)
    }
}

extension Graph.Faces: Collection {
    public struct Index: Equatable, Comparable {
        @usableFromInline
        internal var wrapped: Dictionary<Graph.NodeList, Face>.Index

        @inlinable
        init(wrapped: Dictionary<Graph.NodeList, Face>.Index) {
            self.wrapped = wrapped
        }

        @inlinable
        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.wrapped < rhs.wrapped
        }
    }

    @inlinable
    public var startIndex: Index {
        Index(wrapped: faces.startIndex)
    }

    @inlinable
    public var endIndex: Index {
        Index(wrapped: faces.endIndex)
    }

    @inlinable
    public subscript(index: Index) -> (nodes: [Node], face: Face) {
        let (key, value) = faces[index.wrapped]
        return (key.nodes, value)
    }

    @inlinable
    public func index(after i: Index) -> Index {
        Index(wrapped: faces.index(after: i.wrapped))
    }
}

extension Graph.Faces: Equatable where Face: Equatable {
}

extension Graph.Faces {
    @inlinable
    internal init(_ elements: some Sequence<([Node], Face)>) {
        var faces: [Graph.NodeList: Face] = [:]
        for (nodes, face) in elements {
            let list = Graph.NodeList(nodes)
            precondition(
                faces[list] == nil,
                "The face \(nodes) appears more than once. A face is an undirected cycle, so any rotation or reflection of its nodes is the same face."
            )
            faces[list] = face
        }
        self.init(faces: faces)
    }
}

extension Graph.Faces: ExpressibleByDictionaryLiteral {
    /// Creates a collection of faces from a dictionary literal.
    ///
    /// A face is an undirected cycle, so any rotation or reflection of its nodes describes the same face.
    ///
    /// - Precondition: No face appears more than once.
    public init(dictionaryLiteral elements: ([Node], Face)...) {
        self.init(elements)
    }
}


// MARK: - Adjacency

extension Graph {
    /// Returns the edges connected to the given node.
    ///
    /// The edges are ordered by the node at their far end, ascending. The order
    /// depends only on the nodes themselves, not on the order the graph was
    /// declared in, so repeated runs see the same order.
    ///
    /// - Note: A graph has no geometry, so this order carries no spatial
    ///   meaning — it won't walk around the node in any particular direction.
    @inlinable
    public func edges(from node: Node) -> [AdjacentEdge] {
        adjacentEdges[node] ?? []
    }

    /// Returns the faces adjacent to the given node.
    ///
    /// The faces are ordered lexicographically by their nodes, ascending. The
    /// order depends only on the nodes themselves, not on the order the graph
    /// was declared in, so repeated runs see the same order.
    ///
    /// - Note: A graph has no geometry, so this order carries no spatial
    ///   meaning — it won't walk around the node in any particular direction.
    @inlinable
    public func faces(adjacentTo node: Node) -> [AdjacentFace] {
        adjacentFaces[node] ?? []
    }
}
