import Foundation
import SwiftData

// 할일이 완료되지 않았을 때의 이력을 기록
@Model
final class TodoHistory {
    var id: UUID
    var originalDate: Date       // 원래 해야 했던 날짜
    var wasCompleted: Bool       // 그 날 완료했는지
    var carriedOverTo: Date?     // 이월됐다면 어느 날짜로 넘어갔는지
    var recordedAt: Date         // 기록 시점

    init(originalDate: Date, wasCompleted: Bool, carriedOverTo: Date? = nil) {
        self.id = UUID()
        self.originalDate = originalDate
        self.wasCompleted = wasCompleted
        self.carriedOverTo = carriedOverTo
        self.recordedAt = Date()
    }
}
