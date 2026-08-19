extension Int {
    /// Increases this value by the given amount, but not past the given upper limit.
    ///
    /// - Precondition: `amount` must be non-negative.
    @inlinable
    public mutating func increase(by amount: Int, limit: Int) {
        precondition(amount >= 0, "amount must be non-negative")
        let (sum, overflow) = addingReportingOverflow(amount)
        self = (overflow || sum > limit) ? limit : sum
    }

    /// Decreases this value by the given amount, but not past the given lower limit.
    ///
    /// - Precondition: `amount` must be non-negative.
    @inlinable
    public mutating func decrease(by amount: Int, limit: Int) {
        precondition(amount >= 0, "amount must be non-negative")
        let (difference, overflow) = subtractingReportingOverflow(amount)
        self = (overflow || difference < limit) ? limit : difference
    }
}
