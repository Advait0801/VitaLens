//
//  AuthViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI
internal import Combine

/// ViewModel managing authentication state for the app
@MainActor
class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let tokenKey = "auth_access_token"
    private let refreshTokenKey = "auth_refresh_token"
    
    init() {
        // Check if user is already authenticated on app launch
        checkAuthenticationStatus()
    }
    
    /// Check if user has valid authentication tokens
    func checkAuthenticationStatus() {
        if let _ = UserDefaults.standard.string(forKey: tokenKey) {
            // TODO: Validate token with backend
            isAuthenticated = true
        } else {
            isAuthenticated = false
        }
    }
    
    /// Set authentication state after successful login
    func setAuthenticated(accessToken: String, refreshToken: String) {
        UserDefaults.standard.set(accessToken, forKey: tokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        isAuthenticated = true
        errorMessage = nil
    }
    
    /// Clear authentication and log out
    func logout() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        isAuthenticated = false
        errorMessage = nil
    }
    
    /// Get stored access token
    func getAccessToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    /// Get stored refresh token
    func getRefreshToken() -> String? {
        return UserDefaults.standard.string(forKey: refreshTokenKey)
    }
}
