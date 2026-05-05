import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// 앱 전체 색상 팔레트
extension Color {
    static let todoPrimary    = Color(hex: "2563EB")
    static let todoBackground = Color(hex: "DBEAFE")
    static let deadlinePrimary    = Color(hex: "16A34A")
    static let deadlineBackground = Color(hex: "E7F2EA")
}

// 플랫폼별 시스템 색상 (UIKit/AppKit 직접 참조 대신 사용)
extension Color {
    static var appGroupedBackground: Color {
        #if os(iOS)
        Color(UIColor.systemGroupedBackground)
        #else
        Color(NSColor.windowBackgroundColor)
        #endif
    }

    static var appBackground: Color {
        #if os(iOS)
        Color(UIColor.systemBackground)
        #else
        Color(NSColor.controlBackgroundColor)
        #endif
    }

    static var appGray3: Color {
        #if os(iOS)
        Color(UIColor.systemGray3)
        #else
        Color(NSColor.systemGray).opacity(0.5)
        #endif
    }

    static var appGray5: Color {
        #if os(iOS)
        Color(UIColor.systemGray5)
        #else
        Color(NSColor.systemGray).opacity(0.2)
        #endif
    }

    static var appGray6: Color {
        #if os(iOS)
        Color(UIColor.systemGray6)
        #else
        Color(NSColor.systemGray).opacity(0.1)
        #endif
    }
}
