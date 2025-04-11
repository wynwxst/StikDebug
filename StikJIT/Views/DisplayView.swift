//  DisplayView.swift
//  StikJIT
//
//  Created by neoarz on 4/9/25.

import SwiftUI

struct AccentColorPicker: View {
    @Binding var selectedColor: Color
    
    let colors: [Color] = [
        .blue,  // Default system blue
        .init(hex: "#7FFFD4")!, // Aqua
        .init(hex: "#50C878")!, // Green
        .red,   // Red
        .init(hex: "#6A5ACD")!, // Purple
        .init(hex: "#DA70D6")!, // Pink
        .white, // white
        .black // black
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accent Color")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: Array(repeating: .init(.flexible(), spacing: 12), count: 9), spacing: 12) {
                ForEach(colors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(selectedColor == color ? Color.primary : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture {
                            selectedColor = color
                        }
                }
                
                // Direct Color Picker Circle
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .clipShape(Circle())
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.top, 12)
    }
}

struct DisplayView: View {
    @AppStorage("username") private var username = "User"
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("loadAppIconsOnJIT") private var loadAppIconsOnJIT = true
    @State private var selectedAccentColor: Color = .blue
    @Environment(\.colorScheme) private var colorScheme
    
    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }
    
    var body: some View {
        ZStack {
            Color(colorScheme == .dark ? .black : .white)
                .ignoresSafeArea()
                
            ScrollView {
                VStack(spacing: 16) {
                    // App Theme Section with Accent Colors
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Theme")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            // Theme selector with preview images
                            HStack(spacing: 12) {
                                // Automatic Theme
                                ThemeOptionButton(
                                    title: "Automatic",
                                    imageName: "System",
                                    isSelected: appTheme == "system",
                                    accentColor: selectedAccentColor,
                                    action: { appTheme = "system" }
                                )
                                
                                // Light Theme
                                ThemeOptionButton(
                                    title: "Light",
                                    imageName: "LightUI",
                                    isSelected: appTheme == "light",
                                    accentColor: selectedAccentColor,
                                    action: { appTheme = "light" }
                                )
                                
                                // Dark Theme
                                ThemeOptionButton(
                                    title: "Dark",
                                    imageName: "DarkUI",
                                    isSelected: appTheme == "dark",
                                    accentColor: selectedAccentColor,
                                    action: { appTheme = "dark" }
                                )
                            }
                            .onChange(of: appTheme) { newValue in
                                applyTheme(newValue)
                            }
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            // Accent Color Picker
                            AccentColorPicker(selectedColor: Binding(
                                get: { selectedAccentColor },
                                set: { newColor in
                                    selectedAccentColor = newColor
                                    saveCustomAccentColor(newColor)
                                }
                            ))
                        }
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                    
                    // Username Section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            TextField("Username", text: $username)
                                .padding(14)
                                .background(Color(UIColor.tertiarySystemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                    
                    // App Icons on JIT Toggle Section
                    SettingsCard {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("JIT Options")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .padding(.bottom, 4)
                            
                            Toggle("Load App Icons when Enabling JIT", isOn: $loadAppIconsOnJIT)
                                .foregroundColor(.primary)
                                .padding(.vertical, 6)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 16)
                    }
                    .background(Color(UIColor.tertiarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("Display")
        .onAppear {
            loadCustomAccentColor()
            applyTheme(appTheme)
        }
    }
    
    private func loadCustomAccentColor() {
        if customAccentColorHex.isEmpty {
            selectedAccentColor = .blue
        } else {
            selectedAccentColor = Color(hex: customAccentColorHex) ?? .blue
        }
    }
    
    private func saveCustomAccentColor(_ color: Color) {
        // Always save the custom color if we got here (since auto theme mode is disabled)
        customAccentColorHex = color.toHex() ?? ""
    }
    
    private func applyTheme(_ theme: String) {
        // Set the app's theme (will apply when app is restarted)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            switch theme {
            case "dark":
                window.overrideUserInterfaceStyle = .dark
            case "light":
                window.overrideUserInterfaceStyle = .light
            default:
                window.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

struct ThemeOptionButton: View {
    let title: String
    let imageName: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
                    )
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? accentColor : .primary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

