import SwiftUI
import SwiftData

struct SettleUpView: View {
    @Bindable var sessionPlayer: SessionPlayer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ChipDenomination.value) private var denominations: [ChipDenomination]

    @State private var countTexts: [UUID: String] = [:]

    private var cashOutAmount: Decimal {
        denominations.reduce(Decimal.zero) { partial, denomination in
            partial + Decimal(count(for: denomination)) * denomination.value
        }
    }

    private var netProfit: Decimal {
        cashOutAmount - sessionPlayer.totalBuyIn
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 12) {
                    PlayerAvatar(name: sessionPlayer.player?.name ?? "?")
                    Text(sessionPlayer.player?.name ?? "Unknown")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Spacer()
                    Text("Buy-in \(sessionPlayer.totalBuyIn, format: .currency(code: "USD"))")
                        .foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.cardSurface)

            Section {
                ForEach(denominations) { denomination in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(ChipSwatch.color(for: denomination.colorName))
                            .overlay(Circle().strokeBorder(.secondary.opacity(0.35), lineWidth: 1.5))
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                            .frame(width: 28, height: 28)

                        Text(denomination.displayName)

                        Spacer()

                        Text(denomination.value, format: .currency(code: "USD"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField("0", text: countBinding(for: denomination))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                    }
                }
            } header: {
                SectionHeaderLabel(title: "Count Your Chips", systemImage: "circle.grid.2x2.fill")
            }
            .listRowBackground(Color.cardSurface)

            Section {
                HStack {
                    Text("Cash Owed")
                        .font(.headline)
                        .fontDesign(.rounded)
                    Spacer()
                    Text(cashOutAmount, format: .currency(code: "USD"))
                        .font(.headline)
                        .fontDesign(.rounded)
                }
                HStack {
                    Text("Net")
                    Spacer()
                    Text(netProfit, format: .currency(code: "USD"))
                        .fontWeight(.semibold)
                        .foregroundStyle(netProfit >= 0 ? .green : .red)
                }
            }
            .listRowBackground(Color.cardSurface)
        }
        .themedForm()
        .navigationTitle(sessionPlayer.player?.name ?? "Settle Up")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: confirmSettleUp) {
                Text(sessionPlayer.isCashedOut ? "Update Settle Up" : "Confirm Settle Up")
            }
            .buttonStyle(.primary)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .onAppear {
            for cashOutCount in sessionPlayer.cashOutCounts {
                guard let denominationID = cashOutCount.denomination?.id else { continue }
                countTexts[denominationID] = "\(cashOutCount.count)"
            }
        }
    }

    private func count(for denomination: ChipDenomination) -> Int {
        Int(countTexts[denomination.id] ?? "") ?? 0
    }

    private func countBinding(for denomination: ChipDenomination) -> Binding<String> {
        Binding(
            get: { countTexts[denomination.id] ?? "" },
            set: { countTexts[denomination.id] = $0 }
        )
    }

    private func confirmSettleUp() {
        for existing in sessionPlayer.cashOutCounts {
            modelContext.delete(existing)
        }
        sessionPlayer.cashOutCounts.removeAll()

        for denomination in denominations {
            let chipCount = count(for: denomination)
            guard chipCount > 0 else { continue }
            let cashOutCount = CashOutCount(denomination: denomination, count: chipCount)
            modelContext.insert(cashOutCount)
            sessionPlayer.cashOutCounts.append(cashOutCount)
        }
        sessionPlayer.isCashedOut = true
        dismiss()
    }
}

private func makePreviewSessionPlayer(context: ModelContext) -> SessionPlayer {
    for (color, value) in [("Red", Decimal(0.05)), ("White", 0.10), ("Green", 0.25), ("Blue", 0.50), ("Black", 1.00)] {
        context.insert(ChipDenomination(colorName: color, value: value))
    }
    let session = Session(defaultBuyInAmount: 20, smallBlind: 0.10, bigBlind: 0.25)
    context.insert(session)
    let player = Player(name: "Gabe")
    context.insert(player)
    let sessionPlayer = SessionPlayer(session: session, player: player)
    context.insert(sessionPlayer)
    context.insert(BuyInEvent(sessionPlayer: sessionPlayer, amount: 20, type: .initial))
    return sessionPlayer
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let sessionPlayer = makePreviewSessionPlayer(context: container.mainContext)

    NavigationStack {
        SettleUpView(sessionPlayer: sessionPlayer)
    }
    .modelContainer(container)
}
