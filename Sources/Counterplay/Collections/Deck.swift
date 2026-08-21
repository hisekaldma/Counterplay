/// A deck with a built-in discard pile.
///
/// Cards are ordered bottom to top, so the last one added is the first one drawn.
public struct Deck<Card> {
    /// The cards in the deck.
    public var cards: [Card]

    /// The cards in the discard pile.
    public var discardPile: [Card]

    /// Creates a deck with the given cards and the given discard pile.
    @inlinable
    public init(cards: [Card] = [], discardPile: [Card] = []) {
        self.cards = cards
        self.discardPile = discardPile
    }

    /// Creates a deck with the given cards.
    @inlinable
    public init(cards: some Sequence<Card>) {
        self.cards = cards.map { $0 }
        self.discardPile = []
    }
}


// MARK: - Conformances

extension Deck: Equatable where Card: Equatable {
}

extension Deck: Hashable where Card: Hashable {
}

extension Deck: Sendable where Card: Sendable {
}


// MARK: - Creating decks

extension Deck: ExpressibleByArrayLiteral {
    @inlinable
    public init(arrayLiteral cards: Card...) {
        self.cards = cards
        self.discardPile = []
    }
}


// MARK: - Shuffling decks

extension Deck {
    /// Shuffles the cards in the deck (but not the cards in the discard pile).
    @inlinable
    public mutating func shuffle() {
        cards.shuffle()
    }

    /// Shuffles the cards in the discard pile into the deck.
    @inlinable
    public mutating func shuffleDiscardPileIntoDeck() {
        cards = (cards + discardPile).shuffled()
        discardPile = []
    }
}


// MARK: - Drawing cards

extension Deck {
    /// Draws a card from the deck and returns it.
    ///
    /// If the deck is empty, shuffles the discard pile to make a new deck.
    @inlinable
    public mutating func draw() -> Card? {
        if cards.isEmpty {
            let discardedCards = discardPile
            discardPile = []
            cards = discardedCards.shuffled()
        }
        return cards.popLast()
    }

    /// Draws the given number of cards from the deck and returns them.
    ///
    /// If the deck is empty, shuffles the discard pile to make a new deck.
    ///
    /// - Precondition: `count` must be non-negative
    @inlinable
    public mutating func draw(count: Int) -> [Card] {
        precondition(count >= 0, "count must be non-negative")
        var drawnCards: [Card] = []
        for _ in 0..<count {
            guard let card = draw() else {
                break
            }
            drawnCards.append(card)
        }
        return drawnCards
    }
}


// MARK: - Discarding cards

extension Deck {
    /// Puts the given card on the discard pile.
    @inlinable
    public mutating func discard(_ card: Card) {
        discardPile.append(card)
    }

    /// Puts the given cards on the discard pile.
    @inlinable
    public mutating func discard(_ cards: [Card]) {
        discardPile.append(contentsOf: cards)
    }
}


// MARK: - Removing cards

extension Deck where Card: Equatable {
    /// Removes the given card from the deck.
    @discardableResult
    @inlinable
    public mutating func remove(_ card: Card) -> Card? {
        cards.remove(card)
    }

    /// Removes the given card from the discard pile.
    @discardableResult
    @inlinable
    public mutating func removeDiscarded(_ card: Card) -> Card? {
        discardPile.remove(card)
    }
}


// MARK: - Count

extension Deck {
    /// The total number of cards in both the deck and the discard pile.
    @inlinable
    public var count: Int {
        cards.count + discardPile.count
    }
}
