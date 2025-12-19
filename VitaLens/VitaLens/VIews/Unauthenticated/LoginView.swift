//
//  LoginView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Binding var showingLogin: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Text("VitaLens")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Login")
                .font(.title2)
            
            Spacer()
            
            Text("Login View - To be implemented")
            
            Spacer()
            
            Button(action: {
                showingLogin = false
            }) {
                Text("Don't have an account? Register")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
