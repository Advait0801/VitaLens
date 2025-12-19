//
//  AuthenticatedView.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            MealUploadView()
                .tabItem {
                    Label("Upload", systemImage: "plus.circle.fill")
                }
            
            NutritionSummaryView()
                .tabItem {
                    Label("Nutrition", systemImage: "chart.bar.fill")
                }
            
            HealthInsightsView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.blue)
    }
}
