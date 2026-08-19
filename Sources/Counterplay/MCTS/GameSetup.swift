/// A setup configuration for a game.
public nonisolated protocol GameSetup: Sendable {
    associatedtype Game

    /// Creates a new game based on the setup.
    func newGame() -> Game
}
