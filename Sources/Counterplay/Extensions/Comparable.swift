extension Comparable {
    /// Clamps this value to be within the given range.
    @inlinable
    public mutating func clamp(to range: ClosedRange<Self>) {
        self = clamped(to: range)
    }

    /// Clamps this value to be within the given range.
    @inlinable
    public mutating func clamp(to range: PartialRangeFrom<Self>) {
        self = clamped(to: range)
    }

    /// Clamps this value to be within the given range.
    @inlinable
    public mutating func clamp(to range: PartialRangeThrough<Self>) {
        self = clamped(to: range)
    }

    /// Returns this value clamped to be within the given range.
    @inlinable
    public func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }

    /// Returns this value clamped to be within the given range.
    @inlinable
    public func clamped(to range: PartialRangeFrom<Self>) -> Self {
        max(self, range.lowerBound)
    }

    /// Returns this value clamped to be within the given range.
    @inlinable
    public func clamped(to range: PartialRangeThrough<Self>) -> Self {
        min(self, range.upperBound)
    }
}
