//
//  VisualEffectBlur.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI

// Universal Blur Effect (for iOS)
struct VisualEffectBlur: UIViewRepresentable {
    let style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

