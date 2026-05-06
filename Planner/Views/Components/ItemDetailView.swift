import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    enum Item {
        case todo(TodoItem)
        case deadline(Deadline)
    }

    let item: Item
    @State private var isShowingEditSheet = false

    private var navigationTitle: String {
        switch item {
        case .todo(let todo): return todo.title
        case .deadline(let deadline): return deadline.title
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    switch item {
                    case .todo(let todo): todoContent(todo)
                    case .deadline(let deadline): deadlineContent(deadline)
                    }
                }
                .padding(16)
            }
            .background(theme.groupedBackground)
            .navigationTitle(navigationTitle)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button(theme.str.close) { dismiss() }
                }
                ToolbarItem(placement: .trailingBar) {
                    Button(theme.str.edit) { isShowingEditSheet = true }
                }
            }
        }
        .sheet(isPresented: $isShowingEditSheet) {
            editSheet
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var editSheet: some View {
        switch item {
        case .todo(let todo): AddItemSheet(todo: todo)
        case .deadline(let deadline): AddItemSheet(deadline: deadline)
        }
    }

    // MARK: - Todo Content

    @ViewBuilder
    private func todoContent(_ todo: TodoItem) -> some View {
        // Header card
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    todo.isCompleted.toggle()
                } label: {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(todo.isCompleted ? theme.todoColor : Color.appGray3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if todo.isImportant {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                        Text(todo.title)
                            .font(.title3.weight(.semibold))
                            .strikethrough(todo.isCompleted)
                            .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                    }
                    Text(todoDateString(todo))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !todo.labelList.isEmpty {
                labelChips(todo.labelList)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))

        if !todo.notes.isEmpty {
            sectionCard(title: theme.str.notesLabel) {
                Text(todo.notes)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        if !todo.links.isEmpty {
            sectionCard(title: theme.str.linksLabel) {
                linksContent(todo.links)
            }
        }

        if let deadline = todo.deadline {
            sectionCard(title: theme.str.linkedDeadline) {
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.deadlineColor)
                        .frame(width: 3, height: 18)
                    Text(deadline.title)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    // MARK: - Deadline Content

    @ViewBuilder
    private func deadlineContent(_ deadline: Deadline) -> some View {
        // Header card
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Button {
                    deadline.isCompleted.toggle()
                    Task { try? await ReminderSyncService().pushDeadline(deadline) }
                } label: {
                    Image(systemName: deadline.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundStyle(deadline.isCompleted ? .green : Color.appGray3)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        if deadline.isImportant {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.orange)
                        }
                        Text(deadline.title)
                            .font(.title3.weight(.semibold))
                            .strikethrough(deadline.isCompleted)
                            .foregroundStyle(deadline.isCompleted ? .secondary : .primary)
                            .multilineTextAlignment(.leading)
                    }
                    Text(deadlineDateString(deadline))
                        .font(.subheadline)
                        .foregroundStyle(deadline.startDate != nil ? theme.deadlineColor.opacity(0.9) : .secondary)
                }
                Spacer()
            }

            if !deadline.labelList.isEmpty {
                labelChips(deadline.labelList)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))

        if !deadline.notes.isEmpty {
            sectionCard(title: theme.str.notesLabel) {
                Text(deadline.notes)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        if !deadline.links.isEmpty {
            sectionCard(title: theme.str.linksLabel) {
                linksContent(deadline.links)
            }
        }

        if !deadline.todoList.isEmpty {
            sectionCard(title: theme.str.linkedTodos) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(deadline.todoList, id: \.id) { todo in
                        HStack(spacing: 8) {
                            Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.subheadline)
                                .foregroundStyle(todo.isCompleted ? theme.todoColor : .gray)
                            Text(todo.title)
                                .font(.subheadline)
                                .strikethrough(todo.isCompleted)
                                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Shared UI

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func labelChips(_ labels: [PlannerLabel]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(labels, id: \.id) { label in
                    Text(label.displayTitle)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: label.colorHex).opacity(0.15))
                        .foregroundStyle(Color(hex: label.colorHex))
                        .clipShape(Capsule())
                }
            }
        }
    }

    private func linksContent(_ links: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(links, id: \.self) { link in
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(link)
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Date Helpers

    private func todoDateString(_ todo: TodoItem) -> String {
        let formatter = DateFormatter()
        formatter.locale = theme.locale

        if todo.isMultiDay {
            formatter.dateFormat = theme.language.isKo ? "M/d" : "MMM d"
            let startStr = formatter.string(from: todo.dueDate)
            let endStr = formatter.string(from: todo.effectiveEndDate)
            if todo.hasTime {
                let tf = DateFormatter()
                tf.locale = theme.locale
                tf.dateStyle = .none
                tf.timeStyle = .short
                return "\(startStr) \(tf.string(from: todo.dueDate)) – \(endStr) \(tf.string(from: todo.effectiveEndDate))"
            }
            return "\(startStr) – \(endStr)"
        }

        formatter.dateFormat = todo.hasTime
            ? (theme.language.isKo ? "M월 d일 (E)  a h:mm" : "MMM d (EEE)  h:mm a")
            : (theme.language.isKo ? "M월 d일 (E)" : "MMM d (EEE)")
        return formatter.string(from: todo.dueDate)
    }

    private func deadlineDateString(_ deadline: Deadline) -> String {
        let formatter = DateFormatter()
        formatter.locale = theme.locale
        formatter.dateFormat = theme.language.isKo ? "M월 d일 (E)" : "MMM d (EEE)"

        if let start = deadline.startDate {
            return "\(formatter.string(from: start)) – \(formatter.string(from: deadline.dueDate))"
        }

        if deadline.hasTime {
            formatter.dateFormat = theme.language.isKo ? "M월 d일 (E)  a h:mm" : "MMM d (EEE)  h:mm a"
        }
        return formatter.string(from: deadline.dueDate)
    }
}

#Preview {
    ItemDetailView(item: .todo(TodoItem(title: "샘플 할 일", dueDate: Date(), notes: "메모 내용", isImportant: true)))
        .environment(ThemeManager())
        .modelContainer(for: [TodoItem.self, Deadline.self, PlannerLabel.self, TodoHistory.self])
}
