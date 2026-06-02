import Foundation

struct LilyNote: Identifiable, Hashable {
    let id = UUID()
    let pitch: String
    let duration: Int
    let measure: Int
    let token: String

    var displayName: String {
        "\(pitch.uppercased())\(duration)"
    }
}

struct LilyCompileResult {
    let success: Bool
    let notes: [LilyNote]
    let pdfData: Data?
    let log: String
}
