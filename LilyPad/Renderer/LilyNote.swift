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

struct LilyRenderResult {
    let success: Bool
    let notes: [LilyNote]
    let pdfData: Data?
    let log: String
}
