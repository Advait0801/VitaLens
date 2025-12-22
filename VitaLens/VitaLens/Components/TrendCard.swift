//
//  TrendCard.swift
//  VitaLens
//
//  Created by Advait Naik on 12/22/25.
//

import SwiftUI

struct TrendCard: View {
    let title: String
    let averageValue: String
    let totalValue: String
    let unit: String
    let icon: String
    let color: Color
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(Colors.textSecondary)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(averageValue)
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 28 : 24, weight: .bold))
                        .foregroundColor(Colors.textPrimary)
                    
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(Colors.textSecondary)
                }
                
                Text("Avg per day")
                    .font(.caption)
                    .foregroundColor(Colors.textSecondary)
                
                Text("Total: \(totalValue) \(unit)")
                    .font(.caption)
                    .foregroundColor(Colors.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
        .background(Colors.surface)
        .cornerRadius(16)
        .shadow(color: Colors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}
