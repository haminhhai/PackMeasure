import Foundation
import Testing
@testable import PackMeasure

/// Covers FR-030, FR-031 and FR-032: an accepted estimate must stay auditable,
/// and an item that predates provenance must say so rather than show invented
/// rows.
@Suite("Measurement detail")
struct MeasurementDetailTests {
    private static func makeStore() -> InventoryStore {
        InventoryStore(
            storageURL: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
                .appendingPathComponent("inventory.json")
        )
    }

    private func angle(
        _ sequence: Int,
        width: Double,
        agreed: Bool,
        contributed: Set<DimensionAxis> = []
    ) -> AngleMeasurement {
        AngleMeasurement(
            sequence: sequence,
            lengthMeters: 0.610,
            widthMeters: width,
            heightMeters: 0.508,
            pointCloudConfidence: .high,
            agreedWithConsensus: agreed,
            contributedAcceptedValue: contributed
        )
    }

    @Test("Every contributing angle is exposed beside the accepted value")
    func everyAngleIsExposed() throws {
        let item = MeasuredItem(
            name: "Carton",
            lengthMeters: 0.610,
            widthMeters: 0.573,
            heightMeters: 0.508,
            confidence: .high,
            angleMeasurements: [
                angle(1, width: 0.573, agreed: true, contributed: [.length, .width, .height]),
                angle(2, width: 0.551, agreed: true),
                angle(3, width: 0.610, agreed: false)
            ],
            resolutionRule: .largestAgreeingValue
        )

        let angles = try #require(item.angleMeasurements)
        #expect(angles.count == 3)
        #expect(angles.map(\.sequence) == [1, 2, 3])
        #expect(angles.map(\.widthMeters) == [0.573, 0.551, 0.610])
    }

    @Test("The detail records which angles agreed and which supplied the value")
    func agreementAndContributionAreRecorded() throws {
        let item = MeasuredItem(
            name: "Carton",
            lengthMeters: 0.610,
            widthMeters: 0.573,
            heightMeters: 0.508,
            confidence: .high,
            angleMeasurements: [
                angle(1, width: 0.573, agreed: true, contributed: [.width]),
                angle(2, width: 0.551, agreed: true),
                angle(3, width: 0.610, agreed: false)
            ],
            resolutionRule: .largestAgreeingValue
        )

        let angles = try #require(item.angleMeasurements)
        #expect(angles.filter(\.agreedWithConsensus).count == 2)
        #expect(angles[0].contributedAcceptedValue == [.width])
        #expect(angles[2].agreedWithConsensus == false)
        #expect(angles[2].contributedAcceptedValue.isEmpty)
    }

    @Test("The rule that produced the value is recorded")
    func resolutionRuleIsRecorded() {
        let item = MeasuredItem(
            name: "Carton",
            lengthMeters: 0.610,
            widthMeters: 0.508,
            heightMeters: 0.508,
            confidence: .high,
            resolutionRule: .largestAgreeingValue
        )
        #expect(item.resolutionRule == .largestAgreeingValue)
        #expect(item.resolutionRule?.displayName == "Largest agreeing value")
    }

    @Test("An item saved before provenance existed reports detail as unavailable")
    func legacyItemHasNoFabricatedRows() {
        let legacy = MeasuredItem(
            name: "Legacy carton",
            lengthMeters: 0.610,
            widthMeters: 0.508,
            heightMeters: 0.508,
            confidence: .medium
        )
        // Absent, never an empty array that would render as zero rows.
        #expect(legacy.angleMeasurements == nil)
        #expect(legacy.resolutionRule == nil)
        #expect(legacy.toleranceStatus == nil)
    }

    @Test("Saving with no angles records absence rather than an empty list")
    @MainActor
    func emptyAngleListIsStoredAsAbsent() throws {
        let store = Self.makeStore()
        let model = AppModel(store: store)
        model.addItem(
            name: "Manual carton",
            estimate: MeasurementEstimate(
                lengthMeters: 0.610,
                widthMeters: 0.508,
                heightMeters: 0.508,
                confidence: .high,
                sampleCount: 0,
                frameCount: 0
            ),
            quantity: 1,
            angleMeasurements: []
        )

        #expect(model.items.first?.angleMeasurements == nil)
    }

    @Test("The workflow's provenance survives a save and reload")
    @MainActor
    func provenanceRoundTripsThroughTheStore() throws {
        let store = Self.makeStore()
        let model = AppModel(store: store)
        model.addItem(
            name: "Carton",
            estimate: MeasurementEstimate(
                lengthMeters: 0.610,
                widthMeters: 0.573,
                heightMeters: 0.508,
                confidence: .high,
                sampleCount: 1_200,
                frameCount: 3,
                comparisonAngleCount: 3,
                comparisonAgreementCount: 2
            ),
            quantity: 1,
            angleMeasurements: [
                angle(1, width: 0.573, agreed: true, contributed: [.width]),
                angle(2, width: 0.551, agreed: true)
            ],
            resolutionRule: .largestAgreeingValue
        )

        let reloaded = AppModel(store: store)
        reloaded.loadIfNeeded()
        let item = try #require(reloaded.items.first)

        #expect(item.angleMeasurements?.count == 2)
        #expect(item.resolutionRule == .largestAgreeingValue)
        #expect(item.angleMeasurements?.first?.contributedAcceptedValue == [.width])
    }
}
