/// A tree whose nodes live in a single flat array and refer to each other by index.
///
/// Each node stores the index of its parent, its first child, and its next sibling,
/// so a node's children form a singly linked list threaded through the array.
/// Nodes are appended, never moved or removed, so an index stays valid for the
/// lifetime of the tree.
@usableFromInline
internal struct Tree<Value> {
    /// The position of a node in the tree.
    @usableFromInline
    internal struct Index: Hashable {
        @usableFromInline
        internal let rawValue: Int

        @inlinable
        internal init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    @usableFromInline
    internal struct Node {
        @usableFromInline
        internal var value: Value

        @usableFromInline
        internal var parent: Index

        @usableFromInline
        internal var firstChild: Index

        @usableFromInline
        internal var nextSibling: Index

        @inlinable
        internal init(value: Value, parent: Index) {
            self.value = value
            self.parent = parent
            self.firstChild = .none
            self.nextSibling = .none
        }
    }

    @usableFromInline
    internal var nodes: [Node]

    /// Creates a tree containing a single root node with the given value.
    @inlinable
    internal init(root value: Value) {
        self.nodes = [Node(value: value, parent: .none)]
    }
}

extension Tree.Index {
    /// The index used for a missing link.
    @inlinable
    internal static var none: Self { Self(-1) }
}


// MARK: - Accessing nodes

extension Tree {
    /// The index of the root node.
    @inlinable
    internal var root: Index { Index(0) }

    /// Accesses the value of the node at the given index.
    @inlinable
    internal subscript(index: Index) -> Value {
        _read { yield nodes[index.rawValue].value }
        _modify { yield &nodes[index.rawValue].value }
    }

    /// Returns the index of the parent of the node at the given index, or `nil` for the root.
    @inlinable
    internal func parent(of index: Index) -> Index? {
        let parent = nodes[index.rawValue].parent
        return parent == .none ? nil : parent
    }

    /// Calls `body` with the index of each child of the node at `parent`.
    @inlinable
    internal func forEachChild(of parent: Index, _ body: (Index) -> Void) {
        var child = nodes[parent.rawValue].firstChild
        while child != .none {
            body(child)
            child = nodes[child.rawValue].nextSibling
        }
    }
}


// MARK: - Adding nodes

extension Tree {
    /// Adds a new node with the given value as a child of the node at `parent`, and returns its index.
    @inlinable
    @discardableResult
    internal mutating func addChild(_ value: Value, to parent: Index) -> Index {
        let index = Index(nodes.endIndex)
        var node = Node(value: value, parent: parent)
        node.nextSibling = nodes[parent.rawValue].firstChild
        nodes.append(node)
        nodes[parent.rawValue].firstChild = index
        return index
    }
}
