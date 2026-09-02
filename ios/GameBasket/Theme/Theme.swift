import SwiftUI

// Design tokens pulled directly from design/gamebasket_ui.html so the app
// and the mockup stay in sync. "gb" prefix avoids colliding with system
// Color/Font names.
extension Color {
    static let gbRed = Color(hex: 0xE8564A)
    static let gbRedDim = Color(hex: 0xC4483E)
    static let gbBlue = Color(hex: 0x2E56A6)
    static let gbGreen = Color(hex: 0x47AD6C)
    static let gbGold = Color(hex: 0xF1BC33)
    static let gbGoldDim = Color(hex: 0xB8891F)

    // Hearts use their own dedicated color in the mockup (--heart), a
    // shade off from the brand red (--red) — not the same value.
    static let gbHeart = Color(hex: 0xEB5757)
    static let gbHeartDim = Color(hex: 0xA83A3A)

    static let gbBackground = Color(hex: 0x12141C)
    static let gbSurface = Color(hex: 0x1A1D29)
    static let gbSurface2 = Color(hex: 0x222639)
    static let gbLine = Color(hex: 0x2C3040)
    static let gbText = Color(hex: 0xF4F5F9)
    static let gbTextDim = Color(hex: 0x9AA1B4)
    static let gbTextFaint = Color(hex: 0x616880)

    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// Baloo 2 and Nunito are variable fonts, but both bake in named instances
// with their own PostScript names per weight (confirmed at runtime via
// UIFont.fontNames(forFamilyName:) — CoreText exposes them directly, no
// manual variation-axis code needed).
extension Font {
    static func balooMedium(_ size: CGFloat) -> Font { .custom("Baloo2-Medium", size: size) }
    static func balooSemiBold(_ size: CGFloat) -> Font { .custom("Baloo2-SemiBold", size: size) }
    static func balooBold(_ size: CGFloat) -> Font { .custom("Baloo2-Bold", size: size) }
    static func balooExtraBold(_ size: CGFloat) -> Font { .custom("Baloo2-ExtraBold", size: size) }

    static func nunito(_ size: CGFloat) -> Font { .custom("Nunito-Regular", size: size) }
    static func nunitoSemiBold(_ size: CGFloat) -> Font { .custom("Nunito-SemiBold", size: size) }
    static func nunitoBold(_ size: CGFloat) -> Font { .custom("Nunito-Bold", size: size) }
    static func nunitoExtraBold(_ size: CGFloat) -> Font { .custom("Nunito-ExtraBold", size: size) }
}
