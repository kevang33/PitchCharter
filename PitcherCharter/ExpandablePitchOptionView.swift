//
//  ExpandablePitchOptionButton.swift
//  PitcherCharter
//
//  Created by Kevin Angers on 2023-09-30.
//

import Foundation
import SwiftUI
import CoreData

struct ExpandablePitchOptionItem: Identifiable {
    let id = UUID()
    let text: String
    var action: (() -> Void)? = nil
    
}

struct ExpandablePitchOptionView: View {
    
    @Environment(\.managedObjectContext) var managedObjContext
    @EnvironmentObject var dataController: DataController
    
    let primaryButton: ExpandablePitchOptionItem
    let hasSecondaryButtons: Bool
    
    private var secondaryButtons: [ExpandablePitchOptionItem] {
        if hasSecondaryButtons {
            return [
                ExpandablePitchOptionItem(text: "Whiff 1", action: {
                    pitchOptionButton(pitchResult: .Whiff_1, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                }),
                ExpandablePitchOptionItem(text: "Barrel 1", action: {
                    pitchOptionButton(pitchResult: .Barrel_1, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                }),
                ExpandablePitchOptionItem(text: "Whiff 2", action: {
                    pitchOptionButton(pitchResult: .Whiff_2, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                }),
                ExpandablePitchOptionItem(text: "Barrel 2", action: {
                    pitchOptionButton(pitchResult: .Barrel_2, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                }),
                ExpandablePitchOptionItem(text: "Whiff 3", action: {
                    pitchOptionButton(pitchResult: .Whiff_3, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                }),
                ExpandablePitchOptionItem(text: "Barrel 3", action: {
                    pitchOptionButton(pitchResult: .Barrel_3, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)
                })
            ]
        }
        else { return [] }
    }
    
    
    var primaryColour: Color = .red
    var secondaryColour: Color = .red
    
    private let size: CGFloat = 40
    private var cornerRadius: CGFloat {
        get {size / 1.5}
    }
    
    @State private var isExpanded = false
    @Binding var showPitchOptions: Bool
    //    @ObservedObject var pitchData: PitchManager
    @Binding var currentPitch: Pitch?
    @ObservedObject var atBatManager: AtBatManager
    @Binding var game: Game
    
    var body: some View {
        
//        let gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        
        VStack(alignment: .leading) {
//            LazyVGrid(columns: gridLayout, spacing: 5) {
            
    
            
            
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 500.0, damping: 2000.0)){
                    self.isExpanded.toggle()
                }
                self.primaryButton.action?()
                currentPitch = nil
            }, label: {
                Text(self.primaryButton.text)
                    .foregroundColor(primaryColour)
                    .bold()
                    .font(.title3)
//                    .frame(maxWidth: .infinity, maxHeight: .infinity)
//                    .offset(y: -3)
                
                
                
            })
//            .background(Color.red)
            .buttonStyle(.bordered)
            
            if isExpanded {
                HStack {
                    ForEach(secondaryButtons.reversed()) { button in
                        Button(action: {
                            button.action?()
                        }, label: {
                            ZStack {
                                Rectangle()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(Color.silver)
                                if currentPitch != nil {
                                    PitchView(pitch: currentPitch!)
                                }
                            }
//                            Text(button.text)
//                                .foregroundColor(.white)
//                                .bold()
                            //                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                        })
                        //                        .frame(width: self.size*2.2, height: self.size*1.5)
                        .background(secondaryColour)
                        .cornerRadius(10)
                    }
                }
            }
//            .frame(width: self.size*4, height: self.size)
            
            //                .background(primaryColour)
            
            
        }
//        .background(primaryColour)
//        .cornerRadius(cornerRadius)
//        .shadow(radius: 5)
//        .opacity(0.8)
    }
    
}

func pitchOptionButton(pitchResult: PitchResult, currentPitch: Pitch, atBatManager: AtBatManager, game: Game, showPitchOptions: Binding<Bool>, dataController: DataController, context: NSManagedObjectContext) {
    // Assign pitch result to the current pitch
    currentPitch.pitchResult = pitchResult.rawValue
    
    currentPitch.pitcherOfPitch = atBatManager.currentPitcher
    currentPitch.batterOfPitch = atBatManager.currentBatter
    currentPitch.atBatOfPitch = atBatManager.currentAtBat
    currentPitch.gameOfPitch = game
    
    dataController.addPitch(pitch: currentPitch, context: context)
    
    context.undoManager?.registerUndo(withTarget: dataController) { targetSelf in
        context.delete(currentPitch)
        try? context.save()
    }
    
    // Hide pitch options
    withAnimation(.interactiveSpring()) {
        showPitchOptions.wrappedValue = false
    }
}

struct PitchOptionViewStack: View {
    
    @Binding var showPitchOptions: Bool
    @Binding var currentPitch: Pitch?
    @Binding var atBatManager: AtBatManager
    @Binding var game: Game
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Ball"), hasSecondaryButtons: false, primaryColour: .blue, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Called Strike"), hasSecondaryButtons: true, primaryColour: .coral, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Swinging Strike"), hasSecondaryButtons: true, primaryColour: .red, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "In Play"), hasSecondaryButtons: true, primaryColour: .green, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Foul"), hasSecondaryButtons: true, primaryColour: .yellow, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                    
                    ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Bunt"), hasSecondaryButtons: true, primaryColour: .purple, showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                    
                }
                Spacer()
            }
            .padding(.horizontal)
            Spacer()
        }
    }
}

struct ExpandablePitchOptionView_Previews: PreviewProvider {
    static var previews: some View {
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        let games = try? DataController.preview.container.viewContext.fetch(fetchRequest)
        let sampleGame = games?.first
        
        PitchOptionViewStack(showPitchOptions: .constant(false), currentPitch: .constant(nil), atBatManager: .constant(AtBatManager()), game: .constant(sampleGame!))
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
        
    }
    
}
                                  
                                  

