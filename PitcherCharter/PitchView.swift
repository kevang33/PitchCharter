//
//  PitchView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-07.
//

import SwiftUI

struct PitchView: View {
//    var pitchType: String
//    var pitchResult: PitchResult
    var pitch: Pitch

    
    var body: some View {
        ZStack {
            
            switch PitchResult(rawValue: pitch.pitchResult) ?? .Unknown {
            case PitchResult.Ball:
                Circle()
                    .stroke(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"), lineWidth: 3.0)
                    .frame(width: 25, height: 25)
                
            case PitchResult.Whiff_1:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 15.0)
                }
                
            case PitchResult.Whiff_2:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 15.0)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 19.0)
                }
                
            case PitchResult.Whiff_3:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 15.0)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 19.0)
                    Rectangle()
                        .foregroundColor(.black)
                        .frame(width: 25, height: 2)
                        .offset(y: 23.0)
                }
                
            case PitchResult.Barrel_1:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 31, height: 31)
                }
                
            case PitchResult.Barrel_2:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 31, height: 31)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 38, height: 38)
                }
                
            case PitchResult.Barrel_3:
                ZStack {
                    Circle()
                        .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                        .frame(width: 25, height: 25)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 31, height: 31)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 38, height: 38)
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 45, height: 45)
                }
                
            default:
                Circle()
                    .fill(pitchTypeToColour(pitchType: pitch.pitchType ?? "-"))
                    .frame(width: 25, height: 25)
            }
            
            
//            if pitchResult == PitchResult.Ball {
//                Circle()
//                    .stroke(pitchTypeToColour(pitchType: pitchType), lineWidth: 3.0)
//                    .frame(width: 25, height: 25)
//            }
//            else {
//                Circle()
//                    .fill(pitchTypeToColour(pitchType: pitchType))
//                    .frame(width: 25, height: 25)
//            }
            
            Text(pitch.pitchType ?? "-")
                .font(.caption)
                .bold()
            
            Text(String(pitch.indexInAtBat))
                .font(.system(size: 8))
                .offset(x: 0, y: 8)
            
        }
        
    }
}

struct PitchView_Previews: PreviewProvider {
    static var temporaryDataController = DataController(inMemory: true) // Use in-memory store for previews
    
    
    static var pitch1: Pitch {
        let pitch1 = Pitch(context: temporaryDataController.container.viewContext)
        pitch1.id = UUID()
        pitch1.pitchType = "FB"
        pitch1.indexInAtBat = 1
        pitch1.pitchResult = PitchResult.Barrel_2.rawValue
        return pitch1
    }
    
    
    static var previews: some View {
        PitchView(pitch: pitch1)
            .environment(\.managedObjectContext, temporaryDataController.container.viewContext)
    }
}
