import SwiftUI

struct DayBlockView: View {
    let day: Date
    let todos: [TodoItem]
    let deadlines: [Deadline]
    var onTap: (() -> Void)? = nil
    var onAdd: (() -> Void)? = nil

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "EEE"
        return formatter.string(from: day)
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: day)
    }

    private var isEmpty: Bool {
        todos.isEmpty && deadlines.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            // 날짜 헤더
            HStack {
                HStack(spacing: 6) {
                    Text(dayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(isToday ? .white : .secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(isToday ? Color.todoPrimary : Color(.systemGray5))
                        .clipShape(Capsule())

                    Text(dateText)
                        .font(.subheadline)
                        .foregroundStyle(isToday ? .todoPrimary : .secondary)
                        .fontWeight(isToday ? .semibold : .regular)
                }

                Spacer()

                Button {
                    onAdd?()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 30, height: 30)
                }
                .buttonStyle(.plain)
            }

            // 항목 없을 때
            if isEmpty {
                Text("항목 없음")
                    .font(.caption)
                    .foregroundStyle(.quaternary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                // Todo 섹션
                if !todos.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("할 일", systemImage: "checkmark.circle")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.todoPrimary)

                        ForEach(todos, id: \.id) { todo in
                            TodoRowView(todo: todo)
                        }
                    }
                }

                // 마감일 섹션
                if !deadlines.isEmpty {
                    if !todos.isEmpty {
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label("마감일", systemImage: "flag")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.deadlinePrimary)

                        ForEach(deadlines, id: \.id) { deadline in
                            DeadlineRowView(deadline: deadline)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isToday ? Color.todoPrimary.opacity(0.4) : Color(.systemGray5),
                    lineWidth: isToday ? 1.5 : 0.5
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            onTap?()
        }
    }
}
