import SwiftData
import Foundation

// MARK: - TrekSeeder

/// Pre-populates Pluto's Trek & Mountain Atlas with comprehensive Indian mountain peaks,
/// sacred Himalayan giants, Sahyadri fort pinnacles, Nilgiri summits, and iconic global peaks.
enum TrekSeeder {

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TrekRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existing.map(\.name))

        var insertedCount = 0
        for trek in initialTreks {
            if !existingNames.contains(trek.name) {
                context.insert(trek)
                insertedCount += 1
            }
        }

        if insertedCount > 0 {
            try? context.save()
        }
    }

    static let initialTreks: [TrekRecord] = [
        // =========================================================================
        // 🇮🇳 1. GREAT HIMALAYAS & KARAKORAM (NORTH & NORTHEAST INDIA)
        // =========================================================================

        TrekRecord(
            name: "Kangchenjunga",
            region: "Sikkim Himalayas",
            country: "India / Nepal",
            latitude: 27.7025,
            longitude: 88.1475,
            elevationMeters: 8586,
            trailDistanceKm: 90.0,
            elevationGainMeters: 5200,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "Highest peak in India and 3rd highest on Earth. Revered as the sacred protector deity of Sikkim."
        ),
        TrekRecord(
            name: "Nanda Devi",
            region: "Garhwal, Uttarakhand",
            country: "India",
            latitude: 30.3753,
            longitude: 79.9703,
            elevationMeters: 7816,
            trailDistanceKm: 75.0,
            elevationGainMeters: 4800,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "Highest peak entirely within Indian territory. Surrounded by the protected UNESCO Biosphere ring of twin 7,000m barrier peaks."
        ),
        TrekRecord(
            name: "Kamet",
            region: "Zaskar Range, Uttarakhand",
            country: "India",
            latitude: 30.9200,
            longitude: 79.5700,
            elevationMeters: 7756,
            trailDistanceKm: 65.0,
            elevationGainMeters: 4100,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "Second highest summit in Garhwal near the Tibetan plateau. Massive pyramid monolith."
        ),
        TrekRecord(
            name: "Trisul",
            region: "Kumaon Himalayas, Uttarakhand",
            country: "India",
            latitude: 30.3100,
            longitude: 79.7750,
            elevationMeters: 7120,
            trailDistanceKm: 58.0,
            elevationGainMeters: 3900,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "The sacred Trident peak of Lord Shiva. Towering over the mysterious high-altitude Roopkund glacial tarn."
        ),
        TrekRecord(
            name: "Chaukhamba",
            region: "Gangotri Glacier, Uttarakhand",
            country: "India",
            latitude: 30.7460,
            longitude: 79.2800,
            elevationMeters: 7138,
            trailDistanceKm: 42.0,
            elevationGainMeters: 3600,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "The Four-Pillared Giant overlooking the sacred source of the Bhagirathi river at Gaumukh."
        ),
        TrekRecord(
            name: "Kedarnath Peak",
            region: "Garhwal, Uttarakhand",
            country: "India",
            latitude: 30.7960,
            longitude: 79.0300,
            elevationMeters: 6940,
            trailDistanceKm: 34.0,
            elevationGainMeters: 3200,
            status: .conquered,
            difficulty: .alpineExpert,
            dateConquered: Calendar.current.date(byAdding: .month, value: -10, to: Date()),
            rating: 5,
            personalNotes: "Massive snowy ramparts rising directly behind the historic 8th-century Kedarnath temple shrine."
        ),
        TrekRecord(
            name: "Shivling",
            region: "Tapovan, Uttarakhand",
            country: "India",
            latitude: 30.8780,
            longitude: 79.0660,
            elevationMeters: 6543,
            trailDistanceKm: 48.0,
            elevationGainMeters: 2800,
            status: .conquered,
            difficulty: .alpineExpert,
            dateConquered: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            rating: 5,
            personalNotes: "Known worldwide as the 'Matterhorn of India'. Striking sheer pyramid rising directly from the high-altitude meadow of Tapovan."
        ),
        TrekRecord(
            name: "Stok Kangri",
            region: "Hemis National Park, Ladakh",
            country: "India",
            latitude: 33.9850,
            longitude: 77.4470,
            elevationMeters: 6153,
            trailDistanceKm: 40.0,
            elevationGainMeters: 2600,
            status: .conquered,
            difficulty: .strenuous,
            dateConquered: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
            rating: 5,
            personalNotes: "Ladakh's crown 6,000m trekking peak. 360-degree summit views across the Karakoram, K2, and Zanskar ranges."
        ),
        TrekRecord(
            name: "Nun Kun Massif (Nun)",
            region: "Suru Valley, Ladakh",
            country: "India",
            latitude: 33.9810,
            longitude: 76.0220,
            elevationMeters: 7135,
            trailDistanceKm: 55.0,
            elevationGainMeters: 3700,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "Highest mountain massif in the Zanskar region. Classic high-altitude technical expedition summit."
        ),
        TrekRecord(
            name: "Kedarkantha",
            region: "Govind Pashu Vihar, Uttarakhand",
            country: "India",
            latitude: 31.0250,
            longitude: 78.1730,
            elevationMeters: 3810,
            trailDistanceKm: 20.0,
            elevationGainMeters: 1850,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            rating: 5,
            personalNotes: "India's most beloved winter snow peak. 360-degree sunrise across Swargarohini, Black Peak, and Bandarpoonch."
        ),
        TrekRecord(
            name: "Kuari Pass (Curzon Trail)",
            region: "Garhwal, Uttarakhand",
            country: "India",
            latitude: 30.4900,
            longitude: 79.5600,
            elevationMeters: 3650,
            trailDistanceKm: 33.0,
            elevationGainMeters: 1600,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -5, to: Date()),
            rating: 5,
            personalNotes: "Panoramic eye-level corridor facing Nanda Devi, Kamet, Dronagiri, and Hathi-Ghodi Parvat."
        ),
        TrekRecord(
            name: "Deoriatal - Chandrashila",
            region: "Rudraprayag, Uttarakhand",
            country: "India",
            latitude: 30.4900,
            longitude: 79.2200,
            elevationMeters: 3690,
            trailDistanceKm: 15.0,
            elevationGainMeters: 1200,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
            rating: 5,
            personalNotes: "Trek past the world's highest Shiva temple (Tungnath at 3,680m) to reach the cliff summit of Chandrashila."
        ),
        TrekRecord(
            name: "Brahmatal",
            region: "Chamoli, Uttarakhand",
            country: "India",
            latitude: 30.1500,
            longitude: 79.5700,
            elevationMeters: 3734,
            trailDistanceKm: 22.0,
            elevationGainMeters: 1550,
            status: .wishlist,
            difficulty: .moderate,
            rating: 5,
            personalNotes: "Frozen alpine glacial lake rim with face-to-face vistas of Mt. Trishul and Nanda Ghunti."
        ),
        TrekRecord(
            name: "Har Ki Dun",
            region: "Tons Valley, Uttarakhand",
            country: "India",
            latitude: 31.1340,
            longitude: 78.4350,
            elevationMeters: 3566,
            trailDistanceKm: 47.0,
            elevationGainMeters: 1900,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
            rating: 5,
            personalNotes: "The ancient 'Valley of Gods' cradle at the base of Swargarohini (the Stairway to Heaven)."
        ),
        TrekRecord(
            name: "Goechala Pass",
            region: "Khangchendzonga National Park, Sikkim",
            country: "India",
            latitude: 27.6000,
            longitude: 88.1800,
            elevationMeters: 4940,
            trailDistanceKm: 90.0,
            elevationGainMeters: 3400,
            status: .wishlist,
            difficulty: .strenuous,
            rating: 5,
            personalNotes: "Direct, heart-stopping viewpoint of the massive Southeast Face of Kangchenjunga at dawn."
        ),
        TrekRecord(
            name: "Sandakphu",
            region: "Singalila Ridge, West Bengal / Sikkim",
            country: "India",
            latitude: 27.1060,
            longitude: 88.0000,
            elevationMeters: 3636,
            trailDistanceKm: 45.0,
            elevationGainMeters: 1800,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -9, to: Date()),
            rating: 5,
            personalNotes: "Only vantage point on Earth where you can see the four highest 8000ers: Everest, Kangchenjunga, Lhotse, and Makalu in one frame."
        ),
        TrekRecord(
            name: "Friendship Peak",
            region: "Pir Panjal, Himachal Pradesh",
            country: "India",
            latitude: 32.3960,
            longitude: 77.1050,
            elevationMeters: 5289,
            trailDistanceKm: 28.0,
            elevationGainMeters: 2400,
            status: .wishlist,
            difficulty: .strenuous,
            rating: 5,
            personalNotes: "Premier open-summit trekking peak in Solang valley overlooking the Hanuman Tibba and Dhauladhars."
        ),
        TrekRecord(
            name: "Hampta Pass",
            region: "Pir Panjal to Spiti, Himachal Pradesh",
            country: "India",
            latitude: 32.2800,
            longitude: 77.3600,
            elevationMeters: 4287,
            trailDistanceKm: 35.0,
            elevationGainMeters: 2100,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -11, to: Date()),
            rating: 5,
            personalNotes: "Dramatic landscape shift: lush green valleys of Kullu crossing into the barren desert canyon of Lahaul & Spiti."
        ),
        TrekRecord(
            name: "Pin Parvati Pass",
            region: "Kullu to Spiti, Himachal Pradesh",
            country: "India",
            latitude: 31.8500,
            longitude: 77.8000,
            elevationMeters: 5319,
            trailDistanceKm: 110.0,
            elevationGainMeters: 3600,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "Legendary 11-day Trans-Himalayan ice traverse connecting the sacred hot springs of Kheerganga to Spiti's Mud village."
        ),
        TrekRecord(
            name: "Valley of Flowers & Hemkund Sahib",
            region: "Chamoli, Uttarakhand",
            country: "India",
            latitude: 30.7280,
            longitude: 79.5810,
            elevationMeters: 4329,
            trailDistanceKm: 38.0,
            elevationGainMeters: 2300,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -12, to: Date()),
            rating: 5,
            personalNotes: "UNESCO World Heritage carpet of 500+ alpine floral species beside the glacial lake of Hemkund."
        ),
        TrekRecord(
            name: "Chadar Frozen River Trek",
            region: "Zanskar Gorge, Ladakh",
            country: "India",
            latitude: 33.7800,
            longitude: 76.8800,
            elevationMeters: 3850,
            trailDistanceKm: 62.0,
            elevationGainMeters: 450,
            status: .wishlist,
            difficulty: .strenuous,
            rating: 5,
            personalNotes: "Sub-zero ice expedition walking directly across the frozen glass sheet of the Zanskar River at -30°C."
        ),

        // =========================================================================
        // 🌿 2. WESTERN GHATS (SAHYADRIS, MAHARASHTRA, KARNATAKA, KERALA, TAMIL NADU)
        // =========================================================================

        TrekRecord(
            name: "Kalsubai Peak",
            region: "Kalsubai Harishchandragad, Maharashtra",
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
            personalNotes: "Highest peak of Maharashtra (Everest of Sahyadri). Night climb with golden sunrise over Bhandardara reservoir."
        ),
        TrekRecord(
            name: "Anamudi",
            region: "Eravikulam National Park, Kerala",
            country: "India",
            latitude: 10.1690,
            longitude: 77.0640,
            elevationMeters: 2695,
            trailDistanceKm: 12.0,
            elevationGainMeters: 950,
            status: .wishlist,
            difficulty: .moderate,
            rating: 5,
            personalNotes: "Highest peak in South India and all of the Western Ghats ('Elephant's Forehead'). Home to the endangered Nilgiri Tahr."
        ),
        TrekRecord(
            name: "Doddabetta",
            region: "Nilgiris, Tamil Nadu",
            country: "India",
            latitude: 11.4010,
            longitude: 76.7360,
            elevationMeters: 2637,
            trailDistanceKm: 8.0,
            elevationGainMeters: 550,
            status: .conquered,
            difficulty: .easy,
            dateConquered: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
            rating: 5,
            personalNotes: "Highest summit of the Blue Nilgiri Mountains. Rolling clouds, eucalyptus groves, and high-altitude telescope deck."
        ),
        TrekRecord(
            name: "Mullayanagiri",
            region: "Chikkamagaluru, Karnataka",
            country: "India",
            latitude: 13.3910,
            longitude: 75.7210,
            elevationMeters: 1930,
            trailDistanceKm: 6.0,
            elevationGainMeters: 500,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
            rating: 5,
            personalNotes: "Highest peak in Karnataka. Serene mist-covered ridge trail surrounded by lush coffee estates."
        ),
        TrekRecord(
            name: "Kudremukh",
            region: "Chikkamagaluru, Karnataka",
            country: "India",
            latitude: 13.2200,
            longitude: 75.2570,
            elevationMeters: 1894,
            trailDistanceKm: 22.0,
            elevationGainMeters: 1100,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -5, to: Date()),
            rating: 5,
            personalNotes: "Iconic 'Horse-Face' green ridge in the heart of the Kudremukh National Park rainforest."
        ),
        TrekRecord(
            name: "Harishchandragad & Konkan Kada",
            region: "Ahmednagar, Maharashtra",
            country: "India",
            latitude: 19.3870,
            longitude: 73.7780,
            elevationMeters: 1424,
            trailDistanceKm: 14.0,
            elevationGainMeters: 900,
            status: .conquered,
            difficulty: .strenuous,
            dateConquered: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            rating: 5,
            personalNotes: "Spectacular concave vertical cliff (Konkan Kada) facing the Konkan plains with the rare optical phenomenon of the Brocken Spectre."
        ),
        TrekRecord(
            name: "Rajgad Fort (Suvela Machi)",
            region: "Pune, Maharashtra",
            country: "India",
            latitude: 18.2460,
            longitude: 73.6820,
            elevationMeters: 1376,
            trailDistanceKm: 10.5,
            elevationGainMeters: 750,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            rating: 5,
            personalNotes: "Historic royal capital of Chhatrapati Shivaji Maharaj. Massive stone bastions, double-walled fortifications, and the natural rock needle eye (Nedhe)."
        ),
        TrekRecord(
            name: "Torna Fort (Prachandagad)",
            region: "Pune, Maharashtra",
            country: "India",
            latitude: 18.2770,
            longitude: 73.6230,
            elevationMeters: 1403,
            trailDistanceKm: 9.0,
            elevationGainMeters: 820,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
            rating: 5,
            personalNotes: "The massive fortress captured by 16-year-old Shivaji Maharaj in 1646 to launch the Maratha Empire."
        ),
        TrekRecord(
            name: "Meesapulimala",
            region: "Munnar, Kerala",
            country: "India",
            latitude: 10.0960,
            longitude: 77.1970,
            elevationMeters: 2640,
            trailDistanceKm: 16.0,
            elevationGainMeters: 1050,
            status: .wishlist,
            difficulty: .moderate,
            rating: 5,
            personalNotes: "Second highest peak in Western Ghats. Trek through 8 rolling high-altitude hills and rhododendron Shola forests."
        ),
        TrekRecord(
            name: "Chembra Peak & Heart Lake",
            region: "Wayanad, Kerala",
            country: "India",
            latitude: 11.5120,
            longitude: 76.0880,
            elevationMeters: 2100,
            trailDistanceKm: 9.0,
            elevationGainMeters: 700,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
            rating: 5,
            personalNotes: "Highest peak in Wayanad featuring the famous perennial heart-shaped glacial tarn (Hridaya Saras)."
        ),
        TrekRecord(
            name: "Alang Madan Kulang (AMK)",
            region: "Nashik, Maharashtra",
            country: "India",
            latitude: 19.5840,
            longitude: 73.6520,
            elevationMeters: 1470,
            trailDistanceKm: 28.0,
            elevationGainMeters: 1700,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "The ultimate endurance test of Sahyadri trekking: vertical 90-degree rock climbing, rock traverses, and night ridge camping."
        ),
        TrekRecord(
            name: "Kumara Parvatha (Pushpagiri)",
            region: "Coorg / Dakshina Kannada, Karnataka",
            country: "India",
            latitude: 12.6650,
            longitude: 75.6880,
            elevationMeters: 1712,
            trailDistanceKm: 24.0,
            elevationGainMeters: 1400,
            status: .conquered,
            difficulty: .strenuous,
            dateConquered: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            rating: 5,
            personalNotes: "Toughest trek in Karnataka climbing through Shesha Parvatha volcanic boulders into dense Western Ghats canopy."
        ),
        TrekRecord(
            name: "Salher Fort",
            region: "Baglan, Nashik, Maharashtra",
            country: "India",
            latitude: 20.7220,
            longitude: 73.9400,
            elevationMeters: 1567,
            trailDistanceKm: 8.5,
            elevationGainMeters: 780,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
            rating: 5,
            personalNotes: "Highest fort in Maharashtra and second highest peak in the Sahyadris. Historic battlefield fortress of 1672."
        ),
        TrekRecord(
            name: "Tadiandamol",
            region: "Virajpet, Coorg, Karnataka",
            country: "India",
            latitude: 12.2170,
            longitude: 75.6090,
            elevationMeters: 1748,
            trailDistanceKm: 12.0,
            elevationGainMeters: 650,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
            rating: 5,
            personalNotes: "Highest mountain peak in Coorg with sweeping 360-degree views across the Arabian Sea coastline horizon."
        ),

        // =========================================================================
        // 🏜️ 3. ARAVALLI, VINDHYA, SATPURA & GUJARAT
        // =========================================================================

        TrekRecord(
            name: "Guru Shikhar",
            region: "Mount Abu, Aravalli Range, Rajasthan",
            country: "India",
            latitude: 24.6500,
            longitude: 72.7800,
            elevationMeters: 1722,
            trailDistanceKm: 7.0,
            elevationGainMeters: 450,
            status: .conquered,
            difficulty: .easy,
            dateConquered: Calendar.current.date(byAdding: .month, value: -9, to: Date()),
            rating: 5,
            personalNotes: "Highest point of the ancient 1.5-billion-year-old Aravalli Mountain Range."
        ),
        TrekRecord(
            name: "Girnar Peak (Gorakhnath)",
            region: "Junagadh, Gujarat",
            country: "India",
            latitude: 21.5280,
            longitude: 70.5280,
            elevationMeters: 1069,
            trailDistanceKm: 12.0,
            elevationGainMeters: 900,
            status: .conquered,
            difficulty: .moderate,
            dateConquered: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            rating: 5,
            personalNotes: "Sacred 10,000 stone-step pilgrimage mountain. Highest point in Gujarat rising out of the Gir lion forest."
        ),
        TrekRecord(
            name: "Dhupgarh",
            region: "Pachmarhi, Satpura Range, Madhya Pradesh",
            country: "India",
            latitude: 22.4500,
            longitude: 78.4300,
            elevationMeters: 1352,
            trailDistanceKm: 8.0,
            elevationGainMeters: 480,
            status: .conquered,
            difficulty: .easy,
            dateConquered: Calendar.current.date(byAdding: .month, value: -5, to: Date()),
            rating: 5,
            personalNotes: "Highest peak in Madhya Pradesh and the Satpura Range. Famous for crimson ravine sunsets."
        ),

        // =========================================================================
        // 🌐 4. ICONIC GLOBAL SUMMITS & SEVEN SUMMITS
        // =========================================================================

        TrekRecord(
            name: "Mount Everest",
            region: "Mahalangur Himal",
            country: "Nepal / Tibet",
            latitude: 27.9881,
            longitude: 86.9250,
            elevationMeters: 8848,
            trailDistanceKm: 130.0,
            elevationGainMeters: 5500,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "The roof of the world (Sagarmatha). Ultimate mountaineering frontier."
        ),
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
            name: "Mount Kilimanjaro",
            region: "Kilimanjaro National Park",
            country: "Tanzania",
            latitude: -3.0674,
            longitude: 37.3556,
            elevationMeters: 5895,
            trailDistanceKm: 62.0,
            elevationGainMeters: 4100,
            status: .conquered,
            difficulty: .strenuous,
            dateConquered: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            rating: 5,
            personalNotes: "Uhuru Peak at 5,895m. Roof of Africa across 5 distinct ecological climate zones."
        ),
        TrekRecord(
            name: "Matterhorn",
            region: "Zermatt, Pennine Alps",
            country: "Switzerland",
            latitude: 45.9763,
            longitude: 7.6586,
            elevationMeters: 4478,
            trailDistanceKm: 16.0,
            elevationGainMeters: 1900,
            status: .wishlist,
            difficulty: .alpineExpert,
            rating: 5,
            personalNotes: "The quintessential pyramid monolith."
        )
    ]
}
