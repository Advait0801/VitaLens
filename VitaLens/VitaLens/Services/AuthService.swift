//
//  AuthService.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation

enum AuthError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, let message):
            return message ?? "Server error (Status: \(statusCode))"
        case .decodingError:
            return "Failed to decode response"
        case .networkError(let error):
            return error.localizedDescription
        }
    }
}

class AuthService {
    static let shared = AuthService()
    
    private init() {}
    
    /// Register a new user
    func register(email: String, username: String, password: String) async throws -> UserResponse {
        guard let url = URL(string: "\(APIConfig.authURL)/register") else {
            throw AuthError.invalidURL
        }
        
        let request = RegisterRequest(email: email, username: username, password: password)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw AuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(UserResponse.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }
    
    /// Login with username/email and password
    func login(usernameOrEmail: String, password: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(APIConfig.authURL)/login") else {
            throw AuthError.invalidURL
        }
        
        let request = LoginRequest(usernameOrEmail: usernameOrEmail, password: password)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw AuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }
    
    /// Refresh access token
    func refreshToken(refreshToken: String) async throws -> TokenResponse {
        guard let url = URL(string: "\(APIConfig.authURL)/refresh") else {
            throw AuthError.invalidURL
        }
        
        let request = RefreshTokenRequest(refreshToken: refreshToken)
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw AuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(TokenResponse.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }
    
    /// Logout - calls backend logout endpoint
    func logout() async throws {
        guard let url = URL(string: "\(APIConfig.authURL)/logout") else {
            throw AuthError.invalidURL
        }
        
        guard let token = try? KeychainService.shared.get(forKey: "access_token") else {
            // No token to logout, consider it successful
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        // Accept 200-299 and 401 (unauthorized means token already invalid)
        guard (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 401 else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: Data())
            throw AuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
    }
    
    /// Get current user information
    func getCurrentUser() async throws -> UserResponse {
        guard let url = URL(string: "\(APIConfig.authURL)/me") else {
            throw AuthError.invalidURL
        }
        
        guard let token = try? KeychainService.shared.get(forKey: "access_token") else {
            throw AuthError.httpError(statusCode: 401, message: "Not authenticated")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw AuthError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(UserResponse.self, from: data)
        } catch {
            throw AuthError.decodingError
        }
    }
}
