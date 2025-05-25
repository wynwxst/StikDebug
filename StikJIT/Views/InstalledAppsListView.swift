//
//  InstalledAppsListView.swift
//  StikJIT
//
//  Created by Stossy11 on 28/03/2025.
//

import SwiftUI
import UIKit

struct InstalledAppsListView: View {
    @StateObject private var viewModel = InstalledAppsViewModel()
    @State private var appIcons: [String: UIImage] = [:]
    @Environment(\.dismiss) private var dismiss
    @AppStorage("recentApps") private var recentApps: [String] = []
    @AppStorage("favoriteApps") private var favoriteApps: [String] = []
    var onSelectApp: (String) -> Void

    var body: some View {
        NavigationView {
            Group {
                if viewModel.apps.isEmpty {
                    emptyState
                } else {
                    appsList
                }
            }
            .navigationTitle("Installed Apps")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
        .background(Color(UIColor.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            
            Text("No Debuggable App Found")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("""
StikDebug can only connect to apps with the "**get-task-allow**" entitlement. \
Please check if the app you want to connect to is signed with a **development** certificate.
""")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - List of Apps

    private var appsList: some View {
        List {
            // Favorites
            if !favoriteApps.isEmpty {
                Section(header: Text("Favorites")) {
                    ForEach(favoriteApps, id: \.self) { bundleID in
                        AppButton(
                            bundleID: bundleID,
                            appName: viewModel.apps[bundleID] ?? bundleID,
                            recentApps: $recentApps,
                            favoriteApps: $favoriteApps,
                            appIcons: $appIcons,
                            onSelectApp: onSelectApp
                        )
                    }
                }
            }

            // Recents
            if !recentApps.isEmpty {
                Section(header: Text("Recents")) {
                    ForEach(recentApps, id: \.self) { bundleID in
                        AppButton(
                            bundleID: bundleID,
                            appName: viewModel.apps[bundleID] ?? bundleID,
                            recentApps: $recentApps,
                            favoriteApps: $favoriteApps,
                            appIcons: $appIcons,
                            onSelectApp: onSelectApp
                        )
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                withAnimation {
                                    recentApps.removeAll(where: { $0 == bundleID })
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }

            // All Applications
            if favoriteApps.isEmpty && recentApps.isEmpty {
                Section {
                    ForEach(viewModel.apps.sorted(by: { $0.key < $1.key }), id: \.key) { bundleID, appName in
                        AppButton(
                            bundleID: bundleID,
                            appName: appName,
                            recentApps: $recentApps,
                            favoriteApps: $favoriteApps,
                            appIcons: $appIcons,
                            onSelectApp: onSelectApp
                        )
                    }
                }
            } else {
                Section(header: Text("All Applications")) {
                    ForEach(viewModel.apps.sorted(by: { $0.key < $1.key }), id: \.key) { bundleID, appName in
                        AppButton(
                            bundleID: bundleID,
                            appName: appName,
                            recentApps: $recentApps,
                            favoriteApps: $favoriteApps,
                            appIcons: $appIcons,
                            onSelectApp: onSelectApp
                        )
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

struct AppButton: View {
    @State var bundleID: String
    @State var appName: String
    @Binding var recentApps: [String]
    @Binding var favoriteApps: [String]
    @Binding var appIcons: [String: UIImage]
    @AppStorage("loadAppIconsOnJIT") private var loadAppIconsOnJIT = true
    var onSelectApp: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: selectApp) {
            HStack(spacing: loadAppIconsOnJIT ? 16 : 12) {
                iconView
                appText
                Spacer()
            }
            .padding(.vertical, loadAppIconsOnJIT ? 0 : 8)
        }
        .contextMenu {
            Button {
                toggleFavorite()
            } label: {
                Label(
                    favoriteApps.contains(bundleID) ? "Remove Favorite" : "Add to Favorites",
                    systemImage: favoriteApps.contains(bundleID) ? "star.slash" : "star"
                )
            }

            Button {
                UIPasteboard.general.string = bundleID
            } label: {
                Label("Copy Bundle ID", systemImage: "doc.on.doc")
            }
        }
    }

    private var iconView: some View {
        Group {
            if loadAppIconsOnJIT, let image = appIcons[bundleID] {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .shadow(
                        color: colorScheme == .dark ? .black.opacity(0.2) : .gray.opacity(0.2),
                        radius: 3, x: 0, y: 1
                    )
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(UIColor.systemGray5))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "app")
                            .font(.system(size: 26))
                            .foregroundColor(.gray)
                    )
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .onAppear { loadAppIcon(for: bundleID) }
            }
        }
    }

    private var appText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(appName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
            Text(bundleID)
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .lineLimit(1)
        }
    }

    private func selectApp() {
        recentApps.removeAll(where: { $0 == bundleID })
        recentApps.insert(bundleID, at: 0)
        if recentApps.count > 3 {
            recentApps = Array(recentApps.prefix(3))
        }
        onSelectApp(bundleID)
    }

    private func toggleFavorite() {
        if favoriteApps.contains(bundleID) {
            favoriteApps.removeAll(where: { $0 == bundleID })
        } else {
            favoriteApps.insert(bundleID, at: 0)
        }
    }

    private func loadAppIcon(for bundleID: String) {
        guard loadAppIconsOnJIT else { return }
        AppStoreIconFetcher.getIcon(for: bundleID) { image in
            if let image = image {
                DispatchQueue.main.async {
                    withAnimation(.easeIn(duration: 0.2)) {
                        appIcons[bundleID] = image
                    }
                }
            }
        }
    }
}

extension Array: @retroactive RawRepresentable where Element: Codable {
    public init?(rawValue: String) {
        guard let data = rawValue.data(using: .utf8),
              let result = try? JSONDecoder().decode([Element].self, from: data)
        else { return nil }
        self = result
    }

    public var rawValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let result = String(data: data, encoding: .utf8)
        else { return "[]" }
        return result
    }
}

#Preview {
    InstalledAppsListView { _ in }
}
