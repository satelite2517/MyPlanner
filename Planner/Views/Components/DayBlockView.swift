import SwiftUI

struct DayBlockView: View {
    @Environment(ThemeManager.self) private var theme

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
        formatter.locale = theme.locale
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

    private var previewItems: [PreviewItem] {
        todoPreviewItems + deadlinePreviewItems
    }

    private var todoPreviewItems: [PreviewItem] {
        let todoItems = todos.map {
            PreviewItem(
                title: $0.title,
                systemImage: $0.isCompleted ? "checkmark.circle.fill" : "checkmark.circle",
                tint: $0.isCompleted ? Color.secondary : theme.primary
            )
        }
        return todoItems
    }

    private var deadlinePreviewItems: [PreviewItem] {
        deadlines.map {
            PreviewItem(
                title: $0.title,
                systemImage: "flag.fill",
                tint: Color.deadlinePrimary
            )
        }
    }

    var body: some View {
        #if os(macOS)
        let content = AnyView(
            ViewThatFits(in: .vertical) {
                macRegularLayout
                macCompactLayout
                summaryLayout
            }
        )
        #else
        let content = AnyView(
            ViewThatFits(in: .vertical) {
                regularLayout
                compactLayout
                summaryLayout
            }
        )
        #endif

        return content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()
            .padding(12)
            .background(theme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isToday ? theme.primary.opacity(0.4) : Color.appGray5,
                        lineWidth: isToday ? 1.5 : 0.5
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                onTap?()
            }
    }

    #if os(macOS)
    private var macRegularLayout: some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 12) {
                header(compact: false)

                HStack(alignment: .top, spacing: 12) {
                    macPreviewColumn(title: theme.str.todos, tint: theme.primary, items: todoPreviewItems)

                    Divider()

                    macPreviewColumn(title: theme.str.deadlines, tint: Color.deadlinePrimary, items: deadlinePreviewItems)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var macCompactLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: true)

            HStack(alignment: .top, spacing: 10) {
                macPreviewColumn(title: theme.str.todos, tint: theme.primary, items: todoPreviewItems, compact: true)

                Divider()

                macPreviewColumn(title: theme.str.deadlines, tint: Color.deadlinePrimary, items: deadlinePreviewItems, compact: true)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }
    #endif

    private var regularLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: false)

            if isEmpty {
                emptyState(text: theme.str.noItems, centered: true)
                    .padding(.vertical, 6)
            } else {
                if !todos.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Label(theme.str.todos, systemImage: "checkmark.circle")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(theme.primary)

                        ForEach(todos, id: \.id) { todo in
                            TodoRowView(todo: todo)
                        }
                    }
                }

                if !deadlines.isEmpty {
                    if !todos.isEmpty {
                        Divider()
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Label(theme.str.deadlines, systemImage: "flag")
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
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            header(compact: true)

            if isEmpty {
                emptyState(text: theme.str.noItems, centered: false)
            } else {
                HStack(spacing: 6) {
                    if !todos.isEmpty {
                        countBadge(text: theme.str.todoCount(todos.count), tint: theme.primary, systemImage: "checkmark.circle.fill")
                    }

                    if !deadlines.isEmpty {
                        countBadge(text: theme.str.deadlineCount(deadlines.count), tint: Color.deadlinePrimary, systemImage: "flag.fill")
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(previewItems.prefix(2).enumerated()), id: \.offset) { entry in
                        previewRow(entry.element)
                    }

                    if previewItems.count > 2 {
                        Text(theme.str.moreItems(previewItems.count - 2))
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var summaryLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(compact: true)

            if isEmpty {
                emptyState(text: theme.str.noneShort, centered: false)
            } else {
                HStack(spacing: 6) {
                    if !todos.isEmpty {
                        countBadge(text: "\(todos.count)", tint: theme.primary, systemImage: "checkmark.circle.fill")
                    }

                    if !deadlines.isEmpty {
                        countBadge(text: "\(deadlines.count)", tint: Color.deadlinePrimary, systemImage: "flag.fill")
                    }
                }

                if let firstItem = previewItems.first {
                    previewRow(firstItem)
                }
            }
        }
    }

    private func header(compact: Bool) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: compact ? 4 : 6) {
                Text(dayName)
                    .font(compact ? .caption2 : .caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(isToday ? .white : .secondary)
                    .padding(.horizontal, compact ? 7 : 9)
                    .padding(.vertical, compact ? 3 : 4)
                    .background(isToday ? theme.primary : Color.appGray5)
                    .clipShape(Capsule())

                Text(dateText)
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(isToday ? theme.primary : Color.secondary)
                    .fontWeight(isToday ? .semibold : .regular)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer(minLength: 6)

            Button {
                onAdd?()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: compact ? 13 : 15, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: compact ? 24 : 30, height: compact ? 24 : 30)
            }
            .buttonStyle(.plain)
        }
    }

    private func previewRow(_ item: PreviewItem) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(item.tint)

            Text(item.title)
                .font(.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }

    private func countBadge(text: String, tint: Color, systemImage: String) -> some View {
        Label(text, systemImage: systemImage)
            .font(.caption2)
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private func emptyState(text: String, centered: Bool) -> some View {
        Text(text)
            .font(.caption)
            .foregroundStyle(.quaternary)
            .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
            .lineLimit(1)
    }

    #if os(macOS)
    private func macPreviewColumn(title: String, tint: Color, items: [PreviewItem], compact: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: compact ? 4 : 6) {
            Text(title)
                .font(compact ? .caption2 : .caption)
                .fontWeight(.semibold)
                .foregroundStyle(tint)

            if items.isEmpty {
                Text(theme.str.noneShort)
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                    .lineLimit(1)
            } else {
                ForEach(Array(items.prefix(5).enumerated()), id: \.offset) { entry in
                    previewRow(entry.element, font: compact ? .caption2 : .caption)
                }

                if items.count > 5 {
                    Text(theme.str.moreItems(items.count - 5))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    private func previewRow(_ item: PreviewItem, font: Font) -> some View {
        HStack(spacing: 6) {
            Image(systemName: item.systemImage)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(item.tint)

            Text(item.title)
                .font(font)
                .foregroundStyle(.primary)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)
        }
    }
    #endif
}

private struct PreviewItem {
    let title: String
    let systemImage: String
    let tint: Color
}
