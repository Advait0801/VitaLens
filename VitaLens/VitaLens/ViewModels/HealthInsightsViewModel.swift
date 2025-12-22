//
//  HealthInsightsViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/22/25.
//

import SwiftUI
internal import Combine

@MainActor
class HealthInsightsViewModel: ObservableObject {
    @Published var insights: HealthInsightsResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedDays: Int = 7
    
    private let nutritionService = NutritionService.shared
    
    /// Load health insights
    func loadInsights() async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            insights = try await nutritionService.getHealthInsights(days: selectedDays)
            isLoading = false
        } catch let error as NutritionError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = "Failed to load health insights"
            showError = true
        }
    }
    
    /// Format number with commas
    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}
