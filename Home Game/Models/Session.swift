import Foundation
import SwiftData

@Model
final class Session {
    var id: UUID
    var date: Date
    var location: String?
    var stakes: String?
    var isActive: Bool
    var notes: String?
    var defaultBuyInAmount: Decimal?
    var smallBlind: Decimal
    var bigBlind: Decimal

    @Relationship(deleteRule: .cascade, inverse: \SessionPlayer.session)
    var sessionPlayers: [SessionPlayer] = []

    init(date: Date = .now, location: String? = nil, stakes: String? = nil, isActive: Bool = true, notes: String? = nil, defaultBuyInAmount: Decimal? = nil, smallBlind: Decimal = 0, bigBlind: Decimal = 0) {
        self.id = UUID()
        self.date = date
        self.location = location
        self.stakes = stakes
        self.isActive = isActive
        self.notes = notes
        self.defaultBuyInAmount = defaultBuyInAmount
        self.smallBlind = smallBlind
        self.bigBlind = bigBlind
    }
}

extension Session {
    var totalBuyIns: Decimal {
        sessionPlayers.reduce(Decimal.zero) { $0 + $1.totalBuyIn }
    }

    var totalCashOuts: Decimal {
        sessionPlayers.reduce(Decimal.zero) { $0 + $1.cashOutAmount }
    }

    var totalNetProfit: Decimal {
        totalCashOuts - totalBuyIns
    }
}
