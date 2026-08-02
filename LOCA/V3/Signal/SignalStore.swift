import Foundation

// MARK: - SignalStoring protocol

/// The persistence contract for the Signal layer.
///
/// SignalEngine is the ONLY caller of append() and clear().
/// All reads are available to any consumer.
protocol SignalStoring: Actor {
    /// Store a signal. Called only by SignalEngine.
    func append(_ signal: Signal) throws

    /// Return all signals in insertion order.
    func allSignals() throws -> [Signal]

    /// Return the signal produced from the given Fact, or nil if none exists.
    func signal(forFactID id: UUID) throws -> Signal?

    /// Return the set of all source Fact IDs for which signals exist.
    /// Used by SignalEngine to rebuild dedup state on init.
    func existingFactIDs() throws -> Set<UUID>

    /// Remove all signals. Called exclusively during replay.
    func clear() throws

    /// Total number of signals in the store.
    func count() throws -> Int
}

// MARK: - InMemorySignalStore

/// An in-memory SignalStoring implementation for testing and replay.
///
/// Properties:
///  - Append-only: clear() is the only bulk write; append() is the single write.
///  - Deterministic: allSignals() returns signals in insertion order.
///  - O(1) lookup: signal(forFactID:) uses a dictionary index.
actor InMemorySignalStore: SignalStoring {

    private var storage: [Signal] = []
    private var factIDIndex: [UUID: Int] = [:]

    func append(_ signal: Signal) throws {
        let index = storage.count
        storage.append(signal)
        factIDIndex[signal.provenance.sourceFactID] = index
    }

    func allSignals() throws -> [Signal] {
        storage
    }

    func signal(forFactID id: UUID) throws -> Signal? {
        guard let index = factIDIndex[id] else { return nil }
        return storage[index]
    }

    func existingFactIDs() throws -> Set<UUID> {
        Set(factIDIndex.keys)
    }

    func clear() throws {
        storage = []
        factIDIndex = [:]
    }

    func count() throws -> Int {
        storage.count
    }
}
