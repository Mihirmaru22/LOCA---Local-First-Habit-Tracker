import SwiftUI
import SwiftData

// MARK: - MacLifeDetailColumn

/// Detail column for the Life section.
/// Displays the full interactive Life view corresponding to the selected row or layout variant.
struct MacLifeDetailColumn: View {

    let selectedRow: LifeRow?

    var body: some View {
        MacLifeView()
    }
}
