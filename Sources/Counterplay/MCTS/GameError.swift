/// An error that indicates a problem with a game.
public enum GameError<Game: GameModel>: Error, Sendable, Hashable {
    /// While searching for moves, a game state was found where the game
    /// was not finished, but there were no possible moves.
    case noPossibleMoves(after: [Game.Move])
}
