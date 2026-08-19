extension Array where Element: Equatable {
    /// Removes the first occurrence of the given element from the array, and returns
    /// the element if it was removed, or nil if the element wasn’t in the array.
    ///
    /// Typically used to remove a card from hand. For example:
    ///
    ///     var hand: [Int] = [1, 2, 3]
    ///     let removed = hand.remove(1)
    ///     print(hand) // [2, 3]
    ///     print(removed) // 1
    @discardableResult
    @inlinable
    public mutating func remove(_ element: Element) -> Element? {
        guard let index = self.firstIndex(of: element) else {
            return nil
        }
        self.remove(at: index)
        return element
    }
}
