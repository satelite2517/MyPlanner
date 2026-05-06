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
                tint: $0.isCompleted ? Color.secondary : theme.todoColor
            )
        }
        return todoItems
    }

    private var deadlinePreviewItems: [PreviewItem] {
        deadlines.map {
            PreviewItem(
                title: $0.title,
                systemImage: "flag.fill",
                tint: theme.deadlineColor
            )
        }
    }

    var body: some View {
        let content = AnyView(
            ViewThatFits(in: .vertical) {
                splitRegularLayout
                splitCompactLayout
                summaryLayout
            }
        )

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

    private var splitRegularLayout: some View {
        ViewThatFits(in: .vertical) {
            VStack(alignment: .leading, spacing: 12) {
                header(compact: false)

                HStack(alignment: .top, spacing: 12) {
                    splitPreviewColumn(title: theme.str.todos, tint: theme.todoColor, items: todoPreviewItems)

                    Divider()

                    splitPreviewColumn(title: theme.str.deadlines, tint: theme.deadlineColor, items: deadlinePreviewItems)
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var splitCompactLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            header(compact: true)

            HStack(alignment: .top, spacing: 10) {
                splitPreviewColumn(title: theme.str.todos, tint: theme.todoColor, items: todoPreviewItems, compact: true)

                Divider()

                splitPreviewColumn(title: theme.str.deadlines, tint: theme.deadlineColor, items: deadlinePreviewItems, compact: true)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private var summaryLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            header(compact: true)

            if isEmpty {
                emptyState(text: theme.str.noneShort, centered: false)
            } else {
                HStack(alignment: .top, spacing: 8) {
                    splitPreviewColumn(
                        title: theme.str.todos,
                        tint: theme.todoColor,
                        items: Array(todoPreviewItems.prefix(1)),
                        compact: true
                    )

                    Divider()

                    splitPreviewColumn(
                        title: theme.str.deadlines,
                        tint: theme.deadlineColor,
                        items: Array(deadlinePreviewItems.prefix(1)),
                        compact: true
                    )
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

                if !todos.isEmpty {
                    inlineCountBadge(
                        text: compact ? "\(todos.count)" : theme.str.todoCount(todos.count),
                        tint: theme.todoColor,
                        systemImage: "checkmark.circle.fill",
                        compact: compact
                    )
                }

                if !deadlines.isEmpty {
                    inlineCountBadge(
                        text: compact ? "\(deadlines.count)" : theme.str.deadlineCount(deadlines.count),
                        tint: theme.deadlineColor,
                        systemImage: "flag.fill",
                        compact: compact
                    )
                }
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

    private func inlineCountBadge(text: String, tint: Color, systemImage: String, compact: Bool) -> some View {
        Label(text, systemImage: systemImage)
            .font(compact ? .caption2 : .caption2)
            .foregroundStyle(tint)
            .padding(.horizontal, compact ? 6 : 7)
            .padding(.vertical, compact ? 3 : 4)
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

    private func splitPreviewColumn(title: String, tint: Color, items: [PreviewItem], compact: Bool = false) -> some View {
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
}

private struct PreviewItem {
    let title: String
    let systemImage: String
    let tint: Color
}
