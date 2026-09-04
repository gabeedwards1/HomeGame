import SwiftUI
import SwiftData

struct StartView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var newSession: Session?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            RadialGradient(
                colors: [Color.felt.opacity(0.28), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor.gradient)
                            .frame(width: 104, height: 104)
                            .shadow(color: Color.accentColor.opacity(0.4), radius: 16, y: 8)
                        Image(systemName: "suit.spade.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.black)
                    }

                    VStack(spacing: 4) {
                        Text("Home Game")
                            .font(.largeTitle.bold())
                            .fontDesign(.rounded)
                        Text("Buy-ins, cash-outs, and who owes who")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    startNewGame()
                } label: {
                    Text("New Game")
                }
                .buttonStyle(.primary)
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .navigationDestination(item: $newSession) { session in
            ChipDenominationSetupView(session: session)
        }
    }

    private func startNewGame() {
        let session = Session()
        modelContext.insert(session)
        newSession = session
    }
}

#Preview {
    NavigationStack {
        StartView()
    }
    .modelContainer(
        for: [Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self],
        inMemory: true
    )
}
