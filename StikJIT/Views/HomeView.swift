//
//  ContentView.swift
//  StikJIT
//
//  Created by Stephen on 3/26/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @State private var selectedBackgroundColor: Color = Color(hex: UserDefaults.standard.string(forKey: "customBackgroundColor") ?? "#000000") ?? Color.primaryBackground
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @AppStorage("bundleID") private var bundleID: String = ""
    @State private var isProcessing = false
    @State private var isShowingInstalledApps = false
    @State private var isShowingPairingFilePicker = false
    @State private var pairingFileExists: Bool = false

    var body: some View {
        ZStack {
            selectedBackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("Welcome to StikJIT \(username)!")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Follow the steps below to enable JIT")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Pairing File Button
                Button(action: {
                    isShowingPairingFilePicker = true
                }) {
                    HStack {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 20))
                        Text("Import Pairing File")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.purple.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                
                // Enable JIT Button
                Button(action: {
                    isShowingInstalledApps = true
                }) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 20))
                        Text("Enable JIT")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(pairingFileExists ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: pairingFileExists ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                .disabled(!pairingFileExists)
                
                if !pairingFileExists {
                    Text("Please import a pairing file first")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            checkPairingFileExists()
        }
        .onReceive(timer) { _ in
            refreshBackground()
            checkPairingFileExists()
        }
        .fileImporter(isPresented: $isShowingPairingFilePicker, allowedContentTypes: [.item]) { result in 
            switch result {
            case .success(let url):
                let fileManager = FileManager.default
                let accessing = url.startAccessingSecurityScopedResource()
                
                if fileManager.fileExists(atPath: url.path) {
                    do {
                        if fileManager.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path) {
                            try fileManager.removeItem(at: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        }
                        
                        try fileManager.copyItem(at: url, to: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                        print("File copied successfully!")
                        startHeartbeatInBackground()
                        
                        // Update the file exists state
                        pairingFileExists = true
                        
                        Thread.sleep(forTimeInterval: 5)
                    } catch {
                        print("Error copying file: \(error)")
                    }
                } else {
                    print("Source file does not exist.")
                }
                
                if accessing {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(_):
                print("Failed")
            }
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
    
    private func checkPairingFileExists() {
        pairingFileExists = FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path)
    }
    
    private func refreshBackground() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }
    
    private func startJITInBackground(with bundleID: String) {
        isProcessing = true
        DispatchQueue.global(qos: .background).async {
            guard let cBundleID = strdup(bundleID) else {
                DispatchQueue.main.async { isProcessing = false }
                return
            }
            
            _ = debug_app(cBundleID)
            
            free(cBundleID)
            DispatchQueue.main.async {
                isProcessing = false
            }
        }
    }
}

// Replace the AppInfo struct and related code with this simpler version
struct AppInfo: Identifiable, Hashable {
    let id = UUID()
    let bundleID: String
    let name: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(bundleID)
    }
    
    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        return lhs.bundleID == rhs.bundleID
    }
    
    // Generate a color based on the bundle ID
    var iconColor: Color {
        var hash = 0
        for char in bundleID {
            hash = ((hash << 5) &- hash) &+ Int(char.asciiValue ?? 0)
        }
        let hue = Double(abs(hash) % 360) / 360.0
        return Color(hue: hue, saturation: 0.8, brightness: 0.9)
    }
    
    // Get an appropriate SF Symbol based on bundle ID
    var iconSymbol: String {
        let appTypes: [(pattern: String, icon: String)] = [
            ("game", "gamecontroller"),
            ("play", "gamecontroller"),
            ("photo", "camera"),
            ("camera", "camera.viewfinder"),
            ("spotify", "music.note"),
            ("music", "music.note"),
            ("audio", "headphones"),
            ("netflix", "play.tv"),
            ("video", "play.rectangle"),
            ("tv", "tv"),
            ("player", "play.circle"),
            ("facebook", "message"),
            ("messenger", "message.fill"),
            ("chat", "bubble.left.and.bubble.right"),
            ("message", "bubble.left"),
            ("mail", "envelope"),
            ("safari", "globe"),
            ("web", "network"),
            ("browser", "safari"),
            ("note", "note.text"),
            ("docs", "doc.text"),
            ("document", "doc"),
            ("word", "doc.richtext"),
            ("file", "folder"),
            ("sheets", "tablecells"),
            ("excel", "tablecells.fill"),
            ("calc", "function"),
            ("shop", "cart"),
            ("store", "bag"),
            ("pay", "creditcard"),
            ("wallet", "wallet.pass"),
            ("health", "heart"),
            ("fitness", "figure.walk"),
            ("exercise", "figure.run"),
        ]
        
        let lowerBundleID = bundleID.lowercased()
        let lowerName = name.lowercased()
        
        for appType in appTypes {
            if lowerBundleID.contains(appType.pattern) || lowerName.contains(appType.pattern) {
                return appType.icon
            }
        }
        
        return "app.fill"
    }
}

class InstalledAppsViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    
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
            // Parse the output into AppInfo objects
            self.apps = output.components(separatedBy: "\n")
                .filter { !$0.isEmpty }
                .compactMap { line -> AppInfo? in
                    let components = line.components(separatedBy: "|")
                    if components.count >= 2 {
                        return AppInfo(bundleID: components[0], name: components[1])
                    } else if components.count == 1 {
                        return AppInfo(bundleID: components[0], name: components[0])
                    }
                    return nil
                }
        }
    }
}

struct InstalledAppsListView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customBackgroundColor") private var customBackgroundColorHex: String = Color.primaryBackground.toHex() ?? "#000000"
    @State private var selectedBackgroundColor: Color = Color(hex: UserDefaults.standard.string(forKey: "customBackgroundColor") ?? "#000000") ?? Color.primaryBackground
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @StateObject var viewModel = InstalledAppsViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var searchText: String = ""
    @State private var appIcons: [String: UIImage] = [:]
    
    var onSelect: (String) -> Void
    
    var filteredApps: [AppInfo] {
        if searchText.isEmpty {
            return viewModel.apps
        } else {
            return viewModel.apps.filter { 
                $0.bundleID.localizedCaseInsensitiveContains(searchText) || 
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                selectedBackgroundColor.edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(filteredApps) { app in
                        Button(action: {
                            onSelect(app.bundleID)
                        }) {
                            HStack {
                                // Simplified app icon display
                                appIconView(for: app)
                                    .padding(.trailing, 8)
                                
                                // App details
                                appDetailsView(for: app)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray.opacity(0.7))
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(Color(.secondarySystemGroupedBackground))
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
                .searchable(text: $searchText, prompt: "Search Apps")
            }
            .onReceive(timer) { _ in
                refreshBackground()
            }
        }
    }
    
    // Helper view for app icon
    private func appIconView(for app: AppInfo) -> some View {
        Group {
            if let icon = appIcons[app.bundleID] {
                // Show cached icon
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                    .cornerRadius(12)
            } else {
                // Show placeholder and try to load icon
                placeholderIconView(for: app)
                    .onAppear {
                        loadAppIcon(for: app)
                    }
            }
        }
    }
    
    // Helper view for placeholder icon
    private func placeholderIconView(for app: AppInfo) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(app.iconColor)
                .frame(width: 48, height: 48)
            
            Image(systemName: app.iconSymbol)
                .font(.system(size: 24))
                .foregroundColor(.white)
        }
    }
    
    // Helper view for app details
    private func appDetailsView(for app: AppInfo) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(app.name)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
            
            Text(app.bundleID)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
    
    // Helper method to load app icon
    private func loadAppIcon(for app: AppInfo) {
        AppStoreIconFetcher.getIcon(for: app.bundleID) { image in
            if let image = image {
                self.appIcons[app.bundleID] = image
            }
        }
    }
    
    private func refreshBackground() {
        selectedBackgroundColor = Color(hex: customBackgroundColorHex) ?? Color.primaryBackground
    }
}

// Replace the Icon Fetcher with a simpler implementation
class AppStoreIconFetcher {
    static private var iconCache: [String: UIImage] = [:]
    
    static func getIcon(for bundleID: String, completion: @escaping (UIImage?) -> Void) {
        // Check cache first
        if let cachedIcon = iconCache[bundleID] {
            completion(cachedIcon)
            return
        }
        
        // Simplified URL creation
        let baseURLString = "https://itunes.apple.com/lookup?bundleId="
        let urlString = baseURLString + bundleID
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { completion(nil) }
            return
        }
        
        // Step 1: Fetch app data
        fetchAppData(from: url) { appData in
            if let appData = appData {
                // Step 2: Extract icon URL from app data
                extractIconURL(from: appData) { iconURL in
                    if let iconURL = iconURL {
                        // Step 3: Download icon
                        downloadIcon(from: iconURL) { image in
                            if let image = image {
                                // Store in cache
                                iconCache[bundleID] = image
                            }
                            DispatchQueue.main.async {
                                completion(image)
                            }
                        }
                    } else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // Helper method to fetch app data
    private static func fetchAppData(from url: URL, completion: @escaping ([String: Any]?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   !results.isEmpty {
                    completion(results.first)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    // Helper method to extract icon URL
    private static func extractIconURL(from appData: [String: Any], completion: @escaping (URL?) -> Void) {
        if let iconURLString = appData["artworkUrl100"] as? String,
           let iconURL = URL(string: iconURLString) {
            completion(iconURL)
        } else {
            completion(nil)
        }
    }
    
    // Helper method to download icon
    private static func downloadIcon(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}

#Preview {
    HomeView()
}
