//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        Button(action: startJITInBackground) {
            Text("Enable Jit")
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    func startJITInBackground() {
        DispatchQueue.global(qos: .background).async {
            jitMain()
        }
    }
}

#Preview {
    HomeView()
}
