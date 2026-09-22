import Foundation

/// One known-carton check: what the carton actually measures, what the app
/// said, and the raw per-angle evidence behind that claim.
///
/// Stored separately from the inventory so a calibration carton can never
/// become a measured item (FR-026). Error figures are computed, never stored,
/// so they cannot drift from their inputs.
struct CalibrationRun: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var performedAt: Date
    var label: String
    var trueLengthMeters: Double
    var trueWidthMeters: Double
    var trueHeightMeters: Double
    var measuredLengthMeters: Double
    var measuredWidthMeters: Double
    var measuredHeightMeters: Double
    var reportedConfidence: ScanConfidence
    var resolutionRule: ResolutionRule
    var angleMeasurements: [AngleMeasurement]

    init(
        id: UUID = UUID(),
        performedAt: Date = .now,
        label: String,
        trueLengthMeters: Double,
        trueWidthMeters: Double,
        trueHeightMeters: Double,
        measuredLengthMeters: Double,
        measuredWidthMeters: Double,
        measuredHeightMeters: Double,
        reportedConfidence: ScanConfidence,
        resolutionRule: ResolutionRule,
        angleMeasurements: [AngleMeasurement] = []
    ) {
        self.id = id
        self.performedAt = performedAt
        self.label = label
        self.trueLengthMeters = trueLengthMeters
        self.trueWidthMeters = trueWidthMeters
        self.trueHeightMeters = trueHeightMeters
        self.measuredLengthMeters = measuredLengthMeters
        self.measuredWidthMeters = measuredWidthMeters
        self.measuredHeightMeters = measuredHeightMeters
        self.reportedConfidence = reportedConfidence
        self.resolutionRule = resolutionRule
        self.angleMeasurements = angleMeasurements
    }

    func trueValue(for axis: DimensionAxis) -> Double {
        switch axis {
        case .length: trueLengthMeters
        case .width: trueWidthMeters
        case .height: trueHeightMeters
        }
    }

    func measuredValue(for axis: DimensionAxis) -> Double {
        switch axis {
        case .length: measuredLengthMeters
        case .width: measuredWidthMeters
        case .height: measuredHeightMeters
        }
    }

    func absoluteErrorMeters(for axis: DimensionAxis) -> Double {
        abs(measuredValue(for: axis) - trueValue(for: axis))
    }

    /// `nil` when the entered truth is not a usable positive value, so the UI
    /// shows no percentage rather than a fabricated one.
    func percentError(for axis: DimensionAxis) -> Double? {
        let truth = trueValue(for: axis)
        guard truth.isFinite, truth > 0 else { return nil }
        return absoluteErrorMeters(for: axis) / truth * 100
    }

    func isWithinTolerance(
        for axis: DimensionAxis,
        tolerance: AccuracyTolerance = .standard
    ) -> Bool {
        tolerance.isWithinTolerance(
            measured: measuredValue(for: axis),
            trueValue: trueValue(for: axis)
        )
    }

    /// Every axis must pass. Reporting one aggregate would hide the case this
    /// feature exists for: two axes correct and one badly wrong.
    func isWithinTolerance(_ tolerance: AccuracyTolerance = .standard) -> Bool {
        DimensionAxis.allCases.allSatisfy {
            isWithinTolerance(for: $0, tolerance: tolerance)
        }
    }

    func worstAxis(
        tolerance: AccuracyTolerance = .standard
    ) -> DimensionAxis? {
        DimensionAxis.allCases.max { absoluteErrorMeters(for: $0) < absoluteErrorMeters(for: $1) }
    }
}
