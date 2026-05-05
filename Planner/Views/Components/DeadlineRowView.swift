import SwiftUI
import SwiftData

struct DeadlineRowView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    let deadline: Deadline
    @State private var isShowingEditSheet = false

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = theme.locale
        formatter.dateFormat = theme.language.isKo ? "M/d" : "MMM d"
        return formatter.string(from: date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 왼쪽 amber 바
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.deadlinePrimary.opacity(0.8))
                .frame(width: 3)
                .padding(.vertical, 2)

            VStack(alignment: .leading, spacing: 3) {
                // 제목 + 중요 표시
                HStack(spacing: 4) {
                    if deadline.isImportant {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    Text(deadline.title)
                        .font(.subheadline)
                        .strikethrough(deadline.isCompleted, color: .secondary)
                        .foregroundStyle(deadline.isCompleted ? .tertiary : .primary)
                }

                // 시간 (설정된 경우)
                if deadline.hasTime {
                    Text(deadline.dueDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 기간 (startDate가 있는 경우)
                if let start = deadline.startDate {
                    Text("\(shortDate(start)) – \(shortDate(deadline.dueDate))")
                        .font(.caption2)
                        .foregroundStyle(Color.deadlinePrimary.opacity(0.8))
                }

                // 연결된 할일 수
                if !deadline.todos.isEmpty {
                    Text(theme.str.deadlineLinkedCount(deadline.todos.count))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 라벨
                if !deadline.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(deadline.labels, id: \.id) { label in
                            Text(label.name)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(hex: label.colorHex).opacity(0.15))
                                .foregroundStyle(Color(hex: label.colorHex))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Menu {
                Button(theme.str.edit) {
                    isShowingEditSheet = true
                }

                Button(theme.str.delete, role: .destructive) {
                    deleteDeadline()
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 24, height: 24)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.vertical, 2)
        .sheet(isPresented: $isShowingEditSheet) {
            AddItemSheet(deadline: deadline)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private func deleteDeadline() {
        modelContext.delete(deadline)
        try? modelContext.save()
    }
}
