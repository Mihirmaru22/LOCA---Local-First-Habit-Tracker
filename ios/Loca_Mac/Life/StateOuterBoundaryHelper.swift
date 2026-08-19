import Foundation
import CoreLocation

// MARK: - StateOuterBoundaryHelper

/// Extracts and caches exact, high-precision outer perimeter boundary loops for any Indian State
/// from its constituent high-resolution district boundary dataset, eliminating all internal district lines.
enum StateOuterBoundaryHelper {

    // Cached processed outer boundary coordinate loops keyed by stateCode
    private static var boundaryCache: [String: [[CLLocationCoordinate2D]]] = [:]

    /// Returns the exact outer perimeter boundary loops for the given state code.
    static func outerBoundaries(for stateCode: String) -> [[CLLocationCoordinate2D]] {
        let code = stateCode.uppercased()
        if let cached = boundaryCache[code] {
            return cached
        }

        let districts = IndianDistrictBoundaryData.districts(for: code)
        guard !districts.isEmpty else {
            // Fallback to IndianStateBoundaryData if no districts exist
            if let fallback = IndianStateBoundaryData.polygon(for: code) {
                boundaryCache[code] = [fallback]
                return [fallback]
            }
            return []
        }

        // Structure for undirected edge matching (rounded to 3 decimal places ~100m for robust topological joining)
        struct PointKey: Hashable {
            let lat: Int
            let lon: Int

            init(coord: CLLocationCoordinate2D) {
                self.lat = Int((coord.latitude * 1000).rounded())
                self.lon = Int((coord.longitude * 1000).rounded())
            }
        }

        struct EdgeKey: Hashable {
            let p1: PointKey
            let p2: PointKey

            init(_ c1: CLLocationCoordinate2D, _ c2: CLLocationCoordinate2D) {
                let k1 = PointKey(coord: c1)
                let k2 = PointKey(coord: c2)
                if k1.lat < k2.lat || (k1.lat == k2.lat && k1.lon < k2.lon) {
                    self.p1 = k1
                    self.p2 = k2
                } else {
                    self.p1 = k2
                    self.p2 = k1
                }
            }
        }

        struct DirectedEdge {
            let start: CLLocationCoordinate2D
            let end: CLLocationCoordinate2D
            let key: EdgeKey
        }

        var edgeCounts: [EdgeKey: Int] = [:]
        var allDirectedEdges: [DirectedEdge] = []

        for district in districts {
            let coords = district.coordinates
            guard coords.count >= 3 else { continue }
            for i in 0..<coords.count {
                let nextIdx = (i + 1) % coords.count
                let c1 = coords[i]
                let c2 = coords[nextIdx]
                let key = EdgeKey(c1, c2)
                edgeCounts[key, default: 0] += 1
                allDirectedEdges.append(DirectedEdge(start: c1, end: c2, key: key))
            }
        }

        // Keep only boundary edges (edges that appear exactly once across all districts of this state)
        let outerEdges = allDirectedEdges.filter { edgeCounts[$0.key] == 1 }
        guard !outerEdges.isEmpty else {
            if let fallback = IndianStateBoundaryData.polygon(for: code) {
                boundaryCache[code] = [fallback]
                return [fallback]
            }
            return []
        }

        // Assemble outer edges into continuous perimeter loops
        var adjacency: [PointKey: [(CLLocationCoordinate2D, PointKey)]] = [:]
        for edge in outerEdges {
            let startKey = PointKey(coord: edge.start)
            let endKey = PointKey(coord: edge.end)
            adjacency[startKey, default: []].append((edge.end, endKey))
        }

        var visitedEdges = Set<EdgeKey>()
        var loops: [[CLLocationCoordinate2D]] = []

        for edge in outerEdges {
            if visitedEdges.contains(edge.key) { continue }

            var currentLoop: [CLLocationCoordinate2D] = [edge.start]
            var currentCoord = edge.end
            var currentKey = PointKey(coord: edge.end)
            visitedEdges.insert(edge.key)
            currentLoop.append(currentCoord)

            let maxSteps = outerEdges.count + 10
            var steps = 0

            while steps < maxSteps {
                steps += 1
                guard let neighbors = adjacency[currentKey] else { break }

                var foundNext = false
                for (nextCoord, nextKey) in neighbors {
                    let nextEdgeKey = EdgeKey(currentCoord, nextCoord)
                    if !visitedEdges.contains(nextEdgeKey) {
                        visitedEdges.insert(nextEdgeKey)
                        currentLoop.append(nextCoord)
                        currentCoord = nextCoord
                        currentKey = nextKey
                        foundNext = true
                        break
                    }
                }

                if !foundNext { break }
                if PointKey(coord: currentCoord) == PointKey(coord: currentLoop[0]) && currentLoop.count > 3 {
                    break
                }
            }

            if currentLoop.count >= 4 {
                loops.append(currentLoop)
            }
        }

        let result = loops.isEmpty ? (IndianStateBoundaryData.polygon(for: code).map { [$0] } ?? []) : loops
        boundaryCache[code] = result
        return result
    }
}
