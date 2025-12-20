//
//  APIConfig.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import Foundation

struct APIConfig {
    // TODO: Update this to your backend URL
    // For local development with Docker: http://localhost:8000
    // For iOS Simulator: http://localhost:8000
    // For physical device: http://[YOUR_COMPUTER_IP]:8000
    static let baseURL = "http://localhost:8000"
    
    static var authURL: String {
        "\(baseURL)/auth"
    }
}
