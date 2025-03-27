//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("bundleID") var bundleID: String = "com.stossy11.MeloNX"
    
    var body: some View {
        VStack(spacing: 20) {
            TextField("Enter Bundle ID", text: $bundleID)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: startJITInBackground) {
                Text("Enable Jit")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    func startJITInBackground() {
        DispatchQueue.global(qos: .background).async {
            guard let cBundleID = strdup(bundleID) else {
                return
            }
            
            var args: [UnsafeMutablePointer<Int8>?] = [cBundleID]
            let argc = Int32(args.count)
            
            args.withUnsafeMutableBufferPointer { buffer in
                _ = jitMain(argc, buffer.baseAddress)
            }
            
            free(cBundleID)
        }
    }
}

#Preview {
    HomeView()
}
