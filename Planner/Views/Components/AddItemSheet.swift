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
    @Query(sort: \PlannerLabel.name) private var allLabels: [PlannerLabel]

    let kind: ItemKind
    let day: Date
    private let editingTodo: TodoItem?
    private let editingDeadline: Deadline?

    @State private var title = ""
    @State private var notes = ""
    @State private var dueDate: Date
    @State private var hasTime = false
    @State private var isImportant = false
    @State private var autoCarryOver = true
    @State private var usesEndDate = false
    @State private var usesStartDate = false
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var selectedLabelIDs: Set<UUID> = []
    @State private var isShowingLabelCreator = false

    init(kind: ItemKind, day: Date) {
        self.kind = kind
        self.day = day
        self.editingTodo = nil
        self.editingDeadline = nil

        let defaultDate = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Calendar.current.startOfDay(for: day)
        ) ?? day

        _dueDate = State(initialValue: defaultDate)
        _startDate = State(initialValue: defaultDate)
        _endDate = State(initialValue: defaultDate)
    }

    init(todo: TodoItem) {
        self.kind = .todo
        self.day = todo.dueDate
        self.editingTodo = todo
        self.editingDeadline = nil

        _title = State(initialValue: todo.title)
        _notes = State(initialValue: todo.notes)
        _dueDate = State(initialValue: todo.dueDate)
        _hasTime = State(initialValue: todo.hasTime)
        _isImportant = State(initialValue: todo.isImportant)
        _autoCarryOver = State(initialValue: todo.autoCarryOver)
        _usesEndDate = State(initialValue: todo.endDate != nil)
        _usesStartDate = State(initialValue: false)
        _startDate = State(initialValue: todo.dueDate)
        _endDate = State(initialValue: todo.endDate ?? todo.dueDate)
        _selectedLabelIDs = State(initialValue: Set(todo.labels.map(\.id)))
    }

    init(deadline: Deadline) {
        self.kind = .deadline
        self.day = deadline.dueDate
        self.editingTodo = nil
        self.editingDeadline = deadline

        _title = State(initialValue: deadline.title)
        _notes = State(initialValue: deadline.notes)
        _dueDate = State(initialValue: deadline.dueDate)
        _hasTime = State(initialValue: deadline.hasTime)
        _isImportant = State(initialValue: deadline.isImportant)
        _autoCarryOver = State(initialValue: true)
        _usesEndDate = State(initialValue: false)
        _usesStartDate = State(initialValue: deadline.startDate != nil)
        _startDate = State(initialValue: deadline.startDate ?? deadline.dueDate)
        _endDate = State(initialValue: deadline.dueDate)
        _selectedLabelIDs = State(initialValue: Set(deadline.labels.map(\.id)))
    }

    private var saveDisabled: Bool {
        title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var navigationTitle: String {
        if editingTodo != nil {
            return theme.str.editTodo
        }
        if editingDeadline != nil {
            return theme.str.editDeadline
        }

        switch kind {
        case .todo: return theme.str.addTodo
        case .deadline: return theme.str.addDeadline
        }
    }

    @ViewBuilder
    private var formContent: some View {
        Form {
            Section {
                TextField(theme.str.titleLabel, text: $title)
            }

            Section {
                Toggle(theme.str.timeLabel, isOn: $hasTime.animation(.easeInOut(duration: 0.15)))

                DatePicker(
                    theme.str.dateLabel,
                    selection: $dueDate,
                    displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                )

                if kind == .todo {
                    Toggle(theme.str.endDateToggleLabel, isOn: $usesEndDate.animation(.easeInOut(duration: 0.15)))

                    if usesEndDate {
                        DatePicker(
                            theme.str.endDateLabel,
                            selection: $endDate,
                            displayedComponents: hasTime ? [.date, .hourAndMinute] : [.date]
                        )
                    }

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

            Section {
                HStack {
                    Text(theme.str.labelsLabel)
                        .font(.subheadline)
                    Spacer()
                    Button(theme.str.addLabel) {
                        isShowingLabelCreator = true
                    }
                    .font(.caption)
                }

                if allLabels.isEmpty {
                    Text(theme.str.noLabels)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), alignment: .leading)], alignment: .leading, spacing: 8) {
                        ForEach(allLabels, id: \.id) { label in
                            SelectableLabelChip(
                                label: label,
                                isSelected: selectedLabelIDs.contains(label.id)
                            ) {
                                toggleLabelSelection(label)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                TextField(theme.str.notesLabel, text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                #if os(macOS)
                formContent
                    .frame(maxWidth: 680)
                    .padding(.horizontal, 28)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                #else
                formContent
                #endif
            }
            .background(theme.groupedBackground)
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
        .sheet(isPresented: $isShowingLabelCreator) {
            LabelEditorSheet { label in
                selectedLabelIDs.insert(label.id)
            }
        }
    }

    private func saveItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedDueDate = normalized(date: dueDate, hasTime: hasTime)
        let selectedLabels = allLabels.filter { selectedLabelIDs.contains($0.id) }

        if let editingTodo {
            let normalizedEndDate = usesEndDate ? normalized(date: endDate, hasTime: hasTime) : nil
            editingTodo.title = trimmedTitle
            editingTodo.dueDate = normalizedDueDate
            editingTodo.endDate = normalizedEndDate.map { max($0, normalizedDueDate) }
            editingTodo.hasTime = hasTime
            editingTodo.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            editingTodo.isImportant = isImportant
            editingTodo.autoCarryOver = autoCarryOver
            editingTodo.labels = selectedLabels
        } else if let editingDeadline {
            editingDeadline.title = trimmedTitle
            editingDeadline.dueDate = normalizedDueDate
            editingDeadline.hasTime = hasTime
            editingDeadline.startDate = usesStartDate ? normalized(date: startDate, hasTime: hasTime) : nil
            editingDeadline.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            editingDeadline.isImportant = isImportant
            editingDeadline.labels = selectedLabels
        } else {
            switch kind {
            case .todo:
                let normalizedEndDate = usesEndDate ? normalized(date: endDate, hasTime: hasTime) : nil
                let todo = TodoItem(
                    title: trimmedTitle,
                    dueDate: normalizedDueDate,
                    endDate: normalizedEndDate.map { max($0, normalizedDueDate) },
                    hasTime: hasTime,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    isImportant: isImportant,
                    autoCarryOver: autoCarryOver,
                    labels: selectedLabels
                )
                modelContext.insert(todo)

            case .deadline:
                let deadline = Deadline(
                    title: trimmedTitle,
                    dueDate: normalizedDueDate,
                    hasTime: hasTime,
                    startDate: usesStartDate ? normalized(date: startDate, hasTime: hasTime) : nil,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    isImportant: isImportant,
                    labels: selectedLabels
                )
                modelContext.insert(deadline)
            }
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

    private func toggleLabelSelection(_ label: PlannerLabel) {
        if selectedLabelIDs.contains(label.id) {
            selectedLabelIDs.remove(label.id)
        } else {
            selectedLabelIDs.insert(label.id)
        }
    }
}
