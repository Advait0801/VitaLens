//
//  ProfileViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/21/25.
//

import SwiftUI
internal import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var user: UserResponse?
    @Published var isLoading: Bool = false
    @Published var isLoggingOut: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authService = AuthService.shared
    private let keychainService = KeychainService.shared
    
    /// Load current user information
    func loadUserInfo() async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            user = try await authService.getCurrentUser()
            isLoading = false
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = "Failed to load user information"
            showError = true
        }
    }
    
    /// Logout user
    func logout() async {
        isLoggingOut = true
        errorMessage = nil
        showError = false
        
        do {
            // Call backend logout endpoint
            try await authService.logout()
            
            // Clear tokens from Keychain
            try keychainService.deleteAll()
            
            isLoggingOut = false
            
            // Notify AuthViewModel of logout
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
            
        } catch _ as AuthError {
            // Even if API call fails, clear local tokens
            try? keychainService.deleteAll()
            isLoggingOut = false
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        } catch {
            // Even if API call fails, clear local tokens
            try? keychainService.deleteAll()
            isLoggingOut = false
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        }
    }
}
