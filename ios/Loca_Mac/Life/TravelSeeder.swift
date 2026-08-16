import SwiftData
import Foundation

// MARK: - TravelSeeder

/// Pre-populates Pluto's Travel Odyssey & State Atlas with every state and territory of India,
/// starting with comprehensive dossiers for Gujarat, Maharashtra, Rajasthan, the Himalayas,
/// South India, North-East, and neighboring Subcontinent destinations.
enum TravelSeeder {

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<TravelRecord>()
        let existing = (try? context.fetch(descriptor)) ?? []
        let existingNames = Set(existing.map(\.name))

        var insertedCount = 0
        for record in initialStates {
            if !existingNames.contains(record.name) {
                context.insert(record)
                insertedCount += 1
            }
        }

        if insertedCount > 0 {
            try? context.save()
        }
    }

    static let initialStates: [TravelRecord] = [

        // =========================================================================
        // 🦁 1. WESTERN INDIA (GUJARAT, MAHARASHTRA, GOA)
        // =========================================================================

        TravelRecord(
            name: "Gujarat",
            stateCode: "GJ",
            capital: "Gandhinagar",
            country: "India",
            zone: .western,
            latitude: 22.2587,
            longitude: 71.1924,
            status: .livedHere,
            dateVisited: Calendar.current.date(byAdding: .month, value: -1, to: Date()),
            timesVisited: 15,
            rating: 5,
            visitedCities: ["Ahmedabad", "Surat", "Vadodara", "Rajkot", "Kutch (Bhuj)", "Junagadh", "Dwarka", "Somnath", "Gir", "Saputara"],
            topAttractions: ["Rann of Kutch Salt Desert & Rann Utsav", "Gir National Park (Asiatic Lions)", "Statue of Unity (Tallest on Earth)", "Sun Temple Modhera", "Somnath & Dwarkadhish Temples", "Girnar 10,000 Steps", "Rani Ki Vav Stepwell"],
            cuisineHighlights: "Gujarati Thali, Kathiyawadi, Fafda Jalebi, Undhiyu, Khaman Dhokla, Dabeli, Surati Locho",
            bestSeason: "Oct – Mar (Winter & Rann Utsav Season)",
            officialLanguage: "Gujarati, Hindi",
            personalNotes: "Native home state with world-class infrastructure, ancient maritime trade ports, UNESCO stepwells, and the surreal white salt desert."
        ),
        TravelRecord(
            name: "Maharashtra",
            stateCode: "MH",
            capital: "Mumbai",
            country: "India",
            zone: .western,
            latitude: 19.7515,
            longitude: 75.7139,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -2, to: Date()),
            timesVisited: 12,
            rating: 5,
            visitedCities: ["Mumbai", "Pune", "Nashik", "Aurangabad", "Nagpur", "Mahabaleshwar", "Lonavala", "Igatpuri", "Kolhapur", "Alibaug"],
            topAttractions: ["Gateway of India & Marine Drive", "Ajanta & Ellora UNESCO Caves", "Sahyadri Forts (Rajgad, Torna, Raigad, Kalsubai)", "Trimbakeshwar & Shirdi", "Mahabaleshwar & Arthur's Seat", "Konkan Beaches"],
            cuisineHighlights: "Vada Pav, Misal Pav, Puran Poli, Kolhapuri Mutton/Tambda Rassa, Pithla Bhakri, Bombil Fry, Kanda Poha",
            bestSeason: "Jun – Sep (Monsoon Waterfalls) & Nov – Feb",
            officialLanguage: "Marathi, Hindi",
            personalNotes: "The economic powerhouse of India, crowned by the rugged basalt ramparts of Chhatrapati Shivaji Maharaj's Sahyadri forts."
        ),
        TravelRecord(
            name: "Goa",
            stateCode: "GA",
            capital: "Panaji",
            country: "India",
            zone: .western,
            latitude: 15.2993,
            longitude: 74.1240,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
            timesVisited: 4,
            rating: 5,
            visitedCities: ["Panaji", "Margao", "Calangute", "Anjuna", "Vasco da Gama", "Palolem", "Arambol"],
            topAttractions: ["Dudhsagar Waterfalls (310m)", "Palolem & Morjim Beaches", "Basilica of Bom Jesus (UNESCO)", "Fort Aguada & Chapora Fort", "Fontainhas Latin Quarter", "Spice Plantations"],
            cuisineHighlights: "Goan Fish Curry Thali, Bebinca, Prawn Balchão, Pork Vindaloo, Poi bread, Kokum Sol Kadi",
            bestSeason: "Nov – Feb (Pleasant Coastal Breezes)",
            officialLanguage: "Konkani, Marathi, English",
            personalNotes: "Golden sand coastline, Portuguese heritage cathedrals, lush Western Ghats hinterland, and sunset ocean shacks."
        ),

        // =========================================================================
        // 🏜️ 2. NORTHERN INDIA (RAJASTHAN, HIMACHAL, UTTARAKHAND, DELHI, PUNJAB, UP)
        // =========================================================================

        TravelRecord(
            name: "Rajasthan",
            stateCode: "RJ",
            capital: "Jaipur",
            country: "India",
            zone: .northern,
            latitude: 27.0238,
            longitude: 74.2179,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -4, to: Date()),
            timesVisited: 8,
            rating: 5,
            visitedCities: ["Jaipur", "Udaipur", "Jodhpur", "Jaisalmer", "Bikaner", "Mount Abu", "Pushkar", "Ajmer", "Chittorgarh", "Ranthambore"],
            topAttractions: ["Amber Fort & Hawa Mahal (Jaipur)", "City Palace & Lake Pichola (Udaipur)", "Mehrangarh Fort & Blue City (Jodhpur)", "Jaisalmer Golden Fort & Thar Dunes", "Great Wall of Kumbhalgarh (36km)", "Ranthambore Tiger Sanctuary"],
            cuisineHighlights: "Dal Baati Churma, Laal Maas, Ker Sangri, Ghevar, Pyaz Kachori, Mirchi Vada, Mawa Kachori",
            bestSeason: "Oct – Mar (Crisp Desert Winters)",
            officialLanguage: "Hindi, Rajasthani (Marwari, Mewari)",
            personalNotes: "Land of Kings and Maharajas. Towering sandstone fortresses rising out of the golden Thar dunes, vibrant folk music, and royal palaces."
        ),
        TravelRecord(
            name: "Himachal Pradesh",
            stateCode: "HP",
            capital: "Shimla / Dharamshala",
            country: "India",
            zone: .northern,
            latitude: 31.1048,
            longitude: 77.1734,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
            timesVisited: 6,
            rating: 5,
            visitedCities: ["Manali", "Shimla", "Dharamshala", "Spiti Valley (Kaza)", "Kasol", "Bir Billing", "Dalhousie", "Jibhi", "Kullu"],
            topAttractions: ["Rohtang Pass & Atal Tunnel", "Spiti Valley High Desert & Key Monastery", "Solang Valley Snow Slopes", "Bir Billing (World Paragliding Site)", "Triund Ridge & Dhauladhars", "Dalai Lama Temple McLeod Ganj"],
            cuisineHighlights: "Himachali Dham, Siddu with Ghee, Trout Fish, Chha Gosht, Madra, Babru, Apple Crumble",
            bestSeason: "Mar – Jun (Summers) & Dec – Feb (Snow)",
            officialLanguage: "Hindi, Pahari",
            personalNotes: "Abode of Snow. Ancient deodar forests, soaring Pir Panjal peaks, Tibetan Buddhist monasteries, and roaring river rapids."
        ),
        TravelRecord(
            name: "Uttarakhand",
            stateCode: "UK",
            capital: "Dehradun / Gairsain",
            country: "India",
            zone: .northern,
            latitude: 30.0668,
            longitude: 79.0193,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -5, to: Date()),
            timesVisited: 7,
            rating: 5,
            visitedCities: ["Rishikesh", "Haridwar", "Dehradun", "Nainital", "Mussoorie", "Auli", "Kedarnath", "Badrinath", "Uttarkashi", "Chopta"],
            topAttractions: ["Char Dham Holy Shrines (Kedarnath, Badrinath)", "Rishikesh Yoga & River Rafting", "Valley of Flowers UNESCO Park", "Auli Ski Slopes facing Nanda Devi", "Tungnath (Highest Shiva Temple at 3,680m)", "Jim Corbett Tiger Reserve"],
            cuisineHighlights: "Kafuli, Chainsoo, Bal Mithai, Singodi, Aloo ke Gutke, Bhatt ki Churkani, Garhwal Jhangora Kheer",
            bestSeason: "Apr – Jun & Sep – Nov (Crystal Peak Vistas)",
            officialLanguage: "Hindi, Garhwali, Kumaoni",
            personalNotes: "Devbhoomi (Land of the Gods). Towering sacred Himalayan massifs, holy source of the Ganga, and pristine high-altitude meadows (Bugyals)."
        ),
        TravelRecord(
            name: "Delhi",
            stateCode: "DL",
            capital: "New Delhi",
            country: "India",
            zone: .unionTerritory,
            latitude: 28.6139,
            longitude: 77.2090,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            timesVisited: 10,
            rating: 5,
            visitedCities: ["New Delhi", "Old Delhi", "Mehrauli", "Connaught Place", "Hauz Khas"],
            topAttractions: ["India Gate & Kartavya Path", "Red Fort & Chandni Chowk", "Qutub Minar (UNESCO)", "Humayun's Tomb", "Lotus Temple", "Akshardham Temple", "National Museum"],
            cuisineHighlights: "Butter Chicken, Chole Bhature, Gali Paranthe Wali Parathas, Nihari, Chaat at Chandni Chowk, Kulfi Falooda",
            bestSeason: "Oct – Mar (Cool Autumn & Winter)",
            officialLanguage: "Hindi, English, Punjabi, Urdu",
            personalNotes: "The historic heartbeat of India. Millenniums of empire architecture spanning the Mughals, British Lutyens, and modern Bharat."
        ),
        TravelRecord(
            name: "Punjab",
            stateCode: "PB",
            capital: "Chandigarh",
            country: "India",
            zone: .northern,
            latitude: 31.1471,
            longitude: 75.3412,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            timesVisited: 3,
            rating: 5,
            visitedCities: ["Amritsar", "Ludhiana", "Jalandhar", "Patiala", "Bathinda"],
            topAttractions: ["Golden Temple (Harmandir Sahib)", "Wagah Border Beating Retreat Ceremony", "Jallianwala Bagh Memorial", "Qila Mubarak Patiala", "Virasaat-e-Khalsa Anandpur Sahib"],
            cuisineHighlights: "Sarson Ka Saag & Makki Di Roti, Amritsari Kulcha with Chole, Butter Chicken, Dal Makhani, Creamy Lassi",
            bestSeason: "Oct – Mar",
            officialLanguage: "Punjabi",
            personalNotes: "Land of Five Rivers, warm hospitality, soulful Gurbani kirtan at the Golden Temple, and endless emerald mustard fields."
        ),
        TravelRecord(
            name: "Uttar Pradesh",
            stateCode: "UP",
            capital: "Lucknow",
            country: "India",
            zone: .northern,
            latitude: 26.8467,
            longitude: 80.9462,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -9, to: Date()),
            timesVisited: 5,
            rating: 5,
            visitedCities: ["Varanasi", "Agra", "Lucknow", "Ayodhya", "Prayagraj", "Mathura", "Vrindavan", "Sarnath"],
            topAttractions: ["Taj Mahal (Wonder of the World)", "Varanasi Ganga Ghats & Evening Maha Aarti", "Ram Mandir Ayodhya", "Bara Imambara & Rumi Darwaza", "Triveni Sangam Prayagraj", "Fatehpur Sikri"],
            cuisineHighlights: "Awadhi Dum Biryani, Galouti & Tunday Kebabs, Banarasi Paan, Malaiyyo, Agra Petha, Bedmi Puri",
            bestSeason: "Oct – Mar",
            officialLanguage: "Hindi, Urdu",
            personalNotes: "Epicenter of classical Indian spirituality, timeless ghats of Kashi, Nawabi culinary mastery, and the white marble poetry of the Taj Mahal."
        ),

        // =========================================================================
        // 🌴 3. SOUTHERN INDIA (KERALA, KARNATAKA, TAMIL NADU, TELANGANA, ANDHRA)
        // =========================================================================

        TravelRecord(
            name: "Kerala",
            stateCode: "KL",
            capital: "Thiruvananthapuram",
            country: "India",
            zone: .southern,
            latitude: 10.8505,
            longitude: 76.2711,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -6, to: Date()),
            timesVisited: 4,
            rating: 5,
            visitedCities: ["Kochi (Cochin)", "Munnar", "Alleppey (Alappuzha)", "Wayanad", "Varkala", "Kovalam", "Thekkady", "Kozhikode"],
            topAttractions: ["Alleppey Houseboat Backwater Cruise", "Munnar Tea Plantations & Anamudi", "Fort Kochi Chinese Fishing Nets & Mattancherry", "Varkala Red Cliff Beach", "Periyar Tiger Reserve", "Athirappilly Waterfalls"],
            cuisineHighlights: "Appam with Ishtu, Kerala Sadya on Banana Leaf, Malabar Parotta with Beef/Chicken Roast, Karimeen Pollichathu, Puttu Kadala",
            bestSeason: "Sep – Mar (Post-monsoon Lushness)",
            officialLanguage: "Malayalam, English",
            personalNotes: "God's Own Country. Serene palm-fringed lagoons, emerald tea slopes of the Western Ghats, spice gardens, and Ayurvedic sanctuaries."
        ),
        TravelRecord(
            name: "Karnataka",
            stateCode: "KA",
            capital: "Bengaluru",
            country: "India",
            zone: .southern,
            latitude: 15.3173,
            longitude: 75.7139,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -3, to: Date()),
            timesVisited: 8,
            rating: 5,
            visitedCities: ["Bengaluru", "Mysuru (Mysore)", "Hampi", "Coorg (Madikeri)", "Chikkamagaluru", "Gokarna", "Mangaluru", "Badami", "Udupi"],
            topAttractions: ["UNESCO Hampi Ruins & Stone Chariot", "Mysore Palace Light Illumination", "Coorg Coffee & Spice Estates", "Om Beach & Kudle Beach Gokarna", "Jog Falls (253m)", "Belur & Halebidu Hoysala Temples"],
            cuisineHighlights: "Bisi Bele Bath, Mysore Pak, Neer Dosa, Mangalorean Ghee Roast, Pandi Curry, Davanagere Benne Dosa, Filter Coffee",
            bestSeason: "Oct – Mar",
            officialLanguage: "Kannada, English",
            personalNotes: "Silicon Valley tech hub blending into boulder-strewn Vijayanagara ruins, lush rainforest mountains, and pristine Arabian Sea coves."
        ),
        TravelRecord(
            name: "Tamil Nadu",
            stateCode: "TN",
            capital: "Chennai",
            country: "India",
            zone: .southern,
            latitude: 11.1271,
            longitude: 78.6569,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -10, to: Date()),
            timesVisited: 3,
            rating: 5,
            visitedCities: ["Chennai", "Madurai", "Coimbatore", "Kanyakumari", "Ooty (Udhagamandalam)", "Rameswaram", "Thanjavur", "Mahabalipuram"],
            topAttractions: ["Meenakshi Amman Temple Madurai", "Brihadisvara Great Chola Temple Thanjavur", "Shore Temple Mahabalipuram (UNESCO)", "Pamban Sea Bridge & Rameswaram", "Nilgiri Mountain Toy Train Ooty", "Kanyakumari Southernmost Tip"],
            cuisineHighlights: "Crisp Dosa & Idli Sambar, Chettinad Pepper Chicken, Jigarthanda, Pongal, Filter Kaapi, Madurai Kari Dosa",
            bestSeason: "Nov – Feb",
            officialLanguage: "Tamil",
            personalNotes: "Cradle of classical Dravidian culture, towering temple gopurams with intricate stone carvings, and the confluence of three oceans at Kanyakumari."
        ),
        TravelRecord(
            name: "Telangana",
            stateCode: "TS",
            capital: "Hyderabad",
            country: "India",
            zone: .southern,
            latitude: 18.1124,
            longitude: 79.0193,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -7, to: Date()),
            timesVisited: 4,
            rating: 5,
            visitedCities: ["Hyderabad", "Warangal", "Nizamabad", "Karimnagar"],
            topAttractions: ["Charminar & Laad Bazaar", "Golconda Fort & Acoustic Whispering Galleries", "Ramoji Film City (World's Largest)", "Hussain Sagar Buddha Statue", "Thousand Pillar Temple Warangal"],
            cuisineHighlights: "Hyderabadi Dum Biryani, Haleem, Mirchi Ka Salan, Double Ka Meetha, Irani Chai with Osmania Biscuits",
            bestSeason: "Oct – Mar",
            officialLanguage: "Telugu, Urdu, Hindi",
            personalNotes: "Historic Nizam heritage fused with modern cyber towers, world-famous aromatic dum biryani, and diamond-rich Golconda legends."
        ),
        TravelRecord(
            name: "Andhra Pradesh",
            stateCode: "AP",
            capital: "Amaravati / Visakhapatnam",
            country: "India",
            zone: .southern,
            latitude: 15.9129,
            longitude: 79.7400,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Visakhapatnam (Vizag)", "Tirupati", "Vijayawada", "Guntur", "Araku Valley", "Kurnool"],
            topAttractions: ["Tirupati Venkateswara Balaji Temple", "Araku Valley Coffee Groves & Borra Caves", "Rishikonda Beach Vizag", "Gandikota Grand Canyon of India", "Belum Caves"],
            cuisineHighlights: "Spicy Andhra Meals on Banana Leaf, Gongura Pachadi, Royyala Vepudu (Prawn Fry), Pulihora, Pootharekulu",
            bestSeason: "Oct – Mar",
            officialLanguage: "Telugu",
            personalNotes: "Longest coastline on Eastern India, sacred Tirupati pilgrimage, deep prehistoric subterranean caves, and the Grand Canyon of Gandikota."
        ),

        // =========================================================================
        // 🏔️ 4. THE HIGH HIMALAYAS & UNION TERRITORIES (LADAKH, J&K, SIKKIM, A&N)
        // =========================================================================

        TravelRecord(
            name: "Ladakh",
            stateCode: "LA",
            capital: "Leh",
            country: "India",
            zone: .unionTerritory,
            latitude: 34.1526,
            longitude: 77.5771,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
            timesVisited: 2,
            rating: 5,
            visitedCities: ["Leh", "Kargil", "Nubra Valley (Diskit/Hunder)", "Pangong Tso", "Tso Moriri", "Zanskar (Padum)", "Turtuk"],
            topAttractions: ["Pangong Tso High Altitude Blue Lake", "Khardung La Pass (5,359m)", "Hunder Sand Dunes & Bactrian Camels", "Magnetic Hill", "Thiksey & Hemis Monasteries", "Zanskar Frozen River"],
            cuisineHighlights: "Thukpa, Steamed Mutton Momos, Butter Tea (Gur Gur Chai), Tingmo bread, Skyu stew, Apricot Jam",
            bestSeason: "May – Sep (Open Mountain Passes)",
            officialLanguage: "Ladakhi, Bhoti, Hindi, English",
            personalNotes: "The Last Shangri-La. High-altitude cold desert plateau at 3,500m+ surrounded by the Karakoram and Zanskar ranges with starry Milky Way skies."
        ),
        TravelRecord(
            name: "Jammu & Kashmir",
            stateCode: "JK",
            capital: "Srinagar / Jammu",
            country: "India",
            zone: .unionTerritory,
            latitude: 33.7782,
            longitude: 76.5762,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .year, value: -1, to: Date()),
            timesVisited: 3,
            rating: 5,
            visitedCities: ["Srinagar", "Gulmarg", "Pahalgam", "Sonamarg", "Jammu", "Katra", "Doodhpathri"],
            topAttractions: ["Dal Lake Shikara Rides & Houseboats", "Gulmarg Gondola (Highest Cable Car)", "Betaab Valley & Aru Valley Pahalgam", "Mughal Gardens (Shalimar & Nishat)", "Vaishno Devi Holy Shrine Katra"],
            cuisineHighlights: "Kashmiri Wazwan (Rogan Josh, Gushtaba, Rista), Kahwa with Saffron & Almonds, Modur Pulao, Kashmiri Kulcha",
            bestSeason: "Apr – Oct (Floral Valley) & Dec – Feb (Skiing)",
            officialLanguage: "Kashmiri, Dogri, Urdu, Hindi",
            personalNotes: "Paradise on Earth (Firdaus). Emerald pine valleys, snow-capped Himalayan ridges, floating flower markets on Dal Lake, and Chinar trees."
        ),
        TravelRecord(
            name: "Sikkim",
            stateCode: "SK",
            capital: "Gangtok",
            country: "India",
            zone: .northEast,
            latitude: 27.5330,
            longitude: 88.5122,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -9, to: Date()),
            timesVisited: 2,
            rating: 5,
            visitedCities: ["Gangtok", "Pelling", "Lachung", "Lachen", "Namchi", "Ravangla", "Yuksom"],
            topAttractions: ["Gurudongmar Sacred Lake (5,430m)", "Nathu La Indo-China Pass", "Rumtek & Pemayangtse Monasteries", "Yumthang Valley of Flowers", "Buddha Park Ravangla", "Kangchenjunga Viewpoints"],
            cuisineHighlights: "Steamed Momos, Thukpa, Gundruk Soup, Chhurpi Hard Yak Cheese, Kinema, Sel Roti, Tongba (Warm Millet Brew)",
            bestSeason: "Mar – May (Rhododendrons) & Oct – Dec (Clear Summits)",
            officialLanguage: "Nepali, Sikkimese (Bhutia), Lepcha, English",
            personalNotes: "India's 100% organic Himalayan kingdom nestled beneath Mt. Kangchenjunga (8,586m) with pristine glacial lakes and prayer flag passes."
        ),
        TravelRecord(
            name: "Andaman & Nicobar Islands",
            stateCode: "AN",
            capital: "Port Blair",
            country: "India",
            zone: .unionTerritory,
            latitude: 11.7401,
            longitude: 92.6586,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -11, to: Date()),
            timesVisited: 2,
            rating: 5,
            visitedCities: ["Port Blair", "Havelock Island (Swaraj Dweep)", "Neil Island (Shaheed Dweep)", "Baratang Island"],
            topAttractions: ["Radhanagar Beach (Asia's Best Beach)", "Cellular Jail National Memorial & Light Show", "Elephant Beach Scuba Diving & Coral Reefs", "Natural Bridge Neil Island", "Baratang Mangrove Mud Volcanoes"],
            cuisineHighlights: "Grilled Fresh Lobster & Red Snapper, Coconut Prawn Curry, Banana Flower Curry, Tropical Fruit Shakes",
            bestSeason: "Oct – May (Calm Azure Waters)",
            officialLanguage: "Hindi, Bengali, Tamil, English",
            personalNotes: "Turquoise Indian Ocean archipelago with untouched coral reefs, white sand coves, and solemn freedom fighter memorial history."
        ),

        // =========================================================================
        // 🌿 5. NORTH-EAST INDIA (MEGHALAYA, ASSAM, ARUNACHAL, NAGALAND, ETC.)
        // =========================================================================

        TravelRecord(
            name: "Meghalaya",
            stateCode: "ML",
            capital: "Shillong",
            country: "India",
            zone: .northEast,
            latitude: 25.4670,
            longitude: 91.3662,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            timesVisited: 2,
            rating: 5,
            visitedCities: ["Shillong", "Cherrapunji (Sohra)", "Dawki", "Mawlynnong", "Nongriat", "Jowai"],
            topAttractions: ["Double Decker Living Root Bridge (Nongriat)", "Umngot Crystal Clear River Dawki", "Nohkalikai Falls (340m plunge)", "Mawlynnong (Cleanest Village in Asia)", "Krang Suri Blue Waterfalls", "Mawsmai Limestone Caves"],
            cuisineHighlights: "Jadoh (Rice cooked in Meat Stock), Dohkhlieh, Tungrymbai, Pumaloi, Bamboo Shoot Curry",
            bestSeason: "Oct – Apr (Clear Waters) & Jun – Sep (Monsoon Waterfalls)",
            officialLanguage: "Khasi, Garo, English",
            personalNotes: "Abode of Clouds. Living bio-engineered root bridges grown by the Khasi tribe over centuries, and the glass-like transparency of Dawki river."
        ),
        TravelRecord(
            name: "Assam",
            stateCode: "AS",
            capital: "Dispur / Guwahati",
            country: "India",
            zone: .northEast,
            latitude: 26.2006,
            longitude: 92.9376,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -8, to: Date()),
            timesVisited: 2,
            rating: 5,
            visitedCities: ["Guwahati", "Kaziranga", "Jorhat", "Dibrugarh", "Tezpur", "Majuli Island"],
            topAttractions: ["Kaziranga National Park (Great One-Horned Rhino)", "Kamakhya Shaktipeeth Temple", "Majuli (World's Largest River Island)", "Brahmaputra Sunset River Cruise", "Assam Tea Plantations Jorhat"],
            cuisineHighlights: "Assam Orthodox Black Tea, Khaar, Masor Tenga (Sour Fish Curry), Duck Curry with Ash Gourd, Pitha, Luchi",
            bestSeason: "Nov – Apr",
            officialLanguage: "Assamese, Bengali, Bodo",
            personalNotes: "Gateway to the North-East with the mighty Brahmaputra river, ancient Tantric Shaktipeeths, and two-thirds of the world's one-horned rhinos."
        ),
        TravelRecord(
            name: "Arunachal Pradesh",
            stateCode: "AR",
            capital: "Itanagar",
            country: "India",
            zone: .northEast,
            latitude: 28.2180,
            longitude: 94.7278,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Tawang", "Ziro Valley", "Itanagar", "Bomdila", "Pasighat", "Dirang", "Mechuka"],
            topAttractions: ["Tawang Monastery (Largest in India)", "Sela Pass (4,170m) & Sela Lake", "Ziro Valley Pine Groves & Apatani Culture", "Mechuka Forbidden Valley", "Namdapha National Park"],
            cuisineHighlights: "Thukpa, Zan (Millet porridge), Apong (Rice Beer), Lukter, Pika Pila, Bamboo Shoot Pork",
            bestSeason: "Oct – Apr",
            officialLanguage: "English, Hindi, Monpa, Nyishi",
            personalNotes: "Land of Dawn-Lit Mountains. Untouched frontier of snow-covered high Himalayan passes, ancient Buddhist monasteries, and tribal valleys."
        ),
        TravelRecord(
            name: "Nagaland",
            stateCode: "NL",
            capital: "Kohima",
            country: "India",
            zone: .northEast,
            latitude: 26.1584,
            longitude: 94.5624,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Kohima", "Dimapur", "Mokokchung", "Mon", "Dzükou Valley"],
            topAttractions: ["Hornbill Festival (December in Kisama)", "Dzükou Valley of Flowers & Trek", "Kohima War Cemetery (WWII Battle of Kohima)", "Longwa Village (Indo-Myanmar Border)", "Khonoma Green Village"],
            cuisineHighlights: "Smoked Pork with Axone (Fermented Soybeans), Bamboo Shoot Curry, Galho, Raja Mircha (Ghost Pepper) Chutney",
            bestSeason: "Oct – May (Hornbill in Dec)",
            officialLanguage: "English, Nagamese",
            personalNotes: "Land of 16 Warrior Tribes, famous for the vibrant Hornbill cultural festival, emerald Dzükou valley, and rich weaving traditions."
        ),

        // =========================================================================
        // 🪷 6. EASTERN & CENTRAL INDIA (WEST BENGAL, ODISHA, MP, BIHAR)
        // =========================================================================

        TravelRecord(
            name: "West Bengal",
            stateCode: "WB",
            capital: "Kolkata",
            country: "India",
            zone: .eastern,
            latitude: 22.9868,
            longitude: 87.8550,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -9, to: Date()),
            timesVisited: 3,
            rating: 5,
            visitedCities: ["Kolkata", "Darjeeling", "Siliguri", "Kalimpong", "Sundarbans", "Shantiniketan", "Digha"],
            topAttractions: ["Victoria Memorial & Howrah Bridge", "Darjeeling Himalayan Toy Train & Tiger Hill", "Sundarbans UNESCO Mangrove Tiger Reserve", "Durga Puja Street Art Installations", "Dakshineswar & Belur Math"],
            cuisineHighlights: "Kolkata Biryani, Machher Jhol, Rosogolla, Mishti Doi, Sandesh, Kathi Rolls, Phuchka",
            bestSeason: "Oct – Mar (Durga Puja & Winter)",
            officialLanguage: "Bengali, English",
            personalNotes: "Cultural & intellectual capital of India. Nobel laureates, colonial heritage, tea hills of Darjeeling, and grand Durga Puja celebrations."
        ),
        TravelRecord(
            name: "Odisha",
            stateCode: "OD",
            capital: "Bhubaneswar",
            country: "India",
            zone: .eastern,
            latitude: 20.9517,
            longitude: 85.0985,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Bhubaneswar", "Puri", "Konark", "Cuttack", "Chilika Lake", "Gopalpur"],
            topAttractions: ["Konark Sun Temple (UNESCO Giant Stone Chariot)", "Jagannath Temple Puri & Ratha Yatra", "Chilika Lake (Asia's Largest Brackish Lagoon)", "Udayagiri & Khandagiri Caves", "Lingaraj Temple"],
            cuisineHighlights: "Chhena Poda (Burnt Cheese Dessert), Dalma, Rasagola, Pakhala Bhata, Crab Kalia, Machha Besara",
            bestSeason: "Oct – Mar",
            officialLanguage: "Odia",
            personalNotes: "Land of Kalinga architecture, sacred Jagannath Dham, Irrawaddy dolphin cruises on Chilika, and the colossal Sun Temple of Konark."
        ),
        TravelRecord(
            name: "Madhya Pradesh",
            stateCode: "MP",
            capital: "Bhopal",
            country: "India",
            zone: .central,
            latitude: 22.9734,
            longitude: 78.6569,
            status: .visited,
            dateVisited: Calendar.current.date(byAdding: .month, value: -5, to: Date()),
            timesVisited: 4,
            rating: 5,
            visitedCities: ["Indore", "Bhopal", "Gwalior", "Ujjain", "Khajuraho", "Jabalpur", "Pachmarhi", "Orchha"],
            topAttractions: ["Khajuraho UNESCO Temples", "Bhedaghat Marble Rocks & Dhuandhar Falls", "Mahakaleshwar Jyotirlinga Ujjain", "Gwalior Fort & Man Singh Palace", "Bandhavgarh & Kanha Tiger Reserves", "Sanchi Stupa"],
            cuisineHighlights: "Indori Poha Jalebi, Dal Bafla, Bhutte Ka Kees, Mawa Bati, Chhappan Dukan Street Food, Garadu",
            bestSeason: "Oct – Mar",
            officialLanguage: "Hindi",
            personalNotes: "Heart of Incredible India. Home to the highest tiger population, ancient Sanchi Buddhist stupas, and clean street food capital Indore."
        ),

        // =========================================================================
        // 🌐 7. SUBCONTINENT NEIGHBORS (NEPAL, BHUTAN, SRI LANKA)
        // =========================================================================

        TravelRecord(
            name: "Nepal",
            stateCode: "NP",
            capital: "Kathmandu",
            country: "Nepal",
            zone: .subcontinent,
            latitude: 28.3949,
            longitude: 84.1240,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Kathmandu", "Pokhara", "Lumbini", "Chitwan", "Bhaktapur", "Nagarkot"],
            topAttractions: ["Mount Everest & Annapurna Massifs", "Pashupatinath Sacred Shiva Temple", "Boudhanath & Swayambhunath Stupas", "Phewa Lake Pokhara", "Birthplace of Lord Buddha Lumbini"],
            cuisineHighlights: "Dal Bhat Tarkari, Momos with Sesame Dip, Thukpa, Newari Khaja Set, Sel Roti, Yomari",
            bestSeason: "Oct – Nov & Mar – May (Trekking Peaks)",
            officialLanguage: "Nepali",
            personalNotes: "Roof of the Himalayas with 8 of the world's 14 eight-thousanders, ancient pagoda temples, and birth soil of Gautama Buddha."
        ),
        TravelRecord(
            name: "Bhutan",
            stateCode: "BT",
            capital: "Thimphu",
            country: "Bhutan",
            zone: .subcontinent,
            latitude: 27.5142,
            longitude: 90.4336,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Thimphu", "Paro", "Punakha", "Phobjikha Valley", "Bumthang"],
            topAttractions: ["Paro Taktsang (Tiger's Nest Monastery on 900m Cliff)", "Punakha Dzong at River Confluence", "Buddha Dordenma Giant Statue", "Dochula Pass 108 Memorial Chortens"],
            cuisineHighlights: "Ema Datshi (Chili & Cheese), Kewa Datshi, Red Rice, Shamu Datshi, Suja (Butter Tea)",
            bestSeason: "Mar – May & Sep – Nov",
            officialLanguage: "Dzongkha",
            personalNotes: "The Kingdom of Gross National Happiness. World's only carbon-negative nation with pristine Himalayan forests and cliff monasteries."
        ),
        TravelRecord(
            name: "Sri Lanka",
            stateCode: "LK",
            capital: "Colombo / Sri Jayawardenepura",
            country: "Sri Lanka",
            zone: .subcontinent,
            latitude: 7.8731,
            longitude: 80.7718,
            status: .wishlist,
            rating: 5,
            visitedCities: ["Colombo", "Kandy", "Galle", "Ella", "Nuwara Eliya", "Sigiriya", "Mirissa"],
            topAttractions: ["Sigiriya Lion Rock Fortress (UNESCO)", "Nine Arch Bridge & Blue Train Ella", "Temple of the Sacred Tooth Relic Kandy", "Galle Dutch Fort", "Yala Leopard Safari"],
            cuisineHighlights: "Sri Lankan Crab Curry, Kottu Roti, Hopper with Egg, Pol Sambol, Fish Ambul Thiyal, Ceylon Tea",
            bestSeason: "Dec – Apr (West/South Coast)",
            officialLanguage: "Sinhala, Tamil, English",
            personalNotes: "Pearl of the Indian Ocean. Ancient Buddhist citadels, scenic hill country tea trains, and legendary Ramayana trail landscapes."
        )
    ]
}
