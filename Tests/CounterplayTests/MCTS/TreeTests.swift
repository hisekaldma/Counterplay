import Testing
@testable import Counterplay

@Suite("Tree")
struct TreeTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize with root")
        func initWithRoot() {
            let tree = Tree(root: "root")
            #expect(tree[tree.root] == "root")
            #expect(tree.parent(of: tree.root) == nil)
            #expect(children(of: tree.root, in: tree).isEmpty)
        }
    }

    @Suite("Adding nodes")
    struct AddingNodes {

        @Test("Add child")
        func addChild() {
            var tree = Tree(root: 0)
            let child = tree.addChild(1, to: tree.root)
            #expect(child != tree.root)
            #expect(tree[child] == 1)
            #expect(tree.parent(of: child) == tree.root)
            #expect(children(of: tree.root, in: tree) == [child])
            #expect(children(of: child, in: tree).isEmpty)
        }

        @Test("Add multiple children")
        func addMultipleChildren() {
            var tree = Tree(root: 0)
            let a = tree.addChild(1, to: tree.root)
            let b = tree.addChild(2, to: tree.root)
            let c = tree.addChild(3, to: tree.root)
            #expect(Set([a, b, c]).count == 3)
            #expect(children(of: tree.root, in: tree) == [a, b, c])
            #expect(tree.parent(of: a) == tree.root)
            #expect(tree.parent(of: b) == tree.root)
            #expect(tree.parent(of: c) == tree.root)
        }

        @Test("Add grandchildren")
        func addGrandchildren() {
            var tree = Tree(root: 0)
            let a = tree.addChild(1, to: tree.root)
            let b = tree.addChild(2, to: tree.root)
            let aa = tree.addChild(11, to: a)
            let ab = tree.addChild(12, to: a)
            let ba = tree.addChild(21, to: b)
            #expect(children(of: tree.root, in: tree) == [a, b])
            #expect(children(of: a, in: tree) == [aa, ab])
            #expect(children(of: b, in: tree) == [ba])
            #expect(tree.parent(of: aa) == a)
            #expect(tree.parent(of: ab) == a)
            #expect(tree.parent(of: ba) == b)
            #expect(tree.parent(of: tree.parent(of: ba)!) == tree.root)
        }
    }

    @Suite("Accessing nodes")
    struct AccessingNodes {

        @Test("Mutate value in place")
        func mutateValue() {
            var tree = Tree(root: 0)
            let a = tree.addChild(1, to: tree.root)
            let b = tree.addChild(2, to: tree.root)
            tree[a] += 10
            tree[tree.root] = 100
            #expect(tree[tree.root] == 100)
            #expect(tree[a] == 11)
            #expect(tree[b] == 2)
        }

        @Test("Visit children")
        func forEachChild() {
            var tree = Tree(root: 0)
            let a = tree.addChild(1, to: tree.root)
            let b = tree.addChild(2, to: tree.root)
            tree.addChild(11, to: a)
            tree.addChild(21, to: b)
            var visits: [Tree<Int>.Index: Int] = [:]
            tree.forEachChild(of: tree.root) { visits[$0, default: 0] += 1 }
            #expect(visits == [a: 1, b: 1])
        }

        @Test("Visit children of leaf")
        func forEachChildOfLeaf() {
            var tree = Tree(root: 0)
            let a = tree.addChild(1, to: tree.root)
            var visits: [Tree<Int>.Index: Int] = [:]
            tree.forEachChild(of: a) { visits[$0, default: 0] += 1 }
            #expect(visits == [:])
        }
    }
}


// MARK: - Helpers

private func children<Value>(of parent: Tree<Value>.Index, in tree: Tree<Value>) -> Set<Tree<Value>.Index> {
    var children: Set<Tree<Value>.Index> = []
    tree.forEachChild(of: parent) { children.insert($0) }
    return children
}
