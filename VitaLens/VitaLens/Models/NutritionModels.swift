//
//  NutritionModels.swift
//  VitaLens
//
//  Created by Advait Naik on 12/20/25.
//

import Foundation

// MARK: - Daily Nutrition Response
struct DailyNutritionResponse: Codable {
    let date: String
    let nutrients: [NutrientData]
    let mealCount: Int
    
    enum CodingKeys: String, CodingKey {
        case date
        case nutrients
        case mealCount = "meal_count"
    }
}

// MARK: - Nutrient Data
struct NutrientData: Codable, Identifiable {
    var id: String { name }
    let name: String
    let value: Double?
    let total: Double?
    let averagePerDay: Double?
    let unit: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case value
        case total
        case averagePerDay = "average_per_day"
        case unit
    }
}

// MARK: - Nutrition Summary Response
struct NutritionSummaryResponse: Codable {
    let periodDays: Int
    let startDate: String
    let endDate: String
    let nutrients: [NutrientData]
    let totalMeals: Int
    
    enum CodingKeys: String, CodingKey {
        case periodDays = "period_days"
        case startDate = "start_date"
        case endDate = "end_date"
        case nutrients
        case totalMeals = "total_meals"
    }
}

// MARK: - Today's Nutrition Summary (for dashboard)
struct TodayNutritionSummary {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
    let fiber: Double?
    let mealCount: Int
    
    static let empty = TodayNutritionSummary(
        calories: 0,
        protein: 0,
        carbs: 0,
        fat: 0,
        fiber: nil,
        mealCount: 0
    )
}

// MARK: - Health Insights Response
struct HealthInsightsResponse: Codable {
    let periodDays: Int
    let nutrientSummary: [String: Double]
    let explanation: String
    let recommendations: String
    let disclaimer: String
    
    enum CodingKeys: String, CodingKey {
        case periodDays = "period_days"
        case nutrientSummary = "nutrient_summary"
        case explanation
        case recommendations
        case disclaimer
    }
}
