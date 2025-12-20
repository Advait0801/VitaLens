//
//  AuthModels.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation

// MARK: - Request Models
struct LoginRequest: Codable {
    let usernameOrEmail: String
    let password: String
    
    enum CodingKeys: String, CodingKey {
        case usernameOrEmail = "username_or_email"
        case password
    }
}

struct RegisterRequest: Codable {
    let email: String
    let username: String
    let password: String
}

struct RefreshTokenRequest: Codable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Response Models
struct TokenResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
    }
}

struct UserResponse: Codable {
    let id: Int
    let email: String
    let username: String
    let isActive: Bool
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case username
        case isActive = "is_active"
        case createdAt = "created_at"
    }
}
