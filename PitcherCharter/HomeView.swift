//
//  HomeView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-08.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject var dataController: DataController
    
    @State private var showingCreateGameView = false
    
    @FetchRequest(
        entity: Game.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Game.date, ascending: false)
        ]
    ) var games: FetchedResults<Game>


    
    @FetchRequest(entity: Team.entity(), sortDescriptors: []) var teams: FetchedResults<Team>

    @Environment(\.managedObjectContext) private var managedObjContext

    
    var body: some View {

        NavigationView {
            VStack {
                Button(action:{
                    showingCreateGameView = true
                    
                }) {
                    Text("Create Game")
                        .bold()
                        .font(.body.smallCaps())
                }
                .buttonStyle(.bordered)
                .sheet(isPresented: $showingCreateGameView) {
                    CreateGameView().environmentObject(dataController)
//                        .environment(\.managedObjectContext, self.managedObjContext)
                }
                .navigationTitle("Pitch Charter")
                
                
                
                List {
                    ForEach(games) { game in
                        NavigationLink(destination: ContentView(game: game)) {
                            GameTileView(game: game)
                        }
                        .listRowBackground(Color.paynesgray)
                    }
                    .onDelete(perform: { indexSet in
                        for index in indexSet {
                            let game = games[index]
                            dataController.deleteGame(game: game, context: managedObjContext)
                        }
                    })
                }
            }
        }
        
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
