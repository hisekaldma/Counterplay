import Counterplay

struct TicTacToe: Game {
    let players: [Player]
    private(set) var board: [[Player?]]
    private(set) var currentPlayer: Player

    init(
        players: [Player],
        currentPlayer: Player? = nil,
        boardSize: Int = 3
    ) {
        if let currentPlayer {
            precondition(players.contains(currentPlayer))
        }
        self.players = players
        self.board = Array(repeating: Array(repeating: nil, count: boardSize), count: boardSize)
        self.currentPlayer = currentPlayer ?? players.randomElement()!
    }

    init(
        players: [Player],
        currentPlayer: Player? = nil,
        board: [[Player?]]
    ) {
        if let currentPlayer {
            precondition(players.contains(currentPlayer))
        }
        precondition(board.allSatisfy { $0.count == board.count })
        self.players = players
        self.currentPlayer = currentPlayer ?? players.randomElement()!
        self.board = board
    }

    var possibleMoves: [Move] {
        var moves: [Move] = []
        for y in 0..<board.count {
            for x in 0..<board[y].count {
                if board[y][x] == nil {
                    moves.append(Move(x: x, y: y))
                }
            }
        }
        return moves
    }

    mutating func makeMove(_ move: Move) {
        guard board[move.y][move.x] == nil else { return }
        board[move.y][move.x] = currentPlayer
        if !isFinished {
            currentPlayer = nextPlayer()
        }
    }

    mutating func obscure() {
        // Perfect information
    }

    var isFinished: Bool {
        winner != nil || possibleMoves.isEmpty
    }

    func outcome(for player: Player) -> Outcome {
        if let winner = winner {
            return winner == player ? .win : .loss
        } else if isFinished {
            return .tie
        } else {
            return .estimate(0.5)
        }
    }

    var winner: Player? {
        let size = board.count

        // Check rows and columns
        for i in 0..<size {
            if let rowPlayer = board[i][0], board[i].allSatisfy({ $0 == rowPlayer }) {
                return rowPlayer
            }
            if let colPlayer = board[0][i], (0..<size).allSatisfy({ board[$0][i] == colPlayer }) {
                return colPlayer
            }
        }

        // Check diagonals
        if let diagonal1Player = board[0][0], (0..<size).allSatisfy({ board[$0][$0] == diagonal1Player }) {
            return diagonal1Player
        }
        if let diagonal2Player = board[0][size - 1], (0..<size).allSatisfy({ board[$0][size - $0 - 1] == diagonal2Player }) {
            return diagonal2Player
        }

        return nil
    }


    var moveCount: Int {
        board.reduce(0) { count, row in count + row.reduce(0) { $0 + ($1 == nil ? 0 : 1) } }
    }
}

extension TicTacToe {
    enum Player: UInt, Hashable, SmallRawUInt8 {
        case player1
        case player2
        case player3
    }
}

extension TicTacToe {
    struct Move: Equatable, Hashable {
        var x: Int
        var y: Int
    }
}

extension TicTacToe {
    struct Setup: GameSetup, Equatable {
        var players: [TicTacToe.Player]
        var boardSize: Int

        init(players: [TicTacToe.Player], boardSize: Int = 3) {
            self.players = players
            self.boardSize = boardSize
        }

        func newGame() -> TicTacToe {
            TicTacToe(players: players, boardSize: boardSize)
        }
    }

    struct Result: GameResult, Equatable {
        var players: [TicTacToe.Player]
        var winner: TicTacToe.Player?
        var moveCount: Int
        var boardSize: Int

        init(_ game: TicTacToe) {
            self.players = game.players
            self.winner = game.players.first { game.outcome(for: $0) == .win }
            self.moveCount = game.moveCount
            self.boardSize = game.board.count
        }
    }
}
