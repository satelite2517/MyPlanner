import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Environment(ThemeManager.self) private var theme

    let day: Date
    @Query private var allTodos: [TodoItem]
    @Query private var allDeadlines: [Deadline]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedTab: DetailTab = .todos
    @State private var activeSheet: AddItemSheet.ItemKind?
    
    enum DetailTab: CaseIterable {
        case todos
        case deadlines
    }
    
    private var dayTodos: [TodoItem] {
        allTodos.filter { $0.includes(day) }
            .sorted { first, second in
                // 중요 먼저, 시간 있으면 시간순, 없으면 제목순
                if first.isImportant != second.isImportant {
                    return first.isImportant
                }
                if first.hasTime != second.hasTime {
                    return first.hasTime
                }
                if first.hasTime && second.hasTime {
                    return first.dueDate < second.dueDate
                }
                return first.title < second.title
            }
    }
    
    private var dayDeadlines: [Deadline] {
        allDeadlines.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: day) }
            .sorted { first, second in
                if first.isImportant != second.isImportant {
                    return first.isImportant
                }
                if first.hasTime != second.hasTime {
                    return first.hasTime
                }
                if first.hasTime && second.hasTime {
                    return first.dueDate < second.dueDate
                }
                return first.title < second.title
            }
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }
    
    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.locale = theme.locale
        formatter.dateFormat = theme.language.isKo ? "M월 d일 (E)" : "MMM d (EEE)"
        return formatter.string(from: day)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker
                Divider()
                detailContent
            }
            .navigationTitle(dateTitle)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button(theme.str.close) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .trailingBar) {
                    Menu {
                        Button {
                            activeSheet = .todo
                        } label: {
                            Label(theme.str.addTodo, systemImage: "checkmark.circle")
                        }
                        
                        Button {
                            activeSheet = .deadline
                        } label: {
                            Label(theme.str.addDeadline, systemImage: "flag")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
        }
        .sheet(item: $activeSheet) { kind in
            AddItemSheet(kind: kind, day: day)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var detailContent: some View {
        #if os(iOS)
        TabView(selection: $selectedTab) {
            detailScrollContent {
                todosContent
            }
            .tag(DetailTab.todos)

            detailScrollContent {
                deadlinesContent
            }
            .tag(DetailTab.deadlines)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(theme.groupedBackground)
        #else
        detailScrollContent {
            switch selectedTab {
            case .todos:
                todosContent
            case .deadlines:
                deadlinesContent
            }
        }
        .background(theme.groupedBackground)
        #endif
    }

    private func detailScrollContent<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
    
    // MARK: - Tab Picker

    private var tabPicker: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(title(for: tab))
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? Color.primary : Color.secondary)
                        
                        if selectedTab == tab {
                            Rectangle()
                                .fill(theme.primary)
                                .frame(height: 2)
                        } else {
                            Rectangle()
                                .fill(Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .padding(.top, 8)
                    #if os(macOS)
                    .padding(.top, 4)
                    #endif
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .background(theme.surfaceBackground)
    }
    
    // MARK: - Todos Content
    
    private var todosContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            todoStatsView

            if dayTodos.isEmpty {
                emptyStateView
            } else {
                ForEach(dayTodos, id: \.id) { todo in
                    todoDetailRow(todo)
                }
            }
        }
    }
    
    private var todoStatsView: some View {
        HStack(spacing: 20) {
            statsItem(
                icon: "checkmark.circle.fill",
                color: .green,
                count: dayTodos.filter(\.isCompleted).count,
                label: theme.str.completed
            )
            
            statsItem(
                icon: "circle",
                color: .gray,
                count: dayTodos.filter { !$0.isCompleted }.count,
                label: theme.str.incomplete
            )
            
            statsItem(
                icon: "star.fill",
                color: .yellow,
                count: dayTodos.filter(\.isImportant).count,
                label: theme.str.important
            )
        }
        .padding(12)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Deadlines Content
    
    private var deadlinesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            deadlineStatsView

            if dayDeadlines.isEmpty {
                emptyStateView
            } else {
                ForEach(dayDeadlines, id: \.id) { deadline in
                    deadlineDetailRow(deadline)
                }
            }
        }
    }
    
    private var deadlineStatsView: some View {
        HStack(spacing: 20) {
            statsItem(
                icon: "checkmark.circle.fill",
                color: .green,
                count: dayDeadlines.filter(\.isCompleted).count,
                label: theme.str.completed
            )
            
            statsItem(
                icon: "flag.fill",
                color: theme.deadlineColor,
                count: dayDeadlines.filter { !$0.isCompleted }.count,
                label: theme.str.inProgress
            )
            
            statsItem(
                icon: "star.fill",
                color: .yellow,
                count: dayDeadlines.filter(\.isImportant).count,
                label: theme.str.important
            )
        }
        .padding(12)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Views
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            
            Text(theme.str.noItemsLong)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private func statsItem(icon: String, color: Color, count: Int, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(color)
            
            Text("\(count)")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func linksView(_ links: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(links, id: \.self) { link in
                HStack(spacing: 6) {
                    Image(systemName: "link")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    
                    Text(link)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
            }
        }
    }

    private func todoDetailRow(_ todo: TodoItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            TodoRowView(todo: todo)

            if !todo.notes.isEmpty {
                Text(todo.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 32)
            }

            if !todo.links.isEmpty {
                linksView(todo.links)
                    .padding(.leading, 32)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func deadlineDetailRow(_ deadline: Deadline) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            DeadlineRowView(deadline: deadline)

            if !deadline.notes.isEmpty {
                Text(deadline.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 8)
            }

            if !deadline.todoList.isEmpty {
                connectedTodosView(deadline.todoList)
                    .padding(.leading, 8)
            }

            if !deadline.links.isEmpty {
                linksView(deadline.links)
                    .padding(.leading, 8)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func connectedTodosView(_ todos: [TodoItem]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                Text(theme.str.linkedTodoCount(todos.count))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ForEach(todos, id: \.id) { todo in
                HStack(spacing: 6) {
                    Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.caption)
                        .foregroundStyle(todo.isCompleted ? .green : .gray)
                    
                    Text(todo.title)
                        .font(.caption)
                        .foregroundStyle(.primary)
                        .strikethrough(todo.isCompleted)
                }
            }
        }
        .padding(8)
        .background(Color.appGray5)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func title(for tab: DetailTab) -> String {
        switch tab {
        case .todos: return theme.str.todos
        case .deadlines: return theme.str.deadlines
        }
    }
}

#Preview {
    DayDetailView(day: Date())
        .environment(ThemeManager())
        .modelContainer(for: [TodoItem.self, Deadline.self, PlannerLabel.self, TodoHistory.self])
}
