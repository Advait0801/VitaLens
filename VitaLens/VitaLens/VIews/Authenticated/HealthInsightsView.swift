//
//  HealthInsightsView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct HealthInsightsView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @StateObject private var viewModel = HealthInsightsViewModel()
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Health Insights")
                                .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .bold))
                                .foregroundColor(Colors.textPrimary)
                            
                            Text("AI-powered analysis of your nutrition")
                                .font(.subheadline)
                                .foregroundColor(Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        
                        // Period Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Analysis Period")
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
                                    await viewModel.loadInsights()
                                }
                            }
                        }
                        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                        .background(Colors.surface)
                        .cornerRadius(16)
                        
                        // Loading State
                        if viewModel.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                Text("Generating insights...")
                                    .font(.caption)
                                    .foregroundColor(Colors.textSecondary)
                            }
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
                        
                        // Insights Content
                        if let insights = viewModel.insights {
                            // Explanation Section
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(Colors.accent)
                                    Text("Analysis")
                                        .font(.headline)
                                        .foregroundColor(Colors.textPrimary)
                                }
                                
                                Text(insights.explanation)
                                    .font(.body)
                                    .foregroundColor(Colors.textPrimary)
                                    .lineSpacing(4)
                            }
                            .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                            .background(Colors.surface)
                            .cornerRadius(16)
                            
                            // Recommendations Section
                            if !insights.recommendations.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Colors.success)
                                        Text("Recommendations")
                                            .font(.headline)
                                            .foregroundColor(Colors.textPrimary)
                                    }
                                    
                                    Text(insights.recommendations)
                                        .font(.body)
                                        .foregroundColor(Colors.textPrimary)
                                        .lineSpacing(4)
                                }
                                .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                                .background(Colors.surface)
                                .cornerRadius(16)
                            }
                            
                            // Nutrient Summary
                            if !insights.nutrientSummary.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Nutrient Summary")
                                        .font(.headline)
                                        .foregroundColor(Colors.textPrimary)
                                    
                                    ForEach(Array(insights.nutrientSummary.keys.sorted()), id: \.self) { key in
                                        if let value = insights.nutrientSummary[key] {
                                            HStack {
                                                Text(key.capitalized)
                                                    .font(.body)
                                                    .foregroundColor(Colors.textPrimary)
                                                
                                                Spacer()
                                                
                                                Text(viewModel.formatNumber(value))
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(Colors.primary)
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                }
                                .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
                                .background(Colors.surface)
                                .cornerRadius(16)
                            }
                            
                            // Disclaimer
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(Colors.warning)
                                    Text("Disclaimer")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Colors.textPrimary)
                                }
                                
                                Text(insights.disclaimer)
                                    .font(.caption)
                                    .foregroundColor(Colors.textSecondary)
                                    .lineSpacing(2)
                            }
                            .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 12))
                            .background(Colors.warning.opacity(0.1))
                            .cornerRadius(12)
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
                    await viewModel.loadInsights()
                }
            }
            .navigationTitle("Insights")
            .task {
                await viewModel.loadInsights()
            }
        }
    }
}
