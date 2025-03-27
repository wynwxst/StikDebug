//
//  DebugViewModel.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//

import SwiftUI
import em_proxy

// Debug View Model that calls the Swift bindings on startup.
class DebugViewModel: ObservableObject {
    @Published var status: String = "Initializing..."
    @Published var logs: [String] = []

    init() {
        startProxy()
    }

    func startProxy() {
        let port = 62078
        let bindAddr = "127.0.0.1:\(port)"
        
        DispatchQueue.global(qos: .background).async {
            DispatchQueue.main.async {
                self.status = "Starting em_proxy..."
                self.logs.append("Starting em_proxy on port \(port)...")
            }
            
            // Call the Swift binding that wraps the heartbeat functionality.
            let result = start_emotional_damage(bindAddr)

            DispatchQueue.main.async {
                if result == 0 {
                    self.status = "em_proxy started successfully on port \(port)"
                    self.logs.append("em_proxy started successfully on port \(port).")
                } else {
                    self.status = "Failed to start em_proxy"
                    self.logs.append("Failed to start em_proxy.")
                }
            }
        }
    }
}
