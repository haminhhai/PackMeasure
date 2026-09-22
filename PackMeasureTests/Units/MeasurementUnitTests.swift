import Foundation
import Testing
@testable import PackMeasure

/// Guards the precision table in
/// specs/001-measurement-accuracy-units/contracts/measurement-display.md.
@Suite("Measurement unit")
struct MeasurementUnitTests {
    /// 0.508 m is the short edge of the carton in the documented alpha failure.
    private let shortEdge = 0.508
    /// 0.0127 m is half an inch: the smallest value that must not read as zero.
    private let thinEdge = 0.0127

    @Test("The precision table renders 0.508 m as the contract states")
    func rendersContractTable() {
        #expect(MeasurementUnit.millimeters.formatted(fromMeters: shortEdge) == "508 mm")
        #expect(MeasurementUnit.centimeters.formatted(fromMeters: shortEdge) == "50.8 cm")
        #expect(MeasurementUnit.meters.formatted(fromMeters: shortEdge) == "0.508 m")
        #expect(MeasurementUnit.inches.formatted(fromMeters: shortEdge) == "20.0 in")
        #expect(MeasurementUnit.feetAndInches.formatted(fromMeters: shortEdge) == "1 ft 8 in")
    }

    @Test("A thin edge never renders as zero in any unit")
    func neverRendersAsZero() {
        for unit in MeasurementUnit.allCases {
            let rendered = unit.formattedValue(fromMeters: thinEdge)
            #expect(rendered != "0", "\(unit) rendered a non-zero value as 0")
            #expect(rendered != "0.0", "\(unit) rendered a non-zero value as 0.0")
            #expect(rendered != "0.000", "\(unit) rendered a non-zero value as 0.000")
        }
        #expect(MeasurementUnit.millimeters.formatted(fromMeters: thinEdge) == "13 mm")
        #expect(MeasurementUnit.centimeters.formatted(fromMeters: thinEdge) == "1.3 cm")
        #expect(MeasurementUnit.meters.formatted(fromMeters: thinEdge) == "0.013 m")
        #expect(MeasurementUnit.inches.formatted(fromMeters: thinEdge) == "0.5 in")
        #expect(MeasurementUnit.feetAndInches.formatted(fromMeters: thinEdge) == "0 ft 1 in")
    }

    @Test("Switching unit away and back returns the original figures")
    func roundTripsWithoutDrift() {
        let stored = shortEdge
        let original = MeasurementUnit.feetAndInches.formatted(fromMeters: stored)

        // Walk through every other unit, rendering each time from the stored
        // meter value rather than from the previous rendering.
        for unit in MeasurementUnit.allCases {
            _ = unit.formatted(fromMeters: stored)
        }

        #expect(MeasurementUnit.feetAndInches.formatted(fromMeters: stored) == original)
        #expect(MeasurementUnit.centimeters.formatted(fromMeters: stored) == "50.8 cm")
    }

    @Test("Converting to a unit and back preserves the stored meter value")
    func conversionIsLossless() {
        for unit in MeasurementUnit.allCases {
            let value = unit.value(fromMeters: shortEdge)
            let back = unit.meters(fromValue: value)
            #expect(abs(back - shortEdge) < 1e-12, "\(unit) lost precision")
        }
    }

    @Test("Bounds are enforced in meters so the same limits apply in every unit")
    func boundsAreUnitIndependent() {
        // 480 in is the long-standing maximum.
        #expect(MeasurementBounds.isWithinBounds(meters: 12.192))
        #expect(MeasurementBounds.isWithinBounds(meters: 12.193) == false)
        #expect(MeasurementBounds.isWithinBounds(meters: 0.002))
        #expect(MeasurementBounds.isWithinBounds(meters: 0.001) == false)

        // 12193 mm and 480.1 in are the same physical over-limit value.
        let fromMillimeters = MeasurementUnit.millimeters.meters(fromValue: 12_193)
        let fromInches = MeasurementUnit.inches.meters(fromValue: 480.1)
        #expect(MeasurementBounds.isWithinBounds(meters: fromMillimeters) == false)
        #expect(MeasurementBounds.isWithinBounds(meters: fromInches) == false)
    }

    @Test("A first launch follows the device region")
    func regionDefault() {
        #expect(MeasurementUnit.regionDefault(locale: Locale(identifier: "vi_VN")) == .centimeters)
        #expect(MeasurementUnit.regionDefault(locale: Locale(identifier: "ja_JP")) == .centimeters)
        #expect(MeasurementUnit.regionDefault(locale: Locale(identifier: "en_US")) == .feetAndInches)
    }

    @Test("A non-finite value renders as a placeholder rather than a number")
    func handlesNonFiniteValues() {
        for unit in MeasurementUnit.allCases {
            #expect(unit.formatted(fromMeters: .nan) == "—")
            #expect(unit.formatted(fromMeters: .infinity) == "—")
        }
    }
}
