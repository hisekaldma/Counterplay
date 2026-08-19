import Foundation

public typealias GameModel = Game

/// An object that finds the best move in a game using Monte Carlo Tree Search.
///
/// The algorithm searches from a single root game state, building out a search tree
/// of possible future game states. The more search budget you give the algorithm,
/// the deeper the tree becomes, giving a clearer picture of which move from the root
/// state is the best.
///
/// Call `bestMove(for:budget:)` to find the best move from a given game state, and use
/// `MCTSBudget` to control how much work the search does:
///
///     let move = try MCTS.bestMove(for: game, budget: .time(.seconds(2)))
///
/// For games with hidden information, the `determinizations:` overloads run several searches
/// against randomized views of the state and aggregate the results.
///
/// Create an instance directly when you need to interleave searching and inspection, for example
/// to report progress. The tree is kept between calls, so searching again picks up where the
/// previous search left off:
///
///     let mcts = MCTS(game: game)
///     for _ in 0..<10 {
///         try mcts.search(budget: .time(.milliseconds(100)))
///         report(mcts.moves)
///     }
public final class MCTS<Game> where Game: GameModel {
    /// The parameters that the search runs with.
    public let configuration: MCTSConfiguration

    /// The root node of the search tree.
    @usableFromInline internal let root: Node

    /// Creates a new MCTS instance for the given game state.
    ///
    /// - Parameters:
    ///   - game: The game state to search from. Must not already be finished.
    ///   - configuration: The parameters to search with.
    ///
    /// - Precondition: `game` must not be finished.
    @inlinable
    public init(
        game: Game,
        configuration: MCTSConfiguration = .init()
    ) {
        precondition(!game.isFinished, "The game must not be finished")
        self.configuration = configuration
        self.root = Node(game: game)
    }

    deinit {
        // Tear the tree down iteratively. Releasing the root would otherwise
        // recurse once per level, overflowing the stack on deep trees.
        var pending: [Node] = [root]
        while let node = pending.popLast() {
            pending.append(contentsOf: node.children)
            node.children = []
        }
    }
}


// MARK: - Configuration

/// The parameters a Monte Carlo Tree Search runs with.
public struct MCTSConfiguration: Sendable, Equatable {
    /// The maximum number of moves to simulate the game by playing randomly.
    public var maxPlayoutDepth: Int

    /// The bias towards exploring new moves.
    public var explorationBias: Double

    /// Creates a new search configuration with the given parameters.
    ///
    /// - Parameters:
    ///   - maxPlayoutDepth: The maximum number of moves to make during a random
    ///     playout before calling `Game.outcome(for:)` to evaluate the result of the game.
    ///     The more informative your `.estimate(_)` heuristic is, the lower you can set this.
    ///     The default is 100.
    ///   - explorationBias: The UCB exploration constant. Higher values make
    ///     the search try a wider variety of moves; lower values make it focus
    ///     on moves that have already done well. The default of √2 is
    ///     appropriate for most games.
    ///
    /// - Precondition: `maxPlayoutDepth` must be non-negative.
    /// - Precondition: `explorationBias` must be non-negative and finite.
    public init(
        maxPlayoutDepth: Int = 100,
        explorationBias: Double = 2.squareRoot()
    ) {
        precondition(maxPlayoutDepth >= 0, "maxPlayoutDepth must be non-negative.")
        precondition(explorationBias >= 0, "explorationBias must be non-negative.")
        precondition(explorationBias.isFinite, "explorationBias must be finite.")
        self.maxPlayoutDepth = maxPlayoutDepth
        self.explorationBias = explorationBias
    }
}


// MARK: - Budget

/// How much work a Monte Carlo Tree Search should do before reporting the best move.
public enum MCTSBudget: Sendable, Equatable {
    /// Run a fixed number of iterations.
    case iterations(Int)

    /// Run for a fixed length of time.
    case time(Duration)
}


// MARK: - Errors

/// A reason a search stopped without producing a move.
public enum MCTSError<Game: GameModel>: Error, Sendable, Hashable {
    case cancelled
    case invalidGame(GameError<Game>)
}


// MARK: - Evaluating the best move

extension MCTS {
    /// Finds the best move for the current player within the given search budget.
    ///
    /// - Precondition: `game` must not be finished.
    /// - Precondition: `budget` must be greater than zero.
    @inlinable
    public static func bestMove(
        for game: Game,
        budget: MCTSBudget = .iterations(1000),
        configuration: MCTSConfiguration = .init()
    ) throws(MCTSError<Game>) -> Game.Move {
        let mcts = MCTS(game: game, configuration: configuration)
        try mcts.search(budget: budget)
        guard let move = mcts.bestMove else {
            fatalError("No move available.")
        }
        return move
    }

    /// Finds the best move using Perfect Information Monte Carlo.
    ///
    /// Runs `determinizations` independent searches against randomized views
    /// of the game state, and returns the move with the highest aggregated
    /// visit count. The budget applies to each search, so the total work scales
    /// with `determinizations`.
    ///
    /// For perfect-information games, `determinizations: 1` is equivalent to
    /// `bestMove(for:budget:configuration:)`.
    ///
    /// - Precondition: `game` must not be finished.
    /// - Precondition: `budget` must be greater than zero.
    /// - Precondition: `determinizations` must be at least 1.
    @inlinable
    public static func bestMove(
        for game: Game,
        budget: MCTSBudget = .iterations(1000),
        configuration: MCTSConfiguration = .init(),
        determinizations: Int
    ) throws(MCTSError<Game>) -> Game.Move {
        precondition(!game.isFinished, "The game must not be finished")
        precondition(determinizations > 0, "determinizations must be at least 1")

        var aggregatedVisits: [Game.Move: Int] = [:]

        // Run searches with different determinizations and aggregate their results
        for _ in 0..<determinizations {
            let determinizedGame = game.obscured()
            let mcts = MCTS(game: determinizedGame, configuration: configuration)
            try mcts.search(budget: budget)
            for (move, visits) in mcts.moves {
                aggregatedVisits[move, default: 0] += visits
            }
        }

        // Select the move with the highest aggregated visit count
        guard let move = aggregatedVisits.max(by: { $0.value < $1.value })?.key else {
            fatalError("No moves available.")
        }
        return move
    }

    /// Finds the best move using Perfect Information Monte Carlo,
    /// running `maxConcurrency` determinizations concurrently.
    ///
    /// Runs `determinizations` independent searches against randomized views
    /// of the game state, and returns the move with the highest aggregated
    /// visit count. The budget applies to each search, so the total work scales
    /// with `determinizations`.
    ///
    /// - Precondition: `game` must not be finished.
    /// - Precondition: `budget` must be greater than zero.
    /// - Precondition: `determinizations` must be at least 1.
    /// - Precondition: `maxConcurrency` must be at least 1.
    @concurrent
    public static func bestMove(
        for game: Game,
        budget: MCTSBudget = .iterations(1000),
        configuration: MCTSConfiguration = .init(),
        determinizations: Int,
        maxConcurrency: Int
    ) async throws(MCTSError<Game>) -> Game.Move {
        precondition(!game.isFinished, "The game must not be finished")
        precondition(determinizations > 0, "determinizations must be at least 1")
        precondition(maxConcurrency > 0, "maxConcurrency must be at least 1")

        var aggregatedVisits: [Game.Move: Int] = [:]

        // Concurrently run searches with different determinizations and aggregate their results
        do {
            try await withThrowingTaskGroup(of: [(move: Game.Move, visits: Int)].self) { group in
                // Prime the task group
                var started = Swift.min(maxConcurrency, determinizations)
                for _ in 0..<started {
                    group.addTask {
                        let determinizedGame = game.obscured()
                        let mcts = MCTS(game: determinizedGame, configuration: configuration)
                        try mcts.search(budget: budget)
                        return mcts.moves
                    }
                }

                // Drain and refill the task group
                for try await determinizationMoves in group {
                    for (move, visits) in determinizationMoves {
                        aggregatedVisits[move, default: 0] += visits
                    }
                    guard started < determinizations else { continue }
                    started += 1
                    group.addTask {
                        let determinizedGame = game.obscured()
                        let mcts = MCTS(game: determinizedGame, configuration: configuration)
                        try mcts.search(budget: budget)
                        return mcts.moves
                    }
                }
            }
        } catch let error as MCTSError<Game> {
            throw error
        } catch {
            // `search` is the only thing that throws here, and only ever a MCTSError
            fatalError("Unknown error: \(error)")
        }

        // Select the move with the highest aggregated visit count
        guard let move = aggregatedVisits.max(by: { $0.value < $1.value })?.key else {
            fatalError("No moves available.")
        }
        return move
    }

    /// The best move for the current player found so far.
    ///
    /// Non-`nil` once `search(budget:)` has completed at least once.
    @inlinable
    public var bestMove: Game.Move? {
        root.children
            .max(by: { $0.visits < $1.visits })?
            .move
    }

    /// Visit counts for each possible move for the current player. The higher the visit count, the better the move.
    @inlinable
    public var moves: [(move: Game.Move, visits: Int)] {
        root.children.compactMap { child in
            child.move.map { ($0, child.visits) }
        }
    }
}


// MARK: - Searching for the best move

#if canImport(os)
import os
@usableFromInline internal let signposter = OSSignposter(
    subsystem: "Counterplay",
    category: .pointsOfInterest
)
#endif // canImport(os)

extension MCTS {
    /// Runs the search within the given budget.
    ///
    /// The search tree is kept between calls, so searching again continues to build
    /// out the same tree rather than starting over.
    ///
    /// - Precondition: `budget` must be greater than zero.
    @inlinable
    public func search(budget: MCTSBudget) throws(MCTSError<Game>) {
        #if canImport(os)
        let signpost = signposter.beginInterval("Searching for the best move")
        defer { signposter.endInterval("Searching for the best move", signpost) }
        #endif

        switch budget {
        case .iterations(let iterations):
            precondition(iterations > 0, "iterations must be greater than zero.")
            try iterate(while: { $0 < iterations })
        case .time(let duration):
            precondition(duration > .zero, "duration must be greater than zero.")
            let clock = SuspendingClock()
            let startTime = clock.now
            try iterate(while: { _ in clock.now - startTime < duration })
        }
    }

    @inlinable
    internal func iterate(while shouldContinue: (Int) -> Bool) throws(MCTSError<Game>) {
        // Always perform at least one iteration
        var iteration = 0
        repeat {
            do {
                try iterate()
            } catch {
                throw .invalidGame(error)
            }
            if iteration % 100 == 0 && Task.isCancelled {
                throw .cancelled
            }
            iteration += 1
        } while shouldContinue(iteration)
    }

    @inlinable
    internal func iterate() throws(GameError<Game>) {
        // Perform one select-expand-playout-backpropagate iteration
        let leaf = select()
        let child = leaf.game.isFinished ? leaf : try leaf.expand()
        let rewards = try child.playout(maxPlayoutDepth: configuration.maxPlayoutDepth)
        child.backpropagate(rewards: rewards)
    }

    @inlinable
    internal func select() -> Node {
        var node = root
        while node.untriedMoves.isEmpty, let child = node.bestChild(explorationBias: configuration.explorationBias) {
            node = child
        }
        return node
    }
}


// MARK: - Node

extension MCTS {
    @usableFromInline internal final class Node {
        @usableFromInline internal unowned let parent: Node?
        @usableFromInline internal var children: [Node] = []
        @usableFromInline internal let move: Game.Move?
        @usableFromInline internal let game: Game
        @usableFromInline internal var untriedMoves: [Game.Move]
        @usableFromInline internal var rewards: SIMD8<Double> = .zero
        @usableFromInline internal var visits: Int = 0

        @inlinable
        internal init(game: Game) {
            self.parent = nil
            self.move = nil
            self.game = game
            self.untriedMoves = game.possibleMoves
        }

        @inlinable
        internal init(parent: Node, move: Game.Move) {
            let game = parent.game.makingMove(move)
            self.parent = parent
            self.move = move
            self.game = game
            self.untriedMoves = game.possibleMoves
        }
    }
}

extension MCTS.Node {
    @inlinable
    internal var path: [Game.Move] {
        var path = sequence(first: self, next: \.parent).compactMap(\.move)
        path.reverse()
        return path
    }

    @inlinable
    internal func expand() throws(GameError<Game>) -> MCTS.Node {
        // There must be possible moves, unless the game is finished
        if untriedMoves.isEmpty {
            throw .noPossibleMoves(after: path)
        }

        // Choose a random untried move
        let count = untriedMoves.count
        untriedMoves.swapAt(Int.random(in: 0..<count), count - 1)
        let move = untriedMoves.removeLast()

        // Expand that move
        let childNode = MCTS.Node(parent: self, move: move)
        children.append(childNode)
        return childNode
    }

    @inlinable
    internal func playout(maxPlayoutDepth: Int) throws(GameError<Game>) -> SIMD8<Double> {
        var depth = 0
        var game = game
        var moves: [Game.Move] = []
        while !game.isFinished && depth < maxPlayoutDepth {
            guard let move = game.possibleMoves.randomElement() else {
                throw .noPossibleMoves(after: path + moves)
            }
            moves.append(move)
            game.makeMove(move)
            depth += 1
        }
        return game.outcomeRewards()
    }

    @inlinable
    internal func backpropagate(rewards: SIMD8<Double>) {
        var next: MCTS.Node? = self
        while let node = next {
            node.rewards += rewards
            node.visits += 1
            next = node.parent
        }
    }

    @inlinable
    internal func bestChild(explorationBias: Double) -> MCTS.Node? {
        let player = game.currentPlayer
        let parentVisits = visits
        var bestChild: MCTS.Node? = nil
        var bestUCB = -Double.infinity
        for child in children {
            let ucb = child.ucb(for: player, parentVisits: parentVisits, explorationBias: explorationBias)
            if ucb > bestUCB {
                bestUCB = ucb
                bestChild = child
            }
        }
        return bestChild
    }

    @inlinable
    internal func ucb(for player: Game.Player, parentVisits: Int, explorationBias: Double) -> Double {
        guard visits > 0 else { return .infinity }
        let visits = Double(visits)
        let parentVisits = Double(parentVisits)
        let exploitation = Double(rewards[player]) / visits
        let exploration = (log(parentVisits) / visits).squareRoot()
        return exploitation + explorationBias * exploration
    }
}


// MARK: - Extensions

extension Game {
    @inlinable
    internal func outcomeRewards() -> SIMD8<Double> {
        var rewards: SIMD8<Double> = .zero
        for player in players {
            rewards[player] = outcome(for: player).reward
        }
        return rewards
    }
}

extension SIMD8 {
    @inlinable
    internal subscript<Key>(key: Key) -> Scalar where Key: SmallRawUInt8 {
        get { self[key.scalarIndex] }
        set { self[key.scalarIndex] = newValue }
    }
}
