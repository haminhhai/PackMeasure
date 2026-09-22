import Foundation

struct MeasuredItem: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    var name: String
    var lengthMeters: Double
    var widthMeters: Double
    var heightMeters: Double
    var quantity: Int
    var confidence: ScanConfidence
    var comparisonAngleCount: Int?
    var comparisonAgreementCount: Int?
    var capturedAt: Date
    var stackability: ItemStackability
    var orientationPolicy: ItemOrientationPolicy
    /// `nil` for items saved before per-angle provenance existed. The UI must
    /// say so rather than substitute rows.
    var angleMeasurements: [AngleMeasurement]?
    /// Which rule derived the accepted value. `nil` for untagged legacy items.
    var resolutionRule: ResolutionRule?
    /// `nil` when the item predates tolerance evaluation.
    var toleranceStatus: ToleranceStatus?

    init(
        id: UUID = UUID(),
        name: String,
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double,
        quantity: Int = 1,
        confidence: ScanConfidence,
        comparisonAngleCount: Int? = nil,
        comparisonAgreementCount: Int? = nil,
        capturedAt: Date = .now,
        stackability: ItemStackability = .notStackable,
        orientationPolicy: ItemOrientationPolicy = .keepUpright,
        angleMeasurements: [AngleMeasurement]? = nil,
        resolutionRule: ResolutionRule? = nil,
        toleranceStatus: ToleranceStatus? = nil
    ) {
        self.id = id
        self.name = name
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.quantity = max(1, quantity)
        self.confidence = confidence
        self.comparisonAngleCount = comparisonAngleCount
        self.comparisonAgreementCount = comparisonAgreementCount
        self.capturedAt = capturedAt
        self.stackability = stackability
        self.orientationPolicy = orientationPolicy
        self.angleMeasurements = angleMeasurements
        self.resolutionRule = resolutionRule
        self.toleranceStatus = toleranceStatus
    }

    var footprintSquareFeet: Double {
        MeasurementMath.squareFeet(lengthMeters * widthMeters)
    }

    var volumeCubicFeet: Double {
        MeasurementMath.cubicFeet(lengthMeters * widthMeters * heightMeters)
    }

    var packingItem: PackingItem? {
        guard let dimensions = try? ItemDimensions(
            lengthInches: MeasurementMath.inches(from: lengthMeters),
            widthInches: MeasurementMath.inches(from: widthMeters),
            heightInches: MeasurementMath.inches(from: heightMeters)
        ) else {
            return nil
        }

        return try? PackingItem(
            id: id,
            name: name,
            dimensions: dimensions,
            quantity: quantity,
            stackability: stackability,
            orientationPolicy: orientationPolicy
        )
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case lengthMeters
        case widthMeters
        case heightMeters
        case quantity
        case confidence
        case comparisonAngleCount
        case comparisonAgreementCount
        case capturedAt
        case stackability
        case orientationPolicy
        case angleMeasurements
        case resolutionRule
        case toleranceStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Scanned Item"
        lengthMeters = try container.decode(Double.self, forKey: .lengthMeters)
        widthMeters = try container.decode(Double.self, forKey: .widthMeters)
        heightMeters = try container.decode(Double.self, forKey: .heightMeters)
        quantity = max(1, try container.decodeIfPresent(Int.self, forKey: .quantity) ?? 1)
        confidence = try container.decodeIfPresent(ScanConfidence.self, forKey: .confidence) ?? .low
        comparisonAngleCount = try container.decodeIfPresent(
            Int.self,
            forKey: .comparisonAngleCount
        )
        comparisonAgreementCount = try container.decodeIfPresent(
            Int.self,
            forKey: .comparisonAgreementCount
        )
        capturedAt = try container.decodeIfPresent(Date.self, forKey: .capturedAt) ?? .now
        stackability = try container.decodeIfPresent(ItemStackability.self, forKey: .stackability) ?? .notStackable
        orientationPolicy = try container.decodeIfPresent(
            ItemOrientationPolicy.self,
            forKey: .orientationPolicy
        ) ?? .keepUpright
        angleMeasurements = try container.decodeIfPresent(
            [AngleMeasurement].self,
            forKey: .angleMeasurements
        )
        // A rule or status written by a newer build decodes as nil instead of
        // throwing, so a forward-written file still loads.
        resolutionRule = ResolutionRule(
            rawValue: try container.decodeIfPresent(String.self, forKey: .resolutionRule) ?? ""
        )
        toleranceStatus = ToleranceStatus(
            rawValue: try container.decodeIfPresent(String.self, forKey: .toleranceStatus) ?? ""
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(lengthMeters, forKey: .lengthMeters)
        try container.encode(widthMeters, forKey: .widthMeters)
        try container.encode(heightMeters, forKey: .heightMeters)
        try container.encode(quantity, forKey: .quantity)
        try container.encode(confidence, forKey: .confidence)
        try container.encodeIfPresent(comparisonAngleCount, forKey: .comparisonAngleCount)
        try container.encodeIfPresent(
            comparisonAgreementCount,
            forKey: .comparisonAgreementCount
        )
        try container.encode(capturedAt, forKey: .capturedAt)
        try container.encode(stackability, forKey: .stackability)
        try container.encode(orientationPolicy, forKey: .orientationPolicy)
        try container.encodeIfPresent(angleMeasurements, forKey: .angleMeasurements)
        try container.encodeIfPresent(resolutionRule?.rawValue, forKey: .resolutionRule)
        try container.encodeIfPresent(toleranceStatus?.rawValue, forKey: .toleranceStatus)
    }
}

struct MeasurementEstimate: Equatable, Sendable {
    var lengthMeters: Double
    var widthMeters: Double
    var heightMeters: Double
    var confidence: ScanConfidence
    var sampleCount: Int
    var frameCount: Int
    var comparisonAngleCount: Int? = nil
    var comparisonAgreementCount: Int? = nil

    var sortedBaseEdges: [Double] {
        [lengthMeters, widthMeters].sorted(by: >)
    }
}

enum ScanConfidence: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high

    var title: String {
        rawValue.capitalized
    }

    var guidance: String {
        switch self {
        case .high:
            "Good scan quality"
        case .medium:
            "Usable, but a retake may tighten the estimate"
        case .low:
            "Low confidence. Retake before relying on this measurement"
        }
    }
}

/// Names the rule that derived an accepted value from disagreeing angles, so
/// results stay comparable across versions that resolve them differently.
enum ResolutionRule: String, Codable, CaseIterable, Hashable, Sendable {
    /// Retain the larger supported value on each agreeing axis.
    case largestAgreeingValue

    /// Median of three angles, or the midpoint of two.
    case trimmedConsensus

    var displayName: String {
        switch self {
        case .largestAgreeingValue: "Largest agreeing value"
        case .trimmedConsensus: "Trimmed consensus"
        }
    }
}

/// Whether the evidence behind a measurement supports the stated accuracy
/// tolerance. `unknown` is the honest initial state on a device with no
/// calibration history and must never be presented as `withinTolerance`.
enum ToleranceStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case withinTolerance
    case belowTolerance
    case unknown

    var requiresRetakeOffer: Bool {
        self == .belowTolerance
    }
}

enum ScannerPhase: Equatable {
    case checkingSupport
    case ready
    case scanning(progress: Double)
    case measured
    case unsupported(String)
    case failed(String)
}
