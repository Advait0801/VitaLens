//
//  NutritionSummaryView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct NutritionSummaryView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = NutritionTrendsViewModel()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nutrition Trends")
                                .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .bold))
                                .foregroundColor(Colors.textPrimary)
                            
                            if !viewModel.getPeriodRange().isEmpty {
                                Text(viewModel.getPeriodRange())
                                    .font(.subheadline)
                                    .foregroundColor(Colors.textSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        
                        // Period Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Time Period")
                                .font(.headline)
                                .foregroundColor(Colors.textPrimary)
                            
                            Picker("Days", selection: $viewModel.selectedDays) {
                                Text("7 Days").tag(7)
                                Text("14 Days").tag(14)
                                Text("30 Days").tag(30)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: viewModel.selectedDays) { _ in
                                Task {
                                    await viewModel.loadSummary()
                                }
                            }
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .background(Colors.surface)
                        .cornerRadius(16)
                        
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
                                .frame(maxWidth: .infinity)
                                .background(Colors.error.opacity(0.1))
                                .cornerRadius(12)
                        }
                        
                        // Nutrition Trends Cards
                        if let summary = viewModel.summary {
                            // Key Nutrients Grid
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 12)),
                                    GridItem(.flexible(), spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 12))
                                ],
                                spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass, base: 16)
                            ) {
                                // Calories
                                if let calories = viewModel.getNutrientValue(name: "calories") {
                                    TrendCard(
                                        title: "Calories",
                                        averageValue: viewModel.formatNumber(calories),
                                        totalValue: viewModel.formatNumber(calories * Double(summary.periodDays)),
                                        unit: "kcal",
                                        icon: "flame.fill",
                                        color: Colors.accent
                                    )
                                }
                                
                                // Protein
                                if let protein = viewModel.getNutrientValue(name: "protein") {
                                    TrendCard(
                                        title: "Protein",
                                        averageValue: viewModel.formatNumber(protein),
                                        totalValue: viewModel.formatNumber(protein * Double(summary.periodDays)),
                                        unit: "g",
                                        icon: "leaf.fill",
                                        color: Colors.primary
                                    )
                                }
                                
                                // Carbs
                                if let carbs = viewModel.getNutrientValue(name: "carbohydrates") ?? viewModel.getNutrientValue(name: "carbs") {
                                    TrendCard(
                                        title: "Carbs",
                                        averageValue: viewModel.formatNumber(carbs),
                                        totalValue: viewModel.formatNumber(carbs * Double(summary.periodDays)),
                                        unit: "g",
                                        icon: "cube.fill",
                                        color: Colors.secondary
                                    )
                                }
                                
                                // Fat
                                if let fat = viewModel.getNutrientValue(name: "fat") {
                                    TrendCard(
                                        title: "Fat",
                                        averageValue: viewModel.formatNumber(fat),
                                        totalValue: viewModel.formatNumber(fat * Double(summary.periodDays)),
                                        unit: "g",
                                        icon: "drop.fill",
                                        color: Colors.warning
                                    )
                                }
                            }
                            
                            // All Nutrients List
                            if !summary.nutrients.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("All Nutrients")
                                        .font(.headline)
                                        .foregroundColor(Colors.textPrimary)
                                    
                                    ForEach(summary.nutrients, id: \.name) { nutrient in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(nutrient.name.capitalized)
                                                    .font(.body)
                                                    .foregroundColor(Colors.textPrimary)
                                                
                                                Text("\(viewModel.formatNumber(nutrient.averagePerDay ?? 0)) \(nutrient.unit) per day")
                                                    .font(.caption)
                                                    .foregroundColor(Colors.textSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Text("Total: \(viewModel.formatNumber(nutrient.total ?? 0))")
                                                .font(.caption)
                                                .foregroundColor(Colors.textSecondary)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Colors.surface)
                                        .cornerRadius(8)
                                    }
                                }
                                .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                                .background(Colors.surface)
                                .cornerRadius(16)
                            }
                            
                            // Summary Stats
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Total Meals")
                                        .font(.caption)
                                        .foregroundColor(Colors.textSecondary)
                                    Text("\(summary.totalMeals)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Colors.textPrimary)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("Period")
                                        .font(.caption)
                                        .foregroundColor(Colors.textSecondary)
                                    Text("\(summary.periodDays) days")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Colors.textPrimary)
                                }
                            }
                            .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                            .background(Colors.surface)
                            .cornerRadius(16)
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
                    await viewModel.loadSummary()
                }
            }
            .navigationTitle("Nutrition")
            .task {
                await viewModel.loadSummary()
            }
        }
    }
}
