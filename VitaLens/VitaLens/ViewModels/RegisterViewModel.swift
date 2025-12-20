//
//  RegisterViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation
import SwiftUI
internal import Combine

@MainActor
class RegisterViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let authService = AuthService.shared
    private let keychainService = KeychainService.shared
    
    /// Validate registration form
    func validate() -> Bool {
        errorMessage = nil
        
        // Email validation
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Email is required"
            showError = true
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            showError = true
            return false
        }
        
        // Username validation
        if username.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Username is required"
            showError = true
            return false
        }
        
        if username.count < 3 {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return false
        }
        
        // Password validation
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
        
        // Confirm password validation
        if confirmPassword.isEmpty {
            errorMessage = "Please confirm your password"
            showError = true
            return false
        }
        
        if password != confirmPassword {
            errorMessage = "Passwords do not match"
            showError = true
            return false
        }
        
        return true
    }
    
    /// Perform registration
    func register() async {
        guard validate() else { return }
        
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let _ = try await authService.register(
                email: email.trimmingCharacters(in: .whitespaces).lowercased(),
                username: username.trimmingCharacters(in: .whitespaces),
                password: password
            )
            
            // After successful registration, automatically login
            let tokenResponse = try await authService.login(
                usernameOrEmail: email.trimmingCharacters(in: .whitespaces).lowercased(),
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
    
    /// Validate email format
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
