import Testing
import Foundation
@testable import Counterplay

@Suite("MCTS")
struct MCTSTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize with default parameters")
        func initWithDefaults() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game)

            #expect(mcts.configuration.maxPlayoutDepth == 100)
            #expect(mcts.configuration.explorationBias == 2.squareRoot())
        }

        @Test("Initialize with custom parameters")
        func initWithCustomParameters() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game, configuration: .init(maxPlayoutDepth: 50, explorationBias: 1))

            #expect(mcts.configuration.maxPlayoutDepth == 50)
            #expect(mcts.configuration.explorationBias == 1)
        }

        @Test("The game must not be finished")
        func rejectFinishedGame() async {
            await #expect(processExitsWith: .failure) {
                let game = TicTacToe(
                    players: [.player1, .player2], currentPlayer: .player1,
                    board: [
                        [.player1, .player1, .player1],
                        [.player2, .player2, nil],
                        [nil, nil, nil],
                    ])
                _ = MCTS(game: game)
            }
        }
    }

    @Suite("Configuration")
    struct Configuration {

        @Test("Default configuration")
        func defaults() {
            let configuration = MCTSConfiguration()

            #expect(configuration.maxPlayoutDepth == 100)
            #expect(configuration.explorationBias == 2.squareRoot())
        }

        @Test("Max playout depth cannot be negative")
        func rejectNegativeMaxPlayoutDepth() async {
            await #expect(processExitsWith: .failure) {
                _ = MCTSConfiguration(maxPlayoutDepth: -1)
            }
        }

        @Test("Exploration bias cannot be negative")
        func rejectNegativeExplorationBias() async {
            await #expect(processExitsWith: .failure) {
                _ = MCTSConfiguration(explorationBias: -1)
            }
        }

        @Test("Exploration bias must be finite")
        func rejectInfiniteExplorationBias() async {
            await #expect(processExitsWith: .failure) {
                _ = MCTSConfiguration(explorationBias: .infinity)
            }
            await #expect(processExitsWith: .failure) {
                _ = MCTSConfiguration(explorationBias: .nan)
            }
        }
    }

    @Suite("Searching")
    struct Searching {

        @Test("Single iteration")
        func singleIteration() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game)

            try mcts.iterate()

            #expect(mcts.root.visits == 1)
            #expect(mcts.bestMove != nil)
            #expect(mcts.moves.count > 0)
        }

        @Test("Search within an iteration budget")
        func searchWithIterationBudget() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game)

            try mcts.search(budget: .iterations(100))

            #expect(mcts.root.visits == 100)
            #expect(mcts.bestMove != nil)
            #expect(mcts.moves.count > 0)
        }

        @Test("Search within a time budget")
        func searchWithTimeBudget() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game)

            try mcts.search(budget: .time(.milliseconds(100)))

            #expect(mcts.root.visits >= 100)
            #expect(mcts.bestMove != nil)
            #expect(mcts.moves.count > 0)
        }

        @Test("Search within a minimal iteration budget")
        func minimalIterationBudget() throws {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
            let mcts = MCTS(game: game)
            try mcts.search(budget: .iterations(1))
            #expect(mcts.bestMove != nil)
            #expect(mcts.moves.count == 1)
        }

        @Test("Search within a minimal time budget")
        func minimalTimeBudget() throws {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
            let mcts = MCTS(game: game)
            try mcts.search(budget: .time(.nanoseconds(1)))
            #expect(mcts.bestMove != nil)
            #expect(mcts.moves.count == 1)
        }

        @Test("Searching again continues the same tree")
        func searchingAgainContinuesTheTree() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])
            let mcts = MCTS(game: game)

            try mcts.search(budget: .iterations(500))
            let movesCount1 = mcts.moves.count

            try mcts.search(budget: .iterations(500))
            let movesCount2 = mcts.moves.count

            #expect(mcts.root.visits == 1000)
            #expect(mcts.bestMove != nil)
            #expect(movesCount2 >= movesCount1)
        }

        @Test("Iteration budget cannot be zero")
        func rejectZeroIterations() async {
            await #expect(processExitsWith: .failure) {
                let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
                try? MCTS(game: game).search(budget: .iterations(0))
            }
        }

        @Test("Time budget cannot be zero")
        func rejectZeroDuration() async {
            await #expect(processExitsWith: .failure) {
                let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
                try? MCTS(game: game).search(budget: .time(.zero))
            }
        }
    }

    @Suite("Best move")
    struct BestMove {

        @Test("Best move for obvious win")
        func bestMoveForObviousWin() async throws {
            // Player1 can win by placing at (2, 0)
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(for: game, budget: .iterations(1000))

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("Best move for preventing opponent win")
        func bestMoveForBlockingOpponentWin() async throws {
            // Player2 can win on next turn if Player1 doesn't block
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player2, .player2, nil],
                    [.player1, nil, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(for: game, budget: .iterations(1000))

            // Should block the opponent's winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }
    }

    @Suite("Moves")
    struct Moves {

        @Test("Moves list contains visit counts")
        func movesListContainsVisitCounts() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])

            let mcts = MCTS(game: game)
            try mcts.search(budget: .iterations(500))
            let moves = mcts.moves

            // Should have moves with visit counts
            #expect(moves.count > 0)

            // All visit counts should be positive
            for (_, visits) in moves {
                #expect(visits > 0)
            }

            // Total visits should be at least the iteration count
            let totalVisits = moves.reduce(0) { $0 + $1.visits }
            #expect(totalVisits > 0)
        }

        @Test("Moves list contains all possible moves after sufficient iterations")
        func movesListContainsAllPossibleMoves() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, nil, nil],
                    [nil, .player2, nil],
                    [nil, nil, nil],
                ])

            let mcts = MCTS(game: game)
            try mcts.search(budget: .iterations(10_000))
            let moves = mcts.moves

            // After enough iterations, should have tried all available moves
            #expect(moves.count == game.possibleMoves.count)
        }

        @Test("Best move has highest visit count")
        func bestMoveHasHighestVisitCount() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [nil, nil, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])

            let mcts = MCTS(game: game)
            try mcts.search(budget: .iterations(1000))
            let bestMove = mcts.bestMove
            let moves = mcts.moves

            // Find the visit count for the best move
            let bestMoveVisits = moves.first { $0.move == bestMove }?.visits
            #expect(bestMoveVisits != nil)

            // Best move should have the highest or tied for highest visit count
            let maxVisits = moves.max { $0.visits < $1.visits }?.visits
            #expect(bestMoveVisits == maxVisits)
        }
    }

    @Suite("Determinizations")
    struct Determinizations {

        @Test("Finds winning move with single determinization")
        func singleDeterminization() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(
                for: game,
                budget: .iterations(500),
                determinizations: 1
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("Finds winning move with multiple determinizations")
        func multipleDeterminizations() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(
                for: game,
                budget: .iterations(100),
                determinizations: 10
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("Finds winning move with concurrent determinizations")
        func concurrentDeterminizations() async throws {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])

            let move = try await MCTS.bestMove(
                for: game,
                budget: .iterations(100),
                determinizations: 10,
                maxConcurrency: 4
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("Determinizations cannot be zero")
        func rejectZeroDeterminizations() async {
            await #expect(processExitsWith: .failure) {
                let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
                _ = try? MCTS.bestMove(for: game, determinizations: 0)
            }
        }

        @Test("Max concurrency cannot be zero")
        func rejectZeroConcurrency() async {
            await #expect(processExitsWith: .failure) {
                let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
                _ = try? await MCTS.bestMove(for: game, determinizations: 1, maxConcurrency: 0)
            }
        }
    }

    @Suite("Player count")
    struct PlayerCount {

        @Test("1 player")
        func onePlayer() async throws {
            // One player game - player just needs to find winning moves
            let game = TicTacToe(
                players: [.player1], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [nil, nil, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(
                for: game,
                budget: .iterations(10_000),
                configuration: .init(maxPlayoutDepth: 0)
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("2 players")
        func twoPlayers() async throws {
            // Standard two-player game
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(
                for: game,
                budget: .iterations(10_000),
                configuration: .init(maxPlayoutDepth: 0)
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }

        @Test("3 players")
        func threePlayers() async throws {
            // Three-player game with winning opportunity
            let game = TicTacToe(
                players: [.player1, .player2, .player3], currentPlayer: .player1,
                board: [
                    [.player1, .player1, nil],
                    [.player2, .player3, nil],
                    [nil, nil, nil],
                ])

            let move = try MCTS.bestMove(
                for: game,
                budget: .iterations(10_000),
                configuration: .init(maxPlayoutDepth: 0)
            )

            // Should find the winning move
            #expect(move == TicTacToe.Move(x: 2, y: 0))
        }
    }

    @Suite("Errors")
    struct Errors {
        @Test("No possible moves from the start")
        func errorImmediately() async throws {
            let moves: [InvalidGame.Move] = []
            #expect(throws: MCTSError<InvalidGame>.invalidGame(.noPossibleMoves(after: moves))) {
                let mcts = MCTS(
                    game: InvalidGame(turnsLeft: 0),
                    configuration: .init(maxPlayoutDepth: 0)
                )
                try mcts.search(budget: .iterations(100))
            }
        }

        @Test("No possible moves during expansion")
        func errorDuringExpand() async throws {
            let moves: [InvalidGame.Move] = Array(repeating: .pass, count: 10)
            #expect(throws: MCTSError<InvalidGame>.invalidGame(.noPossibleMoves(after: moves))) {
                let mcts = MCTS(
                    game: InvalidGame(turnsLeft: 10),
                    configuration: .init(maxPlayoutDepth: 0)
                )
                try mcts.search(budget: .iterations(100))
            }
        }

        @Test("No possible moves during random playout")
        func errorDuringPlayout() async throws {
            let moves: [InvalidGame.Move] = Array(repeating: .pass, count: 500)
            #expect(throws: MCTSError<InvalidGame>.invalidGame(.noPossibleMoves(after: moves))) {
                let mcts = MCTS(
                    game: InvalidGame(turnsLeft: 500),
                    configuration: .init(maxPlayoutDepth: 1000)
                )
                try mcts.search(budget: .iterations(100))
            }
        }
    }

    @Suite("Teardown")
    struct Teardown {
        @Test("Releasing a deep tree doesn't overflow the stack")
        func deepTreeTeardown() async throws {
            await #expect(processExitsWith: .success) {
                await withCheckedContinuation { continuation in
                    let thread = Thread {
                        let depth = 2000
                        let mcts = MCTS(
                            game: DeepGame(turnsLeft: depth),
                            configuration: .init(maxPlayoutDepth: 0)
                        )
                        try! mcts.search(budget: .iterations(depth))
                        _ = consume mcts // Release the search tree
                        continuation.resume()
                    }
                    thread.stackSize = 64 * 4_096
                    thread.start()
                }
            }
        }
    }
}

/// A game that finishes after X turns, with exactly one legal move per turn.
private struct DeepGame: Game {
    enum Player: UInt, Hashable, SmallRawUInt8 { case player1 }
    enum Move: Sendable, Hashable { case pass }

    let players: [Player] = [.player1]
    let currentPlayer: Player = .player1
    var turnsLeft: Int

    var possibleMoves: [Move] { isFinished ? [] : [.pass] }
    mutating func makeMove(_ move: Move) { turnsLeft -= 1 }
    mutating func obscure() {}
    var isFinished: Bool { turnsLeft == 0 }
    func outcome(for player: Player) -> Outcome { isFinished ? .win : .estimate(0.5) }
}


/// A game that never finishes, with exactly one legal move per turn until turn X, after which there are no legal moves.
private struct InvalidGame: Game {
    enum Player: UInt, Hashable, SmallRawUInt8 { case player1 }
    enum Move: Sendable, Hashable { case pass }

    let players: [Player] = [.player1]
    let currentPlayer: Player = .player1
    var turnsLeft: Int

    var possibleMoves: [Move] { turnsLeft == 0 ? [] : [.pass] }
    mutating func makeMove(_ move: Move) { turnsLeft -= 1 }
    mutating func obscure() {}
    var isFinished: Bool { false }
    func outcome(for player: Player) -> Outcome { .estimate(0.5) }
}
