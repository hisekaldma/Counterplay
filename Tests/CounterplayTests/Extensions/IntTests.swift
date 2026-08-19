import Testing
import Counterplay

@Suite("Int")
struct IntTests {

    @Suite("Increasing")
    struct Increasing {

        @Test("Increase within limit")
        func belowLimit() {
            var value = 3
            value.increase(by: 2, limit: 10)
            #expect(value == 5)
            value.increase(by: 5, limit: 10)
            #expect(value == 10)
        }

        @Test("Increase past limit stops at the limit")
        func beyondLimit() {
            var value = 3
            value.increase(by: 20, limit: 10)
            #expect(value == 10)
        }

        @Test("Increase that overflows stops at the limit")
        func overflow() {
            var value = Int.max
            value.increase(by: 1, limit: 100)
            #expect(value == 100)

            var nearMax = Int.max - 1
            nearMax.increase(by: 5, limit: .max)
            #expect(nearMax == .max)

            var large = Int.max / 2 + 1
            large.increase(by: Int.max / 2 + 1, limit: .max)
            #expect(large == .max)
        }

        @Test("Cannot increase by a negative amount")
        func rejectNegativeAmount() async {
            await #expect(processExitsWith: .failure) {
                var value = 3
                value.increase(by: -1, limit: 10)
            }
        }
    }

    @Suite("Decreasing")
    struct Decreasing {

        @Test("Decrease within limit")
        func aboveLimit() {
            var value = 10
            value.decrease(by: 3, limit: 0)
            #expect(value == 7)
            value.decrease(by: 7, limit: 0)
            #expect(value == 0)
        }

        @Test("Decrease past limit stops at the limit")
        func beyondLimit() {
            var value = 3
            value.decrease(by: 10, limit: 0)
            #expect(value == 0)
        }

        @Test("Decrease that overflows stops at the limit")
        func overflow() {
            var value = Int.min
            value.decrease(by: 1, limit: -100)
            #expect(value == -100)

            var nearMin = Int.min + 1
            nearMin.decrease(by: 5, limit: .min)
            #expect(nearMin == .min)

            var large = Int.min / 2 - 1
            large.decrease(by: Int.max / 2 + 1, limit: .min)
            #expect(large == .min)
        }

        @Test("Cannot decrease by a negative amount")
        func rejectNegativeAmount() async {
            await #expect(processExitsWith: .failure) {
                var value = 3
                value.decrease(by: -1, limit: 0)
            }
        }
    }
}
