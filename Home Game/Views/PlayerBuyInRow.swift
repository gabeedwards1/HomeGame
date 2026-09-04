import SwiftUI

struct PlayerBuyInRow: View {
    let sessionPlayer: SessionPlayer
    let denominations: [ChipDenomination]

    private var breakdown: [(denomination: ChipDenomination, count: Int)] {
        ChipBreakdownCalculator.suggestedBreakdown(buyIn: sessionPlayer.totalBuyIn, denominations: denominations)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PlayerAvatar(name: sessionPlayer.player?.name ?? "?")

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(sessionPlayer.player?.name ?? "Unknown")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Spacer()
                    Text(sessionPlayer.totalBuyIn, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                if !breakdown.isEmpty {
                    Text(breakdown.map { "\($0.count)× \($0.denomination.displayName)" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }
}
