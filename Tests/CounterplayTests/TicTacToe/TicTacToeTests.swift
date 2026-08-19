import Testing
import Counterplay

@Suite("TicTacToe")
struct TicTacToeTests {
    @Test("Get possible moves")
    func possibleMoves() async throws {
        let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [.player1, .player2, nil],
            [.player1, .player2, nil],
            [nil,     nil,     nil]
        ])
        #expect(game.possibleMoves == [
            TicTacToe.Move(x: 2, y: 0),
            TicTacToe.Move(x: 2, y: 1),
            TicTacToe.Move(x: 0, y: 2),
            TicTacToe.Move(x: 1, y: 2),
            TicTacToe.Move(x: 2, y: 2),
        ])
    }

    @Test("Make a move")
    func makeMove() async throws {
        var game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [nil, nil, nil],
            [nil, nil, nil],
            [nil, nil, nil]
        ])
        game.makeMove(TicTacToe.Move(x: 0, y: 0))
        #expect(game.board[0][0] == .player1)
    }

    @Test("Outcome for ongoing game")
    func outcome() async throws {
        let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [.player1, .player2, nil],
            [.player1, .player2, nil],
            [nil,     nil,     nil]
        ])
        guard case .estimate = game.outcome(for: .player1) else {
            Issue.record("Expected estimate game outcome")
            return
        }
    }

    @Test("Win by completing a row")
    func winByRow() async throws {
        var game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [.player1, .player1, nil],
            [.player2, .player2, nil],
            [nil, nil, nil]
        ])
        game.makeMove(TicTacToe.Move(x: 2, y: 0))
        #expect(game.outcome(for: .player1) == .win)
        #expect(game.outcome(for: .player2) == .loss)
    }

    @Test("Win by completing a column")
    func winByColumn() async throws {
        var game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [.player1, .player2, nil],
            [.player1, .player2, nil],
            [nil,     nil,     nil]
        ])
        game.makeMove(TicTacToe.Move(x: 0, y: 2))
        #expect(game.outcome(for: .player1) == .win)
        #expect(game.outcome(for: .player2) == .loss)
    }

    @Test("Win by completing a diagonal")
    func winByDiagonal() async throws {
        var game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: [
            [.player1, .player2, nil],
            [.player2, .player1, nil],
            [nil,     nil,     nil]
        ])
        game.makeMove(TicTacToe.Move(x: 2, y: 2))
        #expect(game.outcome(for: .player1) == .win)
        #expect(game.outcome(for: .player2) == .loss)
    }

    @Test("Draw when board is full with no winner")
    func draw() async throws {
        let board: [[TicTacToe.Player?]] = [
            [.player1, .player2, .player1],
            [.player1, .player2, .player2],
            [.player2, .player1, .player1]
        ]
        let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1, board: board)
        #expect(game.isFinished == true)
        #expect(game.outcome(for: .player1) == .tie)
        #expect(game.outcome(for: .player2) == .tie)
    }
}
