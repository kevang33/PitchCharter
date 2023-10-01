//
//  DataController.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-11.
//

import Foundation
import CoreData

class DataController: ObservableObject {
    
//    static let shared = DataController()
    
    let container = NSPersistentContainer(name: "DataModel")
    
    init(inMemory: Bool = false) {
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Set the migration options for lightweight migration
            let options = [ NSInferMappingModelAutomaticallyOption : true,
                            NSMigratePersistentStoresAutomaticallyOption : true]
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        }
        
        
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Failed to load the data \(error.localizedDescription)")
            }
        }
        
        let context = container.viewContext
        context.undoManager = UndoManager()
        
    }
    
    
    
    func save(context: NSManagedObjectContext) {
        do {
            try context.save()
            print("Data Saved")
        } catch {
            print("******ERROR******")
//            let nsError = error as NSError
//            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func addGame(date: Date, location: String, gameNumber: String, homeTeam: Team, awayTeam: Team, context: NSManagedObjectContext) {
        let game = Game(context: context)
        game.id = UUID()
        game.date = date
        game.location = location
        game.gameNumber = gameNumber
        game.homeTeamOfGame = homeTeam
        game.awayTeamOfGame = awayTeam
        
        save(context: context)
    }
    
    
    func editGame(game: Game, date: Date, location: String, homeTeam: Team, awayTeam: Team, context: NSManagedObjectContext) {
        game.location = location
        game.homeTeamOfGame = homeTeam
        game.awayTeamOfGame = awayTeam
        
        save(context: context)
    }
    
    func deleteGame(game: Game, context: NSManagedObjectContext) {
        context.delete(game)
        
        save(context: context)
    }
    
    func addTeam(cityName: String, teamName: String, logoData: Data?, context: NSManagedObjectContext) {
        let team = Team(context: context)
        team.id = UUID()
        team.cityName = cityName
        team.teamName = teamName
        team.teamLogo = logoData
        
        save(context: context)
    }
    
    func addPlayerToTeam(team: Team, player: Player, context: NSManagedObjectContext) {
        team.addToPlayersOfTeam(player)
        
        save(context: context)
    }
    
    func addPlayer(playerName: String, playerNumber: String, batsLorR: String, throwsLorR: String, context: NSManagedObjectContext) {
        let player = Player(context: context)
        player.id = UUID()
        player.name = playerName
        player.number = playerNumber
        player.batsLorR = batsLorR
        player.throwsLorR = throwsLorR
        
        save(context: context)
    }
    
    func addPlayer(player: Player, context: NSManagedObjectContext) {
        player.id = UUID()
        
        save(context: context)
    }
    
    func editPlayer(player: Player, playerName: String, playerNumber: String, batsLorR: String, throwsLorR: String, context: NSManagedObjectContext) {
        
        player.name = playerName
        player.number = playerNumber
        player.batsLorR = batsLorR
        player.throwsLorR = throwsLorR
        
        save(context: context)
    }
    
    func editPlayer(player: Player, context: NSManagedObjectContext) {
        save(context: context)
    }
    
    func addAtBat(indexInGame: Int16, context: NSManagedObjectContext) {
        let atBat = AtBat(context: context)
        atBat.id = UUID()
        atBat.indexInGame = indexInGame
        
        save(context: context)
    }
    
    func addAtBat(atBat: AtBat, context: NSManagedObjectContext) {
        atBat.id = UUID()
        
        save(context: context)
    }
    
    func editAtBat(atBat: AtBat, atBatResult: String, context: NSManagedObjectContext) {
        atBat.result = atBatResult
        save(context: context)
    }
    
    func addPitch(pitch: Pitch, context: NSManagedObjectContext) {
        pitch.id = UUID()
        
        save(context: context)
    }
   
}

enum PitchResult: Int16 {
    case Ball = 0
    case StrikeLooking = 1
    case Whiff_3 = 2
    case Whiff_2 = 3
    case Whiff_1 = 4
    case Barrel_3 = 5
    case Barrel_2 = 6
    case Barrel_1 = 7
    case Unknown = 8
}

extension DataController {
    static var preview: DataController = {
        let result = DataController(inMemory: true)
        let viewContext = result.container.viewContext

        result.addTeam(cityName: "Toronto", teamName: "Varsity Blues", logoData: nil, context: viewContext)
        result.addTeam(cityName: "Waterloo", teamName: "Warriors", logoData: nil, context: viewContext)
        result.addTeam(cityName: "Guelph", teamName: "Gryphons", logoData: nil, context: viewContext)
        result.addTeam(cityName: "TMU", teamName: "Bold", logoData: nil, context: viewContext)

        // Fetch the teams from the context
        let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
        let teams = try? viewContext.fetch(fetchRequest)
        
        let date = Date()

        // Add a game using specific teams
        if let homeTeam = teams?.first(where: { $0.teamName == "Varsity Blues" }),
           let awayTeam = teams?.first(where: { $0.teamName == "Warriors" }) {
            result.addGame(date: date, location: "Dan Lang", gameNumber: "1", homeTeam: homeTeam, awayTeam: awayTeam, context: viewContext)
        }
        
        if let homeTeam = teams?.first(where: { $0.teamName == "Varsity Blues" }),
           let awayTeam = teams?.first(where: { $0.teamName == "Gryphons" }) {
            result.addGame(date: date, location: "Megaffin Park", gameNumber: "2", homeTeam: homeTeam, awayTeam: awayTeam, context: viewContext)
        }
        
        result.addPlayer(playerName: "Kevin Angers", playerNumber: "2", batsLorR: "R", throwsLorR: "R", context: viewContext)
        result.addPlayer(playerName: "Aidan Mendonza", playerNumber: "41", batsLorR: "R", throwsLorR: "R", context: viewContext)
        result.addPlayer(playerName: "Jaylen Wood", playerNumber: "1", batsLorR: "L", throwsLorR: "R", context: viewContext)


        return result
    }()
}
