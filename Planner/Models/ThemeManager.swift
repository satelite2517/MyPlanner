import SwiftUI

// MARK: - Theme

struct AccentTheme: Identifiable {
    let id: String
    let name: String
    let primaryHex: String
    let accentBackgroundHex: String

    var primary: Color { Color(hex: primaryHex) }
    var accentBackground: Color { Color(hex: accentBackgroundHex) }
}

struct BackgroundTheme: Identifiable {
    let id: String
    let name: String
    let groupedBackgroundHex: String
    let surfaceBackgroundHex: String
    let borderHex: String

    var groupedBackground: Color { Color(hex: groupedBackgroundHex) }
    var surfaceBackground: Color { Color(hex: surfaceBackgroundHex) }
    var border: Color { Color(hex: borderHex) }
}

// MARK: - Language

enum AppLanguage: String, CaseIterable {
    case korean  = "ko"
    case english = "en"

    var displayName: String { self == .korean ? "한국어" : "English" }
    var locale: Locale      { Locale(identifier: rawValue) }
    var isKo: Bool          { self == .korean }
}

// MARK: - Strings

struct AppStrings {
    let lang: AppLanguage
    private var ko: Bool { lang.isKo }

    // General
    var today:     String { ko ? "오늘"   : "Today" }
    var tomorrow:  String { ko ? "내일"   : "Tomorrow" }
    var yesterday: String { ko ? "어제"   : "Yesterday" }
    var close:     String { ko ? "닫기"   : "Close" }
    var confirm:   String { ko ? "확인"   : "Confirm" }
    var cancel:    String { ko ? "취소"   : "Cancel" }
    var comingSoon: String { ko ? "곧 출시" : "Coming Soon" }
    var allDay:    String { ko ? "종일"   : "All day" }
    var noneShort: String { ko ? "없음" : "None" }
    func moreItems(_ count: Int) -> String { ko ? "+\(count)개 더" : "+\(count) more" }

    // Items
    var all:       String { ko ? "전체"   : "All" }
    var todos:     String { ko ? "할 일"  : "Todos" }
    var deadlines: String { ko ? "마감일" : "Deadlines" }
    var timeline:  String { ko ? "타임라인" : "Timeline" }
    var noItems:   String { ko ? "항목 없음" : "Nothing here" }
    var noItemsLong: String { ko ? "항목이 없습니다" : "No items" }
    var selectDatePrompt: String { ko ? "날짜를 선택하세요" : "Select a date" }
    func todoCount(_ count: Int) -> String { ko ? "할 일 \(count)" : "Todo \(count)" }
    func deadlineCount(_ count: Int) -> String { ko ? "마감 \(count)" : "Due \(count)" }
    func linkedTodoCount(_ count: Int) -> String { ko ? "연결된 할 일 (\(count))" : "Linked Todos (\(count))" }
    func deadlineLinkedCount(_ count: Int) -> String { ko ? "할일 \(count)개 연결됨" : "\(count) linked todos" }

    // Stats
    var completed:  String { ko ? "완료"   : "Done" }
    var incomplete: String { ko ? "미완료" : "Pending" }
    var important:  String { ko ? "중요"   : "Important" }
    var inProgress: String { ko ? "진행중" : "In Progress" }
    var linkedTodos: String { ko ? "연결된 할 일" : "Linked Todos" }

    // Me
    var account:      String { ko ? "계정"    : "Account" }
    var themeLabel:   String { ko ? "테마"    : "Theme" }
    var preferences:  String { ko ? "환경설정" : "Preferences" }
    var integration:  String { ko ? "연동"    : "Integration" }
    var aboutLabel:   String { ko ? "정보"    : "About" }
    var languageLabel: String { ko ? "언어"   : "Language" }
    var accentColorLabel: String { ko ? "메인색" : "Accent" }
    var backgroundColorLabel: String { ko ? "배경색" : "Background" }
    var notifications: String { ko ? "알림"   : "Notifications" }
    var systemNotifications: String { ko ? "시스템 알림 설정" : "System Notification Settings" }
    var appVersion:   String { ko ? "앱 버전" : "App Version" }
    var sendFeedback: String { ko ? "피드백 보내기" : "Send Feedback" }
    var plannerUser:  String { ko ? "플래너 사용자" : "Planner User" }
    var setNameHint:  String { ko ? "이름을 설정하세요" : "Set your name" }
    var setNameTitle: String { ko ? "이름 설정" : "Set Name" }
    var nameFieldLabel: String { ko ? "이름" : "Name" }
    var titleLabel: String { ko ? "제목" : "Title" }
    var notesLabel: String { ko ? "메모" : "Notes" }
    var dateLabel: String { ko ? "날짜" : "Date" }
    var timeLabel: String { ko ? "시간 포함" : "Include time" }
    var startDateLabel: String { ko ? "시작일 사용" : "Use start date" }
    var autoCarryOverLabel: String { ko ? "미완료 시 다음날로 이동" : "Carry over if incomplete" }
    var remindersApp: String { ko ? "미리 알림 앱" : "Reminders" }
    var calendarApp:  String { ko ? "캘린더 앱" : "Calendar" }
    var syncNow: String { ko ? "가져오기" : "Import" }
    var syncing: String { ko ? "동기화 중..." : "Syncing..." }
    var remindersImported: String { ko ? "미리알림 가져오기 완료" : "Reminders imported" }
    var remindersPermissionDenied: String { ko ? "미리알림 접근 권한이 필요합니다" : "Reminders access is required" }
    func remindersImportedCount(_ count: Int) -> String { ko ? "\(count)개 동기화" : "Synced \(count)" }
    func remindersRemovedCount(_ count: Int) -> String { ko ? "\(count)개 제거됨" : "Removed \(count)" }

    // Navigation
    var weeklyTitle: String { ko ? "주간" : "Weekly" }
    var monthlyTitle: String { ko ? "월간" : "Monthly" }
    var listTitle: String { ko ? "목록" : "List" }
    var meTitle: String { ko ? "내 정보" : "Me" }

    // Actions
    var addTodo: String { ko ? "할 일 추가" : "Add Todo" }
    var addDeadline: String { ko ? "마감일 추가" : "Add Deadline" }
    var createItem: String { ko ? "새 항목" : "New Item" }
}

// MARK: - ThemeManager

@Observable
final class ThemeManager {
    static let accentThemes: [AccentTheme] = [
        AccentTheme(id: "blue", name: "Blue", primaryHex: "2563EB", accentBackgroundHex: "DBEAFE"),
        AccentTheme(id: "green", name: "Green", primaryHex: "16A34A", accentBackgroundHex: "DCFCE7"),
        AccentTheme(id: "purple", name: "Purple", primaryHex: "7C3AED", accentBackgroundHex: "EDE9FE"),
        AccentTheme(id: "orange", name: "Orange", primaryHex: "EA580C", accentBackgroundHex: "FFEDD5"),
        AccentTheme(id: "rose", name: "Rose", primaryHex: "E11D48", accentBackgroundHex: "FFE4E6"),
        AccentTheme(id: "teal", name: "Teal", primaryHex: "0D9488", accentBackgroundHex: "CCFBF1"),
    ]

    static let backgroundThemes: [BackgroundTheme] = [
        BackgroundTheme(id: "white", name: "White", groupedBackgroundHex: "FFFFFF", surfaceBackgroundHex: "FFFFFF", borderHex: "E5E7EB"),
        BackgroundTheme(id: "slate", name: "Slate", groupedBackgroundHex: "F3F4F6", surfaceBackgroundHex: "FFFFFF", borderHex: "D1D5DB"),
        BackgroundTheme(id: "cream", name: "Cream", groupedBackgroundHex: "FFF8EE", surfaceBackgroundHex: "FFFCF6", borderHex: "F1D9B5"),
        BackgroundTheme(id: "sky", name: "Sky", groupedBackgroundHex: "F3F8FF", surfaceBackgroundHex: "FBFDFF", borderHex: "C7DBF7"),
        BackgroundTheme(id: "mint", name: "Mint", groupedBackgroundHex: "F1FBF7", surfaceBackgroundHex: "FCFFFD", borderHex: "BFE7D8"),
        BackgroundTheme(id: "rose", name: "Rose", groupedBackgroundHex: "FFF5F7", surfaceBackgroundHex: "FFFCFD", borderHex: "F3CDD8"),
    ]

    var selectedAccentID: String {
        didSet { UserDefaults.standard.set(selectedAccentID, forKey: "appAccentThemeID") }
    }

    var selectedBackgroundID: String {
        didSet { UserDefaults.standard.set(selectedBackgroundID, forKey: "appBackgroundThemeID") }
    }

    var languageRaw: String {
        didSet { UserDefaults.standard.set(languageRaw, forKey: "appLanguage") }
    }

    init() {
        let legacyThemeID = UserDefaults.standard.string(forKey: "appThemeID")
        selectedAccentID = UserDefaults.standard.string(forKey: "appAccentThemeID")
            ?? legacyThemeID
            ?? "blue"
        selectedBackgroundID = UserDefaults.standard.string(forKey: "appBackgroundThemeID") ?? "white"
        languageRaw = UserDefaults.standard.string(forKey: "appLanguage") ?? "ko"
    }

    var currentAccent: AccentTheme {
        ThemeManager.accentThemes.first { $0.id == selectedAccentID } ?? ThemeManager.accentThemes[0]
    }

    var currentBackground: BackgroundTheme {
        ThemeManager.backgroundThemes.first { $0.id == selectedBackgroundID } ?? ThemeManager.backgroundThemes[0]
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .korean }
        set { languageRaw = newValue.rawValue }
    }

    var locale: Locale { language.locale }
    var str: AppStrings { AppStrings(lang: language) }
    var primary: Color { currentAccent.primary }
    var accentBackground: Color { currentAccent.accentBackground }
    var groupedBackground: Color { currentBackground.groupedBackground }
    var surfaceBackground: Color { currentBackground.surfaceBackground }
    var backgroundBorder: Color { currentBackground.border }
}
