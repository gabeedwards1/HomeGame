import Foundation
import SwiftData

@Model
final class SessionPlayer {
    var id: UUID
    var session: Session?
    var player: Player?
    var isCashedOut: Bool
    var joinedAt: Date
    var seatPosition: Int

    @Relationship(deleteRule: .cascade, inverse: \BuyInEvent.sessionPlayer)
    var buyIns: [BuyInEvent] = []

    @Relationship(deleteRule: .cascade, inverse: \CashOutCount.sessionPlayer)
    var cashOutCounts: [CashOutCount] = []

    init(session: Session? = nil, player: Player? = nil, joinedAt: Date = .now, seatPosition: Int = 0) {
        self.id = UUID()
        self.session = session
        self.player = player
        self.isCashedOut = false
        self.joinedAt = joinedAt
        self.seatPosition = seatPosition
    }
}

extension SessionPlayer {
    var totalBuyIn: Decimal {
        buyIns.reduce(Decimal.zero) { $0 + $1.amount }
    }

    var cashOutAmount: Decimal {
        cashOutCounts.reduce(Decimal.zero) { $0 + ($1.denomination?.value ?? .zero) * Decimal($1.count) }
    }

    var netProfit: Decimal {
        cashOutAmount - totalBuyIn
    }
}
