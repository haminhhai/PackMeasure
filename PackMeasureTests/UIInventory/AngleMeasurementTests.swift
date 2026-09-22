import Foundation
import Testing
@testable import PackMeasure

struct AngleMeasurementTests {
    private func makeAngle() -> AngleMeasurement {
        AngleMeasurement(
            sequence: 2,
            lengthMeters: 0.610,
            widthMeters: 0.573,
            heightMeters: 0.508,
            pointCloudConfidence: .high,
            agreedWithConsensus: true,
            contributedAcceptedValue: [.length, .height]
        )
    }

    @Test
    func roundTripsThroughJSON() throws {
        let original = makeAngle()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(AngleMeasurement.self, from: data)
        #expect(decoded == original)
        #expect(decoded.contributedAcceptedValue == [.length, .height])
    }

    @Test
    func reportsValuePerAxis() {
        let angle = makeAngle()
        #expect(angle.value(for: .length) == 0.610)
        #expect(angle.value(for: .width) == 0.573)
        #expect(angle.value(for: .height) == 0.508)
    }

    @Test
    func rejectsNonPositiveDimensions() {
        let angle = AngleMeasurement(
            sequence: 1,
            lengthMeters: 0.5,
            widthMeters: 0,
            heightMeters: 0.4,
            pointCloudConfidence: .low,
            agreedWithConsensus: false
        )
        #expect(angle.hasValidDimensions == false)
    }
}
