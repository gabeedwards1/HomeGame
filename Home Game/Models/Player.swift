import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var colorTag: String?

    @Relationship(deleteRule: .cascade, inverse: \SessionPlayer.player)
    var sessionPlayers: [SessionPlayer] = []

    init(name: String, colorTag: String? = nil) {
        self.id = UUID()
        self.name = name
        self.colorTag = colorTag
    }
}

extension Player {
    var lifetimeNetProfit: Decimal {
        sessionPlayers.reduce(Decimal.zero) { $0 + $1.netProfit }
    }

    var sessionsPlayed: Int {
        sessionPlayers.count
    }
}
