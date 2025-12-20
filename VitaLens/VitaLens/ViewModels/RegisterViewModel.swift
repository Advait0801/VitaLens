//
//  RegisterViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

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
    
    /// Validate registration form field by field
    func validateField(_ field: ValidationField) -> String? {
        switch field {
        case .email:
            if email.trimmingCharacters(in: .whitespaces).isEmpty {
                return "Email is required"
            }
            if !isValidEmail(email) {
                return "Please enter a valid email address"
            }
            return nil
        case .username:
            if username.trimmingCharacters(in: .whitespaces).isEmpty {
                return "Username is required"
            }
            if username.count < 3 {
                return "Username must be at least 3 characters"
            }
            return nil
        case .password:
            if password.isEmpty {
                return "Password is required"
            }
            if password.count < 6 {
                return "Password must be at least 6 characters"
            }
            return nil
        case .confirmPassword:
            if confirmPassword.isEmpty {
                return "Please confirm your password"
            }
            if password != confirmPassword {
                return "Passwords do not match"
            }
            return nil
        }
    }
    
    /// Validate all fields
    func validate() -> Bool {
        errorMessage = nil
        
        if let error = validateField(.email) {
            errorMessage = error
            showError = true
            return false
        }
        
        if let error = validateField(.username) {
            errorMessage = error
            showError = true
            return false
        }
        
        if let error = validateField(.password) {
            errorMessage = error
            showError = true
            return false
        }
        
        if let error = validateField(.confirmPassword) {
            errorMessage = error
            showError = true
            return false
        }
        
        return true
    }
    
    enum ValidationField {
        case email
        case username
        case password
        case confirmPassword
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
