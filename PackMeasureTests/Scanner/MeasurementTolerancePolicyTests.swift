import Testing
@testable import PackMeasure

/// Covers FR-001, FR-002, FR-011 and FR-029.
@Suite("Measurement tolerance policy")
struct MeasurementTolerancePolicyTests {
    private func angle(
        _ sequence: Int,
        length: Double,
        width: Double,
        height: Double,
        confidence: ScanConfidence = .high,
        agreed: Bool = true
    ) -> AngleMeasurement {
        AngleMeasurement(
            sequence: sequence,
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height,
            pointCloudConfidence: confidence,
            agreedWithConsensus: agreed
        )
    }

    @Test("A device with no calibration history reports unknown, never within tolerance")
    func unknownWithoutCalibrationHistory() {
        let status = MeasurementTolerancePolicy().status(
            confidence: .high,
            angleMeasurements: [
                angle(1, length: 0.610, width: 0.508, height: 0.508),
                angle(2, length: 0.612, width: 0.509, height: 0.508)
            ],
            deviceCalibrationWithinTolerance: nil
        )
        #expect(status == .unknown)
        #expect(status != .withinTolerance)
    }

    @Test("A calibrated device with tight agreeing angles is within tolerance")
    func withinToleranceWhenCalibratedAndTight() {
        let status = MeasurementTolerancePolicy().status(
            confidence: .high,
            angleMeasurements: [
                angle(1, length: 0.610, width: 0.508, height: 0.508),
                angle(2, length: 0.612, width: 0.509, height: 0.508)
            ],
            deviceCalibrationWithinTolerance: true
        )
        #expect(status == .withinTolerance)
    }

    @Test("A device measured outside tolerance stays flagged")
    func belowToleranceWhenDeviceCalibrationFailed() {
        let status = MeasurementTolerancePolicy().status(
            confidence: .high,
            angleMeasurements: [angle(1, length: 0.610, width: 0.508, height: 0.508)],
            deviceCalibrationWithinTolerance: false
        )
        #expect(status == .belowTolerance)
    }

    @Test("Low confidence is below tolerance regardless of calibration")
    func lowConfidenceIsBelowTolerance() {
        let status = MeasurementTolerancePolicy().status(
            confidence: .low,
            angleMeasurements: [angle(1, length: 0.610, width: 0.508, height: 0.508)],
            deviceCalibrationWithinTolerance: true
        )
        #expect(status == .belowTolerance)
    }

    @Test("A wide spread between contributing angles is below tolerance")
    func wideAngleSpreadIsBelowTolerance() {
        // 0.508 against 0.573 is a 11.3% spread on the width axis: inside the
        // agreement gate, outside what the tolerance can support.
        let status = MeasurementTolerancePolicy().status(
            confidence: .high,
            angleMeasurements: [
                angle(1, length: 0.610, width: 0.508, height: 0.508),
                angle(2, length: 0.610, width: 0.573, height: 0.508)
            ],
            deviceCalibrationWithinTolerance: true
        )
        #expect(status == .belowTolerance)
    }

    @Test("Angles that did not agree are excluded from the spread check")
    func disagreeingAnglesAreIgnored() {
        let policy = MeasurementTolerancePolicy()
        #expect(policy.exceedsSpread([
            angle(1, length: 0.610, width: 0.508, height: 0.508),
            angle(2, length: 0.610, width: 0.900, height: 0.508, agreed: false)
        ]) == false)
    }

    @Test("A single angle cannot establish a spread")
    func singleAngleHasNoSpread() {
        #expect(MeasurementTolerancePolicy().exceedsSpread([
            angle(1, length: 0.610, width: 0.508, height: 0.508)
        ]) == false)
    }

    @Test("belowTolerance is the only status that offers a retake")
    func onlyBelowToleranceOffersRetake() {
        #expect(ToleranceStatus.belowTolerance.requiresRetakeOffer)
        #expect(ToleranceStatus.withinTolerance.requiresRetakeOffer == false)
        #expect(ToleranceStatus.unknown.requiresRetakeOffer == false)
    }

    @Test("Accuracy tolerance requires both the relative and the absolute bound")
    func toleranceRequiresBothBounds() {
        let tolerance = AccuracyTolerance.standard
        // The documented alpha failure: 0.508 m truth read as 0.610 m.
        #expect(tolerance.isWithinTolerance(measured: 0.610, trueValue: 0.508) == false)
        // Within 5% but outside the 20 mm absolute bound.
        #expect(tolerance.isWithinTolerance(measured: 1.030, trueValue: 1.000) == false)
        // Within both.
        #expect(tolerance.isWithinTolerance(measured: 0.515, trueValue: 0.508))
        // A non-positive truth cannot be scored and fails closed.
        #expect(tolerance.isWithinTolerance(measured: 0.5, trueValue: 0) == false)
    }

    @Test("Agreement between angles does not by itself produce high confidence")
    func agreementDoesNotImplyAccuracy() {
        // Two angles agreeing closely, both with only medium point-cloud
        // evidence, must not be reported as high confidence (FR-011).
        let reported = MeasurementCompletenessPolicy().reportedConfidence(
            pointCloudConfidence: .medium,
            evidence: .independentViewpoints
        )
        #expect(reported == .medium)
    }

    @Test("Adjacent-surface rejection names the obstruction")
    func adjacentSurfaceRejectionNamesObstruction() {
        let reason = CenteredTargetRejection.adjacentSurfaceContamination.reason
        #expect(reason.contains("separated"))
        #expect(reason.contains("pallet") || reason.contains("wall"))
        #expect(reason != CenteredTargetRejection.floorSurface.reason)
    }
}
