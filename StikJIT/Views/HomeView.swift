//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("bundleID") private var bundleID: String = ""
    @State private var isProcessing = false
    @State private var isShowingInstalledApps = false

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
                    startJITInBackground(with: bundleID)
                }) {
                    Label(isProcessing ? "Enabling..." : "Enable JIT",
                          systemImage: isProcessing ? "hourglass" : "bolt.fill")
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
                
                Button(action: {
                    isShowingInstalledApps = true
                }) {
                    Label("View Installed Apps", systemImage: "list.bullet")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $isShowingInstalledApps) {
            InstalledAppsListView { selectedBundle in
                bundleID = selectedBundle
                isShowingInstalledApps = false
                HapticFeedbackHelper.trigger()
                startJITInBackground(with: selectedBundle)
            }
        }
    }
    
    private func startJITInBackground(with bundleID: String) {
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

class InstalledAppsViewModel: ObservableObject {
    @Published var apps: [String] = []
    
    init() {
        loadApps()
    }
    
    func loadApps() {
        guard let rawPointer = list_installed_apps() else {
            self.apps = []
            return
        }
        
        let output = String(cString: rawPointer)
        free(rawPointer)
        
        if output.hasPrefix("Error:") {
            self.apps = []
        } else {
            self.apps = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        }
    }
}

struct InstalledAppsListView: View {
    @StateObject var viewModel = InstalledAppsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    
    var onSelect: (String) -> Void
    
    var filteredApps: [String] {
        if searchText.isEmpty {
            return viewModel.apps
        } else {
            return viewModel.apps.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(filteredApps, id: \.self) { app in
                        Button(action: {
                            onSelect(app)
                        }) {
                            Text(app)
                                .font(.system(.body, design: .rounded))
                                .padding(.vertical, 8)
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationTitle("Installed Apps")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search Bundle IDs")
            }
        }
    }
}

#Preview {
    HomeView()
}
