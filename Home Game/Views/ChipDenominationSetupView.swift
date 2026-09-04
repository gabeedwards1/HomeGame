import SwiftUI
import SwiftData

struct ChipDenominationSetupView: View {
    @Bindable var session: Session
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChipDenomination.value) private var denominations: [ChipDenomination]

    @State private var navigateToAddPlayers = false
    @State private var smallBlindText = ""
    @State private var bigBlindText = ""
    @State private var newChipColor = ""
    @State private var newChipPriceText = ""

    private var newChipPrice: Decimal {
        Decimal(string: newChipPriceText) ?? 0
    }

    private var canAddChip: Bool {
        !newChipColor.trimmingCharacters(in: .whitespaces).isEmpty && newChipPrice > 0
    }

    private var blindsAreSet: Bool {
        session.smallBlind > 0 && session.bigBlind > 0
    }

    var body: some View {
        Form {
            Section {
                Text("Add each chip in your set with its color and dollar value. This is only set up once — it's remembered for future games.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.clear)

            Section {
                HStack {
                    Text("Small Blind")
                    Spacer()
                    TextField("Amount", text: $smallBlindText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .onChange(of: smallBlindText) { _, newValue in
                            session.smallBlind = Decimal(string: newValue) ?? 0
                        }
                }
                HStack {
                    Text("Big Blind")
                    Spacer()
                    TextField("Amount", text: $bigBlindText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .onChange(of: bigBlindText) { _, newValue in
                            session.bigBlind = Decimal(string: newValue) ?? 0
                        }
                }
            } header: {
                SectionHeaderLabel(title: "Blinds", systemImage: "dollarsign.circle.fill")
            }
            .listRowBackground(Color.cardSurface)

            Section {
                TextField("New Chip Color", text: $newChipColor)
                HStack {
                    Text("Price")
                    Spacer()
                    TextField("New Chip Price", text: $newChipPriceText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                Button("Add Chip", action: addChip)
                    .fontWeight(.semibold)
                    .foregroundStyle(canAddChip ? Color.accentColor : .secondary)
                    .disabled(!canAddChip)
            } header: {
                SectionHeaderLabel(title: "Add a Chip", systemImage: "plus.circle.fill")
            }
            .listRowBackground(Color.cardSurface)

            if !denominations.isEmpty {
                Section {
                    ForEach(denominations) { denomination in
                        ChipDenominationRow(denomination: denomination)
                    }
                    .onDelete(perform: removeDenominations)
                } header: {
                    SectionHeaderLabel(title: "Chips (\(denominations.count))", systemImage: "circle.grid.2x2.fill")
                }
                .listRowBackground(Color.cardSurface)
            }
        }
        .themedForm()
        .navigationTitle("Chip & Blind Setup")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                navigateToAddPlayers = true
            } label: {
                Text("Continue")
            }
            .buttonStyle(.primary)
            .disabled(denominations.isEmpty || !blindsAreSet)
            .padding(.horizontal, 32)
            .padding(.bottom, 16)
        }
        .navigationDestination(isPresented: $navigateToAddPlayers) {
            AddPlayersView(session: session)
        }
        .onAppear {
            if session.smallBlind > 0 { smallBlindText = "\(session.smallBlind)" }
            if session.bigBlind > 0 { bigBlindText = "\(session.bigBlind)" }
        }
    }

    private func addChip() {
        guard canAddChip else { return }
        let denomination = ChipDenomination(colorName: newChipColor.trimmingCharacters(in: .whitespaces), value: newChipPrice)
        modelContext.insert(denomination)
        newChipColor = ""
        newChipPriceText = ""
    }

    private func removeDenominations(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(denominations[index])
        }
    }
}

private struct ChipDenominationRow: View {
    @Bindable var denomination: ChipDenomination
    @State private var colorText: String = ""
    @State private var priceText: String = ""

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(ChipSwatch.color(for: colorText))
                .overlay(Circle().strokeBorder(.secondary.opacity(0.35), lineWidth: 1.5))
                .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                .frame(width: 32, height: 32)

            TextField("Color", text: $colorText)
                .onChange(of: colorText) { _, newValue in
                    denomination.colorName = newValue
                }

            Spacer()

            TextField("Price", text: $priceText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .onChange(of: priceText) { _, newValue in
                    denomination.value = Decimal(string: newValue) ?? denomination.value
                }
        }
        .onAppear {
            colorText = denomination.colorName
            priceText = "\(denomination.value)"
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Player.self, Session.self, SessionPlayer.self, BuyInEvent.self, ChipDenomination.self, CashOutCount.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let session = Session()
    container.mainContext.insert(session)

    return NavigationStack {
        ChipDenominationSetupView(session: session)
    }
    .modelContainer(container)
}
