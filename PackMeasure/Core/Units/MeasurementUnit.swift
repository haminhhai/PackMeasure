import Foundation

/// The unit an operator reads and types in.
///
/// A presentation type, deliberately separate from `GeometryLengthUnit`:
/// feet-and-inches is a formatting mode rather than a scale factor, and the
/// per-unit decimal precision below is a display concern that does not belong
/// in the geometry domain. Stored measurements stay in meters; conversion
/// happens here and at manual-entry parse, nowhere else.
enum MeasurementUnit: String, CaseIterable, Codable, Identifiable, Sendable {
    case millimeters
    case centimeters
    case meters
    case inches
    case feetAndInches

    var id: String { rawValue }

    /// Units per meter. `feetAndInches` measures in inches and splits at render.
    var unitsPerMeter: Double {
        switch self {
        case .millimeters: 1_000
        case .centimeters: 100
        case .meters: 1
        case .inches, .feetAndInches: 39.370_078_740_157_48
        }
    }

    /// Chosen so no realistic carton dimension renders as zero or as false
    /// precision. A 0.508 m edge reads 508 mm, 50.8 cm, 0.508 m, 20.0 in.
    var fractionDigits: Int {
        switch self {
        case .millimeters: 0
        case .centimeters: 1
        case .meters: 3
        case .inches: 1
        case .feetAndInches: 0
        }
    }

    var symbol: String {
        switch self {
        case .millimeters: "mm"
        case .centimeters: "cm"
        case .meters: "m"
        case .inches, .feetAndInches: "in"
        }
    }

    /// Menu label for the unit picker.
    var displayName: String {
        switch self {
        case .millimeters: "Millimeters (mm)"
        case .centimeters: "Centimeters (cm)"
        case .meters: "Meters (m)"
        case .inches: "Inches (in)"
        case .feetAndInches: "Feet and inches (ft in)"
        }
    }

    var isMetric: Bool {
        switch self {
        case .millimeters, .centimeters, .meters: true
        case .inches, .feetAndInches: false
        }
    }

    func value(fromMeters meters: Double) -> Double {
        meters * unitsPerMeter
    }

    func meters(fromValue value: Double) -> Double {
        value / unitsPerMeter
    }

    /// The numeric part only, without a symbol.
    func formattedValue(fromMeters meters: Double) -> String {
        guard meters.isFinite else { return "—" }
        if case .feetAndInches = self {
            let totalInches = max(0, Int(value(fromMeters: meters).rounded()))
            return "\(totalInches / 12) ft \(totalInches % 12)"
        }
        return String(format: "%.\(fractionDigits)f", value(fromMeters: meters))
    }

    /// The value with its symbol, as shown to the operator.
    func formatted(fromMeters meters: Double) -> String {
        guard meters.isFinite else { return "—" }
        if case .feetAndInches = self {
            return "\(formattedValue(fromMeters: meters)) in"
        }
        return "\(formattedValue(fromMeters: meters)) \(symbol)"
    }

    /// Spelled-out form for VoiceOver, where a symbol reads poorly.
    func accessibilityFormatted(fromMeters meters: Double) -> String {
        guard meters.isFinite else { return "unavailable" }
        if case .feetAndInches = self {
            let totalInches = max(0, Int(value(fromMeters: meters).rounded()))
            let feet = totalInches / 12
            let inches = totalInches % 12
            let feetPart = "\(feet) \(feet == 1 ? "foot" : "feet")"
            let inchPart = "\(inches) \(inches == 1 ? "inch" : "inches")"
            return "\(feetPart) \(inchPart)"
        }
        let number = formattedValue(fromMeters: meters)
        let spelled: String
        switch self {
        case .millimeters: spelled = "millimeters"
        case .centimeters: spelled = "centimeters"
        case .meters: spelled = "meters"
        case .inches: spelled = "inches"
        case .feetAndInches: spelled = "inches"
        }
        return "\(number) \(spelled)"
    }

    /// Default for a first launch, derived from the device region.
    static func regionDefault(locale: Locale = .current) -> MeasurementUnit {
        locale.measurementSystem == .metric ? .centimeters : .feetAndInches
    }
}

/// Shared physical bounds, enforced in meters after conversion so the same
/// limits apply whichever unit the operator types in (FR-023).
enum MeasurementBounds {
    /// 480 in, the limit the manual-entry form has always enforced.
    static let maximumMeters = 12.192
    /// Matches the geometry estimator's minimum measurable dimension.
    static let minimumMeters = 0.002

    static func isWithinBounds(meters: Double) -> Bool {
        meters.isFinite && meters >= minimumMeters && meters <= maximumMeters
    }
}
