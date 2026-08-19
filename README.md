# Counterplay

**A Swift package for simulating and playtesting board games using Monte Carlo Tree Search.**

Monte Carlo Tree Search (MCTS) is a game-playing algorithm that picks moves by playing out many random simulated games from the current position and choosing the move that won most often across those simulations. It needs no hand-written strategy — only the rules of the game — which makes it well-suited to the prototyping phase of game design, when the rules change often.

This package contains a small, composable set of protocols for modeling turn-based games, and an MCTS engine that can play games using those protocols. It is designed for prototyping board games with player counts from 1 to 8 players, and supports games with hidden information.

Besides the core MCTS algorithm for playing games, the package also contains data structures for efficiently modeling common things like dice, cards, boards, tiles, and resources.

> [!NOTE]
> Counterplay is a personal project in its early stages. I built it for prototyping my own board games, so the API reflects what I've needed so far. Expect things to change as I use it to prototype more games.

## Requirements

- Swift 6.2 or later
- iOS 26 or later
- macOS 26 or later

## Installation

Add Counterplay to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/hisekaldma/counterplay.git", from: "0.0.1")
]
```

Then add `"Counterplay"` to your target’s dependencies.

## Quick start

To use Counterplay, implement the rules of your game as a struct that represents the current game state. Here’s tic-tac-toe:

```swift
import Counterplay

struct TicTacToe: Game {
    enum Player: UInt, Hashable, SmallRawUInt8 {
        case x, o
    }

    struct Move: Sendable, Hashable {
        var x: Int
        var y: Int
    }

    let players: [Player]
    private(set) var currentPlayer: Player
    private(set) var board: [[Player?]]

    init(
        players: [Player] = [.x, .o],
        currentPlayer: Player = .x,
        board: [[Player?]] = [[nil, nil, nil], [nil, nil, nil], [nil, nil, nil]]
    ) {
        self.players = players
        self.currentPlayer = currentPlayer
        self.board = board
    }

    var possibleMoves: [Move] {
        (0..<3).flatMap { y in
            (0..<3).compactMap { x in
                board[y][x] == nil ? Move(x: x, y: y) : nil
            }
        }
    }

    mutating func makeMove(_ move: Move) {
        board[move.y][move.x] = currentPlayer
        currentPlayer = (currentPlayer == .x) ? .o : .x
    }

    mutating func obscure() {
        // Perfect-information game — nothing to hide
    }

    private var winner: Player? {
        let lines: [[Player?]] =
            (0..<3).map { y in (0..<3).map { x in board[y][x] } } +
            (0..<3).map { x in (0..<3).map { y in board[y][x] } } +
            [(0..<3).map { i in board[i][i] },
             (0..<3).map { i in board[i][2 - i] }]
        for line in lines {
            if let first = line[0], line.allSatisfy({ $0 == first }) { return first }
        }
        return nil
    }

    var isFinished: Bool {
        winner != nil || board.allSatisfy { row in row.allSatisfy { $0 != nil } }
    }

    func outcome(for player: Player) -> Outcome {
        switch winner {
        case player:  return .win
        case .some:   return .loss
        case nil:     return isFinished ? .tie : .estimate(0.5)
        }
    }
}
```

Then ask the MCTS algorithm for the best move:

```swift
let game = TicTacToe()
let move = try MCTS.bestMove(for: game, budget: .iterations(1_000))
```

## Modeling your game

### The `Game` protocol

Model your game as a value type that conforms to the `Game` protocol. The protocol covers everything MCTS needs to play your game: who the players are, whose turn it is, what moves are available, how a move changes the state, when the game is over, and who wins/loses.

```swift
enum Player: UInt, Hashable, SmallRawUInt8 {
    case blue, red, green, yellow
}

struct CardGame: Game {
    enum Move: Sendable, Hashable {
        case playCard(Card)
        case drawCard
        case endTurn
    }

    let players: [Player]
    var currentPlayer: Player

    var possibleMoves: [Move] {
        // Return every move the current player is allowed to make
    }

    mutating func makeMove(_ move: Move) {
        // Apply the given move to the game state, advancing to the next player when appropriate
    }

    mutating func obscure() {
        // Randomize anything that the current player can't see (opponents' hands, deck order, etc.)
    }

    var isFinished: Bool {
        // Return true once the game has ended
    }

    func outcome(for player: Player) -> Outcome {
        // Return the result for the given player: .win, .loss, .tie, or .estimate(_) while in progress
    }
}
```

**Split multi-choice turns into multiple moves.** If a player can make multiple decisions on a single turn — play a card then play another card, or play a card then choose a target — model each one as a separate `Move` and only advance `currentPlayer` after the final one. Combining everything into a single compound `Move` works in principle, but it increases the branching factor and quickly overwhelms the search. Splitting the decisions keeps the branching factor small and lets MCTS evaluate each choice on its own merits.

### `Outcome`

An `Outcome` describes how the game is going for a player at a given moment:

- `.win` — the player has won.
- `.loss` — the player has lost.
- `.tie` — the game ended in a tie for the player.
- `.estimate(Double)` — the game is still in progress, with an associated value between 0 and 1 estimating the player’s chance of winning from here.

`outcome(for:)` is called both during the game and when it has ended. When the game has ended, return one of `.win`, `.loss`, or `.tie`. Before the game has ended, return `.estimate(_)` with your best estimate of the player’s probability of winning — for example, the player’s current score divided by the score needed to win, or simply `0.5` if you have no useful estimate.

The estimate is used by the MCTS algorithm to determine which moves to explore, so a more informative estimate produces stronger play. A flat 0.5 is always valid as a starting point — it tells the algorithm nothing, so MCTS must discover how good a move is from random playouts alone. For shorter games this is usually fine. For longer games where playouts hit `maxPlayoutDepth` before finishing, a heuristic that tracks genuine progress through the game can substantially reduce the iterations needed for strong play.

## Finding the best move

The `MCTS` class runs the MCTS algorithm to find the best move for the given game state. Use the static helpers for one-shot evaluation:

```swift
let move = try MCTS.bestMove(for: game, budget: .iterations(10_000))
```

Or drive it manually for finer control. The search tree is kept between calls, so searching again continues to build out the same search tree:

```swift
let mcts = MCTS(game: game)
try mcts.search(budget: .iterations(10_000))
let move = mcts.bestMove
```

The search budget is given as an `MCTSBudget`, either a number of iterations or a length of time:

```swift
let move = try MCTS.bestMove(for: game, budget: .time(.seconds(2)))
```

More iterations or more time means stronger play.

How the tree itself is built is controlled by `MCTSConfiguration`:

```swift
let move = try MCTS.bestMove(
    for: game,
    budget: .iterations(10_000),
    configuration: .init(maxPlayoutDepth: 50, explorationBias: 1)
)
```

- `maxPlayoutDepth` — cap on random playout length (default 100). Once a playout reaches this depth without finishing, it returns the current `outcome(for:)` value instead of continuing. The better your outcome probability values are at estimating a player’s genuine probability of winning, the lower you can set this.
- `explorationBias` — how widely the algorithm spreads its search (default √2). Higher values make the algorithm try a wider variety of moves; lower values make it focus on moves that have already done well. The default is appropriate for most games.

## Playing the game

MCTS only finds the best move for a given game state. To actually play the game, you also need to apply that move and orchestrate players taking turns until the game is finished. The package contains two classes that can help with this: `Runner` and `Simulator`.

### `Runner` — interactive play

The `Runner` class lets you create an interactive version of the game with one human player, and the rest computer players. This is useful for playtesting the game yourself against the computer.

```swift
let runner = Runner(
    game: CardGame(players: [.blue, .red, .green]),
    player: .blue,
    budgetPerTurn: .iterations(10_000)
)

// Play computer players’ turns
await runner.play()

// Play human player’s turn
await runner.makeMove(.playCard(.knight))
```

`makeMove(_:)` applies the human player's move and then takes turns for the computer players, returning when it is the human player's turn again or the game has finished. Observe `runner.isPlayerTurn` to know when the human player can move, and `runner.isPlaying` to know when the computer players are thinking.

### `Simulator` — simulated play

The `Simulator` class lets you simulate many playthroughs of the game with computer players only. This is useful for testing how changes to the game affect things like game length and balance.

To use the `Simulator` you need two supporting types: one that describes the starting conditions for a game (conforming to `GameSetup`), and one that captures what you want to record when it finishes (conforming to `GameResult`). The simulator takes an array of starting conditions and plays one game for each.

```swift
struct CardGameSetup: GameSetup {
    var players: [Player]
 
    func newGame() -> CardGame {
        CardGame(players: players)
    }
}

struct CardGameResult: GameResult {
    var turnCount: Int
    var roundCount: Int
    var scores: [Player: Int]
 
    init(_ game: CardGame) {
        self.turnCount = game.currentTurn
        self.roundCount = game.currentRound
        self.scores = game.scores
    }
}

// Every combination of 2–4 players from the four available.
let setups: [CardGameSetup] = [
    [.blue, .red],
    [.blue, .green],
    [.blue, .yellow],
    [.red, .green],
    [.red, .yellow],
    [.green, .yellow],
    [.blue, .red, .green],
    [.blue, .red, .yellow],
    [.blue, .green, .yellow],
    [.red, .green, .yellow],
    [.blue, .red, .green, .yellow],
].map { CardGameSetup(players: $0) }

let simulator = Simulator<CardGame, CardGameSetup, CardGameResult>(
    setups: setups,
    budgetPerTurn: .iterations(10_000)
)

await simulator.run()

// Observe `simulator.games`, `simulator.completedGames`, `simulator.isRunning`.
```

## Handling hidden information

Both `Runner` and `Simulator` support playing games with hidden information. To properly hide information that the computer players shouldn’t have access to, you need to do two things:

1. **Implement `obscure()`**. This method should randomize anything that the current player can't see. The idea is to throw away anything the player doesn't know — opponents' hands, the order of the deck — and replace it with a plausible random arrangement consistent with what they do know. It must not change `currentPlayer` or `possibleMoves`: the current player can see their own hidden state, so it must not be randomized, even though it is hidden from every other player.

```swift
mutating func obscure() {
    // Add opponents' hands to the deck
    for opponent in players where opponent != currentPlayer {
        deck.cards.append(contentsOf: playerStates[opponent]!.hand)
    }
    
    // Shuffle the deck
    deck.shuffle()
    
    // Draw new hands for opponents from the shuffled deck
    for opponent in players where opponent != currentPlayer {
        playerStates[opponent]!.hand = deck.draw(count: playerStates[opponent]!.hand.count)
    }
}
```

2. **Set `determinizationsPerTurn` to 10 or more.** `Runner` and `Simulator` use an approach called Perfect Information Monte Carlo (PIMC) to handle hidden information. Before evaluating the best move for a computer player, they call `obscure()` to produce a determinization — one plausible random arrangement of the hidden information. They then run a separate MCTS search against each determinization, and aggregate results across all of them. `determinizationsPerTurn` controls how many determinizations to run per turn. The higher you set this, the more “alternative worlds” the algorithm will explore.

The budget applies to each determinization, so the total work per turn is `budgetPerTurn` multiplied by `determinizationsPerTurn`.

```swift
let simulator = Simulator<CardGame, CardGameSetup, CardGameResult>(
    setups: setups,
    budgetPerTurn: .iterations(2_000),
    determinizationsPerTurn: 10
)
await simulator.run()
```

## Modeling game states

Besides the core protocols for modeling game rules, the package also includes standard data structures that are useful when modeling game states and common game components.

### `Deck`

A deck with a built-in discard pile. Cards are ordered bottom to top, so the last one added is the first one drawn. Automatically reshuffles the discard pile when the deck is empty.

```swift
var deck: Deck<Card> = [.knight, .knight, .victoryPoint, /* ... */]
deck.shuffle()
let card = deck.draw()
deck.discard(card!)
```

### `Die`

A die with arbitrary face values, plus presets for the standard polyhedral dice.

```swift
let roll = Die<Int>.d6.roll()
let custom = Die(faces: ["sword", "shield", "blank"]).roll()
```

### `SquareGrid`

A square grid with fixed dimensions. Perfect for games with chess-like boards and tile-laying games with polyominoes.
 
```swift
enum Piece {
    case white(PieceType)
    case black(PieceType)
}
 
var board = SquareGrid<8, 8, Piece?>(repeating: nil)
board[x: 4, y: 0] = .white(.king)
board[x: 4, y: 7] = .black(.king)
 
print(board[x: 4, y: 4]) // nil
print(board[x: 4, y: 0]) // .white(.king)
print(board[x: 4, y: 7]) // .black(.king)
```

### `PointyHexGrid` and `FlatHexGrid`
 
A hexagonal grid with fixed dimensions. Perfect for games with hex maps and tile-laying games with polyhexes. Use `PointyHexGrid` for hexes with a vertex at the top, or `FlatHexGrid` for hexes with a flat edge at the top.
 
```swift
var map = PointyHexGrid<5, 5, Terrain?>(repeating: nil)
map[q: 0, r: 0] = .forest
map[column: 1, row: 2] = .mountains
 
let adjacent = map.neighbors(of: .init(0, 0))
```

### `Tile`
 
A tile made of several square or hexagonal cells. `Polyomino` is a tile on a `SquareGrid` and `Polyhex` a tile on a `PointyHexGrid` or a `FlatHexGrid`. The size parameter is the most cells a tile can have, so a `Polyomino<3, ...>` is a monomino, a domino, or a triomino.
 
```swift
var domino: Polyomino<2, Int> = [
    .init(0, 0): 1,
    .init(1, 0): 2,
]

domino.rotate()

grid.place(domino, at: .init(3, 1))
```

### `Graph`

An immutable graph of nodes, edges, and faces — enough to represent more complex game boards. Think of nodes as positions, edges as the connections between them, and faces as the regions enclosed by edges. Adjacency lookups are precomputed at init to save time when calculating possible moves.

```swift
enum Intersection: Int, Hashable, Comparable {
    case north, northEast, southEast, south, southWest, northWest
    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}
 
enum Terrain {
    case forest, hills, pasture, fields, mountains, desert
}
 
enum Route {
    case road
    case river
}
 
// A single hex tile: six intersections around a terrain face, joined by six routes.
let board = Graph<Intersection, Route, Terrain>(
    nodes: [.north, .northEast, .southEast, .south, .southWest, .northWest],
    edges: [
        (.north,     .northEast): .river,
        (.northEast, .southEast): .river,
        (.southEast, .south):     .road,
        (.south,     .southWest): .road,
        (.southWest, .northWest): .road,
        (.northWest, .north):     .road,
    ],
    faces: [
        [.north, .northEast, .southEast, .south, .southWest, .northWest]: .forest,
    ]
)
 
// Routes connected to an intersection
let routes = board.edges(from: .north)
 
// Terrain tiles touching an intersection
let tiles = board.faces(adjacentTo: .north)
```

### `SmallSet` and `SmallCountedSet`

Inline collections for things like tags, suits and resources. Conform your enums to one of the `SmallRawUInt` protocols to use them with `SmallSet` and `SmallCountedSet`. Unlike Swift’s standard `Set` and `Dictionary`, these collections are stored inline and don’t incur any reference-counting overhead, making them ideal for the kind of small-but-frequently-accessed collections that show up everywhere in game state.

```swift
enum Tag: UInt, SmallRawUInt8 {
    case farming, science, culture, military
}

enum Resource: UInt, SmallRawUInt8 {
    case lumber, wool, grain, brick, ore
}

var tags: SmallSet<Tag> = [.farming, .science]
var cost: SmallCountedSet<Resource> = [.lumber, .ore, .ore]
```

**Use the smallest `SmallRawUInt` variant for your enum.** Backing storage scales with the bound, so `SmallRawUInt8` is the cheapest — reach for the larger protocols only when you genuinely need more than 8 cases.

| Protocol         | Max cases | `SmallSet` storage | `SmallCountedSet` storage |
|------------------|-----------|--------------------|---------------------------|
| `SmallRawUInt8`  | 8         | `UInt8`            | `SIMD8<UInt16>`           |
| `SmallRawUInt16` | 16        | `UInt16`           | `SIMD16<UInt16>`          |
| `SmallRawUInt32` | 32        | `UInt32`           | `SIMD32<UInt16>`          |
| `SmallRawUInt64` | 64        | `UInt64`           | `SIMD64<UInt16>`          |

### `InlineMap`

An inline fixed-size key-value storage, for when a set isn’t enough. Perfect for storing the state of each player:

```swift
enum Player: UInt, SmallRawUInt8 {
    case blue, red, green, yellow
}

struct CardGameState {
    var playerStates: InlineMap<4, Player, PlayerState>
}

struct PlayerState {
    var hand: [Card]
    var resources: SmallCountedSet<Resource>
}
```

The size parameter is a compile-time constant and sets the exact number of entries you'll store. Key must conform to `SmallRawUInt8`.
