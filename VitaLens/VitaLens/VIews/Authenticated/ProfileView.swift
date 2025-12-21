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
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showLogoutConfirmation: Bool = false
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        // Profile Header
                        VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)) {
                            // Avatar
                            Circle()
                                .fill(Colors.primary.opacity(0.2))
                                .frame(width: LayoutHelper.isIPad(horizontalSizeClass) ? 120 : 100, height: LayoutHelper.isIPad(horizontalSizeClass) ? 120 : 100)
                                .overlay(
                                    Text(viewModel.user?.username.prefix(1).uppercased() ?? "U")
                                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 48 : 40, weight: .bold))
                                        .foregroundColor(Colors.primary)
                                )
                            
                            // User Info
                            if let user = viewModel.user {
                                VStack(spacing: 8) {
                                    Text(user.username)
                                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 28 : 24, weight: .bold))
                                        .foregroundColor(Colors.textPrimary)
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(Colors.textSecondary)
                                    
                                    if let createdAt = parseDate(user.createdAt) {
                                        Text("Member since \(formatDate(createdAt))")
                                            .font(.caption)
                                            .foregroundColor(Colors.textSecondary)
                                    }
                                }
                            } else if viewModel.isLoading {
                                ProgressView()
                                    .padding()
                            } else {
                                Text("Loading user information...")
                                    .font(.body)
                                    .foregroundColor(Colors.textSecondary)
                            }
                        }
                        .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        .frame(maxWidth: .infinity)
                        
                        // Error Message
                        if viewModel.showError, let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Colors.error)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                        
                        Spacer(minLength: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 40))
                        
                        // Logout Button
                        Button(action: {
                            showLogoutConfirmation = true
                        }) {
                            HStack {
                                if viewModel.isLoggingOut {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.right.square")
                                    Text("Logout")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Colors.error)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(viewModel.isLoggingOut)
                        .frame(maxWidth: LayoutHelper.isIPad(horizontalSizeClass) ? 400 : .infinity)
                        .padding(.bottom, LayoutHelper.adaptivePadding(horizontalSizeClass))
                    }
                    .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.background)
                .alert("Logout", isPresented: $showLogoutConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Logout", role: .destructive) {
                        Task {
                            await viewModel.logout()
                        }
                    }
                } message: {
                    Text("Are you sure you want to logout?")
                }
            }
            .navigationTitle("Profile")
            .task {
                await viewModel.loadUserInfo()
            }
        }
    }
    
    /// Parse date string from API
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    /// Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
