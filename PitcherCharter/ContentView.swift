//
//  ContentView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-03.
//

import SwiftUI
import CoreData


struct ContentView: View {
    
    @Environment(\.managedObjectContext) var managedObjContext
    @EnvironmentObject var dataController: DataController
    
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)]) var games: FetchedResults<Game>
    
    
    @State var game: Game
    //    @State var pitcher: Player?
    //    @State var batter: Player?
    
    //    @StateObject private var pitchData = PitchManager()
    @StateObject private var atBatManager = AtBatManager()
    
    
    //    @State private var pitchPositions: [PitchPosition] = []
    @State private var zStackFrame: CGRect = .zero
    @State private var showPitchOptions: Bool = false
    //    @State var currentPitch: PitchPosition?
    
    @State private var showingPlayerSelectView = false
    
    @State private var selectionContext: SelectionContext = .none
    
    @State private var filterAtBats: String = "Game"
    
    //    @State var currentAtBat: AtBat? = nil
    
    @State private var showingDeletionAlert = false
    
    @State private var selectedPlayer: Player?
    
    @State private var refreshID = UUID()
    
    @State var currentPitch: Pitch? = nil
    
    @State var atBatResult: String = ""
    
    
    
    enum SelectionContext {
        case pitcher
        case batter
        case none
    }
    
    var sortedAtBats: [AtBat] {
        let atBats = (game.atBatsInGame?.allObjects as? [AtBat])?.sorted(by: {
            $0.indexInGame < $1.indexInGame
        }) ?? []
        
        switch filterAtBats {
        case "Batter":
            return atBats.filter {
                $0.batterOfAtBat == atBatManager.currentBatter
            }
        case "Pitcher":
            return atBats.filter {
                $0.pitcherOfAtBat == atBatManager.currentPitcher
            }
        default:
            return atBats
        }
    }
    
    var body: some View {
    
        
        let currentIndex = sortedAtBats.firstIndex { $0 == atBatManager.currentAtBat }
        
        let pitchesInGame = atBatManager.currentPitcher?.pitchesThrownByPlayer?.allObjects as? [Pitch]
        let pitchCount = pitchesInGame?.filter {
            $0.gameOfPitch?.id == game.id
        }.count ?? 0
        let strikeCount = pitchesInGame?.filter {
            ($0.gameOfPitch?.id == game.id) && ($0.pitchResult != PitchResult.Ball.rawValue && $0.pitchResult != PitchResult.Unknown.rawValue)
        }.count ?? 0
        
        let pitchesThrownByCurrentPitcher = atBatManager.currentPitcher?.pitchesThrownByPlayer?.allObjects as? [Pitch] ?? []
        let pitchesFacedByCurrentBatter = atBatManager.currentBatter?.pitchesFacedByPlayer?.allObjects as? [Pitch] ?? []
        
        ZStack {
            VStack {
                HStack{
                    VStack{
                        HStack {
                            Text("\(game.awayTeamOfGame?.teamName ?? "Unknown") at \(game.homeTeamOfGame?.teamName ?? "Unknown") ")
                                .font(.headline)
                                .underline()
                            Spacer()
                        }
                        HStack {
                            Text("Pitcher:")
                            Button(action: {
                                showingPlayerSelectView = true
                                selectionContext = .pitcher
                                
                            }){
                                HStack {
                                    Text(atBatManager.currentPitcher?.name ?? "Add Pitcher")
                                        .bold()
                                        .lineLimit(1)
                                    
                                    if (atBatManager.currentPitcher != nil) {
                                        Text("#\(atBatManager.currentPitcher?.number ?? "")")
                                            .bold()
                                    }
                                }
                            }
                            .disabled(atBatManager.currentAtBat == nil)
                            .sheet(isPresented: $showingPlayerSelectView) {
                                PlayerSelectView(awayTeam: game.awayTeamOfGame!, homeTeam: game.homeTeamOfGame!, isSheetPresented: $showingPlayerSelectView, selectedPlayer: $selectedPlayer)
                            }
                            .onChange(of: selectedPlayer) { //selected in
                                if let player = selectedPlayer {
                                    
                                    let currentPitchesInAtBat = atBatManager.currentAtBat?.pitchesInAtBat?.allObjects as? [Pitch] ?? []
                                    
                                    switch selectionContext {
                                    case .pitcher:
                                        // Need to change who threw the pitches
                                        for pitch in currentPitchesInAtBat {
                                            pitch.pitcherOfPitch = player
                                        }
                                        atBatManager.currentAtBat?.pitcherOfAtBat = player
                                    case .batter:
                                        for pitch in currentPitchesInAtBat {
                                            pitch.batterOfPitch = player
                                        }
                                        atBatManager.currentAtBat?.batterOfAtBat = player
                                    case .none:
                                        break
                                    }
                                    try? managedObjContext.save()
                                    selectedPlayer = nil // Reset after handling the selected player.
                                    refreshID = UUID()
                                }
                            }
                            
                            Spacer()
                            Text("Count:")
                                .font(.caption)
                            Text(String(pitchCount))
                                .bold()
                                .font(.caption)
                            Text("Strikes:")
                                .font(.caption)
                            Text(String(strikeCount))
                                .bold()
                                .font(.caption)
                        }
                        .padding(.vertical, 5)
                        HStack
                        {
                            Text("Batter:")
                            Button(action: {
                                showingPlayerSelectView = true
                                selectionContext = .batter
                                
                            }){
                                
                                HStack {
                                    Text(atBatManager.currentBatter?.name ?? "Add Batter")
                                        .bold()
                                        .lineLimit(1)
                                    
                                    if (atBatManager.currentBatter != nil) {
                                        Text("#\(atBatManager.currentBatter?.number ?? "")")
                                            .bold()
                                    }
                                    
                                }
                            }
                            .disabled(atBatManager.currentAtBat == nil)
                            
                            Spacer()
                            //                            Text("0-3 this Game. 0-5 against Angers")
                            //                                .font(.caption)
                            //                                .bold()
                            Text("Bats: \(atBatManager.currentBatter?.batsLorR ?? "?")")
                                .font(.body.smallCaps())
                            
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Picker("Filter", selection: $filterAtBats) {
                    Text("Game").tag("Game")
                    Text(atBatManager.currentBatter?.name ?? "Batter").tag("Batter")
                    Text(atBatManager.currentPitcher?.name ?? "Pitcher").tag("Pitcher")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                HStack {
                    // Add New AtBat Button
                    Button(action: {
                        currentPitch = nil
                        
                        let newAtBat = AtBat(context: managedObjContext)
                        newAtBat.gameOfAtBat = game
                        newAtBat.batterOfAtBat = nil
                        newAtBat.pitcherOfAtBat = atBatManager.currentPitcher
                        newAtBat.indexInGame = Int16(sortedAtBats.count + 1)
                        
                        game.addToAtBatsInGame(newAtBat)
                        
                        dataController.addAtBat(atBat: newAtBat, context: managedObjContext)
                        
                        atBatManager.currentAtBat = newAtBat
                        
                        // Dont want adding at bats to be undoabble
                        managedObjContext.undoManager?.removeAllActions()
                        
                    }) {
                        Image(systemName: "plus")
                    }
                    .disabled(filterAtBats != "Game")
                    
                    Spacer()
                    
                    // Previous AtBat Button
                    Button(action: {
                        if let idx = currentIndex, idx > 0 {
                            atBatManager.currentAtBat = sortedAtBats[idx - 1]
                            currentPitch = nil
                        }
                    }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(atBatManager.currentAtBat == nil || currentIndex == 0)
                    
                    Text("At Bat \((currentIndex.map { $0 + 1 })?.description ?? "-") of \(sortedAtBats.count)")
                    
                        .font(.body.smallCaps())
                        .bold()
                    
                    // Next AtBat Button
                    Button(action: {
                        if let idx = currentIndex, idx < sortedAtBats.count - 1 {
                            atBatManager.currentAtBat = sortedAtBats[idx + 1]
                            currentPitch = nil
                        }
                    }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(atBatManager.currentAtBat == nil || currentIndex == sortedAtBats.count - 1)
                    
                    Spacer()
                    
                    // Delete Current AtBat Button
                    Button(action: {
                        showingDeletionAlert = true
                    }) {
                        Image(systemName: "trash")
                    }
                    .disabled(atBatManager.currentAtBat == nil)
                    .alert(isPresented: $showingDeletionAlert) {
                        Alert(title: Text("Delete AtBat"), message: Text("Are you sure you want to delete the current at-bat?"), primaryButton: .destructive(Text("Delete")) {
                            if let idx = currentIndex {
                                let atBatToDelete = sortedAtBats[idx]
                                
                                managedObjContext.delete(atBatToDelete)
                                
                                // Save changes
                                do {
                                    try managedObjContext.save()
                                } catch {
                                    print("Failed to delete AtBat: \(error)")
                                }
                                
                                if idx > 0 {
                                    atBatManager.currentAtBat = sortedAtBats[idx - 1]
                                } else if sortedAtBats.count > 1 {
                                    atBatManager.currentAtBat = sortedAtBats[1]
                                } else {
                                    atBatManager.currentAtBat = nil
                                }
                            }
                        }, secondaryButton: .cancel())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 5)
                
                
                TextField("Result", text: $atBatResult)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: atBatResult) {
                        // Editing result shouldd not be undoabble
                        managedObjContext.processPendingChanges()
                        managedObjContext.undoManager?.disableUndoRegistration()

                        dataController.editAtBat(atBat: atBatManager.currentAtBat!, atBatResult: atBatResult, context: managedObjContext)
                        
                        managedObjContext.processPendingChanges()
                        managedObjContext.undoManager?.enableUndoRegistration()
                }
                .padding(.horizontal)
                .disabled(atBatManager.currentAtBat == nil)
   
                
                if atBatManager.currentAtBat != nil {
                    
                    ZStack {
                        Image("strikezone").resizable()
                            .padding(.horizontal, 85)
                            .padding(.vertical, 75)
                            .aspectRatio(contentMode: .fit)
                        
                    }
                    .background(
                        GeometryReader { geometry in
                            Color.black.opacity(0.05)
                                .onAppear {
                                    self.zStackFrame = geometry.frame(in: .global)
                                }
                        }
                    )
                    .cornerRadius(60)
                    .frame(height: 400)
                    .padding(.horizontal)
                    
                    HStack {
                        
                        Button(action: {managedObjContext.undoManager?.undo()}) {
                            Image(systemName: "arrow.uturn.backward.circle.fill")
                        }
                        .disabled(!(managedObjContext.undoManager?.canUndo ?? false) || (atBatManager.currentAtBat?.pitchesInAtBat?.count) ?? 0 < 1 )
                        
                        
                        ZStack {
                            PitchSelectorView(colour: pitchTypeToColour(pitchType: "FB"), pitchType: "FB", showPitchOptions: $showPitchOptions, zStackFrame: self.zStackFrame, currentPitch: $currentPitch, atBatManager: atBatManager)
                        }
                        .frame(width: 50, height: 50) // Adjust based on the max expected size
                        
                        ZStack {
                            PitchSelectorView(colour: pitchTypeToColour(pitchType: "CH"), pitchType: "CH", showPitchOptions: $showPitchOptions, zStackFrame: self.zStackFrame, currentPitch: $currentPitch, atBatManager: atBatManager)
                        }
                        .frame(width: 50, height: 50)
                        
                        ZStack {
                            PitchSelectorView(colour: pitchTypeToColour(pitchType: "CB"), pitchType: "CB", showPitchOptions: $showPitchOptions, zStackFrame: self.zStackFrame, currentPitch: $currentPitch, atBatManager: atBatManager)
                        }
                        .frame(width: 50, height: 50)
                        
                        ZStack {
                            PitchSelectorView(colour: pitchTypeToColour(pitchType: "SL"), pitchType: "SL", showPitchOptions: $showPitchOptions, zStackFrame: self.zStackFrame, currentPitch: $currentPitch, atBatManager: atBatManager)
                        }
                        .frame(width: 50, height: 50)
                        
                        ZStack {
                            PitchSelectorView(colour: pitchTypeToColour(pitchType: "SP"), pitchType: "SP", showPitchOptions: $showPitchOptions, zStackFrame: self.zStackFrame, currentPitch: $currentPitch, atBatManager: atBatManager)
                        }
                        .frame(width: 50, height: 50)
                        
                        Button(action: {managedObjContext.undoManager?.redo()}) {
                            Image(systemName: "arrow.uturn.forward.circle.fill")
                        }
                        .disabled(!(managedObjContext.undoManager?.canRedo ?? false))
                        
                    }
                    
//                    Text
                    
                    
                    //                    VStack {
                    //                        Text("Current Pitch: \(pitchData.currentPitch?.pitchType ?? "Unknown") at (\(pitchData.currentPitch?.x ?? 0), \(pitchData.currentPitch?.y ?? 0))")
                    //                        Text("Num Pitches: \(pitchData.pitchesInAtBat.count)")
                    //                        HStack {
                    //                            ForEach(pitchData.pitchesInAtBat) { pitch in
                    //                                Text("\(pitch.id?.uuidString ?? "-") ")
                    //
                    //                            }
                    //                        }
                    //                    }
                    //                    .font(.system(size: 8))
                    
                   
                    
                }
                else {
                    Button(action: {
                        // Create new at bat
                        
                        let newAtBat = AtBat(context: managedObjContext)
                        newAtBat.gameOfAtBat = game
                        newAtBat.batterOfAtBat = nil
                        newAtBat.pitcherOfAtBat = atBatManager.currentPitcher
                        newAtBat.indexInGame = Int16((game.atBatsInGame?.count ?? 0) + 1)
                        
                        game.addToAtBatsInGame(newAtBat)
                        
                        dataController.addAtBat(atBat: newAtBat, context: managedObjContext)
                        
                        atBatManager.currentAtBat = newAtBat
                        
                        managedObjContext.undoManager?.removeAllActions()
                        
                    }) {
                        Text("New At Bat")
                            .bold()
                    }
                    .frame(height: 400)
                }
                
//                HStack{
//                    Text("Pitches thrown by \(atBatManager.currentPitcher?.name ?? "UP")")
//                    ForEach(pitchesThrownByCurrentPitcher) { pitch in
//                        Text(pitch.pitchType ?? "-")
//                    }
//                }
//                .font(.caption)
//                
//                HStack{
//                    Text("Pitches faced by \(atBatManager.currentBatter?.name ?? "UP")")
//                    ForEach(pitchesFacedByCurrentBatter) { pitch in
//                        Text(pitch.pitchType ?? "-")
//                    }
//                }
//                .font(.caption)
                
            }
            .onChange(of: atBatManager.currentAtBat) {
                atBatResult = atBatManager.currentAtBat?.result ?? ""
            }
            .onAppear {
                // If there are at-bats, set currentAtBat to the most recent one
                if let lastAtBat = sortedAtBats.last {
                    atBatManager.currentAtBat = lastAtBat
                }
                
                atBatResult = atBatManager.currentAtBat?.result ?? ""
            }
            .id(refreshID)
            
            ForEach(atBatManager.currentAtBat?.pitchesInAtBat?.allObjects as? [Pitch] ?? []) { pitch in
                //                PitchView(pitchType: pitch.pitchType!, pitchResult: PitchResult(rawValue: pitch.pitchResult) ?? .Unknown)
                PitchView(pitch: pitch)
                    .position(x: CGFloat(pitch.x), y: CGFloat(pitch.y))
            }
            if (currentPitch != nil) {
                PitchView(pitch: currentPitch!)
                    .position(x: CGFloat(currentPitch!.x), y: CGFloat(currentPitch!.y))
            }
            
            ZStack {
                if showPitchOptions {
                    HStack {
                        VStack(alignment: .trailing) {
                            //                            PitchOptionView(text: "Ball", colour: .blue, showPitchOptions: $showPitchOptions, pitchData: pitchData)
                            //
                            //                            PitchOptionView(text: "In Play", colour: .green, showPitchOptions: $showPitchOptions, pitchData: pitchData)
                            
                            //pitchResult: PitchResult, currentPitch: Pitch, currentAtBat: AtBat, showPitchOptions: Binding<Bool>
                            
                            ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Ball", action: {pitchOptionButton(pitchResult: .Ball, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}), hasSecondaryButtons: false, primaryColour: Color(red: 14/255, green: 41/255, blue: 213/255), secondaryColour: Color(red: 246/255, green: 81/255, blue: 81/255), showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                            
                            ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "In Play"), hasSecondaryButtons: true, primaryColour: Color(red: 26/255, green: 198/255, blue: 20/255), secondaryColour: Color(red: 246/255, green: 81/255, blue: 81/255), showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                        }
                        .padding(.trailing)
                        
                        VStack(alignment: .leading) {
                            //                            PitchOptionView(text: "Called Strike", colour: .orange, showPitchOptions: $showPitchOptions, pitchData: pitchData)
                            //                            PitchOptionView(text: "Swinging Strike", colour: .red, showPitchOptions: $showPitchOptions, pitchData: pitchData)
                            
                            ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Called Strike", action: {pitchOptionButton(pitchResult: .StrikeLooking, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}), hasSecondaryButtons: false, primaryColour: Color(red: 253/255, green: 150/255, blue: 10/255), secondaryColour: Color(red: 246/255, green: 81/255, blue: 81/255), showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                            
                            ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Swing Strike"), hasSecondaryButtons: true, primaryColour: Color(red: 213/255, green: 41/255, blue: 65/255), secondaryColour: Color(red: 246/255, green: 81/255, blue: 81/255), showPitchOptions: $showPitchOptions, currentPitch: $currentPitch, atBatManager: atBatManager, game: $game)
                            
                            
                        }
                    }
                    .position(x: CGFloat(currentPitch!.x), y: CGFloat(currentPitch!.y))
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .edgesIgnoringSafeArea(.all)
        
    }
}


class AtBatManager: ObservableObject {
    @Published var currentAtBat: AtBat? {
        didSet {
            self.currentPitcher = currentAtBat?.pitcherOfAtBat
            self.currentBatter = currentAtBat?.batterOfAtBat
            print("Current At Bat changed. Pitcher: \(self.currentPitcher?.name ?? "None"), Batter: \(self.currentBatter?.name ?? "None")")
            
        }
    }
    @Published var currentPitcher: Player?
    @Published var currentBatter: Player?
}


struct PitchSelectorView: View {
    
    @Environment(\.managedObjectContext) var managedObjContext
    @EnvironmentObject var dataController: DataController
    
    var colour = Color(red: 0, green: 0, blue: 0, opacity: 100)
    var pitchType: String
    @State private var offset = CGSize.zero
    @State private var cornerRadius = 10.0
    @State private var size = 40.0
    @State private var originalPosition: CGPoint = .zero
    @State private var showText = true
    @Binding var showPitchOptions: Bool
    var zStackFrame: CGRect
    
    @Binding var currentPitch: Pitch?
    
    @ObservedObject var atBatManager: AtBatManager
    
    
    var body: some View {
        ZStack {
            
            Rectangle()
                .frame(width: size, height: size, alignment: .center)
                .cornerRadius(cornerRadius)
                .foregroundColor((atBatManager.currentBatter == nil || atBatManager.currentPitcher == nil) ? .gray : colour)
                .offset(x: offset.width, y: offset.height)
                .gesture(
                    DragGesture(coordinateSpace: .global)
                        .onChanged { gesture in
                            // When the drag starts, store the original position
                            if offset == .zero {
                                originalPosition = gesture.startLocation
                            }
                            offset = gesture.translation
                            cornerRadius = 20.0
                            size = 20.0
                            showText = false
                            withAnimation(.interactiveSpring()) {
                                showPitchOptions = false
                            }
                            currentPitch = nil
                            
                        }
                        .onEnded { value in
                            if zStackFrame.contains(value.location) {
                                
                                currentPitch = Pitch(context: managedObjContext)
                                currentPitch!.x = Float(value.location.x)
                                currentPitch!.y = Float(value.location.y)
                                currentPitch?.pitchType = pitchType
                                currentPitch?.indexInAtBat = Int16(atBatManager.currentAtBat?.pitchesInAtBat?.count ?? 0) + 1
                                
                                withAnimation(.interactiveSpring()) {
                                    showPitchOptions = true
                                }
                            }
                            offset = .zero
                            cornerRadius = 10.0
                            size = 40.0
                            withAnimation {
                                showText = true
                            }
                        }
                )
                .animation(.interactiveSpring(), value: offset)
                .padding(.horizontal, 6)
                .disabled(atBatManager.currentBatter == nil || atBatManager.currentPitcher == nil)
            
            if showText {
                Text(pitchType)
                    .bold()
            }
        }
    }
}




func pitchTypeToColour(pitchType: String) -> Color {
    switch pitchType {
    case "FB":
        return Color(red: 115/255, green: 186/255, blue: 155/255)
    case "CH":
        return Color(red: 231/255, green: 111/255, blue: 81/255)
    case "CB":
        return Color(red: 84/255, green: 122/255, blue: 165/255)
    case "SL":
        return Color(red: 224/255, green: 212/255, blue: 45/255)
    case "SP":
        return Color(red: 214/255, green: 122/255, blue: 245/255)
    default:
        return Color.blue
    }
}

//struct PitchOptionView: View{
//    var text: String
//    var colour: Color
////    @Binding var currentPitch: PitchPosition?
////    @Binding var pitchPositions: [PitchPosition]
//    @Binding var showPitchOptions: Bool
//    @ObservedObject var pitchData: PitchData
//
//
//    var body: some View {
//        Button(action: {pitchOptionButton(button: text, pitchData: pitchData, showPitchOptions: $showPitchOptions)}) {
//            Text(text)
//                .bold()
//                .padding()
//                .background(colour)
//                .cornerRadius(20)
//                .foregroundColor(.white)
//
//        }
//    }
//}




struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        //        ContentView()
        //        PitchOptionView(text: "Ball", colour: Color.blue)
        //        PitchView(pitchType: "FB", pitchResult: .Whiff_2)
        //        ExpandablePitchOptionView(primaryButton: ExpandablePitchOptionItem(text: "Strike"), secondaryButtons: [ExpandablePitchOptionItem(text: "Whiff 1"), ExpandablePitchOptionItem(text: "Whiff 2"), ExpandablePitchOptionItem(text: "Whiff 3")], primaryColour: Color(red: 213/255, green: 41/255, blue: 65/255), secondaryColour: Color(red: 246/255, green: 81/255, blue: 81/255))
        
        
        
        // Fetch the first game from the context
        let fetchRequest: NSFetchRequest<Game> = Game.fetchRequest()
        let games = try? DataController.preview.container.viewContext.fetch(fetchRequest)
        let sampleGame = games?.first
        
        
        return ContentView(game: sampleGame!)
            .environment(\.managedObjectContext, DataController.preview.container.viewContext)
        
        
    }
}
