import Foundation
import SwiftData

enum BuyInType: String, Codable, CaseIterable {
    case initial
    case rebuy
    case addOn
}

@Model
final class BuyInEvent {
    var id: UUID
    var sessionPlayer: SessionPlayer?
    var amount: Decimal
    var timestamp: Date
    var type: BuyInType

    init(sessionPlayer: SessionPlayer? = nil, amount: Decimal, type: BuyInType = .initial, timestamp: Date = .now) {
        self.id = UUID()
        self.sessionPlayer = sessionPlayer
        self.amount = amount
        self.type = type
        self.timestamp = timestamp
    }
}
