import Foundation
import SwiftData

@Model
final class PlannerLabel {
    var id: UUID
    var name: String
    var emoji: String?
    var colorHex: String
    @Relationship(inverse: \TodoItem.labels)
    var todos: [TodoItem]?
    @Relationship(inverse: \Deadline.labels)
    var deadlines: [Deadline]?

    init(name: String, emoji: String? = nil, colorHex: String) {
        self.id = UUID()
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.todos = []
        self.deadlines = []
    }
}

extension PlannerLabel {
    var displayTitle: String {
        guard let emoji, !emoji.isEmpty else { return name }
        return "\(emoji) \(name)"
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
