//
//  RegisterView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingLogin: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("VitaLens")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Register")
                .font(.title2)
            
            Spacer()
            
            Text("Register View - To be implemented")
            
            Spacer()
            
            Button(action: {
                showingLogin = true
            }) {
                Text("Already have an account? Login")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
