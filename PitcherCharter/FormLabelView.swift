//
//  FormLabelView.swift
//  PitchCharter
//
//  Created by Kevin Angers on 2023-09-08.
//

import SwiftUI

struct FormLabelView: View {
    var title: String
    var iconSystemName: String
    var color: Color
    
    var body: some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: iconSystemName)
                .padding(4)
                .background(color)
                .cornerRadius(7)
                .foregroundColor(.white)
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        FormLabelView(title: "Sample Number", iconSystemName: "number", color: .blue)
    }
}
