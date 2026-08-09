import SwiftUI

// MARK: - DS.Mac layout tokens

extension DS {

    /// macOS-specific layout constants.
    ///
    /// Token names mirror the three-pane `NavigationSplitView` column roles.
    /// Values are chosen to fit a 13" MacBook Pro while leaving all three
    /// columns usable at the minimum window width.
    ///
    /// ## Derivation
    /// - windowMinWidth  = sidebarMinWidth + contentMinWidth + detailMinWidth + dividers (~2)
    ///                   = 160 + 280 + 380 + 2 ≈ 822 → rounded to 840
    /// - windowMinHeight = enough for a 7-row habit heatmap + toolbar + sidebar
    ///                   ≈ 560
    enum Mac {

        // MARK: Window

        /// Minimum window width (all three columns at their minimum). 840 pt.
        static let windowMinWidth:  CGFloat = 840
        /// Minimum window height. 560 pt.
        static let windowMinHeight: CGFloat = 560

        // MARK: Sidebar column

        /// Minimum sidebar width. 160 pt — label + icon with breathing room.
        static let sidebarMinWidth:   CGFloat = 160
        /// Preferred sidebar width shown on first launch. 200 pt.
        static let sidebarIdealWidth: CGFloat = 200
        /// Maximum sidebar width before it crowds the content column.
        static let sidebarMaxWidth:   CGFloat = 260

        // MARK: Content (middle) column

        /// Minimum width for the habit/entry list. 280 pt.
        static let contentMinWidth: CGFloat = 280

        // MARK: Detail (right) column

        /// Minimum width for the detail view. 380 pt — wide enough for
        /// the 182-day heatmap at the default cell size.
        static let detailMinWidth: CGFloat = 380

        // MARK: Heatmap

        /// Cell edge on macOS. Slightly larger than iOS (11 pt) to fill the
        /// wider detail column without leaving excessive whitespace.
        static let heatmapCellSize: CGFloat = 13
        /// Gap between heatmap cells. Matched to the iOS gap.
        static let heatmapCellGap:  CGFloat = 3

        // MARK: Toolbar

        /// Standard macOS unified-style toolbar height.
        static let toolbarHeight: CGFloat = 52
    }
}
