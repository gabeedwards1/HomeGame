import SwiftUI

enum ChipSwatch {
    static func color(for colorName: String) -> Color {
        switch colorName.trimmingCharacters(in: .whitespaces).lowercased() {
        case "white": .white
        case "red": .red
        case "blue": .blue
        case "green": .green
        case "black": .black
        case "yellow": .yellow
        case "purple": .purple
        case "orange": .orange
        case "pink": .pink
        case "gray", "grey": .gray
        default: .gray.opacity(0.3)
        }
    }
}
