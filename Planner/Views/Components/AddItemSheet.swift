import SwiftUI
import SwiftData

struct AddItemSheet: View {
    enum ItemKind: Identifiable {
        case todo
        case deadline

        var id: String {
            switch self {
            case .todo: return "todo"
            case .deadline: return "deadline"
            }
        }
    }

    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let kind: ItemKind
    let day: Date

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date
    @State private var hasTime = false
    @State private var isImportant = false
    @State private var autoCarryOver = true
    @State private var usesStartDate = false
    @State private var startDate: Date

    init(kind: ItemKind, day: Date) {
        self.kind = kind
        self.day = day

        let defaultDate = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Calendar.current.startOfDay(for: day)
        ) ?? day

        _dueDate = State(initialValue: defaultDate)
        _startDate = State(initialValue: defaultDate)
    }

    private var saveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationTitle: String {
        switch kind {
        case .todo: return theme.str.addTodo
        case .deadline: return theme.str.addDeadline
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(theme.str.titleLabel, text: $title)
                    TextField(theme.str.notesLabel, text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle(theme.str.timeLabel, isOn: $hasTime.animation(.easeInOut(duration: 0.15)))

                    DatePicker(
                        theme.str.dateLabel,
                        selection: $dueDate,
                        displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                    )

                    if kind == .todo {
                        Toggle(theme.str.autoCarryOverLabel, isOn: $autoCarryOver)
                    }

                    if kind == .deadline {
                        Toggle(theme.str.startDateLabel, isOn: $usesStartDate.animation(.easeInOut(duration: 0.15)))

                        if usesStartDate {
                            DatePicker(
                                theme.str.startDateLabel,
                                selection: $startDate,
                                displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                            )
                        }
                    }
                }

                Section {
                    Toggle(theme.str.important, isOn: $isImportant)
                }
            }
            .navigationTitle(navigationTitle)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button(theme.str.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .trailingBar) {
                    Button(theme.str.confirm) {
                        saveItem()
                    }
                    .disabled(saveDisabled)
                }
            }
        }
    }

    private func saveItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDueDate = normalized(date: dueDate, hasTime: hasTime)

        switch kind {
        case .todo:
            let todo = TodoItem(
                title: trimmedTitle,
                dueDate: normalizedDueDate,
                hasTime: hasTime,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isImportant: isImportant,
                autoCarryOver: autoCarryOver
            )
            modelContext.insert(todo)

        case .deadline:
            let deadline = Deadline(
                title: trimmedTitle,
                dueDate: normalizedDueDate,
                hasTime: hasTime,
                startDate: usesStartDate ? normalized(date: startDate, hasTime: hasTime) : nil,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                isImportant: isImportant
            )
            modelContext.insert(deadline)
        }

        try? modelContext.save()
        dismiss()
    }

    private func normalized(date: Date, hasTime: Bool) -> Date {
        if hasTime {
            return date
        }
        return Calendar.current.startOfDay(for: date)
    }
}
