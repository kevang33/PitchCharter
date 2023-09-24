//
//  CreateGameView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-08.
//

import SwiftUI


struct CreateGameView: View {
    
    @EnvironmentObject var dataController: DataController

//    @FetchRequest(sortDescriptors: []) var teams: FetchedResults<Team>
    @FetchRequest(entity: Team.entity(), sortDescriptors: []) var teams: FetchedResults<Team>


    @Environment(\.managedObjectContext) private var managedObjContext
    
    @State var date: Date = Date()
    @State var location: String = ""
//    @State var homeTeam: Team?
//    @State var awayTeam: Team?
    @State private var selectedHomeTeamID: UUID? = nil
    @State private var selectedAwayTeamID: UUID? = nil
    
    @State var showingCreateTeamView = false
    
    @Environment(\.presentationMode) var presentationMode
    
    
    var body: some View {

        NavigationView {
            Form {
                Section {
                    HStack {
                        FormLabelView(title: "Date", iconSystemName: "calendar", color: .blue)
                        DatePicker("", selection: $date, displayedComponents: .date)
    //                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        FormLabelView(title: "Location", iconSystemName: "location", color: .blue)
                            .padding(.trailing)
                        TextField("Field Location", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                Section {
                    HStack {
                        FormLabelView(title: "Home Team", iconSystemName: "baseball", color: .blue)
                            .padding(.trailing)
                        Picker("", selection: $selectedHomeTeamID) {
                            ForEach(teams) { team in
                                Text(team.teamName!).tag(team.id)
                            }
                            
                        }
                        .pickerStyle(.navigationLink)
                        .navigationBarItems(trailing: Button("Add Team"){
                            showingCreateTeamView = true
                        })
                        
                    }
                    
                    HStack {
                        FormLabelView(title: "Away Team", iconSystemName: "baseball.fill", color: .blue)
                            .padding(.trailing)
                        Picker("", selection: $selectedAwayTeamID) {
                            ForEach(teams) { team in
                                Text(team.teamName!).tag(team.id)
                            }
                            
                        }
                        .pickerStyle(.navigationLink)
                        .navigationBarItems(trailing: Button("Add Team"){
                            showingCreateTeamView = true
                        })
                    }
                }
                .sheet(isPresented: $showingCreateTeamView) {
                    CreateTeamView().environmentObject(dataController)
                }

                
                Button(action: {
                    print("Save button pressed.")
                    print("Date: \(date)")
                    print("Location: \(location)")
                    if let homeTeam = teams.first(where: { $0.id == selectedHomeTeamID }),
                       let awayTeam = teams.first(where: { $0.id == selectedAwayTeamID }) {
                        print("Found home team: \(homeTeam.teamName ?? "") and away team: \(awayTeam.teamName ?? "")")
                        dataController.addGame(date: date, location: location, homeTeam: homeTeam, awayTeam: awayTeam, context: managedObjContext)
                    } else {
                        print("Couldn't find the home or away team.")
                    }
                    
                    print("Resetting selected team IDs")
                    selectedHomeTeamID = nil
                    selectedAwayTeamID = nil
                    
                    presentationMode.wrappedValue.dismiss()
                    
                }) {
                    Text("Save")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
            .navigationTitle("Create Game")
        }.onAppear {
            print("Create Game view loaded")
            print("Printing teams:")
            print(teams)
        }
    }
}




struct CreateGameView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGameView()
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
