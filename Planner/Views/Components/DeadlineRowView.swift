import SwiftUI
import SwiftData

struct DeadlineRowView: View {
    let deadline: Deadline

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
                    Text("\(start.formatted(.dateTime.month().day())) – \(deadline.dueDate.formatted(.dateTime.month().day()))")
                        .font(.caption2)
                        .foregroundStyle(Color.deadlinePrimary.opacity(0.8))
                }

                // 연결된 할일 수
                if !deadline.todos.isEmpty {
                    Text("할일 \(deadline.todos.count)개 연결됨")
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
        }
        .padding(.vertical, 2)
    }
}
