//
//  DebugView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI

// Debug View displaying status and logs.
struct DebugView: View {
    @StateObject private var viewModel = DebugViewModel()

    var body: some View {
        VStack(spacing: 15) {
            Text("StikJIT Debug Panel")
                .font(.title)
                .bold()
                .foregroundColor(.primary)
                .padding(.top)

            HStack {
                Circle()
                    .fill(viewModel.status.contains("successfully") ? Color.green : viewModel.status.contains("Failed") ? Color.red : Color.yellow)
                    .frame(width: 14, height: 14)

                Text(viewModel.status)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 5)

            Divider()
                .background(Color.secondary.opacity(0.3))

            ScrollView {
                VStack(alignment: .leading, spacing: 5) {
                    ForEach(viewModel.logs, id: \.self) { log in
                        Text(log)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 300)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6).opacity(0.5)))
            .padding()

            Button(action: {
                viewModel.startProxy()
            }) {
                Label("Restart Proxy", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .frame(width: 420, height: 500)
        .background(
            FancyBlurView()
                .cornerRadius(15)
                .shadow(radius: 10)
        )
        .padding()
    }
}
