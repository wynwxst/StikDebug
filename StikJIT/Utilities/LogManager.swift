//
//  LogManager.swift
//  StikJIT
//
//  Created by neoarz on 3/29/25.
//

import Foundation
import os.log

class LogManager: ObservableObject {
    static let shared = LogManager()
    
    @Published var logs: [LogEntry] = []
    @Published var errorCount: Int = 0
    
    // Add properties to capture stdout/stderr
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var originalStdout: Int32 = -1
    private var originalStderr: Int32 = -1
    private let logQueue = DispatchQueue(label: "com.stikjit.logQueue")
    
    struct LogEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let type: LogType
        let message: String
        
        enum LogType: String {
            case info = "INFO"
            case error = "ERROR"
            case debug = "DEBUG"
            case warning = "WARNING"
        }
    }
    
    private init() {
        // Add initial system info logs
        addInfoLog("StikJIT starting up")
        addInfoLog("Initializing environment")
        
        // Set up stdout and stderr capture
        captureStandardOutput()
        
        // Register for system log notifications
        #if os(macOS)
        // On macOS, also listen for system log messages
        setupMacOSLogCapture()
        #endif
    }
    
    #if os(macOS)
    private func setupMacOSLogCapture() {
        // On macOS we can use the OSLog system
        // This is a placeholder for macOS-specific log capture
        // Start a background task to read system logs
        DispatchQueue.global(qos: .background).async {
            self.captureSystemLogs()
        }
    }
    
    private func captureSystemLogs() {
        // This is a basic implementation to capture macOS logs
        // A more comprehensive solution would use the OSLog framework
        let task = Process()
        let pipe = Pipe()
        
        task.executableURL = URL(fileURLWithPath: "/usr/bin/log")
        task.arguments = ["stream", "--style", "compact"]
        task.standardOutput = pipe
        
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let string = String(data: data, encoding: .utf8), !string.isEmpty {
                self?.processStandardOutputLine(string, isError: false)
            }
        }
        
        do {
            try task.run()
        } catch {
            self.addErrorLog("Failed to capture system logs: \(error.localizedDescription)")
        }
    }
    #endif
    
    // Function to capture standard output and standard error
    private func captureStandardOutput() {
        #if DEBUG && targetEnvironment(simulator)
        // Skip capturing in simulator debug builds to ensure logs appear in Xcode console
        return
        #endif
        
        // Save original file descriptors safely
        if FileHandle.standardOutput.fileDescriptor >= 0 {
            originalStdout = dup(FileHandle.standardOutput.fileDescriptor)
        }
        if FileHandle.standardError.fileDescriptor >= 0 {
            originalStderr = dup(FileHandle.standardError.fileDescriptor)
        }
        
        // Create pipes
        stdoutPipe = Pipe()
        stderrPipe = Pipe()
        
        // Redirect stdout and stderr to our pipes only if valid
        if let stdoutPipe = stdoutPipe, FileHandle.standardOutput.fileDescriptor >= 0 {
            dup2(stdoutPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardOutput.fileDescriptor)
        }
        if let stderrPipe = stderrPipe, FileHandle.standardError.fileDescriptor >= 0 {
            dup2(stderrPipe.fileHandleForWriting.fileDescriptor, FileHandle.standardError.fileDescriptor)
        }
        
        // Start reading from the pipes on a background queue to avoid blocking
        stdoutPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                // Write back to original stdout for console viewing
                if let strongSelf = self, strongSelf.originalStdout >= 0 {
                    write(strongSelf.originalStdout, string, string.utf8.count)
                }
                
                self?.logQueue.async {
                    self?.processStandardOutputLine(string, isError: false)
                }
            }
        }
        
        stderrPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let string = String(data: data, encoding: .utf8) {
                // Write back to original stderr for console viewing
                if let strongSelf = self, strongSelf.originalStderr >= 0 {
                    write(strongSelf.originalStderr, string, string.utf8.count)
                }
                
                self?.logQueue.async {
                    self?.processStandardOutputLine(string, isError: true)
                }
            }
        }
        
        // Also set up a timer to periodically flush stdout/stderr
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.flushPipes()
        }
    }
    
    private func flushPipes() {
        // Force flush the pipes to ensure all output is captured
        fflush(stdout)
        fflush(stderr)
    }
    
    // Process standard output/error lines and add to logs
    private func processStandardOutputLine(_ line: String, isError: Bool) {
        // Split multi-line output
        let lines = line.components(separatedBy: .newlines)
        
        for line in lines where !line.isEmpty {
            // Determine log type based on content
            let type: LogEntry.LogType
            
            // Check for error indicators
            if line.contains("[ERROR]") || line.contains("Error:") || line.contains("error:") || 
               line.contains("ERROR:") || line.contains("Failed") || (isError && !line.contains("DEBUG")) {
                type = .error
            }
            // Check for warning indicators
            else if line.contains("[WARNING]") || line.contains("Warning:") || line.contains("warning:") || 
                    line.contains("WARN:") || line.contains("WARNING:") {
                type = .warning
            }
            // Check for debug indicators
            else if line.contains("[DEBUG]") || line.contains("DEBUG:") || line.contains("debug:") {
                type = .debug
            }
            // Check for info indicators
            else if line.contains("[INFO]") || line.contains("INFO:") || line.contains("info:") {
                type = .info
            }
            // Default to info for anything else
            else {
                type = isError ? .error : .info
            }
            
            // Add to logs
            addLog(message: line, type: type)
        }
    }
    
    func addLog(message: String, type: LogEntry.LogType) {
        //clean dumb stuff
        var cleanMessage = message
        
        // Clean up common prefixes that match the log type
        let prefixesToRemove = [
            "Info: ", "INFO: ", "Information: ",
            "Error: ", "ERROR: ", "ERR: ",
            "Debug: ", "DEBUG: ", "DBG: ",
            "Warning: ", "WARN: ", "WARNING: "
        ]
        
        for prefix in prefixesToRemove {
            if cleanMessage.hasPrefix(prefix) {
                cleanMessage = String(cleanMessage.dropFirst(prefix.count))
                break
            }
        }
        
        DispatchQueue.main.async {
            self.logs.append(LogEntry(timestamp: Date(), type: type, message: cleanMessage))
            
            if type == .error {
                self.errorCount += 1
            }
            
            // Keep log size manageable
            if self.logs.count > 1000 {
                self.logs.removeFirst(100)
            }
        }
    }
    
    func addInfoLog(_ message: String) {
        addLog(message: message, type: .info)
    }
    
    func addErrorLog(_ message: String) {
        addLog(message: message, type: .error)
    }
    
    func addDebugLog(_ message: String) {
        addLog(message: message, type: .debug)
    }
    
    func addWarningLog(_ message: String) {
        addLog(message: message, type: .warning)
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.errorCount = 0
        }
    }
} 
