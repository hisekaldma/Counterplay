// MARK: - Reductions

extension Sequence {
    /// Returns the sum of applying the given closure to all elements.
    @inlinable
    public func sum<T: AdditiveArithmetic>(of value: (Element) -> T) -> T {
        var result: T = .zero
        for element in self {
            result += value(element)
        }
        return result
    }

    /// Returns true if any element in the sequence satisfies the given predicate
    @inlinable
    public func any(_ predicate: (Element) -> Bool) -> Bool {
        for element in self {
            if predicate(element) {
                return true
            }
        }
        return false
    }

    /// Returns true if all elements in the sequence satisfy the given predicate
    @inlinable
    public func all(_ predicate: (Element) -> Bool) -> Bool {
        for element in self {
            if !predicate(element) {
                return false
            }
        }
        return true
    }
}


// MARK: - Sorting

#if canImport(Foundation)
import Foundation

extension Sequence {
    /// Returns the elements of the sequence sorted by the given property.
    @inlinable
    public func sorted<Value: Comparable>(
        by keyPath: KeyPath<Element, Value>,
        order: SortOrder = .forward
    ) -> [Element] {
        switch order {
        case .forward: self.sorted(by: { $0[keyPath: keyPath] < $1[keyPath: keyPath] })
        case .reverse: self.sorted(by: { $0[keyPath: keyPath] > $1[keyPath: keyPath] })
        }
    }
}

#endif // canImport(Foundation)


// MARK: - Min/max

extension Sequence {
    /// Returns the maximum value resulting from applying the given closure to all elements.
    @inlinable
    public func max<Value: Comparable>(of value: (Element) -> Value) -> Value? {
        var result: Value? = nil
        for element in self {
            let v = value(element)
            if let current = result {
                result = Swift.max(current, v)
            } else {
                result = v
            }
        }
        return result
    }

    /// Returns the minimum value resulting from applying the given closure to all elements.
    @inlinable
    public func min<Value: Comparable>(of value: (Element) -> Value) -> Value? {
        var result: Value? = nil
        for element in self {
            let v = value(element)
            if let current = result {
                result = Swift.min(current, v)
            } else {
                result = v
            }
        }
        return result
    }

    /// Returns the strict maximum element in the sequence, i.e. the element that is higher than ALL other elements, as compared by the given value.
    @inlinable
    public func strictMax<Value: Comparable>(by value: (Element) -> Value) -> Element? {
        var max: (element: Element, value: Value, unique: Bool)? = nil
        for element in self {
            let value = value(element)
            if let previousMax = max {
                if value > previousMax.value {
                    max = (element, value, true)
                } else if value == previousMax.value {
                    max = (element, value, false)
                }
            } else {
                max = (element, value, true)
            }
        }
        if let max, max.unique {
            return max.element
        } else {
            return nil
        }
    }

    /// Returns the strict minimum element in the sequence, i.e. the element that is lower than ALL other elements, as compared by the given value.
    @inlinable
    public func strictMin<Value: Comparable>(by value: (Element) -> Value) -> Element? {
        var min: (element: Element, value: Value, unique: Bool)? = nil
        for element in self {
            let value = value(element)
            if let previousMin = min {
                if value < previousMin.value {
                    min = (element, value, true)
                } else if value == previousMin.value {
                    min = (element, value, false)
                }
            } else {
                min = (element, value, true)
            }
        }
        if let min, min.unique {
            return min.element
        } else {
            return nil
        }
    }
}

