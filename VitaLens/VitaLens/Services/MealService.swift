//
//  MealService.swift
//  VitaLens
//
//  Created by Advait Naik on 12/21/25.
//

import Foundation

enum MealError: LocalizedError {
    case invalidURL
    case invalidFile
    case invalidResponse
    case httpError(statusCode: Int, message: String?)
    case decodingError
    case networkError(Error)
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidFile:
            return "Invalid file selected"
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

class MealService {
    static let shared = MealService()
    private let keychainService = KeychainService.shared
    
    private init() {}
    
    /// Get access token for API requests
    private func getAuthHeader() throws -> String {
        guard let token = try? keychainService.get(forKey: "access_token") else {
            throw MealError.unauthorized
        }
        return "Bearer \(token)"
    }
    
    /// Upload meal file
    func uploadMeal(
        fileURL: URL,
        mealType: MealType = .other,
        mealDate: Date? = nil,
        progressHandler: @escaping (Double) -> Void = { _ in }
    ) async throws -> MealResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)/meals/upload") else {
            throw MealError.invalidURL
        }
        
        // Read file data
        let fileData: Data
        do {
            fileData = try Data(contentsOf: fileURL)
        } catch {
            throw MealError.invalidFile
        }
        
        // Get file name and extension
        let fileName = fileURL.lastPathComponent
        let fileExtension = (fileName as NSString).pathExtension.lowercased()
        
        // Validate file type
        let allowedExtensions = ["jpg", "jpeg", "png", "gif", "bmp", "pdf", "csv"]
        guard allowedExtensions.contains(fileExtension) else {
            throw MealError.invalidFile
        }
        
        // Determine MIME type
        let mimeType: String
        switch fileExtension {
        case "jpg", "jpeg":
            mimeType = "image/jpeg"
        case "png":
            mimeType = "image/png"
        case "gif":
            mimeType = "image/gif"
        case "bmp":
            mimeType = "image/bmp"
        case "pdf":
            mimeType = "application/pdf"
        case "csv":
            mimeType = "text/csv"
        default:
            mimeType = "application/octet-stream"
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(try getAuthHeader(), forHTTPHeaderField: "Authorization")
        
        var body = Data()
        
        // Add file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add meal_type
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"meal_type\"\r\n\r\n".data(using: .utf8)!)
        body.append(mealType.rawValue.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add meal_date if provided
        if let mealDate = mealDate {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let dateString = formatter.string(from: mealDate)
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"meal_date\"\r\n\r\n".data(using: .utf8)!)
            body.append(dateString.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        // Upload with progress tracking
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MealError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 401 {
                throw MealError.unauthorized
            }
            let errorMessage = try? JSONDecoder().decode([String: String].self, from: data)
            throw MealError.httpError(
                statusCode: httpResponse.statusCode,
                message: errorMessage?["detail"]
            )
        }
        
        do {
            return try JSONDecoder().decode(MealResponse.self, from: data)
        } catch {
            throw MealError.decodingError
        }
    }
}
