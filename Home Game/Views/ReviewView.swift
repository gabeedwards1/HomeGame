import SwiftUI
import SwiftData

struct ReviewView: View {
    @Bindable var session: Session
    @Query(sort: \ChipDenomination.value) private var denominations: [ChipDenomination]
    @State private var navigateToTable = false

    private var sortedSessionPlayers: [SessionPlayer] {
        session.sessionPlayers.sorted { $0.joinedAt < $1.joinedAt }
    }

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Small Blind")
                    Spacer()
                    Text(session.smallBlind, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("Big Blind")
                    Spacer()
                    Text(session.bigBlind, format: .currency(code: "USD"))
                        .foregroundStyle(.secondary)
                }
            } header: {
                SectionHeaderLabel(title: "Blinds", systemImage: "dollarsign.circle.fill")
            }
            .listRowBackground(Color.cardSurface)

            Section {
                ForEach(sortedSessionPlayers) { sessionPlayer in
                    PlayerBuyInRow(sessionPlayer: sessionPlayer, denominations: denominations)
                }
            } header: {
                SectionHeaderLabel(title: "Players (\(sortedSessionPlayers.count))", systemImage: "person.2.fill")
            }
            .listRowBackground(Color.cardSurface)

            Section {
                HStack {
                    Text("Total Pot")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Spacer()
                    Text(session.totalBuyIns, format: .currency(code: "USD"))
                        .font(.headline)
                        .fontDesign(.rounded)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .listRowBackground(Color.cardSurface)
        }
        .themedForm()
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToTable = true
            } label: {
                Text("Start Game")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .navigationDestination(isPresented: $navigateToTable) {
            TableView(session: session)
        }
    }
}

private func makePreviewSession(context: ModelContext) -> Session {
    for (color, value) in [("Red", Decimal(0.05)), ("White", 0.10), ("Green", 0.25), ("Blue", 0.50), ("Black", 1.00)] {
        context.insert(ChipDenomination(colorName: color, value: value))
    }
    let session = Session(defaultBuyInAmount: 20, smallBlind: 0.10, bigBlind: 0.25)
    context.insert(session)

    for name in ["Gabe", "Sam"] {
        let player = Player(name: name)
        context.insert(player)
        let sessionPlayer = SessionPlayer(session: session, player: player)
        context.insert(sessionPlayer)
        context.insert(BuyInEvent(sessionPlayer: sessionPlayer, amount: 20, type: .initial))
    }

    return session
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let session = makePreviewSession(context: container.mainContext)

    NavigationStack {
        ReviewView(session: session)
    }
    .modelContainer(container)
}
