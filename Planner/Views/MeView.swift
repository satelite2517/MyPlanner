import SwiftUI
import SwiftData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

struct MeView: View {
    @Environment(ThemeManager.self) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \PlannerLabel.name) private var allLabels: [PlannerLabel]
    @AppStorage("displayName") private var displayName = ""
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @State private var isEditingName = false
    @State private var isSyncingReminders = false
    @State private var reminderStatusText: String? = nil
    @State private var reminderAlertMessage = ""
    @State private var isShowingReminderAlert = false
    @State private var isShowingLabelCreator = false
    @State private var isImportingSyncFile = false
    @State private var syncFileStatusText: String? = nil
    @State private var syncAlertMessage = ""
    @State private var isShowingSyncAlert = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private var str: AppStrings { theme.str }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // MARK: - 계정
                    menuSection(header: str.account) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(theme.primary.gradient)
                                    .frame(width: 52, height: 52)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                if displayName.isEmpty {
                                    Text(str.setNameHint)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text(displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                Text(str.plannerUser)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .contentShape(Rectangle())
                        .onTapGesture { isEditingName = true }
                    }

                    // MARK: - 테마
                    menuSection(header: str.themeLabel) {
                        VStack(alignment: .leading, spacing: 14) {
                            themePaletteRow(title: str.accentColorLabel) {
                                HStack(spacing: 14) {
                                    ForEach(ThemeManager.accentThemes) { accent in
                                        let isSelected = theme.selectedAccentID == accent.id
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                theme.selectedAccentID = accent.id
                                            }
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(accent.primary)
                                                    .frame(width: 28, height: 28)

                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(.white)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Spacer()
                                }
                            }

                            Divider()

                            themePaletteRow(title: str.backgroundColorLabel) {
                                HStack(spacing: 14) {
                                    ForEach(ThemeManager.backgroundThemes) { background in
                                        let isSelected = theme.selectedBackgroundID == background.id
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                theme.selectedBackgroundID = background.id
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(background.groupedBackground)
                                                    .frame(width: 42, height: 42)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(isSelected ? theme.primary : background.border, lineWidth: isSelected ? 2 : 1)
                                                    )

                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(background.surfaceBackground)
                                                    .frame(width: 28, height: 16)
                                                    .offset(y: 8)

                                                Circle()
                                                    .fill(theme.primary)
                                                    .frame(width: 16, height: 16)
                                                    .offset(x: -8, y: -7)

                                                if isSelected {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 12, weight: .bold))
                                                        .foregroundStyle(theme.primary)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    Spacer()
                                }
                            }

                            Divider()

                            themeColorPickerRow(
                                title: str.todoColorLabel,
                                color: theme.todoColor
                            ) { color in
                                theme.updateTodoColor(color)
                            }

                            Divider()

                            themeColorPickerRow(
                                title: str.deadlineColorLabel,
                                color: theme.deadlineColor
                            ) { color in
                                theme.updateDeadlineColor(color)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    // MARK: - 환경설정
                    menuSection(header: str.preferences) {
                        HStack {
                            Label(str.languageLabel, systemImage: "globe")
                                .font(.subheadline)
                            Spacer()
                            languagePicker
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        HStack {
                            Label(str.notifications, systemImage: "bell.fill")
                                .font(.subheadline)
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                                .tint(theme.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        Button { openNotificationSettings() } label: {
                            HStack {
                                Label(str.systemNotifications, systemImage: "gear")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }

                    menuSection(header: str.labelsLabel) {
                        VStack(alignment: .leading, spacing: 14) {
                            if allLabels.isEmpty {
                                Text(str.noLabels)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), alignment: .leading)], alignment: .leading, spacing: 10) {
                                    ForEach(allLabels, id: \.id) { label in
                                        SelectableLabelChip(label: label, isSelected: false) {}
                                            .allowsHitTesting(false)
                                    }
                                }
                            }

                            Button {
                                isShowingLabelCreator = true
                            } label: {
                                Label(str.addLabel, systemImage: "plus")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(theme.accentBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    // MARK: - 연동
                    menuSection(header: str.integration) {
                        Button {
                            syncReminders()
                        } label: {
                            integrationSyncRow(
                                icon: "checklist",
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                title: str.remindersApp,
                                status: reminderStatusText ?? (isSyncingReminders ? str.syncing : str.syncNow),
                                isLoading: isSyncingReminders
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)

                        Button {
                            prepareSyncFileExport()
                        } label: {
                            integrationSyncRow(
                                icon: "square.and.arrow.up",
                                colors: [Color(hex: "5B8DEF"), Color(hex: "3A6BD9")],
                                title: str.createSyncFile,
                                status: syncFileStatusText ?? str.syncFileNotConnected,
                                isLoading: false
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)

                        Button {
                            isImportingSyncFile = true
                        } label: {
                            integrationSyncRow(
                                icon: "folder",
                                colors: [Color(hex: "6D8BFF"), Color(hex: "4F6AE6")],
                                title: str.connectSyncFile,
                                status: syncFileStatusText ?? str.syncFileNotConnected,
                                isLoading: false
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)

                        Button {
                            pullFromSyncFile()
                        } label: {
                            integrationSyncRow(
                                icon: "arrow.down.doc",
                                colors: [Color(hex: "2CB67D"), Color(hex: "1F9D68")],
                                title: str.importSyncFile,
                                status: syncFileStatusText ?? str.syncFileNotConnected,
                                isLoading: false
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)

                        Button {
                            pushToSyncFile()
                        } label: {
                            integrationSyncRow(
                                icon: "arrow.up.doc",
                                colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
                                title: str.exportSyncFile,
                                status: syncFileStatusText ?? str.syncFileNotConnected,
                                isLoading: false
                            )
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 16)

                        integrationRow(
                            icon: "calendar",
                            colors: [Color(hex: "4A90D9"), Color(hex: "357ABD")],
                            title: str.calendarApp
                        )
                    }

                    // MARK: - 정보
                    menuSection(header: str.aboutLabel) {
                        HStack {
                            Label(str.appVersion, systemImage: "info.circle")
                                .font(.subheadline)
                            Spacer()
                            Text(appVersion)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                        Divider().padding(.leading, 16)

                        Button {
                            sendFeedbackEmail()
                        } label: {
                            HStack {
                                Label(str.sendFeedback, systemImage: "envelope")
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(theme.groupedBackground)
        }
        .task {
            refreshSyncFileStatus()
        }
        .alert(str.setNameTitle, isPresented: $isEditingName) {
            TextField(str.nameFieldLabel, text: $displayName)
            Button(str.confirm) {}
            Button(str.cancel, role: .cancel) {}
        }
        .alert(str.remindersApp, isPresented: $isShowingReminderAlert) {
            Button(str.confirm) {}
        } message: {
            Text(reminderAlertMessage)
        }
        .alert(str.iCloudDriveSync, isPresented: $isShowingSyncAlert) {
            Button(str.confirm) {}
        } message: {
            Text(syncAlertMessage)
        }
        .sheet(isPresented: $isShowingLabelCreator) {
            LabelEditorSheet()
        }
        .fileImporter(
            isPresented: $isImportingSyncFile,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleSyncFileImport(result)
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func menuSection<Content: View>(header: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(header)
                .font(.footnote)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(theme.surfaceBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func themePaletteRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            content()
        }
    }

    private func themeColorPickerRow(title: String, color: Color, onChange: @escaping (Color) -> Void) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let hex = color.hexString {
                    Text("#\(hex)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 10) {
                Circle()
                    .fill(color)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Circle()
                            .stroke(theme.backgroundBorder, lineWidth: 1)
                    )

                ColorPicker(
                    title,
                    selection: Binding(
                        get: { color },
                        set: { onChange($0) }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
            }
        }
    }

    private var languagePicker: some View {
        HStack(spacing: 8) {
            ForEach(AppLanguage.allCases, id: \.self) { language in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        theme.language = language
                    }
                } label: {
                    Text(language.displayName)
                        .font(.caption)
                        .fontWeight(theme.language == language ? .semibold : .regular)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(theme.language == language ? theme.primary : Color.appGray6)
                        .foregroundStyle(theme.language == language ? Color.white : Color.primary)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func integrationRow(icon: String, colors: [Color], title: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(str.comingSoon)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private func integrationSyncRow(icon: String, colors: [Color], title: String, status: String, isLoading: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func openNotificationSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
        #endif
    }

    private func syncReminders() {
        guard !isSyncingReminders else { return }

        isSyncingReminders = true

        Task {
            do {
                let result = try await ReminderSyncService().syncDeadlines(from: modelContext)
                let parts = [
                    str.remindersImportedCount(result.importedCount),
                    result.removedCount > 0 ? str.remindersRemovedCount(result.removedCount) : nil,
                    result.skippedCount > 0 ? str.remindersSkippedCount(result.skippedCount) : nil,
                ].compactMap { $0 }
                let message = parts.joined(separator: ", ")

                await MainActor.run {
                    reminderStatusText = message.isEmpty ? str.remindersImported : message
                    reminderAlertMessage = message.isEmpty ? str.remindersImported : message
                    isShowingReminderAlert = true
                    isSyncingReminders = false
                }
            } catch {
                await MainActor.run {
                    reminderStatusText = str.remindersPermissionDenied
                    reminderAlertMessage = error.localizedDescription.isEmpty ? str.remindersPermissionDenied : error.localizedDescription
                    isShowingReminderAlert = true
                    isSyncingReminders = false
                }
            }
        }
    }

    private func refreshSyncFileStatus() {
        syncFileStatusText = PlannerSyncFileService.connectedFileName() ?? str.syncFileNotConnected
    }

    private func prepareSyncFileExport() {
        do {
            #if os(macOS)
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.json]
            panel.nameFieldStringValue = "PlannerSync.json"
            panel.canCreateDirectories = true

            if panel.runModal() == .OK, let url = panel.url {
                try PlannerSyncFileService.export(modelContext: modelContext, theme: theme, to: url)
                try PlannerSyncBookmarkStore.save(url: url)
                refreshSyncFileStatus()
                syncAlertMessage = "\(str.syncCompleted)\n\(url.lastPathComponent)"
                isShowingSyncAlert = true
            }
            #else
            syncAlertMessage = str.connectSyncFile
            isShowingSyncAlert = true
            #endif
        } catch {
            syncAlertMessage = error.localizedDescription
            isShowingSyncAlert = true
        }
    }

    private func handleSyncFileImport(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            try PlannerSyncBookmarkStore.save(url: url)
            try PlannerSyncFileService.import(from: url, modelContext: modelContext, theme: theme)
            refreshSyncFileStatus()
            syncAlertMessage = "\(str.syncCompleted)\n\(url.lastPathComponent)"
            isShowingSyncAlert = true
        } catch {
            syncAlertMessage = error.localizedDescription
            isShowingSyncAlert = true
        }
    }

    private func pullFromSyncFile() {
        do {
            let fileName = try PlannerSyncFileService.importFromConnectedFile(
                modelContext: modelContext,
                theme: theme
            )
            refreshSyncFileStatus()
            syncAlertMessage = "\(str.syncCompleted)\n\(fileName)"
            isShowingSyncAlert = true
        } catch {
            syncAlertMessage = error.localizedDescription
            isShowingSyncAlert = true
        }
    }

    private func pushToSyncFile() {
        do {
            let fileName = try PlannerSyncFileService.exportToConnectedFile(
                modelContext: modelContext,
                theme: theme
            )
            refreshSyncFileStatus()
            syncAlertMessage = "\(str.syncCompleted)\n\(fileName)"
            isShowingSyncAlert = true
        } catch {
            syncAlertMessage = error.localizedDescription
            isShowingSyncAlert = true
        }
    }

    private func sendFeedbackEmail() {
        if let url = URL(string: "mailto:satelite251@gmail.com") {
            openURL(url)
        }
    }
}

#Preview {
    MeView()
        .environment(ThemeManager())
        .modelContainer(for: [TodoItem.self, Deadline.self, PlannerLabel.self, TodoHistory.self])
}
