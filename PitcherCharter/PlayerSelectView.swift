//
//  PlayerSelectView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-15.
//

import SwiftUI
import CoreData

struct PlayerSelectView: View {
    
    // TODO: Clean up views and data management in this file
    
    @EnvironmentObject var dataController: DataController
    
    var awayTeam: Team
    var homeTeam: Team
    
    @Binding var isSheetPresented: Bool
    
//    var selectedPlayer: (Player) -> Void
    @Binding var selectedPlayer: Player?

    
    @State private var newPlayerName: String = ""
    @State private var newPlayerNumber: String = ""
    @State private var newPlayerBatsLorR: String = ""
    @State private var newPlayerThrowsLorR: String = ""
    
    @State private var showingCreateAwayPlayer = false
    @State private var showingCreateHomePlayer = false
    @State private var showingDeleteAlert = false

    
//    @State private var sortedAwayPlayers: [Player] = []
//    @State private var sortedPlayers: [Player] = []
    
    @State private var awayTeamPlayers: [Player] = []
    @State private var homeTeamPlayers: [Player] = []
    
    
    @Environment(\.managedObjectContext) var managedObjContext
    
    @FocusState private var focusNameTextField: Bool
    
    @State private var editingPlayer: Player?

    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                teamView(for: awayTeam, showingCreatePlayer: $showingCreateAwayPlayer)
                Divider()
                    .padding(.vertical)
                teamView(for: homeTeam, showingCreatePlayer: $showingCreateHomePlayer)
            }
        }
        .padding()
        .onAppear {
            self.awayTeamPlayers = sortedPlayers(for: awayTeam)
            self.homeTeamPlayers = sortedPlayers(for: homeTeam)
        }
    }
    
    
    private func teamView(for team: Team, showingCreatePlayer: Binding<Bool>) -> some View {
        VStack(alignment: .leading) {
            Text(team.teamName ?? "Unknown")
                .font(.headline)
                .underline()
            
            let players = team == awayTeam ? awayTeamPlayers : homeTeamPlayers
            
            ForEach(players) { player in
                HStack {
                    Button(action: {
//                        selectedPlayer(player)
                        selectedPlayer = player
                        isSheetPresented = false
                    }) {
                        playerListButtonView(name: player.name, number: player.number)
                    }
                    Spacer()
                    Button(action: {
                        
                        self.editingPlayer = player
                        self.newPlayerName = player.name ?? ""
                        self.newPlayerNumber = player.number ?? ""
                        self.newPlayerBatsLorR = player.batsLorR ?? ""
                        self.newPlayerThrowsLorR = player.throwsLorR ?? ""
                        withAnimation(.interactiveSpring) {
                            showingCreatePlayer.wrappedValue = true
                        }
                        
                        
                    }) {
                        Image(systemName: "ellipsis.circle")
                    }
                    Button(action: {
                        showingDeleteAlert.toggle()
                    }) {
                        Image(systemName: "trash")
                    }
                    .confirmationDialog("Delete Player", isPresented: $showingDeleteAlert, titleVisibility: .visible) {
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                delete(player: player, from: team)
                            }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to delete this player? All related data will be lost.")
                    }
                }
            }
    
            
            playerCreationView(for: team, showing: showingCreatePlayer)
            
            Button(action: {
                self.editingPlayer = nil
                self.newPlayerName = ""
                self.newPlayerNumber = ""
                self.newPlayerBatsLorR = ""
                self.newPlayerThrowsLorR = ""
                withAnimation(.interactiveSpring()) {
                    showingCreatePlayer.wrappedValue.toggle()
                }
            }) {
                Text(showingCreatePlayer.wrappedValue ? "Done" : "New \(team.teamName ?? "") Player")
                    .bold()
            }
            .padding(.vertical)
        }
    }
    
    private func sortedPlayers(for team: Team) -> [Player] {
            guard let players = team.playersOfTeam?.allObjects as? [Player] else { return [] }
            return players.sorted {
                let left = Int($0.number ?? "") ?? Int.max
                let right = Int($1.number ?? "") ?? Int.max
                return left < right
            }
    }
    
    private func playerCreationView(for team: Team, showing: Binding<Bool>) -> some View {
        Group {
            if showing.wrappedValue {
                VStack {
                    HStack {
                        TextField("New Player Name", text: $newPlayerName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusNameTextField)
                        TextField("#", text: $newPlayerNumber)
                            .textFieldStyle(.roundedBorder)
                    }
                    VStack(alignment: .leading) {
                        Text("Bats: ")
                            .font(.callout.smallCaps())
                            .foregroundColor(.secondary)
                        Picker("Bats", selection: $newPlayerBatsLorR) {
                            Text("R").tag("R")
                            Text("L").tag("L")
                            //                                    Text("S").tag("S")
                        }
                        .pickerStyle(.segmented)
                        Text("Throws: ")
                            .font(.callout.smallCaps())
                            .foregroundColor(.secondary)
                        
                        Picker("Throws", selection: $newPlayerThrowsLorR) {
                            Text("R").tag("R")
                            Text("L").tag("L")
                        }
                        .pickerStyle(.segmented)
                    }
                
                Button(action: {
                    if let editingPlayer = editingPlayer {
                        dataController.editPlayer(player: editingPlayer,
                                                          playerName: newPlayerName,
                                                          playerNumber: newPlayerNumber,
                                                          batsLorR: newPlayerBatsLorR,
                                                          throwsLorR: newPlayerThrowsLorR,
                                                          context: managedObjContext)
                    } else {
                        let player = Player(context: managedObjContext)
                        player.name = newPlayerName
                        player.number = newPlayerNumber
                        player.batsLorR = newPlayerBatsLorR
                        player.throwsLorR = newPlayerThrowsLorR
                        
                        team.addToPlayersOfTeam(player)
                        dataController.addPlayer(player: player, context: managedObjContext)
                    }
                    
                    newPlayerName = ""
                    newPlayerNumber = ""
                    newPlayerBatsLorR = ""
                    newPlayerThrowsLorR = ""
                    self.editingPlayer = nil // Reset editingPlayer
                    focusNameTextField = true
                    if team == awayTeam {
                        awayTeamPlayers = sortedPlayers(for: awayTeam)
                    } else {
                        homeTeamPlayers = sortedPlayers(for: homeTeam)
                    }
                    
                }) {
                    Text("Save Player")
                        .font(.body.smallCaps())
                        .bold()
                }
                }
                .padding()
                .background(Color.red.opacity(0.02))
            }
                
        }
    }
    
    private func delete(player: Player, from team: Team) {
            withAnimation {
                // Removing from CoreData
                managedObjContext.delete(player)
                try? managedObjContext.save()

                // Refresh the lists
                if team == awayTeam {
                    awayTeamPlayers = sortedPlayers(for: awayTeam)
                } else {
                    homeTeamPlayers = sortedPlayers(for: homeTeam)
                }
            }
        }
}


struct playerListButtonView: View {
    
    var name: String?
    var number: String?
    
    
    var body: some View {
        
        HStack {
            Text(name ?? "")
            Spacer()
            Text("\(number ?? "")")
        }
        .foregroundColor(.black)
        .font(.headline)
        .padding(.vertical, 5)
        .padding(.horizontal, 5)
        .background(Color.secondary.opacity(0.2))
        .padding(.trailing, 100)
        .cornerRadius(4)
    }
    
}

struct PlayerSelectView_Previews: PreviewProvider {
    
    static var temporaryDataController = DataController(inMemory: true) // Use in-memory store for previews
    
    
    static var player1: Player {
        let player1 = Player(context: temporaryDataController.container.viewContext)
        player1.id = UUID()
        player1.name = "Kevin Angers"
        player1.number = "2"
        return player1
    }
    
    static var player2: Player {
        let player2 = Player(context: temporaryDataController.container.viewContext)
        player2.id = UUID()
        player2.name = "Kento Moriyoshi"
        player2.number = "1"
        return player2
    }
    
    static var player3: Player {
        let player2 = Player(context: temporaryDataController.container.viewContext)
        player2.id = UUID()
        player2.name = "Owen Taylor"
        player2.number = "99"
        return player2
    }
    
    static var homeTeam: Team {
        let homeTeam = Team(context: temporaryDataController.container.viewContext)
        homeTeam.teamName = "Toronto Varsity Blues"
        homeTeam.addToPlayersOfTeam(player1)
        homeTeam.addToPlayersOfTeam(player2)
        homeTeam.addToPlayersOfTeam(player3)
        return homeTeam
    }
    
    static var awayTeam: Team {
        let awayTeam = Team(context: temporaryDataController.container.viewContext)
        awayTeam.teamName = "Guelph Gryphons"
        return awayTeam
    }
    
    static var previews: some View {
        PlayerSelectView(awayTeam: awayTeam, homeTeam: homeTeam, isSheetPresented: .constant(true), selectedPlayer: .constant(nil))
            .environment(\.managedObjectContext, temporaryDataController.container.viewContext)
    }
}
