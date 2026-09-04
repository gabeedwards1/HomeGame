import SwiftUI
import SwiftData

struct AddPlayersView: View {
    @Bindable var session: Session
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChipDenomination.value) private var denominations: [ChipDenomination]
    @Query(sort: \Player.name) private var existingPlayers: [Player]

    @State private var name = ""
    @State private var buyInText = ""
    @State private var navigateToReview = false

    private var buyInAmount: Decimal {
        Decimal(string: buyInText) ?? 0
    }

    private var sortedSessionPlayers: [SessionPlayer] {
        session.sessionPlayers.sorted { $0.joinedAt < $1.joinedAt }
    }

    private var canAddPlayer: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && buyInAmount > 0
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                HStack {
                    Text("Buy-in")
                    Spacer()
                    TextField("New Player Buy-in", text: $buyInText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                Button("Add Player", action: addPlayer)
                    .fontWeight(.semibold)
                    .foregroundStyle(canAddPlayer ? Color.accentColor : .secondary)
                    .disabled(!canAddPlayer)
            } header: {
                SectionHeaderLabel(title: "Add a Player", systemImage: "person.badge.plus.fill")
            }
            .listRowBackground(Color.cardSurface)

            if !sortedSessionPlayers.isEmpty {
                Section {
                    ForEach(sortedSessionPlayers) { sessionPlayer in
                        EditablePlayerBuyInRow(sessionPlayer: sessionPlayer, denominations: denominations)
                    }
                    .onDelete(perform: removePlayers)
                } header: {
                    SectionHeaderLabel(title: "Players (\(sortedSessionPlayers.count))", systemImage: "person.2.fill")
                }
                .listRowBackground(Color.cardSurface)
            }
        }
        .themedForm()
        .navigationTitle("Add Players")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToReview = true
            } label: {
                Text("Continue")
            }
            .buttonStyle(.primary)
            .disabled(sortedSessionPlayers.count < 2)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .navigationDestination(isPresented: $navigateToReview) {
            ReviewView(session: session)
        }
        .onAppear {
            buyInText = defaultBuyInText
        }
    }

    private var defaultBuyInText: String {
        session.defaultBuyInAmount.map { "\($0)" } ?? ""
    }

    private func addPlayer() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard canAddPlayer else { return }

        let player = existingPlayers.first { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
            ?? {
                let newPlayer = Player(name: trimmedName)
                modelContext.insert(newPlayer)
                return newPlayer
            }()

        let sessionPlayer = SessionPlayer(session: session, player: player, seatPosition: sortedSessionPlayers.count)
        modelContext.insert(sessionPlayer)

        let buyInEvent = BuyInEvent(sessionPlayer: sessionPlayer, amount: buyInAmount, type: .initial)
        modelContext.insert(buyInEvent)

        name = ""
        buyInText = defaultBuyInText
    }

    private func removePlayers(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(sortedSessionPlayers[index])
        }
    }
}

private struct EditablePlayerBuyInRow: View {
    let sessionPlayer: SessionPlayer
    let denominations: [ChipDenomination]
    @State private var buyInText = ""

    private var initialBuyIn: BuyInEvent? {
        sessionPlayer.buyIns.first { $0.type == .initial }
    }

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
                    TextField("Amount", text: $buyInText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                        .onChange(of: buyInText) { _, newValue in
                            guard let amount = Decimal(string: newValue) else { return }
                            initialBuyIn?.amount = amount
                        }
                }
                if !breakdown.isEmpty {
                    Text(breakdown.map { "\($0.count)× \($0.denomination.displayName)" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            buyInText = "\(sessionPlayer.totalBuyIn)"
        }
    }
}

private func makePreviewSession(context: ModelContext) -> Session {
    for (color, value) in [("Red", Decimal(0.05)), ("White", 0.10), ("Green", 0.25), ("Blue", 0.50), ("Black", 1.00)] {
        context.insert(ChipDenomination(colorName: color, value: value))
    }
    let session = Session(defaultBuyInAmount: 20, smallBlind: 0.10, bigBlind: 0.25)
    context.insert(session)
    return session
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let session = makePreviewSession(context: container.mainContext)

    NavigationStack {
        AddPlayersView(session: session)
    }
    .modelContainer(container)
}
