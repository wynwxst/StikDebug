import SwiftUI

struct AnnouncementCard: View {
    var announcement: Announcement
    @AppStorage("customAccentColor") private var customAccentColorHex: String = ""

    private var accentColor: Color {
        if customAccentColorHex.isEmpty {
            return .blue
        } else {
            return Color(hex: customAccentColorHex) ?? .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(announcement.title)
                .font(.headline)
                .foregroundColor(.primary)
            Text(announcement.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("\(announcement.date) \(announcement.time)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor, lineWidth: 2)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    AnnouncementCard(
        announcement: Announcement(
            id: 0,
            title: "Title",
            body: "Body",
            date: "2025-01-01",
            time: "00:00",
            visible: true
        )
    )
}
