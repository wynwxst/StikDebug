//
//  ConsoleLogsView.swift
//  StikJIT
//
//  Created by neoarz on 3/29/25.
//

import SwiftUI
import UIKit

struct ConsoleLogsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var dummyLogs: [String] = [
        "Initializing StikJIT environment...",
        "Checking device compatibility...",
        "Loading system configuration...",
        "Verifying device permissions...",
        "Initializing JIT compiler...",
        "Loading pairing credentials...",
        "Configuration loaded successfully",
        "System check completed",
        "Ready for operation"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Terminal-style logs area
                    ScrollView {
                        VStack(spacing: 2) {
                            // Device Information
                            ForEach(["Version: \(UIDevice.current.systemVersion)",
                                     "Name: \(UIDevice.current.name)",
                                     "Model: \(UIDevice.current.model)",
                                     "StikJIT: 1.0"], id: \.self) { info in
                                HStack {
                                    Text("[\(timeString())]")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 12, design: .monospaced))
                                    
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 10))
                                    
                                    Text(info)
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 1)
                                .padding(.horizontal, 8)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Log entries
                            ForEach(dummyLogs.indices, id: \.self) { index in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("[\(timeString(minutesAgo: dummyLogs.count - index))]")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 11, design: .monospaced))
                                    
                                    Text("[INFO]")
                                        .foregroundColor(.green)
                                        .font(.system(size: 11, design: .monospaced))
                                    
                                    Text(dummyLogs[index])
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.vertical, 1)
                                .padding(.horizontal, 8)
                            }
                        }
                        .padding(.vertical, 8)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                    }
                    
                    Spacer()
                    
                    // Bottom section with error count and action buttons
                    VStack(spacing: 16) {
                        // Error count
                        HStack {
                            Text("0 Critical Errors.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(Color.red)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        VStack(spacing: 1) {
                            // Share button
                            Button(action: {
                                let logs = dummyLogs.map { "[\(timeString())] [INFO] \($0)" }.joined(separator: "\n")
                                let activityVC = UIActivityViewController(activityItems: [logs], applicationActivities: nil)
                                
                                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                      let rootVC = windowScene.windows.first?.rootViewController else { return }
                                rootVC.present(activityVC, animated: true)
                            }) {
                                HStack {
                                    Text("Share Logs")
                                        .foregroundColor(.blue)
                                        .padding(.leading, 2)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(Color.black.opacity(0.05))
                            
                            Divider()
                                .background(Color.gray.opacity(0.3))
                            
                            // Copy button
                            Button(action: {
                                let logs = dummyLogs.map { "[\(timeString())] [INFO] \($0)" }.joined(separator: "\n")
                                UIPasteboard.general.string = logs
                            }) {
                                HStack {
                                    Text("Copy Logs")
                                        .foregroundColor(.blue)
                                        .padding(.leading, 2)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .contentShape(Rectangle())
                            }
                            .background(Color.black.opacity(0.05))
                        }
                        .cornerRadius(8)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Console Logs")
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Settings")
                            .fontWeight(.regular)
                    }
                    .foregroundColor(.blue)
                }
            )
        }
    }
    
    // Helper to display current time
    private func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    // Helper to display time with offset for log display
    private func timeString(minutesAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let date = Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
}

// Preview provider
struct ConsoleLogsView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleLogsView()
    }
} 