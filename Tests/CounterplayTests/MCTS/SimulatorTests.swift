import Testing
import Counterplay

private typealias TicTacToeSimulator = Simulator<TicTacToe, TicTacToe.Setup, TicTacToe.Result>

/// A budget small enough that a whole simulation finishes quickly.
private let fastBudget = MCTSBudget.iterations(10)

/// A budget large enough that a simulation is still running when we look at it.
private let slowBudget = MCTSBudget.iterations(500_000)

private func manySetups(_ count: Int) -> [TicTacToe.Setup] {
    (0..<count).map { _ in TicTacToe.Setup(players: [.player1, .player2]) }
}


@Suite("Simulator")
struct SimulatorTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize with no setups")
        func initWithNoSetups() {
            let simulator = TicTacToeSimulator(setups: [])

            #expect(simulator.totalGames == 0)
            #expect(simulator.games.isEmpty == true)
            #expect(simulator.isRunning == false)
        }

        @Test("Initialize with setups")
        func initWithSetups() {
            let simulator = TicTacToeSimulator(
                setups: [
                    .init(players: [.player1, .player2]),
                    .init(players: [.player1, .player2, .player3], boardSize: 4),
                ],
                budgetPerTurn: fastBudget
            )

            #expect(simulator.totalGames == 2)
            #expect(simulator.completedGames == 0)
            #expect(simulator.isRunning == false)
            #expect(simulator.games.count == 2)
            #expect(simulator.games.all { $0.isPending } == true)
            #expect(simulator.games.map(\.id) == [0, 1])
            #expect(
                simulator.games.map(\.setup) == [
                    .init(players: [.player1, .player2]),
                    .init(players: [.player1, .player2, .player3], boardSize: 4),
                ])
        }

        @Test("Initialize with default parameters")
        func initWithDefaults() {
            let simulator = TicTacToeSimulator(setups: [.init(players: [.player1, .player2])])

            #expect(simulator.configuration == MCTSConfiguration())
            #expect(simulator.budgetPerTurn == .iterations(1000))
            #expect(simulator.determinizationsPerTurn == 1)
            #expect(simulator.maxConcurrency >= 1)
        }

        @Test("Initialize with custom parameters")
        func initWithCustomParameters() {
            let simulator = TicTacToeSimulator(
                setups: [.init(players: [.player1, .player2])],
                configuration: .init(maxPlayoutDepth: 50, explorationBias: 1),
                budgetPerTurn: .time(.milliseconds(250)),
                determinizationsPerTurn: 4,
                maxConcurrency: 2
            )

            #expect(simulator.configuration.maxPlayoutDepth == 50)
            #expect(simulator.configuration.explorationBias == 1)
            #expect(simulator.budgetPerTurn == .time(.milliseconds(250)))
            #expect(simulator.determinizationsPerTurn == 4)
            #expect(simulator.maxConcurrency == 2)
        }

        @Test("Determinizations per turn cannot be zero")
        func rejectZeroDeterminizations() async {
            await #expect(processExitsWith: .failure) {
                _ = TicTacToeSimulator(setups: [.init(players: [.player1, .player2])], determinizationsPerTurn: 0)
            }
        }

        @Test("Max concurrency cannot be zero")
        func rejectZeroConcurrency() async {
            await #expect(processExitsWith: .failure) {
                _ = TicTacToeSimulator(setups: [.init(players: [.player1, .player2])], maxConcurrency: 0)
            }
        }
    }

    @Suite("Simulated games")
    struct SimulatedGames {

        @Test("Pending game")
        func pendingGame() {
            let simulator = TicTacToeSimulator(setups: [.init(players: [.player1, .player2])])
            let game = simulator.games[0]

            #expect(game.isPending == true)
            #expect(game.isRunning == false)
            #expect(game.result == nil)
            #expect(game.duration == nil)
        }

        @Test("Completed game")
        func completedGame() async {
            let simulator = TicTacToeSimulator(
                setups: [.init(players: [.player1, .player2])],
                budgetPerTurn: fastBudget
            )

            await simulator.run()

            let game = simulator.games[0]
            #expect(game.isPending == false)
            #expect(game.isRunning == false)
            #expect(game.result != nil)
            #expect(game.duration != nil)
            #expect((game.duration ?? .zero) > .zero)
        }
    }

    @Suite("Running")
    struct Running {

        @Test("Plays every game to completion")
        func playsEveryGame() async {
            let setups = [
                TicTacToe.Setup(players: [.player1, .player2]),
                TicTacToe.Setup(players: [.player2, .player3]),
                TicTacToe.Setup(players: [.player1, .player2, .player3]),
            ]
            let simulator = TicTacToeSimulator(setups: setups, budgetPerTurn: fastBudget)

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 3)
            #expect(simulator.games.all { $0.result != nil })
            #expect(simulator.games.all { $0.isCompleted })
        }

        @Test("Results correspond to their setups")
        func resultsMatchSetups() async {
            let setups = [
                TicTacToe.Setup(players: [.player1, .player2], boardSize: 3),
                TicTacToe.Setup(players: [.player1, .player2, .player3], boardSize: 4),
            ]
            let simulator = TicTacToeSimulator(setups: setups, budgetPerTurn: fastBudget)

            await simulator.run()

            #expect(simulator.games[0].result?.players == [.player1, .player2])
            #expect(simulator.games[0].result?.boardSize == 3)
            #expect(simulator.games[1].result?.players == [.player1, .player2, .player3])
            #expect(simulator.games[1].result?.boardSize == 4)
        }

        @Test("Runs more games than the concurrency limit")
        func runsMoreGamesThanConcurrency() async {
            let simulator = TicTacToeSimulator(
                setups: manySetups(6),
                budgetPerTurn: fastBudget,
                maxConcurrency: 2
            )

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 6)
            #expect(simulator.games.all { $0.isCompleted })
        }

        @Test("Runs within a time budget")
        func runsWithinTimeBudget() async {
            let simulator = TicTacToeSimulator(
                setups: manySetups(2),
                budgetPerTurn: .time(.milliseconds(10))
            )

            await simulator.run()

            #expect(simulator.completedGames == 2)
            #expect(simulator.games.all { $0.isCompleted })
        }

        @Test("Running with no setups finishes immediately")
        func runWithNoSetups() async {
            let simulator = TicTacToeSimulator(setups: [])

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 0)
        }

        @Test("Running again after finishing does nothing")
        func runTwice() async {
            let simulator = TicTacToeSimulator(setups: manySetups(4), budgetPerTurn: fastBudget)

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 4)

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 4)
        }
    }

    @Suite("Cancellation")
    @MainActor
    struct Cancellation {
        @Test("Cancelling discards games in progress")
        func cancelDiscardsInProgressGames() async {
            let simulator = TicTacToeSimulator(
                setups: manySetups(4),
                budgetPerTurn: slowBudget
            )

            let task = Task { await simulator.run() }
            try? await Task.sleep(for: .milliseconds(50))

            #expect(simulator.isRunning == true)
            #expect(simulator.games.any { $0.isRunning } == true)
            #expect(simulator.completedGames == 0)

            task.cancel()
            await task.value

            #expect(simulator.isRunning == false)
            #expect(simulator.games.any { $0.isRunning } == false)
            #expect(simulator.completedGames == 0)
        }

        @Test("Cancelling keeps completed games")
        func cancelKeepsCompletedGames() async {
            let simulator = TicTacToeSimulator(
                setups: manySetups(2000),
                budgetPerTurn: fastBudget
            )

            let task = Task { await simulator.run() }
            try? await Task.sleep(for: .milliseconds(50))

            #expect(simulator.isRunning == true)
            #expect(simulator.games.any { $0.isRunning } == true)
            #expect(simulator.completedGames > 0)

            // However many games got done, cancelling must not throw them away
            let completedBeforeCancel = simulator.completedGames
            task.cancel()
            await task.value

            #expect(simulator.isRunning == false)
            #expect(simulator.games.any { $0.isRunning } == false)
            #expect(simulator.completedGames >= completedBeforeCancel)
        }
    }
}
