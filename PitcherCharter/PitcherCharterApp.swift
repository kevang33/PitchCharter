//
//  PitcherCharterApp.swift
//  PitcherCharter
//
//  Created by Kevin Angers on 2023-09-19.
//

import SwiftUI

@main
struct PitcherCharterApp: App {
    
    @StateObject private var dataController = DataController()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(\.managedObjectContext, dataController.container.viewContext)
                .environmentObject(dataController)
        }
    }
}
