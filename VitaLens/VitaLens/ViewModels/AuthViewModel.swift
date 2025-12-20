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
    
    private let keychainService = KeychainService.shared
    
    private var loginObserver: NSObjectProtocol?
    private var logoutObserver: NSObjectProtocol?
    
    init() {
        // Check if user is already authenticated on app launch
        checkAuthenticationStatus()
        
        // Listen for login/logout notifications
        loginObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogin,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLogin()
        }
        
        logoutObserver = NotificationCenter.default.addObserver(
            forName: .userDidLogout,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleLogout()
        }
    }
    
    /// Handle successful login notification
    @MainActor
    private func handleLogin() {
        isAuthenticated = true
        errorMessage = nil
    }
    
    /// Handle logout notification
    @MainActor
    private func handleLogout() {
        isAuthenticated = false
        errorMessage = nil
    }
    
    deinit {
        if let loginObserver = loginObserver {
            NotificationCenter.default.removeObserver(loginObserver)
        }
        if let logoutObserver = logoutObserver {
            NotificationCenter.default.removeObserver(logoutObserver)
        }
    }
    
    /// Check if user has valid authentication tokens
    func checkAuthenticationStatus() {
        do {
            let _ = try keychainService.get(forKey: "access_token")
            // Token exists, user is authenticated
            isAuthenticated = true
        } catch {
            // No token found
            isAuthenticated = false
        }
    }
    
    /// Clear authentication and log out
    func logout() {
        do {
            try keychainService.deleteAll()
            isAuthenticated = false
            errorMessage = nil
            NotificationCenter.default.post(name: .userDidLogout, object: nil)
        } catch {
            errorMessage = "Failed to logout"
        }
    }
    
    /// Get stored access token
    func getAccessToken() -> String? {
        do {
            return try keychainService.get(forKey: "access_token")
        } catch {
            return nil
        }
    }
    
    /// Get stored refresh token
    func getRefreshToken() -> String? {
        do {
            return try keychainService.get(forKey: "refresh_token")
        } catch {
            return nil
        }
    }
}
