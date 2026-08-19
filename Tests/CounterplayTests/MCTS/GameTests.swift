import Testing
import Counterplay

@Suite("Game")
struct GameTests {

    @Suite("Player order")
    struct PlayerOrder {

        @Test("The next player is the player after")
        func nextPlayer() {
            let game = TicTacToe(players: [.player1, .player3, .player2], currentPlayer: .player1)
            #expect(game.nextPlayer() == .player3)
            #expect(game.nextPlayer(after: .player1) == .player3)
            #expect(game.nextPlayer(after: .player3) == .player2)
        }

        @Test("The next player wraps around to the start")
        func nextPlayerWraps() {
            let game = TicTacToe(players: [.player1, .player3, .player2], currentPlayer: .player2)
            #expect(game.nextPlayer() == .player1)
            #expect(game.nextPlayer(after: .player2) == .player1)
        }

        @Test("The previous player is the player before")
        func previousPlayerBeforeGiven() {
            let game = TicTacToe(players: [.player1, .player3, .player2], currentPlayer: .player2)
            #expect(game.previousPlayer() == .player3)
            #expect(game.previousPlayer(before: .player2) == .player3)
            #expect(game.previousPlayer(before: .player3) == .player1)
        }

        @Test("The previous player wraps around to the end")
        func previousPlayerWraps() {
            let game = TicTacToe(players: [.player1, .player3, .player2], currentPlayer: .player1)
            #expect(game.previousPlayer() == .player2)
            #expect(game.previousPlayer(before: .player1) == .player2)
        }

        @Test("A player who isn't in the game has no next/previous player")
        func unknownPlayer() {
            let game = TicTacToe(players: [.player1, .player2], currentPlayer: .player1)
            #expect(game.nextPlayer(after: .player3) == nil)
            #expect(game.previousPlayer(before: .player3) == nil)
        }
    }
}
