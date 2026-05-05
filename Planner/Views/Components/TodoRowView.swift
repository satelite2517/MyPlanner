import SwiftUI
import SwiftData

struct TodoRowView: View {
    @Environment(ThemeManager.self) private var theme
    @Bindable var todo: TodoItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 완료 체크 버튼
            Button {
                todo.isCompleted.toggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(todo.isCompleted ? theme.primary : Color.appGray3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                // 제목 + 중요 표시
                HStack(spacing: 4) {
                    if todo.isImportant {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.orange)
                    }
                    Text(todo.title)
                        .font(.subheadline)
                        .strikethrough(todo.isCompleted, color: .secondary)
                        .foregroundStyle(todo.isCompleted ? .tertiary : .primary)
                }

                // 시간 (설정된 경우)
                if todo.hasTime {
                    Text(todo.dueDate.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 라벨
                if !todo.labels.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(todo.labels, id: \.id) { label in
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

            // 연결된 마감일 있음 표시
            if todo.deadline != nil {
                Image(systemName: "flag.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.deadlinePrimary.opacity(0.7))
            }
        }
        .padding(.vertical, 2)
    }
}
