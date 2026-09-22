import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    private(set) var items: [MeasuredItem] = []
    var showingScanner = false
    var bannerMessage: String?
    private(set) var loadMix: PackingLoadMix = .mixedHousehold

    /// The operator's display unit. Presentation only: changing it never
    /// rewrites a stored measurement.
    private(set) var measurementUnit: MeasurementUnit

    /// Completed known-carton checks, newest first. Device-scoped and never
    /// transmitted anywhere.
    private(set) var calibrationRuns: [CalibrationRun] = []

    @ObservationIgnored private let store: InventoryStore
    @ObservationIgnored private let unitPreferenceStore: UnitPreferenceStore
    @ObservationIgnored private let calibrationStore: CalibrationStore
    @ObservationIgnored private let tolerancePolicy = MeasurementTolerancePolicy()
    @ObservationIgnored private var hasLoaded = false

    init(
        store: InventoryStore = InventoryStore(),
        unitPreferenceStore: UnitPreferenceStore = UnitPreferenceStore(),
        calibrationStore: CalibrationStore = CalibrationStore()
    ) {
        self.store = store
        self.unitPreferenceStore = unitPreferenceStore
        self.calibrationStore = calibrationStore
        measurementUnit = unitPreferenceStore.load()
    }

    // MARK: - Calibration

    /// `nil` until this device has a completed run. The UI must render that as
    /// unknown, never as a pass (FR-029).
    var deviceCalibrationWithinTolerance: Bool? {
        calibrationRuns.deviceCalibrationWithinTolerance()
    }

    var isDeviceOutsideTolerance: Bool {
        deviceCalibrationWithinTolerance == false
    }

    func recordCalibrationRun(_ run: CalibrationRun) {
        do {
            calibrationRuns = try calibrationStore.append(run)
        } catch {
            bannerMessage = "Could not save the calibration result."
        }
    }

    func toleranceStatus(
        confidence: ScanConfidence,
        angleMeasurements: [AngleMeasurement]
    ) -> ToleranceStatus {
        tolerancePolicy.status(
            confidence: confidence,
            angleMeasurements: angleMeasurements,
            deviceCalibrationWithinTolerance: deviceCalibrationWithinTolerance
        )
    }

    /// The single formatter every surface reads, so no screen can drift onto a
    /// different unit or a different axis name.
    var dimensionFormatter: DimensionFormatter {
        DimensionFormatter(unit: measurementUnit)
    }

    func setMeasurementUnit(_ unit: MeasurementUnit) {
        guard unit != measurementUnit else { return }
        measurementUnit = unit
        unitPreferenceStore.save(unit)
    }

    func loadIfNeeded() {
        guard !hasLoaded else { return }
        hasLoaded = true

        do {
            items = try store.load()
        } catch {
            bannerMessage = "Could not load saved inventory."
        }

        // A failure here must not block the inventory; calibration history is
        // supporting evidence, not the operator's data.
        calibrationRuns = (try? calibrationStore.load()) ?? []
    }

    func addItem(
        name: String,
        estimate: MeasurementEstimate,
        quantity: Int,
        stackability: ItemStackability = .notStackable,
        orientationPolicy: ItemOrientationPolicy = .keepUpright,
        angleMeasurements: [AngleMeasurement]? = nil,
        resolutionRule: ResolutionRule? = nil,
        toleranceStatus: ToleranceStatus? = nil
    ) {
        items.append(
            MeasuredItem(
                name: normalizedName(name),
                lengthMeters: estimate.lengthMeters,
                widthMeters: estimate.widthMeters,
                heightMeters: estimate.heightMeters,
                quantity: max(1, quantity),
                confidence: estimate.confidence,
                comparisonAngleCount: estimate.comparisonAngleCount,
                comparisonAgreementCount: estimate.comparisonAgreementCount,
                stackability: stackability,
                orientationPolicy: orientationPolicy,
                angleMeasurements: angleMeasurements?.isEmpty == true ? nil : angleMeasurements,
                resolutionRule: resolutionRule,
                toleranceStatus: toleranceStatus ?? self.toleranceStatus(
                    confidence: estimate.confidence,
                    angleMeasurements: angleMeasurements ?? []
                )
            )
        )
        persist()
    }

    func updateItem(
        id: UUID,
        name: String,
        quantity: Int,
        stackability: ItemStackability,
        orientationPolicy: ItemOrientationPolicy
    ) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items[index].name = normalizedName(name)
        items[index].quantity = max(1, quantity)
        items[index].stackability = stackability
        items[index].orientationPolicy = orientationPolicy
        persist()
    }

    func setLoadMix(_ loadMix: PackingLoadMix) {
        self.loadMix = loadMix
    }

    func deleteItems(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        persist()
    }

    var packingItems: [PackingItem] {
        items.compactMap(\.packingItem)
    }

    var packingSummary: PackingSummary {
        PackingPlanner().summary(for: packingItems)
    }

    var vehicleRecommendation: PackingVehicleRecommendation {
        PackingPlanner().recommendVehicle(
            for: packingItems,
            from: PackingVehicleCatalog.conservativeMovingFleet(loadMix: loadMix)
        )
    }

    /// Once a vehicle is selected, its cargo height can reduce the number of
    /// safe stack layers. This is the floor estimate the home screen should use.
    var planningSummary: PackingSummary {
        let recommendation = vehicleRecommendation
        return recommendation.vehicle == nil
            ? packingSummary
            : recommendation.summary
    }

    var ignoredPackingItemCount: Int {
        items.count - packingItems.count
    }

    private func persist() {
        do {
            try store.save(items)
            bannerMessage = nil
        } catch {
            bannerMessage = "Could not save inventory."
        }
    }

    private func normalizedName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Scanned Item" : trimmed
    }
}
