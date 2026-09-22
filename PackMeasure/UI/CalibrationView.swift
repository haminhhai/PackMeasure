import SwiftUI

/// Measures a carton whose real size the operator already knows, and reports
/// how far off the app was, per axis.
///
/// This is the instrument the accuracy work depends on: `Docs/DeviceCalibration.md`
/// has been an empty table since the alpha, so no accuracy decision so far has
/// had recorded evidence behind it.
struct CalibrationView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    @State private var label = ""
    @State private var lengthText = ""
    @State private var widthText = ""
    @State private var heightText = ""
    @State private var completedRun: CalibrationRun?

    private var unit: MeasurementUnit { appModel.measurementUnit }
    private var formatter: DimensionFormatter { appModel.dimensionFormatter }

    var body: some View {
        NavigationStack {
            Form {
                if let completedRun {
                    resultSection(for: completedRun)
                } else {
                    truthSection
                    scanSection
                }
                historySection
            }
            .navigationTitle("Calibration check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // Leaving before the scan completes records nothing.
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    // MARK: - Entering the truth

    private var truthSection: some View {
        Section {
            TextField("What is this carton?", text: $label)
            truthField(axis: .length, text: $lengthText)
            truthField(axis: .width, text: $widthText)
            truthField(axis: .height, text: $heightText)
        } header: {
            Text("Measured with a tape")
        } footer: {
            Text(
                "Enter the carton's real outside dimensions in \(unit.symbol). "
                + "The result below compares the app's estimate against these numbers."
            )
        }
    }

    private func truthField(axis: DimensionAxis, text: Binding<String>) -> some View {
        LabeledContent(axis.displayName) {
            HStack(spacing: 6) {
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(minWidth: 80)
                    .accessibilityLabel("\(axis.displayName) in \(unit.symbol)")
                Text(unit.symbol).foregroundStyle(.secondary)
            }
        }
    }

    private var scanSection: some View {
        Section {
            Button("Scan this carton") {
                appModel.showingScanner = true
            }
            .disabled(truthMeters == nil)
        } footer: {
            if truthMeters == nil {
                Text("Enter all three measured dimensions to start.")
            } else {
                Text(
                    "The scan uses the same multi-angle capture as a normal measurement. "
                    + "The carton is not added to your items."
                )
            }
        }
    }

    /// `nil` until all three axes hold a usable, in-bounds value.
    private var truthMeters: (length: Double, width: Double, height: Double)? {
        let values = [lengthText, widthText, heightText].map { text -> Double? in
            guard let raw = Double(text.trimmingCharacters(in: .whitespaces)) else { return nil }
            let meters = unit.meters(fromValue: raw)
            return MeasurementBounds.isWithinBounds(meters: meters) ? meters : nil
        }
        guard let length = values[0], let width = values[1], let height = values[2] else {
            return nil
        }
        return (length, width, height)
    }

    // MARK: - Reporting the result

    private func resultSection(for run: CalibrationRun) -> some View {
        Section {
            // Per axis, never one aggregate: the failure this exists to catch
            // is two axes correct and one badly wrong.
            ForEach(DimensionAxis.allCases) { axis in
                VStack(alignment: .leading, spacing: 3) {
                    LabeledContent(
                        axis.displayName,
                        value: unit.formatted(fromMeters: run.measuredValue(for: axis))
                    )
                    Text(errorDescription(for: axis, in: run))
                        .font(.caption)
                        .foregroundStyle(
                            run.isWithinTolerance(for: axis)
                                ? AnyShapeStyle(.secondary)
                                : AnyShapeStyle(.orange)
                        )
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text(run.isWithinTolerance() ? "Within tolerance" : "Outside tolerance")
        } footer: {
            Text(
                run.isWithinTolerance()
                ? "Every axis is inside 5% and 20 mm of the size you entered."
                : "At least one axis is outside 5% or 20 mm. Measurements on this device are "
                  + "flagged until a later check passes."
            )
        }
    }

    private func errorDescription(for axis: DimensionAxis, in run: CalibrationRun) -> String {
        let absolute = unit.formatted(fromMeters: run.absoluteErrorMeters(for: axis))
        guard let percent = run.percentError(for: axis) else {
            return "True \(unit.formatted(fromMeters: run.trueValue(for: axis))) · off by \(absolute)"
        }
        return "True \(unit.formatted(fromMeters: run.trueValue(for: axis)))"
            + " · off by \(absolute) (\(String(format: "%.1f", percent))%)"
    }

    private var historySection: some View {
        Section("History") {
            if appModel.calibrationRuns.isEmpty {
                Text("No calibration checks recorded on this device yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(appModel.calibrationRuns) { run in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(run.label.isEmpty ? "Calibration carton" : run.label)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(run.isWithinTolerance() ? "Pass" : "Fail")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(run.isWithinTolerance() ? .green : .orange)
                        }
                        Text(run.performedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        ForEach(DimensionAxis.allCases) { axis in
                            Text("\(axis.displayName): \(errorDescription(for: axis, in: run))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    /// Called once the scan produces an accepted estimate. Only a completed
    /// check is recorded (FR-028).
    func complete(
        with estimate: MeasurementEstimate,
        angleMeasurements: [AngleMeasurement],
        resolutionRule: ResolutionRule
    ) {
        guard let truth = truthMeters else { return }
        let run = CalibrationRun(
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            trueLengthMeters: truth.length,
            trueWidthMeters: truth.width,
            trueHeightMeters: truth.height,
            measuredLengthMeters: estimate.lengthMeters,
            measuredWidthMeters: estimate.widthMeters,
            measuredHeightMeters: estimate.heightMeters,
            reportedConfidence: estimate.confidence,
            resolutionRule: resolutionRule,
            angleMeasurements: angleMeasurements
        )
        appModel.recordCalibrationRun(run)
        completedRun = run
    }
}
