import Foundation
import Testing
@testable import PackMeasure

/// Guards the error math in
/// specs/001-measurement-accuracy-units/contracts/calibration-store.md.
@Suite("Calibration run")
struct CalibrationRunTests {
    /// The documented alpha failure: a 24 x 20 x 20 in carton read as
    /// 24 x 24 x 20 in. Two axes are fine and one is badly wrong, which is
    /// exactly why error is reported per axis and never averaged.
    private func documentedFailure() -> CalibrationRun {
        CalibrationRun(
            label: "Known carton 24x20x20",
            trueLengthMeters: 0.6096,
            trueWidthMeters: 0.508,
            trueHeightMeters: 0.508,
            measuredLengthMeters: 0.610,
            measuredWidthMeters: 0.610,
            measuredHeightMeters: 0.508,
            reportedConfidence: .high,
            resolutionRule: .largestAgreeingValue
        )
    }

    @Test("Per-axis absolute error matches the contract's worked example")
    func absoluteErrorPerAxis() {
        let run = documentedFailure()
        #expect(abs(run.absoluteErrorMeters(for: .width) - 0.102) < 0.0005)
        #expect(run.absoluteErrorMeters(for: .length) < 0.001)
        #expect(run.absoluteErrorMeters(for: .height) < 0.001)
    }

    @Test("Per-axis percent error matches the contract's worked example")
    func percentErrorPerAxis() throws {
        let run = documentedFailure()
        let widthError = try #require(run.percentError(for: .width))
        #expect(abs(widthError - 20.1) < 0.2)

        let lengthError = try #require(run.percentError(for: .length))
        #expect(lengthError < 1.0)
    }

    @Test("Two good axes never rescue a failing one")
    func oneBadAxisFailsTheRun() {
        let run = documentedFailure()
        #expect(run.isWithinTolerance(for: .length))
        #expect(run.isWithinTolerance(for: .height))
        #expect(run.isWithinTolerance(for: .width) == false)
        #expect(run.isWithinTolerance() == false)
        #expect(run.worstAxis() == .width)
    }

    @Test("A run inside both bounds on every axis passes")
    func accurateRunPasses() {
        let run = CalibrationRun(
            label: "Good carton",
            trueLengthMeters: 0.6096,
            trueWidthMeters: 0.508,
            trueHeightMeters: 0.508,
            measuredLengthMeters: 0.6100,
            measuredWidthMeters: 0.5095,
            measuredHeightMeters: 0.5070,
            reportedConfidence: .high,
            resolutionRule: .largestAgreeingValue
        )
        #expect(run.isWithinTolerance())
    }

    @Test("Error figures are derived, so they cannot drift from their inputs")
    func errorIsDerivedNotStored() throws {
        var run = documentedFailure()
        let before = run.absoluteErrorMeters(for: .width)

        run.measuredWidthMeters = 0.508
        let after = run.absoluteErrorMeters(for: .width)

        #expect(before != after)
        #expect(after < 0.001)

        // Nothing named "error" is encoded; the figures are computed on read.
        let json = try JSONSerialization.jsonObject(
            with: try JSONEncoder().encode(run)
        ) as? [String: Any]
        let keys = Set((json ?? [:]).keys)
        #expect(keys.contains("measuredWidthMeters"))
        #expect(keys.contains(where: { $0.lowercased().contains("error") }) == false)
    }

    @Test("A non-positive truth yields no percentage rather than a fabricated one")
    func nonPositiveTruthHasNoPercentage() {
        let run = CalibrationRun(
            label: "Bad input",
            trueLengthMeters: 0,
            trueWidthMeters: 0.5,
            trueHeightMeters: 0.5,
            measuredLengthMeters: 0.6,
            measuredWidthMeters: 0.5,
            measuredHeightMeters: 0.5,
            reportedConfidence: .low,
            resolutionRule: .largestAgreeingValue
        )
        #expect(run.percentError(for: .length) == nil)
        #expect(run.isWithinTolerance(for: .length) == false)
    }

    @Test("A run round-trips through JSON with its per-angle evidence")
    func roundTripsWithAngles() throws {
        var run = documentedFailure()
        run.angleMeasurements = [
            AngleMeasurement(
                sequence: 1,
                lengthMeters: 0.610,
                widthMeters: 0.573,
                heightMeters: 0.508,
                pointCloudConfidence: .high,
                agreedWithConsensus: true,
                contributedAcceptedValue: [.length]
            )
        ]
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        let decoded = try decoder.decode(
            CalibrationRun.self,
            from: try encoder.encode(run)
        )
        #expect(decoded.angleMeasurements.count == 1)
        #expect(decoded.angleMeasurements.first?.sequence == 1)
    }
}
