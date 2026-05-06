import SwiftUI
import SwiftData

struct TodoRowView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Bindable var todo: TodoItem

    private enum ActiveSheet: Identifiable {
        case edit, detail
        var id: Self { self }
    }
    @State private var activeSheet: ActiveSheet?

    private var scheduleText: String? {
        let formatter = DateFormatter()
        formatter.locale = theme.locale

        if todo.isMultiDay {
            formatter.dateFormat = theme.language.isKo ? "M/d" : "M/d"
            let startText = formatter.string(from: todo.dueDate)
            let endText = formatter.string(from: todo.effectiveEndDate)

            if todo.hasTime {
                let timeFormatter = DateFormatter()
                timeFormatter.locale = theme.locale
                timeFormatter.dateStyle = .none
                timeFormatter.timeStyle = .short
                return "\(startText) \(timeFormatter.string(from: todo.dueDate)) – \(endText) \(timeFormatter.string(from: todo.effectiveEndDate))"
            }

            return "\(startText) – \(endText)"
        }

        if todo.hasTime {
            return todo.dueDate.formatted(date: .omitted, time: .shortened)
        }

        return nil
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // 완료 체크 버튼
            Button {
                todo.isCompleted.toggle()
            } label: {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(todo.isCompleted ? theme.todoColor : Color.appGray3)
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

                if let scheduleText {
                    Text(scheduleText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                // 라벨
                if !todo.labelList.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(todo.labelList, id: \.id) { label in
                            Text(label.displayTitle)
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
            .contentShape(Rectangle())
            .onTapGesture { activeSheet = .detail }

            Spacer()

            HStack(spacing: 8) {
                if todo.deadline != nil {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.deadlineColor.opacity(0.7))
                }

                Menu {
                    Button(theme.str.edit) {
                        activeSheet = .edit
                    }

                    Button(theme.str.delete, role: .destructive) {
                        deleteTodo()
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: 24, height: 24)
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding(.vertical, 2)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .edit:
                AddItemSheet(todo: todo)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            case .detail:
                ItemDetailView(item: .todo(todo))
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func deleteTodo() {
        modelContext.delete(todo)
        try? modelContext.save()
    }
}
