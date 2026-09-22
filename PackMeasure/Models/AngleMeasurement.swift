import Foundation

/// One capture's contribution to a multi-angle result.
///
/// Stored with the item so that a reader can tell whether an accepted value
/// came from a single outlying viewpoint. It holds derived numbers only; no
/// frame, pixel buffer, or point cloud is retained.
struct AngleMeasurement: Identifiable, Codable, Hashable, Sendable {
    var id: UUID
    /// 1-based capture order within the series.
    var sequence: Int
    var lengthMeters: Double
    var widthMeters: Double
    var heightMeters: Double
    /// This angle's own point-cloud evidence, before any completeness downgrade.
    var pointCloudConfidence: ScanConfidence
    var agreedWithConsensus: Bool
    /// Which accepted axes this angle supplied the value for.
    var contributedAcceptedValue: Set<DimensionAxis>

    init(
        id: UUID = UUID(),
        sequence: Int,
        lengthMeters: Double,
        widthMeters: Double,
        heightMeters: Double,
        pointCloudConfidence: ScanConfidence,
        agreedWithConsensus: Bool,
        contributedAcceptedValue: Set<DimensionAxis> = []
    ) {
        self.id = id
        self.sequence = sequence
        self.lengthMeters = lengthMeters
        self.widthMeters = widthMeters
        self.heightMeters = heightMeters
        self.pointCloudConfidence = pointCloudConfidence
        self.agreedWithConsensus = agreedWithConsensus
        self.contributedAcceptedValue = contributedAcceptedValue
    }

    var hasValidDimensions: Bool {
        [lengthMeters, widthMeters, heightMeters].allSatisfy { $0.isFinite && $0 > 0 }
    }

    func value(for axis: DimensionAxis) -> Double {
        switch axis {
        case .length: lengthMeters
        case .width: widthMeters
        case .height: heightMeters
        }
    }
}
