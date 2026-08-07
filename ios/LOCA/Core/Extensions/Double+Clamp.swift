// MARK: - Double + Clamping

extension Double {

    /// Returns this value clamped to the closed range `[range.lowerBound, range.upperBound]`.
    ///
    /// Used by `HeatmapDataProvider` (Phase 2) to bound daily completion ratios
    /// to `0...1` before computing heatmap cell opacity. The clamping prevents
    /// over-achievement (total > target) from producing an opacity greater than 1.0,
    /// which would render as a clipped or invisible cell depending on the compositing mode.
    ///
    /// Uses `Swift.min` and `Swift.max` with explicit module qualification to avoid
    /// shadowing by any future `min`/`max` overloads introduced to the project.
    ///
    /// - Parameter range: The closed range within which to constrain the value.
    ///                    Both bounds are inclusive.
    /// - Returns: `range.lowerBound` if `self < range.lowerBound`,
    ///            `range.upperBound` if `self > range.upperBound`,
    ///            or `self` unchanged if already within the range.
    ///
    /// Example:
    /// ```swift
    /// let intensity = (dayTotal / effectiveTarget).clamped(to: 0...1)
    /// // intensity is always in [0.0, 1.0] regardless of dayTotal
    /// ```
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
