import Foundation

/// Renders a measured triple so that every value names its axis.
///
/// Always reads the stored meter value and never re-parses its own output, so
/// switching units away and back returns the original figures with no
/// accumulated rounding drift (FR-021).
struct DimensionFormatter: Equatable, Sendable {
    var unit: MeasurementUnit

    init(unit: MeasurementUnit) {
        self.unit = unit
    }

    struct Row: Equatable, Identifiable, Sendable {
        var axis: DimensionAxis
        /// "61.0 cm"
        var value: String
        /// "Length, 61.0 centimeters"
        var accessibilityLabel: String

        var id: DimensionAxis { axis }
        var label: String { axis.displayName }
    }

    /// One row per axis, for layouts with room to name each value in full.
    func rows(
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double
    ) -> [Row] {
        zip(DimensionAxis.allCases, [lengthMeters, widthMeters, heightMeters]).map { axis, meters in
            Row(
                axis: axis,
                value: unit.formatted(fromMeters: meters),
                accessibilityLabel: accessibilityLabel(axis: axis, meters: meters)
            )
        }
    }

    /// "L 61.0 cm · W 50.8 cm · H 50.8 cm" — for a single line.
    func compact(
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double
    ) -> String {
        rows(lengthMeters: lengthMeters, widthMeters: widthMeters, heightMeters: heightMeters)
            .map { "\($0.axis.compactLabel) \($0.value)" }
            .joined(separator: " · ")
    }

    /// The whole triple as one spoken phrase, for a single accessibility element.
    func accessibilitySummary(
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double
    ) -> String {
        rows(lengthMeters: lengthMeters, widthMeters: widthMeters, heightMeters: heightMeters)
            .map(\.accessibilityLabel)
            .joined(separator: ", ")
    }

    func accessibilityLabel(axis: DimensionAxis, meters: Double) -> String {
        "\(axis.displayName), \(unit.accessibilityFormatted(fromMeters: meters))"
    }

    func value(meters: Double) -> String {
        unit.formatted(fromMeters: meters)
    }
}

extension DimensionFormatter {
    func rows(for item: MeasuredItem) -> [Row] {
        rows(
            lengthMeters: item.lengthMeters,
            widthMeters: item.widthMeters,
            heightMeters: item.heightMeters
        )
    }

    func compact(for item: MeasuredItem) -> String {
        compact(
            lengthMeters: item.lengthMeters,
            widthMeters: item.widthMeters,
            heightMeters: item.heightMeters
        )
    }

    func accessibilitySummary(for item: MeasuredItem) -> String {
        accessibilitySummary(
            lengthMeters: item.lengthMeters,
            widthMeters: item.widthMeters,
            heightMeters: item.heightMeters
        )
    }

    func rows(for estimate: MeasurementEstimate) -> [Row] {
        rows(
            lengthMeters: estimate.lengthMeters,
            widthMeters: estimate.widthMeters,
            heightMeters: estimate.heightMeters
        )
    }

    func compact(for estimate: MeasurementEstimate) -> String {
        compact(
            lengthMeters: estimate.lengthMeters,
            widthMeters: estimate.widthMeters,
            heightMeters: estimate.heightMeters
        )
    }

    func rows(for angle: AngleMeasurement) -> [Row] {
        rows(
            lengthMeters: angle.lengthMeters,
            widthMeters: angle.widthMeters,
            heightMeters: angle.heightMeters
        )
    }

    func compact(for angle: AngleMeasurement) -> String {
        compact(
            lengthMeters: angle.lengthMeters,
            widthMeters: angle.widthMeters,
            heightMeters: angle.heightMeters
        )
    }
}
