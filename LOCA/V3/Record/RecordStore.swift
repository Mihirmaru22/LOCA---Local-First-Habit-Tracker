import Foundation

// MARK: - RecordStoring protocol

/// The persistence contract for the Record layer.
///
/// Implementors must be actors (Sendable + Actor) so they can be stored in
/// RecordEngine and called across concurrency boundaries safely.
///
/// RecordEngine is the ONLY caller of append(). Nothing else may write
/// to the store directly — all writes go through RecordEngine's serialized,
/// dedup-checking write path.
protocol RecordStoring: Actor {
    /// Durably store a fact. Called only by RecordEngine.
    /// May throw RecordError.storageFailure if the underlying store fails.
    func append(_ fact: Fact) throws

    /// Return facts matching the query, sorted per query.order.
    func facts(matching query: RecordQuery) throws -> [Fact]

    /// Return every fact in the store, sorted recordedAt ascending.
    /// Used for replay and full export.
    func allFacts() throws -> [Fact]

    /// Count facts matching the query without loading them into memory.
    func count(matching query: RecordQuery) throws -> Int

    /// Return the set of all fact IDs currently in the store.
    /// Used by RecordEngine to rebuild its dedup state (e.g. on warm restart
    /// from a persistent store). The in-memory implementation returns its
    /// live id set; a persistent implementation scans the store.
    func existingIDs() throws -> Set<UUID>
}

// MARK: - InMemoryRecordStore

/// An in-memory RecordStoring implementation for testing and replay.
///
/// This store is the reference implementation:
///  - Append-only: `append()` is the only write; there is no update or delete.
///  - Deterministic: `allFacts()` returns facts in the order they were appended.
///  - Fast: all operations are O(n) or O(1) over in-memory arrays/sets.
///
/// Production code will use a persistent store (file-backed or SwiftData-backed)
/// that conforms to RecordStoring behind the same contract.
actor InMemoryRecordStore: RecordStoring {

    private var storage: [Fact] = []
    private var idSet: Set<UUID> = []

    // MARK: - RecordStoring

    func append(_ fact: Fact) throws {
        storage.append(fact)
        idSet.insert(fact.id)
    }

    func facts(matching query: RecordQuery) throws -> [Fact] {
        var result = storage.filter { fact in
            if let kinds = query.kinds, !kinds.contains(fact.kind) { return false }
            if let range = query.dateRange, !range.contains(fact.occurredAt) { return false }
            if let sources = query.sources, !sources.contains(fact.provenance.source) { return false }
            return true
        }

        result = applyOrder(result, order: query.order)

        let start = min(query.offset, result.count)
        result = Array(result.dropFirst(start))

        if let limit = query.limit {
            result = Array(result.prefix(limit))
        }

        return result
    }

    func allFacts() throws -> [Fact] {
        storage.sorted { $0.recordedAt < $1.recordedAt }
    }

    func count(matching query: RecordQuery) throws -> Int {
        try facts(matching: query).count
    }

    func existingIDs() throws -> Set<UUID> {
        idSet
    }

    // MARK: - Private helpers

    private func applyOrder(_ facts: [Fact], order: RecordOrder) -> [Fact] {
        switch order {
        case .recordedAtAscending:   return facts.sorted { $0.recordedAt < $1.recordedAt }
        case .recordedAtDescending:  return facts.sorted { $0.recordedAt > $1.recordedAt }
        case .occurredAtAscending:   return facts.sorted { $0.occurredAt < $1.occurredAt }
        case .occurredAtDescending:  return facts.sorted { $0.occurredAt > $1.occurredAt }
        }
    }
}
