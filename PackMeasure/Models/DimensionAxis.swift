import Foundation

/// The single source of truth for naming a measured axis. Visual labels,
/// VoiceOver phrasing, and manual-entry fields all read from here so that
/// length, width, and height cannot come to mean different things on
/// different screens.
enum DimensionAxis: String, Codable, CaseIterable, Hashable, Identifiable, Sendable {
    var id: String { rawValue }

    case length
    case width
    case height

    /// Full name used for row labels and accessibility output.
    var displayName: String {
        switch self {
        case .length: "Length"
        case .width: "Width"
        case .height: "Height"
        }
    }

    /// Single-letter label for the compact form, where the three values appear
    /// on one line.
    var compactLabel: String {
        switch self {
        case .length: "L"
        case .width: "W"
        case .height: "H"
        }
    }
}
