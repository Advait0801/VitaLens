//
//  NutrientsTrendViewModel.swift
//  VitaLens
//
//  Created by Advait Naik on 12/22/25.
//

import SwiftUI
internal import Combine

@MainActor
class NutritionTrendsViewModel: ObservableObject {
    @Published var summary: NutritionSummaryResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var selectedDays: Int = 7
    
    private let nutritionService = NutritionService.shared
    
    /// Load nutrition summary for trends
    func loadSummary() async {
        isLoading = true
        errorMessage = nil
        showError = false
        
        do {
            summary = try await nutritionService.getNutritionSummary(days: selectedDays)
            isLoading = false
        } catch let error as NutritionError {
            isLoading = false
            errorMessage = error.errorDescription
            showError = true
        } catch {
            isLoading = false
            errorMessage = "Failed to load nutrition trends"
            showError = true
        }
    }
    
    /// Get nutrient value by name
    func getNutrientValue(name: String) -> Double? {
        return summary?.nutrients.first { $0.name.lowercased() == name.lowercased() }?.averagePerDay
    }
    
    /// Format number with commas
    func formatNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = value >= 1000 ? 0 : 1
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
    
    /// Get period date range string
    func getPeriodRange() -> String {
        guard let summary = summary else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        if let startDate = parseDate(summary.startDate),
           let endDate = parseDate(summary.endDate) {
            return "\(formatter.string(from: startDate)) - \(formatter.string(from: endDate))"
        }
        return ""
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
}
