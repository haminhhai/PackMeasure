import Foundation
import Testing
@testable import PackMeasure

@Suite("Unit preference store")
struct UnitPreferenceStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "PackMeasureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test("A first launch in a metric region starts in centimeters")
    func firstLaunchMetric() {
        let store = UnitPreferenceStore(
            defaults: makeDefaults(),
            locale: Locale(identifier: "vi_VN")
        )
        #expect(store.load() == .centimeters)
    }

    @Test("A first launch in an imperial region starts in feet and inches")
    func firstLaunchImperial() {
        let store = UnitPreferenceStore(
            defaults: makeDefaults(),
            locale: Locale(identifier: "en_US")
        )
        #expect(store.load() == .feetAndInches)
    }

    @Test("The chosen unit survives a relaunch")
    func persistsAcrossLaunches() {
        let defaults = makeDefaults()
        let locale = Locale(identifier: "en_US")

        UnitPreferenceStore(defaults: defaults, locale: locale).save(.millimeters)

        // A fresh store instance stands in for the next launch.
        let reloaded = UnitPreferenceStore(defaults: defaults, locale: locale)
        #expect(reloaded.load() == .millimeters)
    }

    @Test("An unrecognized stored value falls back to the region default")
    func unrecognizedValueFallsBack() {
        let defaults = makeDefaults()
        defaults.set("furlongs", forKey: UnitPreferenceStore.defaultsKey)

        let store = UnitPreferenceStore(
            defaults: defaults,
            locale: Locale(identifier: "vi_VN")
        )
        #expect(store.load() == .centimeters)
    }

    @Test("Every unit round-trips through storage")
    func everyUnitRoundTrips() {
        let defaults = makeDefaults()
        let store = UnitPreferenceStore(defaults: defaults, locale: Locale(identifier: "en_US"))
        for unit in MeasurementUnit.allCases {
            store.save(unit)
            #expect(store.load() == unit)
        }
    }
}
