import SwiftUI

/// The one place a measured triple becomes pixels.
///
/// Every surface renders through this so that no screen can drift onto a
/// different axis name, a different unit, or an unlabeled `A × B × C` string.
struct DimensionSummary: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let formatter: DimensionFormatter
    let lengthMeters: Double
    let widthMeters: Double
    let heightMeters: Double

    init(
        formatter: DimensionFormatter,
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double
    ) {
        self.formatter = formatter
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
    }

    private var rows: [DimensionFormatter.Row] {
        formatter.rows(
            lengthMeters: lengthMeters,
            widthMeters: widthMeters,
            heightMeters: heightMeters
        )
    }

    var body: some View {
        // At accessibility text sizes the single line cannot hold three
        // labeled values without truncating, so it becomes one row per axis.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stacked
            } else {
                ViewThatFits(in: .horizontal) {
                    inline
                    stacked
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            formatter.accessibilitySummary(
                lengthMeters: lengthMeters,
                widthMeters: widthMeters,
                heightMeters: heightMeters
            )
        )
    }

    private var inline: some View {
        HStack(spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                if index > 0 {
                    Text("·").foregroundStyle(.tertiary)
                }
                HStack(spacing: 3) {
                    Text(row.axis.compactLabel)
                        .foregroundStyle(.secondary)
                    Text(row.value)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(rows) { row in
                HStack(spacing: 4) {
                    Text(row.label)
                        .foregroundStyle(.secondary)
                    Text(row.value)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// The always-expanded form, for detail screens with room for full names.
struct DimensionRows: View {
    let formatter: DimensionFormatter
    let lengthMeters: Double
    let widthMeters: Double
    let heightMeters: Double

    var body: some View {
        ForEach(
            formatter.rows(
                lengthMeters: lengthMeters,
                widthMeters: widthMeters,
                heightMeters: heightMeters
            )
        ) { row in
            LabeledContent(row.label, value: row.value)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
        }
    }
}

extension DimensionSummary {
    init(formatter: DimensionFormatter, item: MeasuredItem) {
        self.init(
            formatter: formatter,
            lengthMeters: item.lengthMeters,
            widthMeters: item.widthMeters,
            heightMeters: item.heightMeters
        )
    }

    init(formatter: DimensionFormatter, estimate: MeasurementEstimate) {
        self.init(
            formatter: formatter,
            lengthMeters: estimate.lengthMeters,
            widthMeters: estimate.widthMeters,
            heightMeters: estimate.heightMeters
        )
    }

    init(formatter: DimensionFormatter, angle: AngleMeasurement) {
        self.init(
            formatter: formatter,
            lengthMeters: angle.lengthMeters,
            widthMeters: angle.widthMeters,
            heightMeters: angle.heightMeters
        )
    }
}
