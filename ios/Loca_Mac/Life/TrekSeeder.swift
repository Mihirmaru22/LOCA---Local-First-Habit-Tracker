import SwiftData
import Foundation

// MARK: - TrekSeeder

/// Pre-populates Pluto's Trek & Mountain Atlas with iconic global summits and trails
/// so the interactive map and list are immediately rich and engaging on first launch.
enum TrekSeeder {

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TrekRecord>()
        let count = (try? context.fetchCount(descriptor)) ?? 0

        guard count == 0 else { return }

        let initialTreks: [TrekRecord] = [
            // Asia & Himalayas
            TrekRecord(
                name: "Mount Fuji",
                region: "Honshu",
                country: "Japan",
                latitude: 35.3606,
                longitude: 138.7274,
                elevationMeters: 3776,
                trailDistanceKm: 14.5,
                elevationGainMeters: 1450,
                status: .conquered,
                difficulty: .moderate,
                dateConquered: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
                rating: 5,
                personalNotes: "Sunrise at 3,776m above the sea of clouds (Goraikō). Unforgettable volcanic trail."
            ),
            TrekRecord(
                name: "Everest Base Camp",
                region: "Khumbu Valley, Himalayas",
                country: "Nepal",
                latitude: 28.0044,
                longitude: 86.8568,
                elevationMeters: 5364,
                trailDistanceKm: 130.0,
                elevationGainMeters: 4500,
                status: .wishlist,
                difficulty: .alpineExpert,
                rating: 5,
                personalNotes: "Dream expedition: 12-day high-altitude trek via Namche Bazaar and Tengboche."
            ),
            TrekRecord(
                name: "Kalsubai Peak",
                region: "Western Ghats, Maharashtra",
                country: "India",
                latitude: 19.6010,
                longitude: 73.7050,
                elevationMeters: 1646,
                trailDistanceKm: 6.6,
                elevationGainMeters: 820,
                status: .conquered,
                difficulty: .moderate,
                dateConquered: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
                rating: 5,
                personalNotes: "Highest peak of Maharashtra. Night trek with glorious golden sunrise at the temple summit."
            ),
            TrekRecord(
                name: "Mount Kinabalu",
                region: "Sabah, Borneo",
                country: "Malaysia",
                latitude: 6.0753,
                longitude: 116.5583,
                elevationMeters: 4095,
                trailDistanceKm: 18.0,
                elevationGainMeters: 2200,
                status: .wishlist,
                difficulty: .strenuous,
                rating: 4,
                personalNotes: "Granite plateaus above the tropical rainforest canopy."
            ),

            // Europe & Alps
            TrekRecord(
                name: "Mont Blanc",
                region: "Chamonix, Alps",
                country: "France / Italy",
                latitude: 45.8326,
                longitude: 6.8652,
                elevationMeters: 4809,
                trailDistanceKm: 32.0,
                elevationGainMeters: 3800,
                status: .conquered,
                difficulty: .alpineExpert,
                dateConquered: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
                rating: 5,
                personalNotes: "The monarch of the Alps. Glacial traverse via Goûter route. Pure alpine grandeur."
            ),
            TrekRecord(
                name: "Matterhorn",
                region: "Zermatt, Pennine Alps",
                country: "Switzerland",
                latitude: 45.9763,
                longitude: 7.6586,
                elevationMeters: 4478,
                trailDistanceKm: 12.0,
                elevationGainMeters: 1800,
                status: .wishlist,
                difficulty: .extreme,
                rating: 5,
                personalNotes: "Iconic pyramidal summit. Hörnli Ridge technical route."
            ),
            TrekRecord(
                name: "Mount Olympus (Mytikas)",
                region: "Thessaly",
                country: "Greece",
                latitude: 40.0855,
                longitude: 22.3585,
                elevationMeters: 2917,
                trailDistanceKm: 21.0,
                elevationGainMeters: 2100,
                status: .wishlist,
                difficulty: .strenuous,
                rating: 4,
                personalNotes: "Throne of Zeus. Scramble up the Kakiskala ridge."
            ),

            // North America
            TrekRecord(
                name: "Half Dome",
                region: "Yosemite National Park, California",
                country: "USA",
                latitude: 37.7460,
                longitude: -119.5332,
                elevationMeters: 2694,
                trailDistanceKm: 22.5,
                elevationGainMeters: 1460,
                status: .conquered,
                difficulty: .strenuous,
                dateConquered: Calendar.current.date(byAdding: .month, value: -10, to: Date()),
                rating: 5,
                personalNotes: "Granite cables route to the 4,000ft sheer drop over Yosemite Valley."
            ),
            TrekRecord(
                name: "Mount Whitney",
                region: "Sierra Nevada, California",
                country: "USA",
                latitude: 36.5785,
                longitude: -118.2920,
                elevationMeters: 4421,
                trailDistanceKm: 35.4,
                elevationGainMeters: 2020,
                status: .wishlist,
                difficulty: .strenuous,
                rating: 5,
                personalNotes: "Highest summit in the contiguous United States. Epic 99 switchbacks."
            ),
            TrekRecord(
                name: "Mount Rainier",
                region: "Cascade Range, Washington",
                country: "USA",
                latitude: 46.8523,
                longitude: -121.7603,
                elevationMeters: 4392,
                trailDistanceKm: 24.0,
                elevationGainMeters: 2750,
                status: .wishlist,
                difficulty: .alpineExpert,
                rating: 5,
                personalNotes: "Glacier-clad stratovolcano with 25 major glaciers."
            ),

            // Africa & South America
            TrekRecord(
                name: "Mount Kilimanjaro (Uhuru Peak)",
                region: "Kilimanjaro National Park",
                country: "Tanzania",
                latitude: -3.0674,
                longitude: 37.3556,
                elevationMeters: 5895,
                trailDistanceKm: 62.0,
                elevationGainMeters: 4100,
                status: .wishlist,
                difficulty: .strenuous,
                rating: 5,
                personalNotes: "Roof of Africa. 7-day Machame Route through five distinct climate zones."
            ),
            TrekRecord(
                name: "Mount Toubkal",
                region: "High Atlas Mountains",
                country: "Morocco",
                latitude: 31.0594,
                longitude: -7.9292,
                elevationMeters: 4167,
                trailDistanceKm: 28.0,
                elevationGainMeters: 2400,
                status: .conquered,
                difficulty: .strenuous,
                dateConquered: Calendar.current.date(byAdding: .month, value: -14, to: Date()),
                rating: 5,
                personalNotes: "Highest peak in the Atlas Mountains and North Africa. Spectacular Berber valley ascent."
            ),
            TrekRecord(
                name: "Aconcagua",
                region: "Mendoza, Andes",
                country: "Argentina",
                latitude: -32.6532,
                longitude: -70.0109,
                elevationMeters: 6961,
                trailDistanceKm: 60.0,
                elevationGainMeters: 4150,
                status: .wishlist,
                difficulty: .extreme,
                rating: 5,
                personalNotes: "Highest summit in the Americas and outside of Asia."
            )
        ]

        for trek in initialTreks {
            context.insert(trek)
        }

        try? context.save()
    }
}
