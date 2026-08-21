/// A representation of a game state.
///
/// Conforming types model the rules of a turn-based game: who the players are,
/// whose turn it is, what moves are legal, how a move changes the state, and how
/// the game ends. Conforming types should be value types — MCTS copies the state
/// aggressively during search and playouts.
///
/// ## Required invariants
///
/// - `players` must be non-empty and constant for the lifetime of the game.
/// - `currentPlayer` must always be a member of `players`.
/// - `possibleMoves` must not be empty if `isFinished` is `false`.
/// - `outcome(for:)` must return `.estimate(_)` when the game is in progress and
///   one of `.win`, `.loss`, or `.tie` when `isFinished` is `true`.
/// - `obscure()` must not change `currentPlayer` or `possibleMoves`.
public nonisolated protocol Game: Sendable {
    /// A representation of a player in the game.
    associatedtype Player: Hashable, SmallRawUInt8

    /// A representation of a move in the game.
    associatedtype Move: Sendable, Hashable

    /// The players who are playing the game.
    ///
    /// - Important: Must be non-empty and constant for the lifetime of the game.
    var players: [Player] { get }

    /// The player whose turn it is.
    ///
    /// - Important: Must always be a member of `players`.
    var currentPlayer: Player { get }

    /// The moves that the current player can make.
    ///
    /// - Important: Must not be empty if `isFinished` is `false`.
    ///   If a player has no legal move but the game continues (e.g. a forced pass),
    ///   model this as an explicit `Move` rather than returning an empty array.
    var possibleMoves: [Move] { get }

    /// Applies the given move to the game state for the current player.
    ///
    /// Implementations are responsible for updating the state according to the move,
    /// and advancing `currentPlayer` as appropriate. If a player may make multiple
    /// moves during a turn, advance currentPlayer only after their final move.
    ///
    /// - Parameter move: The move to apply.
    mutating func makeMove(_ move: Move)

    /// Randomize all information that is hidden from the current player.
    ///
    /// - For perfect-information games (chess, tic-tac-toe), leave this empty.
    /// - For hidden-information games, randomize opponents' hands, the order of
    ///   face-down decks, and any other state the current player cannot observe.
    ///
    /// - Important: Must not change `currentPlayer` or `possibleMoves`.
    ///   The player whose turn it is can see their own hidden state, so it must not be randomized.
    mutating func obscure()

    /// Returns whether the game has reached a terminal state.
    var isFinished: Bool { get }

    /// Returns the outcome of the game for the given player.
    ///
    /// - For terminal states return `.win`, `.loss`, or `.tie`.
    /// - For non-terminal states return `.estimate(_)` with an estimate between 0 and 1
    ///     of the player's chance of winning from here.
    ///
    /// The `.estimate` value is used by MCTS when a random playout hits
    /// `maxPlayoutDepth` without reaching a terminal state. A flat `0.5` is
    /// always valid but uninformative; a heuristic that tracks genuine progress
    /// (score / score needed to win, board material, etc.) substantially
    /// reduces the iterations needed for strong play in long games.
    ///
    /// - Parameter player: The player whose outcome to evaluate.
    func outcome(for player: Player) -> Outcome
}

extension Game {
    /// Returns the updated game state that results from making the given move for the current player.
    public func makingMove(_ move: Move) -> Self {
        var copy = self
        copy.makeMove(move)
        return copy
    }

    /// Returns the game state that results from randomizing all information that is hidden from the current player.
    public func obscured() -> Self {
        var copy = self
        copy.obscure()
        assert(copy.currentPlayer == currentPlayer, "`obscure()` must not change `currentPlayer`.")
        assert(Set(copy.possibleMoves) == Set(possibleMoves), "`obscure()` must not change `possibleMoves`.")
        return copy
    }
}


// MARK: - Player order

extension Game {
    /// Returns the player after the current player, wrapping around to the start of the player order if necessary.
    ///
    /// Typically used to find the next player to pass the turn to. For example:
    ///
    ///     currentPlayer = nextPlayer()
    @inlinable
    public func nextPlayer() -> Player {
        nextPlayer(after: currentPlayer)!
    }

    /// Returns the player before the current player, wrapping around to the end of the player order if necessary.
    @inlinable
    public func previousPlayer() -> Player {
        previousPlayer(before: currentPlayer)!
    }

    /// Returns the player after the given player, wrapping around to the start of the player order if necessary.
    @inlinable
    public func nextPlayer(after player: Player) -> Player? {
        players.element(afterWithWrapping: player)
    }

    /// Returns the player before the given player, wrapping around to the end of the player order if necessary.
    @inlinable
    public func previousPlayer(before player: Player) -> Player? {
        players.element(beforeWithWrapping: player)
    }
}
