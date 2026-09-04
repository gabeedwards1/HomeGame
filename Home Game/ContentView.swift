//
//  ContentView.swift
//  Home Game
//
//  Created by Gabe Edwards on 8/1/26.
//

import SwiftUI

struct ContentView: View {
    @State private var navigationID = UUID()

    var body: some View {
        NavigationStack {
            StartView()
        }
        .id(navigationID)
        .environment(\.endSession) {
            navigationID = UUID()
        }
    }
}

#Preview {
    ContentView()
}
