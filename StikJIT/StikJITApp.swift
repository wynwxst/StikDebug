//
//  StikJITApp.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI
import em_proxy

@main
struct HeartbeatApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onAppear {
                    startProxy()
                    startHeartbeatInBackground()
                }
        }
    }
    
    func startHeartbeatInBackground() {
        DispatchQueue.global(qos: .background).async {
            startHeartbeat()
        }
    }
    func startProxy() {
        let port = 51820
        let bindAddr = "127.0.0.1:\(port)"
        
        DispatchQueue.global(qos: .background).async {
            let result = start_emotional_damage(bindAddr)

            DispatchQueue.main.async {
                if result == 0 {
                    print("DEBUG: em_proxy started successfully on port \(port)")
                    print("DEBUG: em_proxy started successfully on port \(port).")
                } else {
                    print("DEBUG: Failed to start em_proxy")
                    print("DEBUG: Failed to start em_proxy.")
                }
            }
        }
    }
}
