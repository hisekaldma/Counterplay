/// A die that can be rolled.
public struct Die<T> {
    /// The faces of the die.
    public let faces: [T]

    /// Creates a die with the given faces.
    ///
    /// - Precondition: `faces` must not be empty.
    public init(faces: [T]) {
        precondition(!faces.isEmpty, "faces must not be empty")
        self.faces = faces
    }
}


// MARK: - Conformances

extension Die: Equatable where T: Equatable {
}

extension Die: Hashable where T: Hashable {
}

extension Die: Sendable where T: Sendable {
}


// MARK: - Rolling

extension Die {
    /// Returns the result of rolling the die.
    @inlinable
    public func roll() -> T {
        faces.randomElement()!
    }

    /// Returns the result of rolling the die the given number of times.
    ///
    /// - Precondition: `count` must be non-negative
    @inlinable
    public func roll(count: Int) -> [T] {
        precondition(count >= 0, "count must be non-negative")
        var result: [T] = []
        for _ in 0..<count {
            result.append(self.roll())
        }
        return result
    }
}


// MARK: - Standard numeric dice

extension Die where T: Strideable, T.Stride: SignedInteger {
    /// Creates a die with one face for each number in the given range.
    public init(range: ClosedRange<T>) {
        self.faces = range.map { $0 }
    }
}

extension Die<Int> {
    /// A standard die with faces 1-4.
    public static let d4 = Die(range: 1...4)

    /// A standard die with faces 1-6.
    public static let d6 = Die(range: 1...6)

    /// A standard die with faces 1-8.
    public static let d8 = Die(range: 1...8)

    /// A standard die with faces 1-10.
    public static let d10 = Die(range: 1...10)

    /// A standard die with faces 1-12.
    public static let d12 = Die(range: 1...12)

    /// A standard die with faces 1-20.
    public static let d20 = Die(range: 1...20)
}
