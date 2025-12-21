//
//  DashboardViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/20/25.
//

import SwiftUI
internal import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var todaySummary: TodayNutritionSummary = .empty
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    private let nutritionService = NutritionService.shared
    
    /// Load today's nutrition data
    func loadTodayNutrition() async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            let response = try await nutritionService.getDailyNutrition()
            todaySummary = parseNutritionSummary(from: response)
            isLoading = false
        } catch let error as NutritionError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = "Failed to load nutrition data"
            showError = true
        }
    }
    
    /// Parse nutrition response into summary
    private func parseNutritionSummary(from response: DailyNutritionResponse) -> TodayNutritionSummary {
        var calories: Double = 0
        var protein: Double = 0
        var carbs: Double = 0
        var fat: Double = 0
        var fiber: Double?
        
        for nutrient in response.nutrients {
            let value = nutrient.value ?? 0
            let name = nutrient.name.lowercased()
            
            switch name {
            case "calories", "calorie", "energy":
                calories = value
            case "protein":
                protein = value
            case "carbohydrates", "carbs", "carbohydrate", "carb":
                carbs = value
            case "fat", "total fat", "total_fat":
                fat = value
            case "fiber", "dietary fiber", "dietary_fiber":
                fiber = value
            default:
                break
            }
        }
        
        return TodayNutritionSummary(
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            fiber: fiber,
            mealCount: response.mealCount
        )
    }
    
    /// Format number with commas
    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    /// Calculate progress percentage (assuming daily goals)
    func calculateProgress(value: Double, goal: Double) -> Double {
        guard goal > 0 else { return 0 }
        return min(value / goal, 1.0)
    }
}
