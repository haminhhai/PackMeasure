import Foundation

/// Local, device-scoped calibration history.
///
/// Deliberately a different file from the inventory: keeping the two apart
/// makes "a calibration carton is never a measured item" a structural property
/// rather than a filter a later change could break (FR-026). Nothing here is
/// transmitted anywhere.
struct CalibrationStore {
    private let fileManager: FileManager
    private let explicitStorageURL: URL?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileManager: FileManager = .default, storageURL: URL? = nil) {
        self.fileManager = fileManager
        explicitStorageURL = storageURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .secondsSince1970
        decoder.dateDecodingStrategy = .secondsSince1970
    }

    /// Newest first (FR-027).
    func load() throws -> [CalibrationRun] {
        let url = try storageURL()
        guard fileManager.fileExists(atPath: url.path) else { return [] }
        let data = try Data(contentsOf: url)
        return try decoder.decode([CalibrationRun].self, from: data)
            .sorted { $0.performedAt > $1.performedAt }
    }

    /// Only completed runs reach here; an abandoned check never calls save
    /// (FR-028).
    func save(_ runs: [CalibrationRun]) throws {
        let url = try storageURL()
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(runs.sorted { $0.performedAt > $1.performedAt })
        try data.write(to: url, options: .atomic)
    }

    func append(_ run: CalibrationRun) throws -> [CalibrationRun] {
        var runs = try load()
        runs.append(run)
        try save(runs)
        return try load()
    }

    func storageURL() throws -> URL {
        if let explicitStorageURL { return explicitStorageURL }
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return base
            .appendingPathComponent("PackMeasure", isDirectory: true)
            .appendingPathComponent("calibration.json")
    }
}

extension Array where Element == CalibrationRun {
    /// Whether this device's most recent evidence supports the tolerance.
    /// `nil` when there is no history, which the UI must show as unknown rather
    /// than as a pass (FR-029).
    func deviceCalibrationWithinTolerance(
        tolerance: AccuracyTolerance = .standard
    ) -> Bool? {
        guard let newest = self.max(by: { $0.performedAt < $1.performedAt }) else {
            return nil
        }
        return newest.isWithinTolerance(tolerance)
    }
}
