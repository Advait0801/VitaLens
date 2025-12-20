//
//  LoginViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
class LoginViewModel: ObservableObject {
    @Published var usernameOrEmail: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authService = AuthService.shared
    private let keychainService = KeychainService.shared
    
    /// Validate login form
    func validate() -> Bool {
        errorMessage = nil
        
        if usernameOrEmail.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Username or email is required"
            showError = true
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Password is required"
            showError = true
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return false
        }
        
        return true
    }
    
    /// Perform login
    func login() async {
        guard validate() else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let tokenResponse = try await authService.login(
                usernameOrEmail: usernameOrEmail.trimmingCharacters(in: .whitespaces),
                password: password
            )
            
            // Store tokens securely in Keychain
            try keychainService.save(tokenResponse.accessToken, forKey: "access_token")
            try keychainService.save(tokenResponse.refreshToken, forKey: "refresh_token")
            
            isLoading = false
            
            // Notify AuthViewModel of successful login
            NotificationCenter.default.post(name: .userDidLogin, object: nil)
            
        } catch let error as AuthError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = "An unexpected error occurred"
            showError = true
        }
    }
}
