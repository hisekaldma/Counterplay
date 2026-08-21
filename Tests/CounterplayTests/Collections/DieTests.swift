import Testing
import Counterplay

@Suite("Die")
struct DieTests {
    @Test("Initialize die with faces")
    func initWithFaces() {
        let die = Die(faces: [1, 2, 3, 4, 5, 6])
        #expect(die.faces == [1, 2, 3, 4, 5, 6])
    }

    @Test("Initialize die with range")
    func initWithRange() {
        let die = Die(range: 1...6)
        #expect(die.faces == [1, 2, 3, 4, 5, 6])
    }

    @Test("Equatable")
    func equatable() {
        let die1 = Die(faces: [1, 2, 3])
        let die2 = Die(faces: [1, 2, 3])
        let die3 = Die(faces: [4, 5, 6])
        #expect(die1 == die2)
        #expect(die1 != die3)
    }

    @Test("Hashable")
    func hashable() {
        let die1 = Die(faces: [1, 2, 3])
        let die2 = Die(faces: [1, 2, 3])
        let die3 = Die(faces: [4, 5, 6])
        #expect(Set([die1, die2]).count == 1)
        #expect(Set([die1, die3]).count == 2)
    }

    @Test("Roll returns a valid face")
    func roll() {
        let die = Die(faces: [1, 2, 3, 4, 5, 6])
        let result = die.roll()
        #expect(die.faces.contains(result))
    }

    @Test("Roll multiple times returns valid faces")
    func rollMultipleTimes() {
        let die = Die(faces: [1, 2, 3, 4, 5, 6])
        let results = die.roll(count: 10)
        #expect(results.count == 10)
        for result in results {
            #expect(die.faces.contains(result))
        }
    }

    @Test("Roll zero times returns empty array")
    func rollZeroTimes() {
        let die = Die(faces: [1, 2, 3, 4, 5, 6])
        let results = die.roll(count: 0)
        #expect(results.isEmpty)
    }

    @Test("Standard dice")
    func standardD4() {
        #expect(Die.d4.faces == Array(1...4))
        #expect(Die.d6.faces == Array(1...6))
        #expect(Die.d8.faces == Array(1...8))
        #expect(Die.d10.faces == Array(1...10))
        #expect(Die.d12.faces == Array(1...12))
        #expect(Die.d20.faces == Array(1...20))
    }
}
