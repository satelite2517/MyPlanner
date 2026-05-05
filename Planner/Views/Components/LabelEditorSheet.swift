import SwiftUI
import SwiftData

struct LabelEditorSheet: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PlannerLabel.name) private var existingLabels: [PlannerLabel]

    var onCreate: ((PlannerLabel) -> Void)? = nil

    @State private var name = ""
    @State private var selectedColorHex = PlannerLabel.presetColorHexes.first ?? "2563EB"

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
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
            Form {
                Section {
                    TextField(theme.str.labelNameLabel, text: $name)

                    if hasDuplicateName && !trimmedName.isEmpty {
                        Text(theme.str.labelExists)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(theme.str.labelColorLabel) {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(PlannerLabel.presetColorHexes, id: \.self) { colorHex in
                            Button {
                                selectedColorHex = colorHex
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: colorHex))
                                        .frame(width: 30, height: 30)

                                    if selectedColorHex == colorHex {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
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

    private func saveLabel() {
        let label = PlannerLabel(name: trimmedName, colorHex: selectedColorHex)
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
