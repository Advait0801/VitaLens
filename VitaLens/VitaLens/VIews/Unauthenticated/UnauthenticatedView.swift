//
//  UnauthenticatedView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct UnauthenticatedView: View {
    @State private var showingLogin = true
    
    var body: some View {
        NavigationStack {
            if showingLogin {
                LoginView(showingLogin: $showingLogin)
            } else {
                RegisterView(showingLogin: $showingLogin)
            }
        }
    }
}
