import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Environment(ThemeManager.self) private var theme
    @Query private var allTodos: [TodoItem]
    @Query private var allDeadlines: [Deadline]

    @State private var currentWeekStart: Date = Self.weekStart(for: Date())
    @State private var selectedDay: Date? = nil
    @State private var addTargetDay: Date? = nil
    @State private var activeAddKind: AddItemSheet.ItemKind? = nil
    @State private var isShowingAddTypeDialog = false

    // 한국 기준 일(Sun)~토(Sat) 주 시작
    private static func weekStart(for date: Date) -> Date {
        var cal = Calendar.current
        cal.firstWeekday = 1 // 1 = 일요일
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: comps) ?? date
    }

    private var weekDays: [Date] {
        (0..<7).compactMap {
            Calendar.current.date(byAdding: .day, value: $0, to: currentWeekStart)
        }
    }

    private var weekRangeText: String {
        guard let end = Calendar.current.date(byAdding: .day, value: 6, to: currentWeekStart) else { return "" }
        let startFmt = DateFormatter()
        let endFmt = DateFormatter()
        startFmt.locale = theme.locale
        endFmt.locale = theme.locale

        if theme.language.isKo {
            startFmt.dateFormat = "M월 d일"
            endFmt.dateFormat = "d일"
        } else {
            startFmt.dateFormat = "MMM d"
            endFmt.dateFormat = Calendar.current.isDate(currentWeekStart, equalTo: end, toGranularity: .month) ? "d" : "MMM d"
        }

        return "\(startFmt.string(from: currentWeekStart)) – \(endFmt.string(from: end))"
    }

    private func todos(for day: Date) -> [TodoItem] {
        allTodos.filter { $0.includes(day) }
    }

    private func deadlines(for day: Date) -> [Deadline] {
        allDeadlines.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: day) }
    }

    private var isCurrentWeek: Bool {
        Calendar.current.isDate(currentWeekStart, equalTo: Self.weekStart(for: Date()), toGranularity: .weekOfYear)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                weekNavigationBar
                Divider()

                GeometryReader { geo in
                    let vPad: CGFloat = 10
                    let spacing: CGFloat = 6
                    let blockHeight = (geo.size.height - vPad * 2 - spacing * 6) / 7

                    VStack(spacing: spacing) {
                        ForEach(weekDays, id: \.self) { day in
                            DayBlockView(
                                day: day,
                                todos: todos(for: day),
                                deadlines: deadlines(for: day),
                                onTap: { selectedDay = day },
                                onAdd: {
                                    addTargetDay = day
                                    isShowingAddTypeDialog = true
                                }
                            )
                            .frame(height: max(blockHeight, 0), alignment: .top)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, vPad)
                }
            }
            .background(theme.groupedBackground)
            // 날짜 상세 뷰
            .sheet(item: $selectedDay) { day in
                DayDetailView(day: day)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(item: $activeAddKind, onDismiss: {
                addTargetDay = nil
            }) { kind in
                if let addTargetDay {
                    AddItemSheet(kind: kind, day: addTargetDay)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                } else {
                    EmptyView()
                }
            }
            .confirmationDialog(theme.str.createItem, isPresented: $isShowingAddTypeDialog, titleVisibility: .visible) {
                Button(theme.str.addTodo) {
                    activeAddKind = .todo
                }

                Button(theme.str.addDeadline) {
                    activeAddKind = .deadline
                }

                Button(theme.str.cancel, role: .cancel) {
                    addTargetDay = nil
                }
            }
        }
    }

    private var weekNavigationBar: some View {
        ZStack {
            HStack {
                weekArrowButton(systemName: "chevron.left", direction: -1)

                Spacer()

                HStack(spacing: 8) {
                    weeklyTodayButton

                    weekArrowButton(systemName: "chevron.right", direction: 1)
                }
            }

            Text(weekRangeText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(theme.surfaceBackground)
    }

    private var weeklyTodayButton: some View {
        Button(theme.str.today) {
            withAnimation {
                currentWeekStart = Self.weekStart(for: Date())
            }
        }
        .font(.caption2)
        .fontWeight(.medium)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.appGray6)
        .foregroundStyle(.secondary)
        .clipShape(Capsule())
        .opacity(isCurrentWeek ? 0 : 1)
        .allowsHitTesting(!isCurrentWeek)
    }

    private func weekArrowButton(systemName: String, direction: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentWeekStart = Calendar.current.date(
                    byAdding: .weekOfYear, value: direction, to: currentWeekStart
                ) ?? currentWeekStart
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
}
