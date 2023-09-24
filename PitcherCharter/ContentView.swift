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
                                    Text("#\(atBatManager.currentPitcher?.number ?? "")")
                                        .bold()
                                }
                            }
                            .disabled(atBatManager.currentAtBat == nil)
                            .sheet(isPresented: $showingPlayerSelectView) {
                                PlayerSelectView(awayTeam: game.awayTeamOfGame!, homeTeam: game.homeTeamOfGame!, isSheetPresented: $showingPlayerSelectView, selectedPlayer: $selectedPlayer)
                            }
                            .onChange(of: selectedPlayer) { selected in
                                if let player = selected {
                                    switch selectionContext {
                                    case .pitcher:
                                        atBatManager.currentAtBat?.pitcherOfAtBat = player
                                    case .batter:
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
                                    Text("#\(atBatManager.currentBatter?.number ?? "")")
                                        .bold()
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
                
                //                Text(atBatManager.currentAtBat?.id?.uuidString ?? "nil")
                //                Text(atBatManager.currentPitcher?.name ?? "Unknown")
                //                Text(atBatManager.currentBatter?.name ?? "Unknown")
                
                
                if atBatManager.currentAtBat != nil {
                    
                    ZStack {
                        Image("strikezone").resizable()
                            .padding(.horizontal, 75)
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
                        
                    }
                    
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
                        
                        
                    }) {
                        Text("New At Bat")
                            .bold()
                    }
                    .frame(height: 400)
                }
                
            }
            .onAppear {
                // If there are at-bats, set currentAtBat to the most recent one
                if let lastAtBat = sortedAtBats.last {
                    atBatManager.currentAtBat = lastAtBat
                }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //        .background(Color.red.opacity(0.10))
        .edgesIgnoringSafeArea(.all)
        
    }
}


//class PitchManager: ObservableObject {
//    @Published var pitchesInAtBat: [Pitch] = []
//    @Published var currentPitch: Pitch?
//}

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
    //    @Binding var pitchPositions: [PitchPosition]
    @State private var showText = true
    @Binding var showPitchOptions: Bool
    var zStackFrame: CGRect
    
    @Binding var currentPitch: Pitch?
    
    //    @ObservedObject var pitchData: PitchManager
    
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
                                //                                pitchData.currentPitch = Pitch(x: value.location.x, y: value.location.y, pitchType: pitchType)
                                
                                currentPitch = Pitch(context: managedObjContext)
                                currentPitch!.x = Float(value.location.x)
                                currentPitch!.y = Float(value.location.y)
                                currentPitch?.pitchType = pitchType
                                currentPitch?.indexInAtBat = Int16(atBatManager.currentAtBat?.pitchesInAtBat?.count ?? 0) + 1
                                
                                //                                pitchData.pitchPositions.append(pitchData.currentPitch!)
                                
                                //                                pitchPositions.append(pitchPos)
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
                ExpandablePitchOptionItem(text: "Whiff 1", action: {pitchOptionButton(pitchResult: .Whiff_1, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}),
                ExpandablePitchOptionItem(text: "Barrel 1", action: {pitchOptionButton(pitchResult: .Barrel_1, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}),
                ExpandablePitchOptionItem(text: "Whiff 2", action: {pitchOptionButton(pitchResult: .Whiff_2, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}),
                ExpandablePitchOptionItem(text: "Barrel 2", action: {pitchOptionButton(pitchResult: .Barrel_2, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}),
                ExpandablePitchOptionItem(text: "Whiff 3", action: {pitchOptionButton(pitchResult: .Whiff_3, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)}),
                ExpandablePitchOptionItem(text: "Barrel 3", action: {pitchOptionButton(pitchResult: .Barrel_3, currentPitch: currentPitch!, atBatManager: atBatManager, game: game, showPitchOptions: $showPitchOptions, dataController: dataController, context: managedObjContext)})
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
        
        let gridLayout: [GridItem] = Array(repeating: .init(.flexible()), count: 2)
        
        VStack {
            LazyVGrid(columns: gridLayout, spacing: 5) {
                
                if isExpanded {
                    ForEach(secondaryButtons.reversed()) { button in
                        Button(action: {
                            button.action?()
                        }, label: {
                            Text(button.text)
                                .foregroundColor(.white)
                                .bold()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                        })
                        .frame(width: self.size*2.2, height: self.size*1.5)
                        .background(secondaryColour)
                        .cornerRadius(10)
                    }
                }
            }
            
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 500.0, damping: 2000.0)){
                    self.isExpanded.toggle()
                }
                self.primaryButton.action?()
            }, label: {
                Text(self.primaryButton.text)
                    .foregroundColor(.white)
                    .bold()
                    .font(.title3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .offset(y: -3)
                
                
                
            })
            .frame(width: self.size*4, height: self.size)
            
            //                .background(primaryColour)
            
            
        }
        .background(primaryColour)
        .cornerRadius(cornerRadius)
        .shadow(radius: 5)
        .opacity(0.8)
    }
    
}

func pitchOptionButton(pitchResult: PitchResult, currentPitch: Pitch, atBatManager: AtBatManager, game: Game, showPitchOptions: Binding<Bool>, dataController: DataController, context: NSManagedObjectContext) {
    // Assign pitch result to the current pitch
    currentPitch.pitchResult = pitchResult.rawValue
    
    // Append the current pitch to the current at-bat's pitches
    //    atBatManager.currentAtBat?.addToPitchesInAtBat(currentPitch)
    
    currentPitch.pitcherOfPitch = atBatManager.currentPitcher
    currentPitch.batterOfPitch = atBatManager.currentBatter
    currentPitch.atBatOfPitch = atBatManager.currentAtBat
    currentPitch.gameOfPitch = game
    
    dataController.addPitch(pitch: currentPitch, context: context)
    
    // Hide pitch options
    withAnimation(.interactiveSpring()) {
        showPitchOptions.wrappedValue = false
    }
}


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
