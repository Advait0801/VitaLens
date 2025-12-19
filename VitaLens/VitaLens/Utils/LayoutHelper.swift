//
//  LayoutHelper.swift
//  VitaLens
//
//  Created by Advait Naik on 12/19/25.
//

import SwiftUI

/// Helper for adaptive layouts based on size classes and device type
struct LayoutHelper {
    /// Check if device is iPad based on horizontal size class
    static func isIPad(_ horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }
    
    /// Get adaptive spacing based on device type
    static func adaptiveSpacing(_ horizontalSizeClass: UserInterfaceSizeClass?, base: CGFloat = 20) -> CGFloat {
        isIPad(horizontalSizeClass) ? base * 1.5 : base
    }
    
    /// Get adaptive padding based on device type
    static func adaptivePadding(_ horizontalSizeClass: UserInterfaceSizeClass?, base: CGFloat = 16) -> CGFloat {
        isIPad(horizontalSizeClass) ? base * 2 : base
    }
    
    /// Get adaptive font size multiplier
    static func adaptiveFontMultiplier(_ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        isIPad(horizontalSizeClass) ? 1.2 : 1.0
    }
    
    /// Get max content width for iPad (centered layout)
    static func maxContentWidth(_ geometry: GeometryProxy, _ horizontalSizeClass: UserInterfaceSizeClass?) -> CGFloat {
        if isIPad(horizontalSizeClass) {
            return min(geometry.size.width * 0.7, 800)
        }
        return geometry.size.width
    }
}
