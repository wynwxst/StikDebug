//
//  Color.swift
//  StikJIT
//
//  Created by Stephen on 3/27/25.
//


import SwiftUI

extension Color {
    func toHex() -> String? {
        let components = UIColor(self).cgColor.components
        let r = Float(components?[0] ?? 0)
        let g = Float(components?[1] ?? 0)
        let b = Float(components?[2] ?? 0)
        let hex = String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        return "#" + hex
    }
    
    init?(hex: String) {
        if hex.isEmpty || hex.count < 2 {
            return nil
        }
        
        let r, g, b: CGFloat
        
        if hex.hasPrefix("#") && hex.count >= 7 {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6, let hexNumber = Int(hexColor, radix: 16) {
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat(hexNumber & 0x0000ff) / 255
                self.init(red: r, green: g, blue: b)
                return
            }
        }
        
        return nil
    }
}

extension Color {
    static let primaryBackground = Color.black
    static let cardBackground = Color.white.opacity(0.2)
    
    // Instead of a static color, provide a function that gets the current accent color
    static func dynamicAccentColor(opacity: Double = 0.8) -> Color {
        let colorHex = UserDefaults.standard.string(forKey: "customAccentColor") ?? ""
        if colorHex.isEmpty {
            return Color.blue.opacity(opacity)
        } else {
            return (Color(hex: colorHex) ?? .blue).opacity(opacity)
        }
    }
    
    // For backward compatibility
    static var cardBackground2: Color {
        return dynamicAccentColor(opacity: 0.8)
    }
    
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    
    // Determine if a color is dark or light to decide text color
    func isDark() -> Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate perceived brightness using the formula for luminance
        // 0.299*R + 0.587*G + 0.114*B
        let brightness = (0.299 * red) + (0.587 * green) + (0.114 * blue)
        
        // Return true if the color is dark (brightness < 0.5)
        return brightness < 0.5
    }
    
    // Returns black or white depending on the background brightness
    func contrastText() -> Color {
        return self.isDark() ? .white : .black
    }
}
