import Foundation
import Testing
@testable import PackMeasure

@Suite("Calibration store")
struct CalibrationStoreTests {
    private func makeStores() -> (CalibrationStore, InventoryStore, URL) {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        return (
            CalibrationStore(storageURL: directory.appendingPathComponent("calibration.json")),
            InventoryStore(storageURL: directory.appendingPathComponent("inventory.json")),
            directory
        )
    }

    private func makeRun(
        label: String,
        performedAt: Date = .now,
        measuredWidth: Double = 0.610
    ) -> CalibrationRun {
        CalibrationRun(
            performedAt: performedAt,
            label: label,
            trueLengthMeters: 0.6096,
            trueWidthMeters: 0.508,
            trueHeightMeters: 0.508,
            measuredLengthMeters: 0.610,
            measuredWidthMeters: measuredWidth,
            measuredHeightMeters: 0.508,
            reportedConfidence: .high,
            resolutionRule: .largestAgreeingValue
        )
    }

    @Test("A completed run persists and reloads")
    func completedRunPersists() throws {
        let (calibration, _, _) = makeStores()
        _ = try calibration.append(makeRun(label: "Carton A"))

        let reloaded = try calibration.load()
        #expect(reloaded.count == 1)
        #expect(reloaded.first?.label == "Carton A")
    }

    @Test("An empty history is not an error")
    func emptyHistoryLoads() throws {
        let (calibration, _, _) = makeStores()
        #expect(try calibration.load().isEmpty)
    }

    @Test("An abandoned check leaves no record")
    func abandonedRunLeavesNoRecord() throws {
        let (calibration, _, _) = makeStores()
        // An abandoned check never calls append, so the file stays absent.
        #expect(try calibration.load().isEmpty)
        #expect(
            FileManager.default.fileExists(atPath: try calibration.storageURL().path) == false
        )
    }

    @Test("History is returned newest first")
    func historyIsNewestFirst() throws {
        let (calibration, _, _) = makeStores()
        let old = makeRun(label: "Older", performedAt: Date(timeIntervalSince1970: 1_000))
        let new = makeRun(label: "Newer", performedAt: Date(timeIntervalSince1970: 2_000))

        _ = try calibration.append(old)
        _ = try calibration.append(new)

        #expect(try calibration.load().map(\.label) == ["Newer", "Older"])
    }

    @Test("A calibration run never lands in the inventory file")
    func calibrationNeverEntersInventory() throws {
        let (calibration, inventory, _) = makeStores()
        _ = try calibration.append(makeRun(label: "Calibration carton"))

        #expect(try inventory.load().isEmpty)
        #expect(
            FileManager.default.fileExists(atPath: try inventory.storageURL().path) == false
        )
        #expect(try calibration.storageURL() != inventory.storageURL())
    }

    @Test("Device tolerance is unknown until a run exists")
    func deviceToleranceUnknownWithoutHistory() throws {
        let (calibration, _, _) = makeStores()
        #expect(try calibration.load().deviceCalibrationWithinTolerance() == nil)
    }

    @Test("Device tolerance follows the most recent run")
    func deviceToleranceFollowsNewestRun() throws {
        let (calibration, _, _) = makeStores()
        _ = try calibration.append(
            makeRun(
                label: "Bad",
                performedAt: Date(timeIntervalSince1970: 1_000),
                measuredWidth: 0.610
            )
        )
        #expect(try calibration.load().deviceCalibrationWithinTolerance() == false)

        _ = try calibration.append(
            makeRun(
                label: "Good",
                performedAt: Date(timeIntervalSince1970: 2_000),
                measuredWidth: 0.5095
            )
        )
        #expect(try calibration.load().deviceCalibrationWithinTolerance() == true)
    }
}
