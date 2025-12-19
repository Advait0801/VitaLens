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
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                    Text("VitaLens")
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 48 : 34, weight: .bold))
                        .foregroundColor(Colors.primary)
                        .padding(.top, LayoutHelper.isIPad(horizontalSizeClass) ? 60 : 40)
                    
                    Text("Register")
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 28 : 22))
                        .foregroundColor(Colors.textSecondary)
                    
                    Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 40))
                    
                    Text("Register View - To be implemented")
                        .font(.body)
                        .foregroundColor(Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 40))
                    
                    Button(action: {
                        showingLogin = true
                    }) {
                        Text("Already have an account? Login")
                            .font(.body)
                            .foregroundColor(Colors.primary)
                    }
                    .padding(.bottom, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Colors.background)
        }
    }
}
