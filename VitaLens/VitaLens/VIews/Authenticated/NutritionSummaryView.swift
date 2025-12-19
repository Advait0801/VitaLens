//
//  NutritionSummaryView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct NutritionSummaryView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: LayoutHelper.adaptiveSpacing(horizontalSizeClass)) {
                        Text("Nutrition Summary")
                            .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 36 : 28, weight: .semibold))
                            .foregroundColor(Colors.textPrimary)
                            .padding(.top, LayoutHelper.adaptivePadding(horizontalSizeClass))
                        
                        Text("To be implemented")
                            .font(.body)
                            .foregroundColor(Colors.textSecondary)
                    }
                    .frame(maxWidth: LayoutHelper.maxContentWidth(geometry, horizontalSizeClass))
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, LayoutHelper.adaptivePadding(horizontalSizeClass))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Colors.background)
            }
            .navigationTitle("Nutrition")
        }
    }
}
