import SwiftUI

enum TrellisTheme {
    static let ink = Color(red: 18.0 / 255.0, green: 16.0 / 255.0, blue: 14.0 / 255.0)
    static let plate = Color(red: 27.0 / 255.0, green: 24.0 / 255.0, blue: 21.0 / 255.0)
    static let brass = Color(red: 194.0 / 255.0, green: 149.0 / 255.0, blue: 79.0 / 255.0)
    static let bone = Color(red: 232.0 / 255.0, green: 223.0 / 255.0, blue: 208.0 / 255.0)
    static let ash = Color(red: 170.0 / 255.0, green: 158.0 / 255.0, blue: 143.0 / 255.0)
    static let jade = Color(red: 111.0 / 255.0, green: 143.0 / 255.0, blue: 123.0 / 255.0)
    static let danger = Color(red: 210.0 / 255.0, green: 119.0 / 255.0, blue: 98.0 / 255.0)
}

extension Color {
    static let trellisInk = TrellisTheme.ink
    static let trellisPlate = TrellisTheme.plate
    static let trellisBrass = TrellisTheme.brass
    static let trellisBone = TrellisTheme.bone
    static let trellisAsh = TrellisTheme.ash
    static let trellisJade = TrellisTheme.jade
    static let trellisDanger = TrellisTheme.danger
}

extension View {
    func trellisCard() -> some View {
        self
            .padding(18)
            .background(Color.trellisPlate)
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            }
    }
}

