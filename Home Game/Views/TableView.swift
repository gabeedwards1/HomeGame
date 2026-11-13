import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TableView: View {
    @Bindable var session: Session
    @Environment(\.modelContext) private var modelContext

    @State private var actionTarget: SessionPlayer?
    @State private var rebuyTarget: SessionPlayer?
    @State private var rebuyAmountText = ""
    /// Set when the rebuy sheet is correcting an existing rebuy instead of adding one.
    @State private var editingRebuy: BuyInEvent?
    @State private var editBuyInsTarget: SessionPlayer?
    @State private var navigateToSettleUp: SessionPlayer?
    @State private var navigateToEndGame = false

    private var seatedPlayers: [SessionPlayer] {
        session.sessionPlayers.sorted { $0.seatPosition < $1.seatPosition }
    }

    var body: some View {
        GeometryReader { geometry in
            let table = tableSize(in: geometry.size)
            ZStack {
                Color.appBackground.ignoresSafeArea()

                Capsule(style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.felt.opacity(0.95), Color.felt.opacity(0.7)],
                            center: .center,
                            startRadius: 10,
                            endRadius: table.height / 2
                        )
                    )
                    .overlay(
                        Capsule(style: .continuous)
                            .strokeBorder(Color.accentColor.opacity(0.55), lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 24, y: 12)
                    .frame(width: table.width, height: table.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                ForEach(seatedPlayers) { sessionPlayer in
                    SeatView(sessionPlayer: sessionPlayer)
                        .position(seatPoint(for: sessionPlayer, in: geometry.size))
                        .onTapGesture {
                            actionTarget = sessionPlayer
                        }
                        .onDrag {
                            NSItemProvider(object: sessionPlayer.id.uuidString as NSString)
                        }
                        .onDrop(
                            of: [.text],
                            delegate: SeatDropDelegate(target: sessionPlayer, players: seatedPlayers)
                        )
                }
            }
        }
        .navigationTitle("Table")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("End Game") {
                    navigateToEndGame = true
                }
            }
        }
        .confirmationDialog(
            actionTarget?.player?.name ?? "",
            isPresented: Binding(
                get: { actionTarget != nil },
                set: { if !$0 { actionTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let target = actionTarget {
                if target.isCashedOut {
                    Button("View / Edit Settle Up") {
                        navigateToSettleUp = target
                    }
                } else {
                    Button("Add Rebuy") {
                        editingRebuy = nil
                        rebuyAmountText = session.defaultBuyInAmount.map { "\($0)" } ?? ""
                        rebuyTarget = target
                    }
                    Button("Settle Up") {
                        navigateToSettleUp = target
                    }
                }
                if let lastRebuy = lastRebuy(of: target) {
                    Button("Edit Last Rebuy") {
                        editingRebuy = lastRebuy
                        rebuyAmountText = "\(lastRebuy.amount)"
                        rebuyTarget = target
                    }
                }
                Button("Edit Buy-ins") {
                    editBuyInsTarget = target
                }
            }
        }
        .sheet(item: $rebuyTarget, onDismiss: { editingRebuy = nil }) { target in
            RebuySheet(
                playerName: target.player?.name ?? "Player",
                isEditing: editingRebuy != nil,
                amountText: $rebuyAmountText,
                onAdd: {
                    if let rebuy = editingRebuy {
                        updateRebuy(rebuy)
                    } else {
                        addRebuy(to: target)
                    }
                    rebuyTarget = nil
                },
                onCancel: {
                    rebuyTarget = nil
                }
            )
            .presentationDetents([.height(220)])
        }
        .sheet(item: $editBuyInsTarget) { target in
            EditBuyInsSheet(sessionPlayer: target) {
                editBuyInsTarget = nil
            }
        }
        .navigationDestination(item: $navigateToSettleUp) { sessionPlayer in
            SettleUpView(sessionPlayer: sessionPlayer)
        }
        .navigationDestination(isPresented: $navigateToEndGame) {
            EndGameView(session: session)
        }
    }

    /// The oval felt is sized once and shared by the table shape and the seat ring.
    /// A vertical racetrack fills the tall phone screen and puts the seat cards
    /// along the long left/right edges. Sized to hold 9+ seats without overlap.
    private func tableSize(in size: CGSize) -> CGSize {
        // Width is held back so the side seat cards stay on screen; height takes
        // the rest of the vertical space (minus room for the top/bottom cards),
        // capped so the racetrack doesn't get pencil-thin.
        let maxWidth = size.width - 100
        let height = min(size.height - 120, maxWidth * 1.9)
        let width = min(maxWidth, height / 1.7)
        return CGSize(width: width, height: height)
    }

    private func seatPoint(for sessionPlayer: SessionPlayer, in size: CGSize) -> CGPoint {
        let index = seatedPlayers.firstIndex(where: { $0.id == sessionPlayer.id }) ?? 0
        let total = max(seatedPlayers.count, 1)
        let table = tableSize(in: size)
        // Seat cards ride just inside the felt edge; the x inset keeps the side
        // cards clear of the screen edge.
        let radiusX = Double(table.width / 2 - 18)
        let radiusY = Double(table.height / 2 - 10)
        // Space seats by equal arc length, not equal angle, so they don't bunch
        // up at the narrow top and bottom of the oval when the table is full.
        let angle = seatAngle(index: index, total: total, radiusX: radiusX, radiusY: radiusY)
        let x = Double(size.width / 2) + radiusX * cos(angle)
        let y = Double(size.height / 2) + radiusY * sin(angle)
        return CGPoint(x: x, y: y)
    }

    /// Parametric angle for a seat placed `index / total` of the way around the
    /// seat-ring ellipse, measured by arc length from the top (−π/2).
    private func seatAngle(index: Int, total: Int, radiusX: Double, radiusY: Double) -> Double {
        let steps = 360
        let dt = 2 * Double.pi / Double(steps)
        let start = -Double.pi / 2

        var cumulative = [Double](repeating: 0, count: steps + 1)
        var acc = 0.0
        for i in 1...steps {
            let mid = start + dt * (Double(i) - 0.5)
            acc += hypot(radiusX * sin(mid), radiusY * cos(mid)) * dt
            cumulative[i] = acc
        }

        let target = acc * Double(index) / Double(total)
        var lo = 0
        while lo < steps && cumulative[lo + 1] < target { lo += 1 }
        let span = cumulative[lo + 1] - cumulative[lo]
        let frac = span > 0 ? (target - cumulative[lo]) / span : 0
        return start + dt * (Double(lo) + frac)
    }

    private func addRebuy(to sessionPlayer: SessionPlayer) {
        let amount = Decimal(string: rebuyAmountText) ?? 0
        guard amount > 0 else { return }
        let event = BuyInEvent(amount: amount, type: .rebuy)
        modelContext.insert(event)
        sessionPlayer.buyIns.append(event)
    }

    private func lastRebuy(of sessionPlayer: SessionPlayer) -> BuyInEvent? {
        sessionPlayer.buyIns
            .filter { $0.type == .rebuy }
            .max { $0.timestamp < $1.timestamp }
    }

    private func updateRebuy(_ rebuy: BuyInEvent) {
        let amount = Decimal(string: rebuyAmountText) ?? 0
        guard amount > 0 else { return }
        rebuy.amount = amount
    }
}

private struct SeatView: View {
    let sessionPlayer: SessionPlayer

    private var rebuyCount: Int {
        max(0, sessionPlayer.buyIns.count - 1)
    }

    var body: some View {
        VStack(spacing: 4) {
            PlayerAvatar(name: sessionPlayer.player?.name ?? "?", size: 30)

            Text(sessionPlayer.player?.name ?? "Unknown")
                .font(.caption.weight(.bold))
                .fontDesign(.rounded)
                .lineLimit(1)

            if sessionPlayer.isCashedOut {
                Text(sessionPlayer.netProfit, format: .currency(code: "USD"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(sessionPlayer.netProfit >= 0 ? .green : .red)
            } else {
                Text(sessionPlayer.totalBuyIn, format: .currency(code: "USD"))
                    .font(.caption2.weight(.semibold))
                if rebuyCount > 0 {
                    Text("+\(rebuyCount) rebuy\(rebuyCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(10)
        .frame(width: 100, height: 92)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(sessionPlayer.isCashedOut ? Color.gray.opacity(0.4) : Color.accentColor, lineWidth: sessionPlayer.isCashedOut ? 1 : 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
        .opacity(sessionPlayer.isCashedOut ? 0.75 : 1)
    }
}

private struct RebuySheet: View {
    let playerName: String
    var isEditing = false
    @Binding var amountText: String
    let onAdd: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Rebuy for \(playerName)") {
                    TextField("Amount", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color.cardSurface)
            }
            .themedForm()
            .navigationTitle(isEditing ? "Edit Rebuy" : "Add Rebuy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add", action: onAdd)
                        .disabled((Decimal(string: amountText) ?? 0) <= 0)
                }
            }
        }
    }
}

private struct EditBuyInsSheet: View {
    @Bindable var sessionPlayer: SessionPlayer
    @Environment(\.modelContext) private var modelContext
    let onDone: () -> Void

    private var sortedBuyIns: [BuyInEvent] {
        sessionPlayer.buyIns.sorted { $0.timestamp < $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buy-ins for \(sessionPlayer.player?.name ?? "Player")") {
                    ForEach(sortedBuyIns) { event in
                        BuyInEventRow(event: event, label: label(for: event))
                    }
                    .onDelete(perform: removeBuyIns)
                }
                .listRowBackground(Color.cardSurface)
            }
            .themedForm()
            .navigationTitle("Edit Buy-ins")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onDone)
                }
            }
        }
    }

    private func label(for event: BuyInEvent) -> String {
        switch event.type {
        case .initial:
            return "Initial Buy-in"
        case .rebuy:
            let rebuys = sortedBuyIns.filter { $0.type == .rebuy }
            let rebuyNumber = (rebuys.firstIndex(where: { $0.id == event.id }) ?? 0) + 1
            return "Rebuy \(rebuyNumber)"
        case .addOn:
            return "Add-On"
        }
    }

    private func removeBuyIns(at offsets: IndexSet) {
        // Snapshot first: `sortedBuyIns` is computed, so it reshuffles after each
        // delete and the remaining offsets would point at the wrong rows.
        let snapshot = sortedBuyIns
        guard snapshot.count - offsets.count >= 1 else { return }
        for event in offsets.compactMap({ $0 < snapshot.count ? snapshot[$0] : nil }) {
            sessionPlayer.buyIns.removeAll { $0.id == event.id }
            modelContext.delete(event)
        }
    }
}

private struct BuyInEventRow: View {
    @Bindable var event: BuyInEvent
    let label: String

    /// What the user is currently typing. `nil` means "show the stored amount".
    ///
    /// The field used to be backed by plain `@State` seeded in `onAppear`. Form rows
    /// can re-run `onAppear` when the list re-materialises them (e.g. the bottom row,
    /// usually a rebuy, scrolling under the keyboard), which overwrites whatever was
    /// typed with the stored amount. Falling back to the model unless a draft is in
    /// flight makes the row safe to re-render at any moment.
    @State private var draft: String?
    @FocusState private var isFocused: Bool

    private var amountText: Binding<String> {
        Binding(
            get: { draft ?? "\(event.amount)" },
            set: { newValue in
                draft = newValue
                // Commit per keystroke: the decimal pad has no return key, so waiting
                // for a commit event would lose the edit when "Done" closes the sheet.
                if let amount = Decimal(string: newValue), amount > 0 {
                    event.amount = amount
                }
            }
        )
    }

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            TextField("Amount", text: amountText)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .focused($isFocused)
        }
        // Drop the draft on blur so a half-typed or empty entry snaps back to the
        // stored amount instead of lingering, and on identity change so a recycled
        // row never shows the previous event's text.
        .onChange(of: isFocused) { _, focused in
            if !focused { draft = nil }
        }
        .onChange(of: event.id) { _, _ in
            draft = nil
        }
    }
}

private struct SeatDropDelegate: DropDelegate {
    let target: SessionPlayer
    let players: [SessionPlayer]

    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.text]).first else { return false }
        provider.loadObject(ofClass: NSString.self) { reading, _ in
            guard let idString = reading as? String, let sourceID = UUID(uuidString: idString) else { return }
            DispatchQueue.main.async {
                guard let source = players.first(where: { $0.id == sourceID }), source.id != target.id else { return }
                let sourcePosition = source.seatPosition
                source.seatPosition = target.seatPosition
                target.seatPosition = sourcePosition
            }
        }
        return true
    }
}

private func makePreviewSession(context: ModelContext) -> Session {
    for (color, value) in [("Red", Decimal(0.05)), ("White", 0.10), ("Green", 0.25), ("Blue", 0.50), ("Black", 1.00)] {
        context.insert(ChipDenomination(colorName: color, value: value))
    }
    let session = Session(defaultBuyInAmount: 20, smallBlind: 0.10, bigBlind: 0.25)
    context.insert(session)

    for (index, name) in ["Gabe", "Sam", "Alex", "Jordan"].enumerated() {
        let player = Player(name: name)
        context.insert(player)
        let sessionPlayer = SessionPlayer(session: session, player: player, seatPosition: index)
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
        TableView(session: session)
    }
    .modelContainer(container)
}
