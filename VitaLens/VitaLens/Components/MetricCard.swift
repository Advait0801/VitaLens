//
//  MetricCard.swift
//  VitaLens
//
//  Created by Advait Naik on 12/20/25.
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    let progress: Double? // Optional progress value (0.0 to 1.0)
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Colors.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(size: LayoutHelper.isIPad(horizontalSizeClass) ? 32 : 28, weight: .bold))
                        .foregroundColor(Colors.textPrimary)
                    
                    Text(unit)
                        .font(.subheadline)
                        .foregroundColor(Colors.textSecondary)
                }
            }
            
            if let progress = progress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Colors.surface)
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(color)
                            .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(LayoutHelper.adaptivePadding(horizontalSizeClass, base: 16))
        .background(Colors.surface)
        .cornerRadius(16)
        .shadow(color: Colors.textSecondary.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}
