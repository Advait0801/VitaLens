//
//  ProfileView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        Text("Profile")
                            .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .semibold))
                            .foregroundColor(Colors.textPrimary)
                            .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        
                        Text("To be implemented")
                            .font(.body)
                            .foregroundColor(Colors.textSecondary)
                        
                        Button(action: {
                            authViewModel.logout()
                        }) {
                            Text("Logout")
                                .font(.body)
                                .foregroundColor(.white)
                                .padding(.vertical, LayoutHelper.adaptivePadding(horizontalSizeClass, base: 12))
                                .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass, base: 24))
                                .frame(maxWidth: LayoutHelper.isIPad(horizontalSizeClass) ? 300 : 200)
                                .background(Colors.error)
                                .cornerRadius(10)
                        }
                        .padding(.top, LayoutHelper.adaptiveSpacing(horizontalSizeClass))
                        .padding(.bottom, LayoutHelper.adaptivePadding(horizontalSizeClass))
                    }
                    .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.background)
            }
            .navigationTitle("Profile")
        }
    }
}
