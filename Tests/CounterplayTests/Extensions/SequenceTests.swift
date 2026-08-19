import Testing
import Counterplay

@Suite("Sequence")
struct SequenceTests {

    @Suite("Strict max/min")
    struct StrictMaxMin {

        @Test("An empty sequence has no strict min/max")
        func empty() {
            #expect([Int]().strictMin { $0 } == nil)
            #expect([Int]().strictMax { $0 } == nil)
        }

        @Test("A sequence of equal values has no strict min/max")
        func equal() {
            #expect([4, 4, 4].strictMin { $0 } == nil)
            #expect([4, 4, 4].strictMax { $0 } == nil)
        }

        @Test("A single element is its own strict min/max")
        func single() {
            #expect([7].strictMin { $0 } == 7)
            #expect([7].strictMax { $0 } == 7)
        }

        @Test("The strict min/max is the highest/lowest value in the sequence")
        func unique() {
            #expect([3, 3, 1].strictMin { $0 } == 1)
            #expect([3, 5, 1].strictMin { $0 } == 1)
            #expect([1, 3, 5].strictMin { $0 } == 1)
            #expect([5, 3, 3].strictMax { $0 } == 5)
            #expect([3, 5, 1].strictMax { $0 } == 5)
            #expect([1, 3, 5].strictMax { $0 } == 5)
        }

        @Test("A duplicate highest/lowest value does not count as strict min/max")
        func tied() {
            #expect([1, 3, 1].strictMin { $0 } == nil)
            #expect([3, 1, 1].strictMin { $0 } == nil)
            #expect([1, 1, 3].strictMin { $0 } == nil)
            #expect([5, 3, 5].strictMax { $0 } == nil)
            #expect([3, 5, 5].strictMax { $0 } == nil)
            #expect([5, 5, 3].strictMax { $0 } == nil)
        }
    }
}
