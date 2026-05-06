import SwiftUI
import SwiftData

struct MonthlyView: View {
    @Environment(ThemeManager.self) private var theme
    @Query private var allTodos: [TodoItem]
    @Query private var allDeadlines: [Deadline]

    @State private var currentMonth: Date = Self.monthStart(for: Date())
    @State private var selectedDay: Date? = Self.defaultSelectedDay(for: Self.monthStart(for: Date()))
    @State private var filter: FilterMode = .all

    enum FilterMode: CaseIterable {
        case all
        case todos
        case deadlines
    }

    private struct CombinedSelectedItem {
        let date: Date
        let content: Content

        enum Content {
            case todo(TodoItem)
            case deadline(Deadline)
        }
    }

    private static func monthStart(for date: Date) -> Date {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return Calendar.current.date(from: comps) ?? date
    }

    private static func defaultSelectedDay(for month: Date) -> Date {
        let today = Date()
        if Calendar.current.isDate(today, equalTo: month, toGranularity: .month) {
            return today
        }
        return month
    }

    private var calendarDays: [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 일요일 시작

        guard let monthEnd = Calendar.current.date(
            byAdding: DateComponents(month: 1, day: -1), to: currentMonth
        ) else { return [] }

        let startComps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentMonth)
        let endComps   = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthEnd)

        guard let calStart = cal.date(from: startComps),
              let weekOfEnd = cal.date(from: endComps),
              let calEnd = cal.date(byAdding: .day, value: 6, to: weekOfEnd)
        else { return [] }

        var days: [Date] = []
        var day = calStart
        while day <= calEnd {
            days.append(day)
            day = Calendar.current.date(byAdding: .day, value: 1, to: day) ?? day
        }
        return days
    }

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.locale = theme.locale
        fmt.dateFormat = theme.language.isKo ? "yyyy년 M월" : "MMMM yyyy"
        return fmt.string(from: currentMonth)
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(
            currentMonth,
            equalTo: Self.monthStart(for: Date()),
            toGranularity: .month
        )
    }

    private func todos(for day: Date) -> [TodoItem] {
        allTodos.filter { $0.includes(day) }
    }

    private func deadlines(for day: Date) -> [Deadline] {
        let cal = Calendar.current
        let dayStart = cal.startOfDay(for: day)
        return allDeadlines.filter { dl in
            if cal.isDate(dl.dueDate, inSameDayAs: day) { return true }
            if let start = dl.startDate {
                let dlStart = cal.startOfDay(for: start)
                let dlEnd   = cal.startOfDay(for: dl.dueDate)
                return dayStart >= dlStart && dayStart <= dlEnd
            }
            return false
        }
    }

    private var selectedTodos: [TodoItem] {
        guard let selectedDay else { return [] }
        return todos(for: selectedDay).sorted { first, second in
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

    private var selectedDeadlines: [Deadline] {
        guard let selectedDay else { return [] }
        return deadlines(for: selectedDay).sorted { first, second in
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

    private var selectedDayTitle: String {
        guard let selectedDay else { return theme.str.selectDatePrompt }
        let formatter = DateFormatter()
        formatter.locale = theme.locale
        formatter.dateFormat = theme.language.isKo ? "M월 d일 (E)" : "MMM d (EEE)"
        return formatter.string(from: selectedDay)
    }

    private var selectedAllItems: [CombinedSelectedItem] {
        let todoItems = selectedTodos.map { CombinedSelectedItem(date: $0.dueDate, content: .todo($0)) }
        let deadlineItems = selectedDeadlines.map { CombinedSelectedItem(date: $0.dueDate, content: .deadline($0)) }

        return (todoItems + deadlineItems).sorted { first, second in
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
    }

    private var selectedItemsEmptyForFilter: Bool {
        switch filter {
        case .all:
            return selectedAllItems.isEmpty
        case .todos:
            return selectedTodos.isEmpty
        case .deadlines:
            return selectedDeadlines.isEmpty
        }
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var weekDayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = theme.locale
        return formatter.shortStandaloneWeekdaySymbols
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                monthNavigationBar
                Divider()

                ScrollView {
                    VStack(spacing: 0) {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(weekDayNames, id: \.self) { name in
                                Text(name)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                            }
                        }
                        .padding(.horizontal, 12)

                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(calendarDays, id: \.self) { day in
                                MonthDayCell(
                                    day: day,
                                    currentMonth: currentMonth,
                                    isSelected: selectedDay.map { Calendar.current.isDate($0, inSameDayAs: day) } ?? false,
                                    todos: todos(for: day),
                                    deadlines: deadlines(for: day)
                                )
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.18)) {
                                        selectedDay = day
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 12)

                        selectedDayPanel
                            .padding(.horizontal, 12)
                            .padding(.bottom, 16)
                    }
                }
                .background(theme.groupedBackground)
            }
            .background(theme.groupedBackground)
        }
    }

    private var monthNavigationBar: some View {
        ZStack {
            HStack {
                monthArrowButton(systemName: "chevron.left", direction: -1)

                Spacer()

                HStack(spacing: 8) {
                    monthlyTodayButton

                    monthArrowButton(systemName: "chevron.right", direction: 1)
                }
            }

            Text(monthTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(theme.surfaceBackground)
    }

    private var monthlyTodayButton: some View {
        Button(theme.str.today) {
            withAnimation {
                let newMonth = Self.monthStart(for: Date())
                currentMonth = newMonth
                selectedDay = Self.defaultSelectedDay(for: newMonth)
            }
        }
        .font(.caption2)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appGray6)
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
        .opacity(isCurrentMonth ? 0 : 1)
        .allowsHitTesting(!isCurrentMonth)
    }

    private func monthArrowButton(systemName: String, direction: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                let newMonth = Calendar.current.date(
                    byAdding: .month, value: direction, to: currentMonth
                ) ?? currentMonth
                currentMonth = newMonth
                selectedDay = Self.defaultSelectedDay(for: newMonth)
            }
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 30, height: 30)
                .background(Color.appGray6)
                .clipShape(Circle())
        }
    }

    private var selectedDayPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(selectedDayTitle)
                .font(.headline)
                .fontWeight(.semibold)

            filterPicker

            if let _ = selectedDay {
                if selectedItemsEmptyForFilter {
                    Text(theme.str.noItemsLong)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 20)
                } else {
                    if filter == .all {
                        detailSection(title: theme.str.all, tint: theme.primary, systemImage: "line.3.horizontal.decrease.circle") {
                            ForEach(Array(selectedAllItems.enumerated()), id: \.offset) { _, item in
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
                    } else if filter == .todos && !selectedTodos.isEmpty {
                        detailSection(title: theme.str.todos, tint: theme.todoColor, systemImage: "checkmark.circle") {
                            ForEach(selectedTodos, id: \.id) { todo in
                                TodoRowView(todo: todo)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(theme.surfaceBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }

                    if filter == .deadlines && !selectedDeadlines.isEmpty {
                        detailSection(title: theme.str.deadlines, tint: theme.deadlineColor, systemImage: "flag") {
                            ForEach(selectedDeadlines, id: \.id) { deadline in
                                DeadlineRowView(deadline: deadline)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(theme.surfaceBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }
            } else {
                Text(theme.str.selectDatePrompt)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            }
        }
        .padding(16)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filterPicker: some View {
        HStack(spacing: 8) {
            ForEach(FilterMode.allCases, id: \.self) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        filter = mode
                    }
                } label: {
                    Text(title(for: mode))
                        .font(.caption)
                        .fontWeight(filter == mode ? .semibold : .regular)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(filter == mode ? theme.primary : Color.appGray6)
                        .foregroundStyle(filter == mode ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func detailSection<Content: View>(title: String, tint: Color, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(tint)

            VStack(spacing: 8) {
                content()
            }
        }
    }

    private func title(for mode: FilterMode) -> String {
        switch mode {
        case .all: return theme.str.all
        case .todos: return theme.str.todos
        case .deadlines: return theme.str.deadlines
        }
    }
}

// MARK: - Day Cell

private struct MonthDayCell: View {
    @Environment(ThemeManager.self) private var theme
    let day: Date
    let currentMonth: Date
    let isSelected: Bool
    let todos: [TodoItem]
    let deadlines: [Deadline]

    private var isToday: Bool {
        Calendar.current.isDateInToday(day)
    }

    private var isInCurrentMonth: Bool {
        Calendar.current.isDate(day, equalTo: currentMonth, toGranularity: .month)
    }

    private var dayNumber: String {
        "\(Calendar.current.component(.day, from: day))"
    }

    private struct CellItem {
        let title: String
        let isTodo: Bool
    }

    private var items: [CellItem] {
        let t = todos.map { CellItem(title: $0.title, isTodo: true) }
        let d = deadlines.map { CellItem(title: $0.title, isTodo: false) }
        return t + d
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(dayNumber)
                .font(.system(size: 12, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.white : (isInCurrentMonth ? Color.primary : Color.secondary.opacity(0.35)))
                .frame(width: 22, height: 22)
                .background(isToday ? theme.primary : Color.clear)
                .clipShape(Circle())
                .frame(maxWidth: .infinity, alignment: .center)

            ForEach(0..<min(2, items.count), id: \.self) { idx in
                let item = items[idx]
                Text(item.title)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .foregroundStyle(item.isTodo ? theme.todoColor : theme.deadlineColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(item.isTodo ? theme.todoBackground : theme.deadlineBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
            }

            if items.count > 2 {
                Text("+\(items.count - 2)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: 62)
        .background(isInCurrentMonth ? theme.surfaceBackground : Color.appGray6)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    isSelected ? theme.primary : (isToday ? theme.primary.opacity(0.45) : Color.appGray5),
                    lineWidth: isSelected ? 2 : (isToday ? 1.5 : 0.5)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    MonthlyView()
        .environment(ThemeManager())
        .modelContainer(for: [TodoItem.self, Deadline.self, PlannerLabel.self, TodoHistory.self])
}
