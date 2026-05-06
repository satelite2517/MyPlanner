import SwiftUI
import SwiftData

struct LabelEditorSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PlannerLabel.name) private var existingLabels: [PlannerLabel]

    var onCreate: ((PlannerLabel) -> Void)? = nil

    @State private var name = ""
    @State private var emoji = ""
    @State private var selectedColorHex = PlannerLabel.presetColorHexes.first ?? "2563EB"

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmoji: String {
        emoji.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasDuplicateName: Bool {
        existingLabels.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
    }

    private var saveDisabled: Bool {
        trimmedName.isEmpty || hasDuplicateName
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    editorCard(title: theme.str.labelNameLabel) {
                        VStack(alignment: .leading, spacing: 8) {
                            TextField(theme.str.labelNameLabel, text: $name)
                                .textFieldStyle(.roundedBorder)

                            if hasDuplicateName && !trimmedName.isEmpty {
                                Text(theme.str.labelExists)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    editorCard(title: theme.str.labelEmojiLabel) {
                        HStack(spacing: 14) {
                            TextField("😀", text: $emoji)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 120)

                            if !trimmedEmoji.isEmpty {
                                Text(trimmedEmoji)
                                    .font(.system(size: 28))
                                    .frame(width: 44, height: 44)
                                    .background(theme.groupedBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Spacer()
                        }
                    }

                    editorCard(title: theme.str.labelColorLabel) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(PlannerLabel.presetColorHexes, id: \.self) { colorHex in
                                Button {
                                    selectedColorHex = colorHex
                                } label: {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: colorHex))
                                            .frame(width: 34, height: 34)

                                        if selectedColorHex == colorHex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 28)
            .background(theme.groupedBackground)
            .navigationTitle(theme.str.addLabel)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .leadingBar) {
                    Button(theme.str.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .trailingBar) {
                    Button(theme.str.confirm) {
                        saveLabel()
                    }
                    .disabled(saveDisabled)
                }
            }
        }
    }

    @ViewBuilder
    private func editorCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func saveLabel() {
        let label = PlannerLabel(
            name: trimmedName,
            emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
            colorHex: selectedColorHex
        )
        modelContext.insert(label)
        try? modelContext.save()
        onCreate?(label)
        dismiss()
    }
}

struct SelectableLabelChip: View {
    let label: PlannerLabel
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: label.colorHex))
                    .frame(width: 8, height: 8)

                if let emoji = label.emoji, !emoji.isEmpty {
                    Text(emoji)
                        .font(.caption)
                }

                Text(label.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(hex: label.colorHex).opacity(isSelected ? 0.2 : 0.12))
            .foregroundStyle(Color(hex: label.colorHex))
            .overlay(
                Capsule()
                    .stroke(Color(hex: label.colorHex).opacity(isSelected ? 0.45 : 0), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
