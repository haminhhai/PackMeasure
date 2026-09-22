import Foundation

/// Persists the operator's chosen display unit.
///
/// A single scalar preference, so it lives in `UserDefaults` rather than in
/// `inventory.json`. Changing it never touches a stored measurement (FR-021).
/// `UserDefaults` is thread-safe but not `Sendable`, so the store is marked
/// unchecked rather than copying the value out.
struct UnitPreferenceStore: @unchecked Sendable {
    static let defaultsKey = "PackMeasure.measurementUnit"

    private let defaults: UserDefaults
    private let locale: Locale

    init(defaults: UserDefaults = .standard, locale: Locale = .current) {
        self.defaults = defaults
        self.locale = locale
    }

    /// The stored unit, or the region default on a first launch (FR-019). An
    /// unrecognized stored value falls back to the region default rather than
    /// failing.
    func load() -> MeasurementUnit {
        guard let raw = defaults.string(forKey: Self.defaultsKey),
              let unit = MeasurementUnit(rawValue: raw) else {
            return MeasurementUnit.regionDefault(locale: locale)
        }
        return unit
    }

    func save(_ unit: MeasurementUnit) {
        defaults.set(unit.rawValue, forKey: Self.defaultsKey)
    }
}
