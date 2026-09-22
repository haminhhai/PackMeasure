import Foundation

/// Unit-agnostic conversions shared by the frozen packing domain, which works
/// in inches and cubic feet.
///
/// Operator-facing dimension strings are not built here. They go through
/// `DimensionFormatter`, which follows the chosen display unit and names each
/// axis. The feet-and-inches string helpers this type used to expose were
/// removed with the unit feature.
enum MeasurementMath {
    static func inches(from meters: Double) -> Double {
        meters * 39.370_078_740_157_48
    }

    static func feet(from meters: Double) -> Double {
        meters * 3.28084
    }

    static func squareFeet(_ squareMeters: Double) -> Double {
        squareMeters * 10.7639
    }

    static func cubicFeet(_ cubicMeters: Double) -> Double {
        cubicMeters * 35.3147
    }

    static func decimalSquareFeetString(_ value: Double) -> String {
        String(format: "%.1f sq ft", value)
    }

    static func decimalCubicFeetString(_ value: Double) -> String {
        String(format: "%.0f cu ft", value)
    }
}
