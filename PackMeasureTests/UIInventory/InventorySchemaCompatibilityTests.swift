import Foundation
import Testing
@testable import PackMeasure

/// Guards the contract in specs/001-measurement-accuracy-units/contracts/inventory-schema.md:
/// a file written by any previously released build must keep loading, and the
/// three fields added by this feature must decode as `nil` rather than as a
/// substituted default that could be mistaken for real data.
struct InventorySchemaCompatibilityTests {
    private let legacyPayload = """
    [
      {
        "id": "8C6E5F2A-0A1B-4C3D-9E8F-1A2B3C4D5E6F",
        "name": "Carton A",
        "lengthMeters": 0.61,
        "widthMeters": 0.508,
        "heightMeters": 0.508,
        "quantity": 2,
        "confidence": "high",
        "comparisonAngleCount": 3,
        "comparisonAgreementCount": 3,
        "capturedAt": 1758412800.0,
        "stackability": { "notStackable": {} },
        "orientationPolicy": "keepUpright"
      }
    ]
    """

    private func makeStore() -> (InventoryStore, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("inventory.json")
        return (InventoryStore(storageURL: url), url)
    }

    @Test
    func legacyFileDecodesWithNewFieldsAbsent() throws {
        let (store, url) = makeStore()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(legacyPayload.utf8).write(to: url)

        let items = try store.load()
        #expect(items.count == 1)
        let item = try #require(items.first)

        // No data loss on the existing fields.
        #expect(item.name == "Carton A")
        #expect(item.quantity == 2)
        #expect(item.confidence == .high)
        #expect(item.comparisonAngleCount == 3)

        // The additions decode as absent, never as a substituted value.
        #expect(item.angleMeasurements == nil)
        #expect(item.resolutionRule == nil)
        #expect(item.toleranceStatus == nil)
    }

    @Test
    func unrecognizedResolutionRuleDecodesAsNilRatherThanThrowing() throws {
        let forwardPayload = """
        [
          {
            "id": "8C6E5F2A-0A1B-4C3D-9E8F-1A2B3C4D5E6F",
            "name": "Carton B",
            "lengthMeters": 0.61,
            "widthMeters": 0.508,
            "heightMeters": 0.508,
            "quantity": 1,
            "confidence": "medium",
            "capturedAt": 1758412800.0,
            "stackability": { "notStackable": {} },
            "orientationPolicy": "keepUpright",
            "resolutionRule": "someFutureRuleThisBuildDoesNotKnow",
            "toleranceStatus": "someFutureStatus"
          }
        ]
        """
        let (store, url) = makeStore()
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data(forwardPayload.utf8).write(to: url)

        let items = try store.load()
        #expect(items.count == 1)
        #expect(items.first?.resolutionRule == nil)
        #expect(items.first?.toleranceStatus == nil)
    }

    @Test
    func newFieldsSurviveASaveAndLoadCycle() throws {
        let (store, _) = makeStore()
        let angle = AngleMeasurement(
            sequence: 1,
            lengthMeters: 0.61,
            widthMeters: 0.51,
            heightMeters: 0.508,
            pointCloudConfidence: .high,
            agreedWithConsensus: true,
            contributedAcceptedValue: [.length]
        )
        let item = MeasuredItem(
            name: "Carton C",
            lengthMeters: 0.61,
            widthMeters: 0.51,
            heightMeters: 0.508,
            confidence: .high,
            angleMeasurements: [angle],
            resolutionRule: .largestAgreeingValue,
            toleranceStatus: .withinTolerance
        )

        try store.save([item])
        let reloaded = try store.load()

        #expect(reloaded.first?.angleMeasurements == [angle])
        #expect(reloaded.first?.resolutionRule == .largestAgreeingValue)
        #expect(reloaded.first?.toleranceStatus == .withinTolerance)
    }
}
