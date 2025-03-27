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
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            if isLoading {
                LoadingView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                isLoading = false
                            }
                        }
                        startProxy()
                        if FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            startHeartbeatInBackground()
                        }
                    }
            } else {
                MainTabView()
            }
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
                } else {
                    print("DEBUG: Failed to start em_proxy")
                }
            }
        }
    }
}


func startHeartbeatInBackground() {
    let heartBeat = Thread {
        startHeartbeat()
    }
    
    heartBeat.qualityOfService = .background
    heartBeat.name = "HeartBeat"
    heartBeat.start()
}


struct LoadingView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                ZStack {
                    Circle()
                        .stroke(lineWidth: 8)
                        .foregroundColor(Color.white.opacity(0.3))
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(AngularGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.3)]),
                            center: .center
                        ), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .rotationEffect(.degrees(animate ? 360 : 0))
                        .frame(width: 80, height: 80)
                        .animation(Animation.linear(duration: 1.2).repeatForever(autoreverses: false), value: animate)
                }
                .shadow(color: .white.opacity(0.5), radius: 10, x: 0, y: 0)
                .onAppear {
                    animate = true
                }

                Text("Loading...")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 20)
                    .opacity(animate ? 1.0 : 0.5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animate)
            }
        }
    }
}
