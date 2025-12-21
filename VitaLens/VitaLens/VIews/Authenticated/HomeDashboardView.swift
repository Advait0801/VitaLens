//
//  HomeDashboardView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct HomeDashboardView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = DashboardViewModel()
    
    // Daily goals (can be made configurable later)
    private let calorieGoal: Double = 2000
    private let proteinGoal: Double = 150
    private let carbGoal: Double = 250
    private let fatGoal: Double = 65
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Today's Summary")
                                .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .bold))
                                .foregroundColor(Colors.textPrimary)
                            
                            Text(getFormattedDate())
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        
                        // Key Metrics Cards
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 12)),
                                GridItem(.flexible(), spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 12))
                            ],
                            spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)
                        ) {
                            // Calories Card
                            MetricCard(
                                title: "Calories",
                                value: viewModel.formatNumber(viewModel.todaySummary.calories),
                                unit: "kcal",
                                icon: "flame.fill",
                                color: Colors.accent,
                                progress: viewModel.calculateProgress(value: viewModel.todaySummary.calories, goal: calorieGoal)
                            )
                            
                            // Protein Card
                            MetricCard(
                                title: "Protein",
                                value: viewModel.formatNumber(viewModel.todaySummary.protein),
                                unit: "g",
                                icon: "leaf.fill",
                                color: Colors.primary,
                                progress: viewModel.calculateProgress(value: viewModel.todaySummary.protein, goal: proteinGoal)
                            )
                            
                            // Carbs Card
                            MetricCard(
                                title: "Carbs",
                                value: viewModel.formatNumber(viewModel.todaySummary.carbs),
                                unit: "g",
                                icon: "cube.fill",
                                color: Colors.secondary,
                                progress: viewModel.calculateProgress(value: viewModel.todaySummary.carbs, goal: carbGoal)
                            )
                            
                            // Fat Card
                            MetricCard(
                                title: "Fat",
                                value: viewModel.formatNumber(viewModel.todaySummary.fat),
                                unit: "g",
                                icon: "drop.fill",
                                color: Colors.warning,
                                progress: viewModel.calculateProgress(value: viewModel.todaySummary.fat, goal: fatGoal)
                            )
                        }
                        
                        // Meal Count Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "fork.knife")
                                    .font(.title2)
                                    .foregroundColor(Colors.primary)
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meals Logged")
                                    .font(.subheadline)
                                    .foregroundColor(Colors.textSecondary)
                                
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(viewModel.todaySummary.mealCount)")
                                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 32 : 28, weight: .bold))
                                        .foregroundColor(Colors.textPrimary)
                                    
                                    Text("today")
                                        .font(.subheadline)
                                        .foregroundColor(Colors.textSecondary)
                                }
                            }
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Colors.surface)
                        .cornerRadius(16)
                        .shadow(color: Colors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 2)
                        
                        // Loading State
                        if viewModel.isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        // Error State
                        if viewModel.showError, let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(Colors.error)
                                .padding()
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
                    .padding(.bottom, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.background)
                .refreshable {
                    await viewModel.loadTodayNutrition()
                }
            }
            .navigationTitle("Dashboard")
            .task {
                await viewModel.loadTodayNutrition()
            }
        }
    }
    
    /// Get formatted date string
    private func getFormattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
}
