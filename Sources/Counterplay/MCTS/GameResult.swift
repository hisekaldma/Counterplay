/// A summary of the results of a finished game.
public nonisolated protocol GameResult: Sendable {
    associatedtype Game

    /// Summarizes the results for the given game.
    init(_: Game)
}
