import Foundation
import Observation

/// An object that lets you run a single interactive version of the game with one human player and the
/// remaining players controlled by the computer, making decisions using Monte Carlo Tree Search (MCTS).
///
/// To start the computer players taking turns, call `play()`. It returns when it is the human player's turn
/// or the game has finished:
///
///     Button("Start playing") {
///         playingTask = Task { await runner.play() }
///     }
///
/// To take a turn for the human player, call `makeMove(_:)`. It makes the given move for the human player
/// and starts taking turns for the computer players, until it is the human player’s turn again or the game has finished.
///
///     Button("Play card") {
///         playingTask = Task { await runner.makeMove(.playCard(.knight)) }
///     }
///
/// To stop the computer players, cancel the task driving `play()` or `makeMove()`. The move currently
/// being evaluated is discarded, so calling `play()` resumes playing at the right point.
///
///     Button("Stop playing") {
///         playingTask?.cancel()
///     }
///
/// To start a new game, cancel the task and create a new runner. A runner is bound to one game
/// for its lifetime, and cannot be reset:
///
///     Button("New game") {
///         playingTask?.cancel()
///         runner = Runner(game: setup.newGame())
///     }
///
/// - Note: `Runner` has no isolation of its own and is not `Sendable`, so it stays in the
/// isolation region it was created in. The MCTS evaluation is run concurrently on the global
/// concurrent executor.
@Observable
public final class Runner<Game> where Game: GameModel {
    /// The game currently in progress.
    public private(set) var game: Game

    /// The human player in the game.
    public let player: Game.Player

    /// The parameters to use for the Monte Carlo Tree Search.
    public let configuration: MCTSConfiguration

    /// How much work to spend evaluating each turn.
    public let budgetPerTurn: MCTSBudget

    /// How many determinizations to create each turn for games with hidden information.
    public let determinizationsPerTurn: Int

    /// The maximum number of determinizations to evaluate concurrently.
    public let maxConcurrency: Int

    /// Whether the computer players are currently playing.
    public private(set) var isPlaying: Bool = false

    /// Creates a new runner with the given game and player.
    ///
    /// To start a new game, create a new runner. Cancel the task driving `play()` first;
    /// the old runner's evaluation is discarded along with the runner itself.
    ///
    /// - Parameter player: The human player. `nil` to choose one at random.
    ///
    /// - Precondition: `player` must be one of `game.players`.
    /// - Precondition: `budgetPerTurn` must be greater than zero.
    /// - Precondition: `determinizationsPerTurn` must be at least 1.
    /// - Precondition: `maxConcurrency` must be at least 1.
    public init(
        game: Game,
        player: Game.Player? = nil,
        configuration: MCTSConfiguration = .init(),
        budgetPerTurn: MCTSBudget = .iterations(1000),
        determinizationsPerTurn: Int = 1,
        maxConcurrency: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
    ) {
        let player = player ?? game.players.randomElement()!
        precondition(game.players.contains(player), "The human player must be one of the game's players.")
        precondition(determinizationsPerTurn > 0, "determinizationsPerTurn must be at least 1")
        precondition(maxConcurrency > 0, "maxConcurrency must be at least 1")
        self.game = game
        self.player = player
        self.configuration = configuration
        self.budgetPerTurn = budgetPerTurn
        self.determinizationsPerTurn = determinizationsPerTurn
        self.maxConcurrency = maxConcurrency
    }
}


// MARK: - State

extension Runner {
    /// Whether the human player can make a move right now.
    public var isPlayerTurn: Bool {
        !isPlaying && !game.isFinished && game.currentPlayer == player
    }
}


// MARK: - Playing

extension Runner {
    /// Plays the computer players' turns, returning when it is the human player's turn or the game has finished.
    ///
    /// Does nothing if the computer players are already playing, if it is the human player's turn,
    /// or if the game has finished. Returns early if the surrounding task is cancelled, discarding all
    /// in-progress work, so the game stays on the turn it was on and a later `play()` resumes from there.
    public func play() async {
        guard !isPlaying else {
            return
        }

        isPlaying = true
        defer { isPlaying = false }

        while !Task.isCancelled, !game.isFinished, game.currentPlayer != player {
            guard let move = try? await MCTS.bestMove(
                for: game,
                budget: budgetPerTurn,
                configuration: configuration,
                determinizations: determinizationsPerTurn,
                maxConcurrency: maxConcurrency
            ) else { break }
            guard !Task.isCancelled else { break }
            game.makeMove(move)
        }
    }

    /// Makes the given move for the human player, then plays the computer players' turns.
    ///
    /// Does nothing if it isn't the human player's turn.
    public func makeMove(_ move: Game.Move) async {
        guard isPlayerTurn else {
            return
        }
        game.makeMove(move)
        await play()
    }
}
