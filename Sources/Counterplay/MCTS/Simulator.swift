import Foundation
import Observation

/// An object that lets you run multiple playthroughs of a game with all players controlled
/// by the computer, making decisions using Monte Carlo Tree Search (MCTS).
///
/// To start the simulation, call the `run()` method. This will start the simulation of all the setups,
/// and return when all games have finished playing.
///
///     Button("Start simulation") {
///         simulationTask = Task { await simulator.run() }
///     }
///
/// To stop the simulation, cancel the task driving `run()`. Completed games are kept, but in-progress
/// games are discarded and returned to the queue, so calling `run()` restarts them.
///
///     Button("Stop simulation") {
///         simulationTask?.cancel()
///     }
///
/// To simulate a different set of games, cancel the task and create a new simulator. A simulator
/// is bound to one queue for its lifetime, and cannot be reset:
///
///     Button("New simulation") {
///         simulationTask?.cancel()
///         simulator = Simulator(setups: setups)
///     }
///
/// - Note: `Simulator` has no isolation of its own and is not `Sendable`, so it stays in the
/// isolation region it was created in. The game simulations are run concurrently on the global
/// concurrent executor.
@Observable
public final class Simulator<Game, Setup, Result> where
    Game: GameModel,
    Setup: GameSetup,
    Result: GameResult,
    Game == Setup.Game,
    Game == Result.Game
{
    /// The simulation of a single game match.
    public struct SimulatedGame: Identifiable {
        public let id:    Int
        public let setup: Setup
        public var state: SimulationState

        public init(id: Int, setup: Setup, state: SimulationState) {
            self.id = id
            self.setup = setup
            self.state = state
        }
    }

    /// The state of the simulation of a single game match.
    public enum SimulationState {
        /// The game is waiting to be simulated.
        case pending

        /// The game is currently being simulated.
        case running

        /// The game was simulated until the game reached a terminal state.
        case completed(Result, Duration)

        /// The game was simulated until it encountered an error.
        case failed(GameError<Game>, Duration)
    }

    /// The games played by the simulator.
    public private(set) var games: [SimulatedGame]

    /// The number of games that have successfully finished playing so far.
    public private(set) var completedGames: Int = 0

    /// The number of games that have failed to finish playing so far.
    public private(set) var failedGames: Int = 0

    /// The parameters to use for the Monte Carlo Tree Search.
    public let configuration: MCTSConfiguration

    /// How much work to spend evaluating each turn.
    public let budgetPerTurn: MCTSBudget

    /// How many determinizations to create each turn for games with hidden information.
    public let determinizationsPerTurn: Int

    /// The maximum number of games to simulate concurrently.
    public let maxConcurrency: Int

    /// Whether the simulator is currently playing games.
    public private(set) var isRunning: Bool = false

    /// Creates a new simulator with the given setups.
    ///
    /// - Precondition: `budgetPerTurn` must be greater than zero.
    /// - Precondition: `determinizationsPerTurn` must be at least 1.
    /// - Precondition: `maxConcurrency` must be at least 1.
    public init(
        setups: [Setup],
        configuration: MCTSConfiguration = .init(),
        budgetPerTurn: MCTSBudget = .iterations(1000),
        determinizationsPerTurn: Int = 1,
        maxConcurrency: Int = max(1, ProcessInfo.processInfo.activeProcessorCount - 1)
    ) {
        precondition(determinizationsPerTurn > 0, "determinizationsPerTurn must be at least 1")
        precondition(maxConcurrency > 0, "maxConcurrency must be at least 1")
        self.games = setups.enumerated().map { SimulatedGame(id: $0, setup: $1, state: .pending) }
        self.configuration = configuration
        self.budgetPerTurn = budgetPerTurn
        self.determinizationsPerTurn = determinizationsPerTurn
        self.maxConcurrency = maxConcurrency
    }
}


// MARK: - Conformances

extension Simulator.SimulatedGame {
    /// Whether the game has not been started yet.
    public var isPending: Bool { if case .pending = self.state { true } else { false } }

    /// Whether the game is running.
    public var isRunning: Bool { if case .running = self.state { true } else { false } }

    /// Whether the game has run to completion.
    public var isCompleted: Bool { if case .completed = self.state { true } else { false } }

    /// Whether the game failed to run to completion.
    public var isFailed: Bool { if case .failed = self.state { true } else { false } }

    /// The result of the game, if it ran to completion.
    public var result: Result? {
        if case .completed(let result, _) = state {
            result
        } else {
            nil
        }
    }

    /// The error, if the game failed to run to completion.
    public var error: GameError<Game>? {
        if case .failed(let error, _) = state {
            error
        } else {
            nil
        }
    }

    /// The duration of the game, if the game was completed or failed.
    public var duration: Duration? {
        switch state {
        case .pending, .running:
            nil
        case .completed(_, let duration):
            duration
        case .failed(_, let duration):
            duration
        }
    }
}

extension Simulator.SimulatedGame: Equatable where Setup: Equatable, Result: Equatable {
}

extension Simulator.SimulationState: Equatable where Result: Equatable {
}


// MARK: - State

extension Simulator {
    /// The total number of games to play.
    public var totalGames: Int {
        games.count
    }
}


// MARK: - Running

extension Simulator {
    /// Plays every pending game, returning when they have all finished.
    ///
    /// Games are played concurrently, with at most `maxConcurrency` games at the same time.
    /// Does nothing if a `run()` is already in progress. Returns early if the surrounding task is cancelled,
    /// keeping completed and failed games but discarding in-progress games, so that a later `run()`
    /// picks them up again.
    public func run() async {
        guard !isRunning else {
            return
        }

        isRunning = true
        defer {
            isRunning = false

            // Discard in-progress games so that a later run picks them up again
            for index in games.indices where games[index].isRunning {
                games[index].state = .pending
            }
        }

        #if canImport(Darwin)
        // Pause system sleep
        let activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .idleSystemSleepDisabled],
            reason: "Simulating"
        )
        defer { ProcessInfo.processInfo.endActivity(activity) }
        #endif // canImport(Darwin)

        // Parameters are copied into locals so that the child tasks don't capture `self`
        let configuration = self.configuration
        let budgetPerTurn = self.budgetPerTurn
        let determinizationsPerTurn = self.determinizationsPerTurn

        await withTaskGroup(of: (index: Int, result: Swift.Result<Result, MCTSError<Game>>, duration: Duration).self) { group in
            // Prime the group up to the concurrency limit
            for _ in 0..<maxConcurrency {
                guard let claimed = claimNextGame() else { break }
                group.addTask {
                    await Self.simulateGame(
                        index: claimed.index,
                        setup: claimed.setup,
                        configuration: configuration,
                        budgetPerTurn: budgetPerTurn,
                        determinizationsPerTurn: determinizationsPerTurn
                    )
                }
            }

            // Drain and refill
            for await completion in group {
                // Drain
                switch completion.result {
                case .success(let result):
                    games[completion.index].state = .completed(result, completion.duration)
                    completedGames += 1
                case .failure(.invalidGame(let error)):
                    games[completion.index].state = .failed(error, completion.duration)
                    failedGames += 1
                case .failure(.cancelled):
                    games[completion.index].state = .pending
                }

                // Refill
                guard !Task.isCancelled, let next = claimNextGame() else { continue }
                group.addTask {
                    await Self.simulateGame(
                        index: next.index,
                        setup: next.setup,
                        configuration: configuration,
                        budgetPerTurn: budgetPerTurn,
                        determinizationsPerTurn: determinizationsPerTurn
                    )
                }
            }
        }
    }

    private func claimNextGame() -> (index: Int, setup: Setup)? {
        guard let index = games.firstIndex(where: \.isPending) else {
            return nil
        }
        games[index].state = .running
        return (index, games[index].setup)
    }
}


// MARK: - Simulating

extension Simulator {
    @concurrent
    private static func simulateGame(
        index: Int,
        setup: Setup,
        configuration: MCTSConfiguration,
        budgetPerTurn: MCTSBudget,
        determinizationsPerTurn: Int
    ) async -> (index: Int, result: Swift.Result<Result, MCTSError<Game>>, duration: Duration) {
        let clock = SuspendingClock()
        let startTime = clock.now
        var game = setup.newGame()
        do {
            while !game.isFinished {
                let move = try MCTS.bestMove(
                    for: game,
                    budget: budgetPerTurn,
                    configuration: configuration,
                    determinizations: determinizationsPerTurn
                )
                game.makeMove(move)
            }
            return (index, .success(Result(game)), startTime.duration(to: clock.now))
        } catch {
            return (index, .failure(error), startTime.duration(to: clock.now))
        }
    }
}
