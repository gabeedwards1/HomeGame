import Foundation
import SwiftData

@Model
final class CashOutCount {
    var id: UUID
    var sessionPlayer: SessionPlayer?
    var denomination: ChipDenomination?
    var count: Int

    init(sessionPlayer: SessionPlayer? = nil, denomination: ChipDenomination? = nil, count: Int = 0) {
        self.id = UUID()
        self.sessionPlayer = sessionPlayer
        self.denomination = denomination
        self.count = count
    }
}
