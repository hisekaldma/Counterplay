/// The outcome of a game for a specific player.
public enum Outcome: Sendable, Equatable {
    /// The player has won the game.
    case win

    /// The player has lost the game.
    case loss

    /// The player has tied with another player for winning the game.
    case tie

    /// An estimate of the player's chance of winning the game.
    ///
    /// The associated value should lie in `0...1` (where 0 is certain loss,
    /// 1 is certain win, and 0.5 is 50/50). Values outside this range
    /// are clamped when used.
    case estimate(Double)
}

extension Outcome {
    /// The numeric reward of the outcome, in `0...1`.
    ///
    /// - `.win` → `1`
    /// - `.loss` → `0`
    /// - `.tie` → `0.5`
    /// - `.estimate(v)` → `v`, clamped to `0...1`
    public var reward: Double {
        switch self {
        case .win:                 return 1
        case .loss:                return 0
        case .tie:                 return 0.5
        case .estimate(let reward): return reward.isNaN ? 0.5 : max(min(reward, 1), 0)
        }
    }
}
