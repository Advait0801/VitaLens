//
//  RootView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct RootView: View {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                AuthenticatedView()
                    .environmentObject(authViewModel)
            } else {
                UnauthenticatedView()
                    .environmentObject(authViewModel)
            }
        }
        .background(Colors.background)
        .animation(.easeInOut, value: authViewModel.isAuthenticated)
    }
}
