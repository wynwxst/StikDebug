//
//  RoundedTextField.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI

struct RoundedTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .font(.system(.body, design: .rounded))
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .foregroundColor(.primary)
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(.tertiaryLabel), lineWidth: 0.5))
    }
}
