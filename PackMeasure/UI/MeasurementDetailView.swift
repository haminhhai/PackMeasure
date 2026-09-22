import SwiftUI

/// Shows what each contributing angle actually measured, beside the accepted
/// value. When a result looks wrong, this is how an operator tells whether one
/// viewpoint was an outlier.
struct MeasurementDetailView: View {
    @Environment(AppModel.self) private var appModel

    let item: MeasuredItem

    private var formatter: DimensionFormatter { appModel.dimensionFormatter }

    var body: some View {
        Form {
            Section("Accepted measurement") {
                DimensionRows(
                    formatter: formatter,
                    lengthMeters: item.lengthMeters,
                    widthMeters: item.widthMeters,
                    heightMeters: item.heightMeters
                )
                LabeledContent("Confidence", value: item.confidence.title)
                if let rule = item.resolutionRule {
                    LabeledContent("Resolved by", value: rule.displayName)
                }
                if let status = item.toleranceStatus {
                    LabeledContent("Accuracy", value: toleranceDescription(status))
                }
            }

            anglesSection
        }
        .navigationTitle("Measurement detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var anglesSection: some View {
        if let angles = item.angleMeasurements, !angles.isEmpty {
            Section {
                ForEach(angles.sorted { $0.sequence < $1.sequence }) { angle in
                    angleRow(angle)
                }
            } header: {
                Text("Contributing angles")
            } footer: {
                Text(
                    "Agreement between angles shows the measurement repeated, not that it is "
                    + "accurate. Check it against a tape before relying on a tight fit."
                )
            }
        } else {
            Section("Contributing angles") {
                // Never blank rows, zeros, or reconstructed values.
                Text("Per-angle detail is not available for this item. It was saved before the app recorded individual angles.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func angleRow(_ angle: AngleMeasurement) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Angle \(angle.sequence)")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(angle.agreedWithConsensus ? "Agreed" : "Did not agree")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(angle.agreedWithConsensus ? .green : .orange)
            }

            DimensionSummary(formatter: formatter, angle: angle)
                .font(.subheadline)

            if !angle.contributedAcceptedValue.isEmpty {
                Text("Supplied the accepted \(contributedDescription(angle)).")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Text("Point cloud: \(angle.pointCloudConfidence.title)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private func contributedDescription(_ angle: AngleMeasurement) -> String {
        DimensionAxis.allCases
            .filter { angle.contributedAcceptedValue.contains($0) }
            .map { $0.displayName.lowercased() }
            .formatted(.list(type: .and))
    }

    private func toleranceDescription(_ status: ToleranceStatus) -> String {
        switch status {
        case .withinTolerance: "Within tolerance"
        case .belowTolerance: "Below tolerance"
        case .unknown: "Not verified on this device"
        }
    }
}
