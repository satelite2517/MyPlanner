import SwiftUI
import SwiftData

struct WeeklyView: View {
    @Query private var allTodos: [TodoItem]
    @Query private var allDeadlines: [Deadline]

    @State private var currentWeekStart: Date = Self.weekStart(for: Date())
    @State private var selectedDay: Date? = nil

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
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "ko_KR")
        fmt.dateFormat = "M월 d일"
        let endFmt = DateFormatter()
        endFmt.locale = Locale(identifier: "ko_KR")
        endFmt.dateFormat = "d일"
        return "\(fmt.string(from: currentWeekStart)) – \(endFmt.string(from: end))"
    }

    private func todos(for day: Date) -> [TodoItem] {
        allTodos.filter { Calendar.current.isDate($0.dueDate, inSameDayAs: day) }
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

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(weekDays, id: \.self) { day in
                                DayBlockView(
                                    day: day,
                                    todos: todos(for: day),
                                    deadlines: deadlines(for: day),
                                    onTap: { selectedDay = day },
                                    onAdd: { selectedDay = day }
                                )
                                .id(day)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .onAppear {
                        // 오늘 블럭으로 자동 스크롤
                        if let today = weekDays.first(where: { Calendar.current.isDateInToday($0) }) {
                            proxy.scrollTo(today, anchor: .top)
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Weekly")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isCurrentWeek {
                        Button("오늘") {
                            withAnimation {
                                currentWeekStart = Self.weekStart(for: Date())
                            }
                        }
                        .font(.subheadline)
                    }
                }
            }
            // 날짜 상세 뷰 (이후 단계에서 구현)
            .sheet(item: $selectedDay) { day in
                Text("날짜 상세 뷰: \(day.formatted(.dateTime.month().day()))")
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var weekNavigationBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentWeekStart = Calendar.current.date(
                        byAdding: .weekOfYear, value: -1, to: currentWeekStart
                    ) ?? currentWeekStart
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }

            Spacer()

            Text(weekRangeText)
                .font(.subheadline)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentWeekStart = Calendar.current.date(
                        byAdding: .weekOfYear, value: 1, to: currentWeekStart
                    ) ?? currentWeekStart
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)
                    .frame(width: 34, height: 34)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
    }
}

// sheet(item:)을 위해 Date를 Identifiable로 확장
extension Date: @retroactive Identifiable {
    public var id: TimeInterval { timeIntervalSince1970 }
}
