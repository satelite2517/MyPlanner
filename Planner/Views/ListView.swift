import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(ThemeManager.self) private var theme
    @Query(sort: \TodoItem.dueDate) private var allTodos: [TodoItem]
    @Query(sort: \Deadline.dueDate) private var allDeadlines: [Deadline]

    @State private var filter: FilterMode = .all

    enum FilterMode: CaseIterable {
        case all
        case todos
        case deadlines
    }

    private struct CombinedListItem {
        let date: Date
        let content: Content

        enum Content {
            case todo(TodoItem)
            case deadline(Deadline)
        }
    }

    private var visibleRangeStart: Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let today = Date()
        let startOfToday = calendar.startOfDay(for: today)
        let weekday = calendar.component(.weekday, from: startOfToday)
        let offset = (weekday - calendar.firstWeekday + 7) % 7

        return calendar.date(byAdding: .day, value: -offset, to: startOfToday) ?? startOfToday
    }

    // MARK: - Grouped Data

    private var groupedTodos: [(key: Date, items: [TodoItem])] {
        guard filter != .deadlines else { return [] }
        return Dictionary(grouping: allTodos.filter { $0.dueDate >= visibleRangeStart }) {
            Calendar.current.startOfDay(for: $0.dueDate)
        }
        .sorted { $0.key < $1.key }
        .map { (key: $0.key, items: $0.value) }
    }

    private var groupedAllItems: [(key: Date, items: [CombinedListItem])] {
        guard filter == .all else { return [] }

        let items =
            allTodos
                .filter { $0.dueDate >= visibleRangeStart }
                .map { CombinedListItem(date: $0.dueDate, content: .todo($0)) }
            +
            allDeadlines
                .filter { $0.dueDate >= visibleRangeStart }
                .map { CombinedListItem(date: $0.dueDate, content: .deadline($0)) }

        return Dictionary(grouping: items) {
            Calendar.current.startOfDay(for: $0.date)
        }
        .sorted { $0.key < $1.key }
        .map { key, items in
            let sortedItems = items.sorted { first, second in
                if first.date != second.date {
                    return first.date < second.date
                }

                switch (first.content, second.content) {
                case (.todo(let lhs), .todo(let rhs)):
                    if lhs.isImportant != rhs.isImportant { return lhs.isImportant }
                    return lhs.title < rhs.title
                case (.deadline(let lhs), .deadline(let rhs)):
                    if lhs.isImportant != rhs.isImportant { return lhs.isImportant }
                    return lhs.title < rhs.title
                case (.todo(let lhs), .deadline(let rhs)):
                    if lhs.isImportant != rhs.isImportant { return lhs.isImportant }
                    return lhs.title < rhs.title
                case (.deadline(let lhs), .todo(let rhs)):
                    if lhs.isImportant != rhs.isImportant { return lhs.isImportant }
                    return lhs.title < rhs.title
                }
            }

            return (key: key, items: sortedItems)
        }
    }

    private var groupedDeadlines: [(key: Date, items: [Deadline])] {
        guard filter != .todos else { return [] }
        return Dictionary(grouping: allDeadlines.filter { $0.dueDate >= visibleRangeStart }) {
            Calendar.current.startOfDay(for: $0.dueDate)
        }
        .sorted { $0.key < $1.key }
        .map { (key: $0.key, items: $0.value) }
    }

    private var isEmpty: Bool {
        groupedTodos.isEmpty && groupedDeadlines.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterPicker
                Divider()

                if isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 20) {
                            if filter == .all {
                                ForEach(groupedAllItems, id: \.key) { group in
                                    dateSection(date: group.key) {
                                        ForEach(Array(group.items.enumerated()), id: \.offset) { _, item in
                                            switch item.content {
                                            case .todo(let todo):
                                                TodoRowView(todo: todo)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .background(theme.surfaceBackground)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            case .deadline(let deadline):
                                                DeadlineRowView(deadline: deadline)
                                                    .padding(.horizontal, 14)
                                                    .padding(.vertical, 10)
                                                    .background(theme.surfaceBackground)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                        }
                                    }
                                }
                            } else if filter != .deadlines {
                                ForEach(groupedTodos, id: \.key) { group in
                                    dateSection(date: group.key) {
                                        ForEach(group.items, id: \.id) { todo in
                                            TodoRowView(todo: todo)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(theme.surfaceBackground)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }

                            if filter != .todos {
                                ForEach(groupedDeadlines, id: \.key) { group in
                                    dateSection(date: group.key) {
                                        ForEach(group.items, id: \.id) { deadline in
                                            DeadlineRowView(deadline: deadline)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(theme.surfaceBackground)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .background(theme.groupedBackground)
                }
            }
            .background(theme.groupedBackground)
            .navigationTitle(theme.str.listTitle)
            .largeNavigationTitle()
        }
    }

    // MARK: - Subviews

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { filter = mode }
                } label: {
                    Text(title(for: mode))
                        .font(.subheadline)
                        .fontWeight(filter == mode ? .semibold : .regular)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(filter == mode ? theme.primary : Color.appGray6)
                        .foregroundStyle(filter == mode ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(theme.surfaceBackground)
    }

    @ViewBuilder
    private func dateSection<Content: View>(date: Date, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(sectionTitle(for: date))
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 2)

            VStack(spacing: 6) {
                content()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(theme.str.noItemsLong)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.groupedBackground)
    }

    // MARK: - Helpers

    private func sectionTitle(for date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return theme.str.today }
        if cal.isDateInTomorrow(date) { return theme.str.tomorrow }
        if cal.isDateInYesterday(date) { return theme.str.yesterday }

        let fmt = DateFormatter()
        fmt.locale = theme.locale
        fmt.dateFormat = theme.language.isKo ? "M월 d일 (E)" : "MMM d (EEE)"
        return fmt.string(from: date)
    }

    private func title(for mode: FilterMode) -> String {
        switch mode {
        case .all: return theme.str.all
        case .todos: return theme.str.todos
        case .deadlines: return theme.str.deadlines
        }
    }
}

#Preview {
    ListView()
        .environment(ThemeManager())
        .modelContainer(for: [TodoItem.self, Deadline.self, PlannerLabel.self, TodoHistory.self])
}
