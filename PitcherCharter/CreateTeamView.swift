//
//  CreateTeamView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-13.
//

import SwiftUI
import PhotosUI


struct CreateTeamView: View {
    
    @EnvironmentObject var dataController: DataController
    
    @Environment(\.managedObjectContext) var managedObjContext
    
    @State var teamName: String = ""
    @State var cityName: String = ""
    @State var teamLogo: Image?
    
    @State private var logoItem: PhotosPickerItem?
    @State private var logoImage: Image?
    @State private var uiLogoImage: UIImage?

    
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    HStack {
                        FormLabelView(title: "City Name", iconSystemName: "mappin.circle.fill", color: .blue)
                        TextField("Toronto", text: $cityName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                    }
                    HStack {
                        FormLabelView(title: "Team Name", iconSystemName: "pencil.circle.fill", color: .blue)
                        TextField("Varsity Blues", text: $teamName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                    }
                }
                
                Section {
                    HStack {
                        FormLabelView(title: "Team Logo", iconSystemName: "photo.circle.fill", color: .blue)
                            .padding(.trailing)
                        PhotosPicker("Select Team Logo", selection: $logoItem, matching: .images)
                        
                        if let logoImage {
                            logoImage
                                .resizable()
                                .scaledToFit()
                                .frame(width: 300, height: 300)
                            
                        }
                    }
                    .onChange(of: logoItem) { _ in
                        Task {
                            if let data = try? await logoItem?.loadTransferable(type: Data.self) {
                                if let uiImage = UIImage(data: data) {
                                    uiLogoImage = uiImage
                                    logoImage = Image(uiImage: uiImage)
                                    return
                                }
                            }
                            
                            print("Failed")
                        }
                    }
                }
                
                Button(action: {
                    // save code here
                    
                    if let logoImageData = uiLogoImage?.pngData() {
                        dataController.addTeam(cityName: cityName, teamName: teamName, logoData: logoImageData, context: managedObjContext)
                    } else {
                        dataController.addTeam(cityName: cityName, teamName: teamName, logoData: nil, context: managedObjContext)
                    }
                    self.presentationMode.wrappedValue.dismiss()
                    
                    
                    self.presentationMode.wrappedValue.dismiss()
                    
                }) {
                    Text("Save")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                }
                .listRowBackground(Color.blue)
            }
            .navigationTitle("Create Team")
        }
    }
}

struct CreateTeamView_Previews: PreviewProvider {
    static var previews: some View {
        CreateTeamView()
        
        
    }
}
