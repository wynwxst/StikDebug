//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("bundleID") private var bundleID: String = "com.stossy11.MeloNX"
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("StikJIT")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Enter the app's Bundle ID and enable JIT.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                RoundedTextField(placeholder: "Enter Bundle ID", text: $bundleID)
                    .padding(.horizontal, 20)
                Button(action: {
                    HapticFeedbackHelper.trigger()
                    startJITInBackground()
                }) {
                    Label(isProcessing ? "Enabling..." : "Enable JIT", systemImage: isProcessing ? "hourglass" : "bolt.fill")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isProcessing ? Color.gray.opacity(0.6) : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        .animation(.easeInOut(duration: 0.2), value: isProcessing)
                }
                .disabled(isProcessing)
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
        }
    }
    
    private func startJITInBackground() {
        isProcessing = true
        DispatchQueue.global(qos: .background).async {
            guard let cBundleID = strdup(bundleID) else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            
            var args: [UnsafeMutablePointer<Int8>?] = [cBundleID]
            let argc = Int32(args.count)
            
            args.withUnsafeMutableBufferPointer { buffer in
                _ = jitMain(argc, buffer.baseAddress)
            }
            
            free(cBundleID)
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

#Preview {
    HomeView()
}
