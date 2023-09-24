//
//  GameTileView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-14.
//

import SwiftUI
import CoreData

struct GameTileView: View {
    
    var game: Game
    
    var body: some View {
        ZStack  {
            VStack (alignment: .leading){
                HStack {
                    Spacer() // Pushes the adjacent items to the edge
                    Text(game.awayTeamOfGame?.cityName ?? "Unknown Team")
                        .font(.body.smallCaps())
//                    Spacer() // Create space between the team names and the "at"
                    if let awayTeamLogoData = game.awayTeamOfGame?.teamLogo,
                           let awayTeamLogoImage = UIImage(data: awayTeamLogoData) {
                            Image(uiImage: awayTeamLogoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else {
                            // Placeholder for teams without logos
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
                                .cornerRadius(2)
                        }
                    
                    Text("at")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: 20)
//                    Spacer() // Create space between the "at" and the team names
                    if let homeTeamLogoData = game.homeTeamOfGame?.teamLogo,
                           let homeTeamLogoImage = UIImage(data: homeTeamLogoData) {
                            Image(uiImage: homeTeamLogoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else {
                            // Placeholder for teams without logos
                            Rectangle()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.secondary)
                                .cornerRadius(2)
                        }

                    Text(game.homeTeamOfGame?.cityName ?? "Unknown Team")
                        .font(.body.smallCaps())
                    Spacer() // Pushes the adjacent items to the edge
                }
                HStack {
                    Text(game.date?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown Date")
                        .font(.caption)
                    Text(game.location ?? "Unknown Location")
                        .font(.caption)
                }
            }
//            .frame(maxWidth: .infinity)
            .padding(6)
    //        .background(Color.blue)
        }
        .cornerRadius(50)
//        .background(Color.black.opacity(0.1))
        
    }
}

struct GameTileView_Previews: PreviewProvider {
    static var previews: some View {
        // Fetch the first game from the context
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        let games = try? DataController.preview.container.viewContext.fetch(fetchRequest)
        let sampleGame = games?.first
        
        return GameTileView(game: sampleGame!)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
    }
}
