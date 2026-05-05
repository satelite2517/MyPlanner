import Foundation
import SwiftData

@Model
final class PlannerLabel {
    var id: UUID
    var name: String
    var colorHex: String

    init(name: String, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
}

extension PlannerLabel {
    static let presetColorHexes: [String] = [
        "2563EB",
        "16A34A",
        "EA580C",
        "E11D48",
        "7C3AED",
        "0D9488",
        "D97706",
        "475569",
    ]
}
