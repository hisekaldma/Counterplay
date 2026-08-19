import Testing
import Counterplay

@Suite("Deck")
struct DeckTests {
    @Test("Initialize empty deck")
    func initEmptyDeck() {
        let deck: Deck<Int> = []
        #expect(deck.cards == [])
        #expect(deck.discardPile == [])
    }

    @Test("Initialize deck with sequence")
    func initWithSequence() {
        let deck = Deck(cards: 1...3)
        #expect(deck.cards == [1, 2, 3])
        #expect(deck.discardPile == [])
    }

    @Test("Initialize deck with array literal")
    func initWithLiteral() {
        let deck: Deck<Int> = [1, 2, 3]
        #expect(deck.cards == [1, 2, 3])
        #expect(deck.discardPile == [])
    }

    @Test("Equatable")
    func equatable() {
        let deck1 = Deck(cards: [1, 2, 3], discardPile: [1])
        let deck2 = Deck(cards: [1, 2, 3], discardPile: [1])
        let deck3 = Deck(cards: [4, 5, 6], discardPile: [1])
        let deck4 = Deck(cards: [4, 5, 6], discardPile: [2])
        #expect(deck1 == deck2)
        #expect(deck1 != deck3)
        #expect(deck3 != deck4)
    }

    @Test("Hashable")
    func hashable() {
        let deck1 = Deck(cards: [1, 2, 3], discardPile: [1])
        let deck2 = Deck(cards: [1, 2, 3], discardPile: [1])
        let deck3 = Deck(cards: [4, 5, 6], discardPile: [1])
        let deck4 = Deck(cards: [4, 5, 6], discardPile: [2])
        #expect(Set([deck1, deck2]).count == 1)
        #expect(Set([deck1, deck3]).count == 2)
        #expect(Set([deck3, deck4]).count == 2)
    }

    @Test("Draw single card")
    func drawCard() {
        var deck: Deck<Int> = .init(cards: [1, 2, 3])
        let card = deck.draw()
        #expect(card == 3)
        #expect(deck.cards == [1, 2])
        #expect(deck.discardPile == [])
    }

    @Test("Draw card shuffles discard pile")
    func drawCardShufflesDiscardPile() {
        var deck: Deck<Int> = .init(cards: [], discardPile: [1, 1, 1])
        let card = deck.draw()
        #expect(card == 1)
        #expect(deck.cards == [1, 1])
        #expect(deck.discardPile == [])
    }

    @Test("Draw multiple cards")
    func drawCards() {
        var deck: Deck<Int> = .init(cards: [1, 2, 3])
        let cards = deck.draw(count: 3)
        #expect(cards == [3, 2, 1])
        #expect(deck.cards == [])
        #expect(deck.discardPile == [])
    }

    @Test("Draw multiple cards shuffles discard pile")
    func drawCardsShufflesDiscardPile() {
        var deck: Deck<Int> = .init(cards: [2, 3], discardPile: [1, 1, 1])
        let cards = deck.draw(count: 3)
        #expect(cards == [3, 2, 1])
        #expect(deck.cards == [1, 1])
        #expect(deck.discardPile == [])
    }

    @Test("Draw from empty deck")
    func drawFromEmptyDeck() {
        var deck: Deck<Int> = .init(cards: [])
        let card = deck.draw()
        #expect(card == nil)
        #expect(deck.cards == [])
    }

    @Test("Draw zero cards")
    func drawZeroCards() {
        var deck: Deck<Int> = .init(cards: [1, 2, 3])
        let cards = deck.draw(count: 0)
        #expect(cards == [])
        #expect(deck.cards == [1, 2, 3])
    }

    @Test("Draw count cannot be negative")
    func rejectNegativeDrawCount() async {
        await #expect(processExitsWith: .failure) {
            var deck: Deck<Int> = .init(cards: [1, 2, 3])
            _ = deck.draw(count: -1)
        }
    }

    @Test("Discard single card")
    func discardCard() {
        var deck: Deck<Int> = .init(cards: [2, 3])
        deck.discard(1)
        #expect(deck.cards == [2, 3])
        #expect(deck.discardPile == [1])
    }

    @Test("Discard multiple cards")
    func discardCards() {
        var deck: Deck<Int> = .init(cards: [3])
        deck.discard([1, 2])
        #expect(deck.cards == [3])
        #expect(deck.discardPile == [1, 2])
    }
}
