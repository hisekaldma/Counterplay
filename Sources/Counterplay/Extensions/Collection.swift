extension BidirectionalCollection {
    @inlinable
    internal var lastIndex: Index {
        index(before: endIndex)
    }

    @inlinable
    internal func index(afterWithWrapping i: Index) -> Index {
        guard !isEmpty else { return endIndex }
        if i < lastIndex {
            return index(after: i)
        } else {
            return startIndex
        }
    }

    @inlinable
    internal func index(beforeWithWrapping i: Index) -> Index {
        guard !isEmpty else { return startIndex }
        if i > startIndex {
            return index(before: i)
        } else {
            return lastIndex
        }
    }
}

extension BidirectionalCollection where Element: Equatable {
    @inlinable
    internal func element(beforeWithWrapping element: Element) -> Element? {
        guard let index = self.firstIndex(of: element) else {
            return nil
        }
        let indexBefore = self.index(beforeWithWrapping: index)
        return self[indexBefore]
    }

    @inlinable
    internal func element(afterWithWrapping element: Element) -> Element? {
        guard let index = self.firstIndex(of: element) else {
            return nil
        }
        let indexAfter = self.index(afterWithWrapping: index)
        return self[indexAfter]
    }
}
