import SwiftUI
import SwiftData

struct EndGameView: View {
    @Bindable var session: Session
    @Environment(\.endSession) private var endSession

    private var sortedPlayers: [SessionPlayer] {
        session.sessionPlayers.sorted { $0.seatPosition < $1.seatPosition }
    }

    private var stillPlayingCount: Int {
        sortedPlayers.filter { !$0.isCashedOut }.count
    }

    private var allSettled: Bool {
        stillPlayingCount == 0
    }

    private var discrepancy: Decimal {
        session.totalCashOuts - session.totalBuyIns
    }

    var body: some View {
        Form {
            if !allSettled {
                Section {
                    Label(
                        "\(stillPlayingCount) player\(stillPlayingCount == 1 ? "" : "s") still playing",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.orange)
                }
                .listRowBackground(Color.cardSurface)
            }

            Section {
                ForEach(sortedPlayers) { sessionPlayer in
                    EndGamePlayerRow(sessionPlayer: sessionPlayer)
                }
            } header: {
                SectionHeaderLabel(title: "Players", systemImage: "person.2.fill")
            }
            .listRowBackground(Color.cardSurface)

            Section {
                HStack {
                    Text("Total Buy-ins")
                    Spacer()
                    Text(session.totalBuyIns, format: .currency(code: "USD"))
                }
                HStack {
                    Text("Total Cash-outs")
                    Spacer()
                    Text(session.totalCashOuts, format: .currency(code: "USD"))
                }
                HStack {
                    Text("Discrepancy")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Spacer()
                    Text(discrepancy, format: .currency(code: "USD"))
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(discrepancyColor)
                }
            }
            .listRowBackground(Color.cardSurface)
        }
        .themedForm()
        .navigationTitle("End Game")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: closeSession) {
                Text(allSettled ? "Close Session" : "Close Anyway")
            }
            .buttonStyle(.primary(tint: allSettled ? .accentColor : .orange))
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
    }

    private var discrepancyColor: Color {
        guard allSettled else { return .secondary }
        return discrepancy == 0 ? .green : .red
    }

    private func closeSession() {
        session.isActive = false
        endSession()
    }
}

private struct EndGamePlayerRow: View {
    let sessionPlayer: SessionPlayer

    private var rebuyCount: Int {
        max(0, sessionPlayer.buyIns.count - 1)
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
                    if sessionPlayer.isCashedOut {
                        Text(sessionPlayer.netProfit, format: .currency(code: "USD"))
                            .font(.headline)
                            .fontDesign(.rounded)
                            .foregroundStyle(sessionPlayer.netProfit >= 0 ? .green : .red)
                    } else {
                        Text("Still Playing")
                            .font(.subheadline)
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 12) {
                    Text("Buy-in \(sessionPlayer.totalBuyIn, format: .currency(code: "USD"))")
                    if rebuyCount > 0 {
                        Text("• \(rebuyCount) rebuy\(rebuyCount == 1 ? "" : "s")")
                    }
                    if sessionPlayer.isCashedOut {
                        Text("• Cash-out \(sessionPlayer.cashOutAmount, format: .currency(code: "USD"))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private func makePreviewSession(context: ModelContext) -> Session {
    var denominations: [ChipDenomination] = []
    for (color, value) in [("Red", Decimal(0.05)), ("White", 0.10), ("Green", 0.25), ("Blue", 0.50), ("Black", 1.00)] {
        let denomination = ChipDenomination(colorName: color, value: value)
        context.insert(denomination)
        denominations.append(denomination)
    }
    let session = Session(defaultBuyInAmount: 20, smallBlind: 0.10, bigBlind: 0.25)
    context.insert(session)

    func denomination(_ value: Decimal) -> ChipDenomination? {
        denominations.first { $0.value == value }
    }

    let winner = Player(name: "Gabe")
    context.insert(winner)
    let winnerSP = SessionPlayer(session: session, player: winner, seatPosition: 0)
    context.insert(winnerSP)
    context.insert(BuyInEvent(sessionPlayer: winnerSP, amount: 20, type: .initial))
    if let black = denomination(1.00) {
        let cashOut = CashOutCount(denomination: black, count: 35)
        context.insert(cashOut)
        winnerSP.cashOutCounts.append(cashOut)
    }
    winnerSP.isCashedOut = true

    let loser = Player(name: "Sam")
    context.insert(loser)
    let loserSP = SessionPlayer(session: session, player: loser, seatPosition: 1)
    context.insert(loserSP)
    context.insert(BuyInEvent(sessionPlayer: loserSP, amount: 20, type: .initial))
    context.insert(BuyInEvent(sessionPlayer: loserSP, amount: 20, type: .rebuy))
    if let white = denomination(0.05) {
        let cashOut = CashOutCount(denomination: white, count: 100)
        context.insert(cashOut)
        loserSP.cashOutCounts.append(cashOut)
    }
    loserSP.isCashedOut = true

    let stillPlaying = Player(name: "Alex")
    context.insert(stillPlaying)
    let stillPlayingSP = SessionPlayer(session: session, player: stillPlaying, seatPosition: 2)
    context.insert(stillPlayingSP)
    context.insert(BuyInEvent(sessionPlayer: stillPlayingSP, amount: 20, type: .initial))

    return session
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let session = makePreviewSession(context: container.mainContext)

    NavigationStack {
        EndGameView(session: session)
    }
    .modelContainer(container)
}
