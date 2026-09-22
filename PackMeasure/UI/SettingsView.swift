import SwiftUI

/// Holds the display-unit choice. Presentation only: picking a unit never
/// rewrites a stored measurement.
struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(
                        "Measurement unit",
                        selection: Binding(
                            get: { appModel.measurementUnit },
                            set: { appModel.setMeasurementUnit($0) }
                        )
                    ) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text("Measurement unit")
                } footer: {
                    Text(
                        "Applies to every measurement the app shows and to the values you type in. "
                        + "Measurements themselves are stored independently of this setting, so "
                        + "switching units never changes a saved size."
                    )
                }

                Section {
                    LabeledContent(
                        "Example",
                        value: appModel.dimensionFormatter.compact(
                            lengthMeters: 0.610,
                            widthMeters: 0.508,
                            heightMeters: 0.508
                        )
                    )
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
