import Testing
import Counterplay

@MainActor
private func waitUntil(timeout: Duration = .seconds(10), _ condition: () -> Bool) async -> Bool {
    let deadline = ContinuousClock.now + timeout
    while ContinuousClock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(1))
    }
    return condition()
}

@Suite("Runner")
struct RunnerTests {

    @Suite("Initialization")
    struct Initialization {

        @Test("Initialize with default parameters")
        func initWithDefaults() {
            let game = TicTacToe(players: [.player1, .player2])
            let runner = Runner(game: game)

            #expect(runner.game.players.contains(runner.player))
            #expect(runner.configuration == MCTSConfiguration())
            #expect(runner.budgetPerTurn == .iterations(1000))
            #expect(runner.determinizationsPerTurn == 1)
            #expect(runner.maxConcurrency >= 1)
            #expect(runner.isPlaying == false)
        }

        @Test("Initialize with custom parameters")
        func initWithCustomParameters() {
            let game = TicTacToe(players: [.player1, .player2])
            let runner = Runner(
                game: game,
                player: .player1,
                configuration: .init(maxPlayoutDepth: 50, explorationBias: 1),
                budgetPerTurn: .time(.milliseconds(250)),
                determinizationsPerTurn: 4,
                maxConcurrency: 2
            )

            #expect(runner.player == .player1)
            #expect(runner.configuration.maxPlayoutDepth == 50)
            #expect(runner.configuration.explorationBias == 1)
            #expect(runner.budgetPerTurn == .time(.milliseconds(250)))
            #expect(runner.determinizationsPerTurn == 4)
            #expect(runner.maxConcurrency == 2)
            #expect(runner.isPlaying == false)
        }

        @Test("Human player must be one of the game’s players")
        func rejectUnknownPlayer() async {
            await #expect(processExitsWith: .failure) {
                _ = Runner(
                    game: TicTacToe(players: [.player1, .player2], boardSize: 3),
                    player: .player3
                )
            }
        }

        @Test("Determinizations per turn cannot be zero")
        func rejectZeroDeterminizations() async {
            await #expect(processExitsWith: .failure) {
                _ = Runner(
                    game: TicTacToe(players: [.player1, .player2], boardSize: 3),
                    player: .player1,
                    determinizationsPerTurn: 0
                )
            }
        }

        @Test("Max concurrency cannot be zero")
        func rejectZeroConcurrency() async {
            await #expect(processExitsWith: .failure) {
                _ = Runner(
                    game: TicTacToe(players: [.player1, .player2], boardSize: 3),
                    player: .player1,
                    maxConcurrency: 0
                )
            }
        }
    }

    @Suite("State")
    struct State {

        @Test("It is the human player's turn")
        func isPlayerTurn() {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
            let runner = Runner(game: game, player: .player1)

            #expect(runner.isPlayerTurn == true)
        }

        @Test("It is not the human player's turn")
        func isNotPlayerTurn() {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(game: game, player: .player1)

            #expect(runner.isPlayerTurn == false)
        }

        @Test("It is not the human player's turn when the game is finished")
        func isNotPlayerTurnWhenFinished() {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, .player1],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])
            let runner = Runner(game: game, player: .player1)

            #expect(runner.isPlayerTurn == false)
        }
    }

    @Suite("Playing")
    struct Playing {

        @Test("Plays until it is the human player's turn")
        func playsUntilPlayerTurn() async {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.play()

            #expect(runner.game.moveCount == 1)
            #expect(runner.game.board.any { $0.any { $0 == .player2 } } == true)
            #expect(runner.game.currentPlayer == .player1)
            #expect(runner.isPlaying == false)
            #expect(runner.isPlayerTurn == true)
        }

        @Test("Plays to the end of the game")
        func playsToGameEnd() async {
            let runner = Runner(
                game: TicTacToe(
                    players: [.player1, .player2, .player3], currentPlayer: .player1,
                    board: [
                        [.player1, .player1, nil],
                        [.player2, .player2, nil],
                        [.player3, .player3, nil],
                    ]),
                player: .player2
            )

            await runner.play()

            #expect(runner.game.isFinished == true)
            #expect(runner.isPlayerTurn == false)
            #expect(runner.isPlaying == false)
        }

        @Test("Plays every computer player before handing back to the human player")
        func playsAllComputerPlayers() async {
            let game = TicTacToe(players: [.player1, .player2, .player3], currentPlayer: .player2)
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.play()

            #expect(runner.game.moveCount == 2)
            #expect(runner.game.currentPlayer == .player1)
        }

        @Test("Playing does nothing when it is the human player's turn")
        func playDoesNothingOnPlayerTurn() async {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.play()

            #expect(runner.game.moveCount == 0)
            #expect(runner.isPlayerTurn == true)
        }

        @Test("Playing does nothing when the game is finished")
        func playDoesNothingWhenFinished() async {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player2,
                board: [
                    [.player1, .player1, .player1],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.play()

            #expect(runner.game.moveCount == 5)
        }

        @Test("Plays within a time budget")
        func playsWithinTimeBudget() async {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(
                game: game,
                player: .player1,
                budgetPerTurn: .time(.milliseconds(50))
            )

            await runner.play()

            #expect(runner.game.moveCount == 1)
            #expect(runner.game.currentPlayer == .player1)
        }

        @Test("Plays with multiple determinizations per turn")
        func playsWithDeterminizations() async {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(
                game: game,
                player: .player1,
                budgetPerTurn: .iterations(100),
                determinizationsPerTurn: 4,
                maxConcurrency: 2
            )

            await runner.play()

            #expect(runner.game.moveCount == 1)
            #expect(runner.game.currentPlayer == .player1)
        }
    }

    @Suite("Making moves")
    struct MakingMoves {

        @Test("Making a move plays until it is the human player's turn again")
        func makeMovePlaysUntilPlayerTurn() async {
            let game = TicTacToe(players: [.player1, .player2, .player3], currentPlayer: .player1)
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.makeMove(TicTacToe.Move(x: 0, y: 0))

            #expect(runner.game.board[0][0] == .player1)
            #expect(runner.game.moveCount == 3)
            #expect(runner.game.board.any { $0.any { $0 == .player2 } } == true)
            #expect(runner.game.board.any { $0.any { $0 == .player3 } } == true)
            #expect(runner.game.currentPlayer == .player1)
            #expect(runner.isPlaying == false)
            #expect(runner.isPlayerTurn == true)
        }

        @Test("Making a move plays to the end of the game")
        func makeMovePlaysToGameEnd() async {
            let runner = Runner(
                game: TicTacToe(
                    players: [.player1, .player2, .player3], currentPlayer: .player1,
                    board: [
                        [.player1, .player1, nil],
                        [.player2, .player2, nil],
                        [.player3, .player3, nil],
                    ]),
                player: .player1
            )

            await runner.makeMove(.init(x: 2, y: 2))

            #expect(runner.game.board[2][2] == .player1)
            #expect(runner.game.board[1][2] == .player2)
            #expect(runner.game.winner == .player2)
            #expect(runner.game.isFinished == true)
            #expect(runner.isPlayerTurn == false)
            #expect(runner.isPlaying == false)
        }

        @Test("Making a move does nothing when it is not the human player's turn")
        func makeMoveOnComputerTurn() async {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.makeMove(TicTacToe.Move(x: 0, y: 0))

            #expect(runner.game.moveCount == 0)
        }

        @Test("Making a move does nothing when the game is finished")
        func makeMoveWhenFinished() async {
            let game = TicTacToe(
                players: [.player1, .player2], currentPlayer: .player1,
                board: [
                    [.player1, .player1, .player1],
                    [.player2, .player2, nil],
                    [nil, nil, nil],
                ])
            let runner = Runner(game: game, player: .player1, budgetPerTurn: .iterations(100))

            await runner.makeMove(TicTacToe.Move(x: 2, y: 1))

            #expect(runner.game.board[1][2] == nil)
            #expect(runner.game.moveCount == 5)
        }
    }

    @Suite("Cancellation")
    @MainActor
    struct Cancellation {
        @Test("Cancelling discards the evaluation in progress")
        func cancelDiscardsInProgressEvaluation() async throws {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player2)
            let runner = Runner(
                game: game,
                player: .player1,
                budgetPerTurn: .time(.seconds(2)),
                maxConcurrency: 1
            )

            let task = Task { await runner.play() }
            try #require(await waitUntil { runner.isPlaying })

            #expect(runner.game.currentPlayer == .player2)
            #expect(runner.game.moveCount == 0)

            task.cancel()
            await task.value

            #expect(runner.isPlaying == false)
            #expect(runner.game.currentPlayer == .player2)
            #expect(runner.game.moveCount == 0)
        }
    }
}
