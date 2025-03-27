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
    @State private var pairingFileMessage: String = ""
    @State private var showPairingFileMessage: Bool = false
    @State private var pairingFileIsValid: Bool = false

    var body: some View {
        ZStack {
            selectedBackgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                Spacer()
                VStack(spacing: 5) {
                    Text("Welcome to StikJIT \(username)!")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                    
                    Text("Click enable JIT to get started")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                // Single button - handles both pairing file and JIT
                Button(action: {
                    if pairingFileExists {
                        // If pairing file exists, show app list
                        isShowingInstalledApps = true
                    } else {
                        // If no pairing file, show file picker
                        isShowingPairingFilePicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: pairingFileExists ? "bolt.fill" : "doc.badge.plus")
                            .font(.system(size: 20))
                        Text(pairingFileExists ? "Enable JIT" : "Import Pairing File")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, 20)
                
                // Success message that doesn't affect layout
                ZStack {
                    if showPairingFileMessage && pairingFileIsValid {
                        Text("✓ Pairing file successfully imported")
                            .font(.system(.callout, design: .rounded))
                            .foregroundColor(.green)
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                            .transition(.opacity)
                    }
                    
                    // This empty text reserves space so layout doesn't shift
                    Text(" ").opacity(0)
                }
                .frame(height: 30)
                
                // Error messages (only show if there's an error)
                if showPairingFileMessage && !pairingFileIsValid {
                    Text(pairingFileMessage)
                        .font(.system(.callout, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.vertical, 4)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
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
        .fileImporter(isPresented: $isShowingPairingFilePicker, allowedContentTypes: [.data, .item]) { result in 
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    pairingFileMessage = "Failed to access the selected file"
                    showPairingFileMessage = true
                    pairingFileIsValid = false
                    return
                }
                
                let fileManager = FileManager.default
                
                // Check if the file has a valid extension
                let fileExtension = url.pathExtension.lowercased()
                guard fileExtension == "plist" || fileExtension == "mobiledevicepairing" else {
                    pairingFileMessage = "Invalid file type. Please select a .plist or .mobiledevicepairing file."
                    showPairingFileMessage = true
                    pairingFileIsValid = false
                    url.stopAccessingSecurityScopedResource()
                    return
                }
                
                if fileManager.fileExists(atPath: url.path) {
                    do {
                        let destURL = URL.documentsDirectory.appendingPathComponent("pairingFile.plist")
                        
                        if fileManager.fileExists(atPath: destURL.path) {
                            try fileManager.removeItem(at: destURL)
                        }
                        
                        try fileManager.copyItem(at: url, to: destURL)
                        print("File copied successfully!")
                        
                        // Validate the pairing file
                        do {
                            let data = try Data(contentsOf: destURL)
                            if let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                                // Basic validation - check for some expected keys in a pairing file
                                if plist["DeviceCertificate"] != nil || plist["HostCertificate"] != nil || 
                                   plist["WiFiMACAddress"] != nil || plist["DeviceID"] != nil {
                                    pairingFileMessage = "" // We'll use a fixed success message
                                    pairingFileIsValid = true
                                    pairingFileExists = true
                                    
                                    // Start heartbeat
                                    startHeartbeatInBackground()
                                    
                                    // Show success message briefly
                                    withAnimation(.easeIn(duration: 0.2)) {
                                        showPairingFileMessage = true
                                    }
                                    
                                    // Automatically hide message after 3 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            showPairingFileMessage = false
                                        }
                                    }
                                    
                                    // Don't automatically show apps list - let user click button
                                } else {
                                    pairingFileMessage = "File is a plist but doesn't appear to be a valid pairing file."
                                    pairingFileIsValid = false
                                    showPairingFileMessage = true
                                }
                            } else {
                                pairingFileMessage = "Invalid pairing file format."
                                pairingFileIsValid = false
                                showPairingFileMessage = true
                            }
                        } catch {
                            pairingFileMessage = "Could not validate pairing file: \(error.localizedDescription)"
                            pairingFileIsValid = false
                            showPairingFileMessage = true
                        }
                    } catch {
                        pairingFileMessage = "Error copying file: \(error.localizedDescription)"
                        showPairingFileMessage = true
                        pairingFileIsValid = false
                    }
                } else {
                    pairingFileMessage = "Source file does not exist."
                    showPairingFileMessage = true
                    pairingFileIsValid = false
                }
                
                url.stopAccessingSecurityScopedResource()
                
                // Hide error messages after 3 seconds
                if !pairingFileIsValid && showPairingFileMessage {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showPairingFileMessage = false
                        }
                    }
                }
                
            case .failure(let error):
                pairingFileMessage = "Failed to import file: \(error.localizedDescription)"
                showPairingFileMessage = true
                pairingFileIsValid = false
                
                // Hide error message after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showPairingFileMessage = false
                    }
                }
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
        let exists = FileManager.default.fileExists(atPath: URL.documentsDirectory.appendingPathComponent("pairingFile.plist").path)
        pairingFileExists = exists
        
        // If the file exists and we haven't validated it yet, validate it
        if exists && !pairingFileIsValid {
            do {
                let data = try Data(contentsOf: URL.documentsDirectory.appendingPathComponent("pairingFile.plist"))
                if let _ = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
                    pairingFileIsValid = true
                }
            } catch {
                // Silently fail - we don't want to show an error message on every timer tick
                pairingFileIsValid = false
            }
        }
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
