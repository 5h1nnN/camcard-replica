import SwiftUI

enum AppColors {
    static let primary = Color(red: 0.08, green: 0.64, blue: 0.94)
    static let primaryStrong = Color(red: 0.11, green: 0.45, blue: 0.96)
    static let primaryDark = Color(red: 0.05, green: 0.18, blue: 0.39)
    static let pageBackground = Color(red: 0.95, green: 0.95, blue: 0.96)
    static let cardBackground = Color.white
    static let textPrimary = Color(red: 0.10, green: 0.12, blue: 0.16)
    static let textSecondary = Color(red: 0.42, green: 0.45, blue: 0.50)
    static let success = Color(red: 0.16, green: 0.68, blue: 0.45)
    static let promotion = Color(red: 0.95, green: 0.47, blue: 0.16)
}

enum AppSpacing {
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 16
    static let large: CGFloat = 24
    static let xLarge: CGFloat = 32
}

enum AppRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 14
    static let large: CGFloat = 22
}

enum AppSize {
    static let pageInset: CGFloat = 16
    static let tabBarHeight: CGFloat = 72
    static let scanButton: CGFloat = 52
    static let controlHeight: CGFloat = 48
}

enum AppShadow {
    static let cardColor = Color.black.opacity(0.08)
    static let cardRadius: CGFloat = 12
    static let cardY: CGFloat = 4
}
