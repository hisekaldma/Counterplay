import Testing
import Counterplay

private typealias TicTacToeSimulator = Simulator<TicTacToe, TicTacToe.Setup, TicTacToe.Result>

@MainActor
private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(1))
    }
    return condition()
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
                budgetPerTurn: .iterations(10)
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
                budgetPerTurn: .iterations(10)
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
            let simulator = TicTacToeSimulator(setups: setups, budgetPerTurn: .iterations(10))

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
            let simulator = TicTacToeSimulator(setups: setups, budgetPerTurn: .iterations(10))

            await simulator.run()

            #expect(simulator.games[0].result?.players == [.player1, .player2])
            #expect(simulator.games[0].result?.boardSize == 3)
            #expect(simulator.games[1].result?.players == [.player1, .player2, .player3])
            #expect(simulator.games[1].result?.boardSize == 4)
        }

        @Test("Runs more games than the concurrency limit")
        func runsMoreGamesThanConcurrency() async {
            let simulator = TicTacToeSimulator(
                setups: (0..<6).map { _ in TicTacToe.Setup(players: [.player1, .player2]) },
                budgetPerTurn: .iterations(10),
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
                setups: (0..<2).map { _ in TicTacToe.Setup(players: [.player1, .player2]) },
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
            let simulator = TicTacToeSimulator(
                setups: (0..<4).map { _ in TicTacToe.Setup(players: [.player1, .player2]) },
                budgetPerTurn: .iterations(10)
            )

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 4)

            await simulator.run()

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 4)
        }
    }

    @Suite("Cancellation", .serialized)
    @MainActor
    struct Cancellation {

        @Test("Cancelling discards games in progress")
        func cancelDiscardsInProgressGames() async throws {
            let simulator = TicTacToeSimulator(
                setups: (0..<4).map { _ in TicTacToe.Setup(players: [.player1, .player2]) },
                budgetPerTurn: .time(.seconds(2)),
                maxConcurrency: 1
            )

            let task = Task { await simulator.run() }
            try #require(await waitUntil { simulator.isRunning })

            task.cancel()
            await task.value

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames == 0)
        }

        @Test("Cancelling keeps completed games")
        func cancelKeepsCompletedGames() async throws {
            let simulator = TicTacToeSimulator(
                setups: (0..<2000).map { _ in TicTacToe.Setup(players: [.player1, .player2]) },
                budgetPerTurn: .iterations(100),
                maxConcurrency: 1
            )

            let task = Task { await simulator.run() }
            try #require(await waitUntil { simulator.completedGames > 0 })

            let completedAtCancel = simulator.completedGames
            task.cancel()
            await task.value

            #expect(simulator.isRunning == false)
            #expect(simulator.completedGames >= completedAtCancel)
            #expect(simulator.completedGames < 50)
        }
    }
}
