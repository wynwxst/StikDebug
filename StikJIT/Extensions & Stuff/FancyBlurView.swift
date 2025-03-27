//
//  FancyBlurView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI

// Custom Blur Effect for macOS/iOS
struct FancyBlurView: View {
    var body: some View {
        #if os(macOS)
        VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
        #else
        VisualEffectBlur(style: .systemUltraThinMaterial)
        #endif
    }
}
