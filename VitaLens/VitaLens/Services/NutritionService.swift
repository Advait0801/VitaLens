//
//  NutritionService.swift
//  VitaLens
//
//  Created by Advait Naik on 12/20/25.
//

import Foundation

enum NutritionError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError
    case networkError(Error)
    case unauthorized
    
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
        case .unauthorized:
            return "Unauthorized. Please login again."
        }
    }
}

class NutritionService {
    static let shared = NutritionService()
    private let keychainService = KeychainService.shared
    
    private init() {}
    
    /// Get access token for API requests
    private func getAuthHeader() throws -> String {
        guard let token = try? keychainService.get(forKey: "access_token") else {
            throw NutritionError.unauthorized
        }
        return "Bearer \(token)"
    }
    
    /// Get daily nutrition for a specific date
    func getDailyNutrition(date: Date? = nil) async throws -> DailyNutritionResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/nutrition/daily") else {
            throw NutritionError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            components?.queryItems = [URLQueryItem(name: "target_date", value: formatter.string(from: date))]
        }
        
        guard let finalURL = components?.url else {
            throw NutritionError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(try getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NutritionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NutritionError.unauthorized
            }
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NutritionError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(DailyNutritionResponse.self, from: data)
        } catch {
            throw NutritionError.decodingError
        }
    }
    
    /// Get nutrition summary for the last N days
    func getNutritionSummary(days: Int = 7) async throws -> NutritionSummaryResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/nutrition/summary") else {
            throw NutritionError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "days", value: "\(days)")]
        
        guard let finalURL = components?.url else {
            throw NutritionError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(try getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NutritionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NutritionError.unauthorized
            }
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NutritionError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(NutritionSummaryResponse.self, from: data)
        } catch {
            throw NutritionError.decodingError
        }
    }
    
    /// Get health insights with LLM-generated explanations
    func getHealthInsights(days: Int = 7) async throws -> HealthInsightsResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/nutrition/insights") else {
            throw NutritionError.invalidURL
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "days", value: "\(days)")]
        
        guard let finalURL = components?.url else {
            throw NutritionError.invalidURL
        }
        
        var request = URLRequest(url: finalURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(try getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NutritionError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw NutritionError.unauthorized
            }
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw NutritionError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(HealthInsightsResponse.self, from: data)
        } catch {
            throw NutritionError.decodingError
        }
    }
}
