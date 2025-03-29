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
    @StateObject private var logManager = LogManager.shared
    @State private var autoScroll = true
    @State private var scrollView: ScrollViewProxy? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Terminal-style logs area
                    ScrollViewReader { proxy in
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
                                
                                // Real log entries
                                ForEach(logManager.logs) { logEntry in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("[\(formatTime(date: logEntry.timestamp))]")
                                            .foregroundColor(.gray)
                                            .font(.system(size: 11, design: .monospaced))
                                        
                                        Text("[\(logEntry.type.rawValue)]")
                                            .foregroundColor(colorForLogType(logEntry.type))
                                            .font(.system(size: 11, design: .monospaced))
                                        
                                        Text(logEntry.message)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundColor(.primary)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(.vertical, 1)
                                    .padding(.horizontal, 8)
                                    .id(logEntry.id)
                                }
                            }
                            .padding(.vertical, 8)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(8)
                            .padding(.horizontal, 8)
                            .padding(.top, 8)
                        }
                        .onAppear {
                            scrollView = proxy
                        }
                        .onChange(of: logManager.logs.count) {
                            if autoScroll, let lastLog = logManager.logs.last {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Bottom section with error count and action buttons
                    VStack(spacing: 16) {
                        // Error count
                        HStack {
                            Text("\(logManager.errorCount) Critical Errors.")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 20)
                                .frame(maxWidth: .infinity)
                                .background(logManager.errorCount > 0 ? Color.red : Color.green)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        // Action buttons
                        VStack(spacing: 1) {
                            // Share button
                            Button(action: {
                                let logs = logManager.logs.map { "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" }.joined(separator: "\n")
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
                                let logs = logManager.logs.map { "[\(formatTime(date: $0.timestamp))] [\($0.type.rawValue)] \($0.message)" }.joined(separator: "\n")
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
                },
                trailing: Button(action: {
                    logManager.clearLogs()
                }) {
                    Text("Clear")
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
    
    // Helper to format Date objects to time strings
    private func formatTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
    
    // Helper to display time with offset for log display
    private func timeString(minutesAgo: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let date = Calendar.current.date(byAdding: .minute, value: -minutesAgo, to: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    // Return color based on log type
    private func colorForLogType(_ type: LogManager.LogEntry.LogType) -> Color {
        switch type {
        case .info:
            return .green
        case .error:
            return .red
        case .debug:
            return .blue
        case .warning:
            return .orange
        }
    }
}

// Preview provider
struct ConsoleLogsView_Previews: PreviewProvider {
    static var previews: some View {
        ConsoleLogsView()
    }
} 