import Foundation
import SwiftData

@Model
final class ChipDenomination {
    var id: UUID
    var colorName: String
    var value: Decimal

    init(colorName: String, value: Decimal) {
        self.id = UUID()
        self.colorName = colorName
        self.value = value
    }
}

extension ChipDenomination {
    var displayName: String {
        colorName.isEmpty ? value.formatted(.currency(code: "USD")) : colorName
    }
}
