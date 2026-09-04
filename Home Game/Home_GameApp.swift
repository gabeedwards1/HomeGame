//
//  Home_GameApp.swift
//  Home Game
//
//  Created by Gabe Edwards on 8/1/26.
//

import SwiftUI
import SwiftData

@main
struct Home_GameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(Self.makeModelContainer())
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            Player.self,
            Session.self,
            SessionPlayer.self,
            BuyInEvent.self,
            ChipDenomination.self,
            CashOutCount.self
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("-UITesting")
        let configuration = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
        return try! ModelContainer(for: schema, configurations: [configuration])
    }
}
