//
//  MealModels.swift
//  VitaLens
//
//  Created by Advait Naik on 12/21/25.
//

import Foundation

// MARK: - Meal Type
enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snack: return "Snack"
        case .other: return "Other"
        }
    }
}

// MARK: - Meal Response
struct MealResponse: Codable {
    let id: Int
    let userId: Int
    let mealType: MealType
    let sourceType: String
    let sourceFilePath: String?
    let rawText: String?
    let foodItems: [FoodItemResponse]
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case mealType = "meal_type"
        case sourceType = "source_type"
        case sourceFilePath = "source_file_path"
        case rawText = "raw_text"
        case foodItems = "food_items"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Food Item Response
struct FoodItemResponse: Codable {
    let id: Int
    let name: String
    let normalizedName: String?
    let quantity: Double?
    let unit: String?
    let brand: String?
    let barcode: String?
    let description: String?
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case normalizedName = "normalized_name"
        case quantity
        case unit
        case brand
        case barcode
        case description
        case createdAt = "created_at"
    }
}
