//
//  DebugView.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI

struct DebugView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Welcome to StikJIT")
                .font(.largeTitle)
                .bold()
                .padding()

            Text("Use the Debug tab to monitor the logs.")
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    DebugView()
}
