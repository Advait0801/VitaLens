//
//  ProfileView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Profile")
                    .font(.title)
                
                Text("To be implemented")
                
                Button(action: {
                    authViewModel.logout()
                }) {
                    Text("Logout")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(.red)
                        .cornerRadius(10)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Profile")
        }
    }
}
