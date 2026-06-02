import Foundation
import UIKit

struct LilySubsetCompiler {
    static func compile(_ source: String) -> LilyCompileResult {
        let title = extractHeaderValue("title", from: source) ?? "LilyPad Offline Preview"
        let music = extractMusicBlock(from: source)
        let notes = parseNotes(from: music)

        var log: [String] = []
        log.append("LilyPad v0.2 离线编译 MVP")
        log.append("模式：Swift LilyPond 子集编译器")
        log.append("说明：当前不是完整 LilyPond，只支持基础旋律子集。")
        log.append("")
        log.append("标题：\(title)")
        log.append("识别音符：\(notes.count) 个")

        guard !notes.isEmpty else {
            log.append("❌ 没有识别到可编译的音符。")
            log.append("请确认源码中包含类似 c4 d e f | g2 g 的旋律。")
            return LilyCompileResult(success: false, notes: [], pdfData: nil, log: log.joined(separator: "\n"))
        }

        let pdf = LilyPDFRenderer.render(title: title, notes: notes, source: source)
        log.append("✅ 已生成离线 PDF 预览。")
        log.append("输出：内存 PDF 数据，已交给 PDFKit 预览。")
        log.append("")
        log.append("下一步：扩展 parser，支持更多 LilyPond 语法、和弦、歌词、MIDI。")

        return LilyCompileResult(success: true, notes: notes, pdfData: pdf, log: log.joined(separator: "\n"))
    }

    private static func extractHeaderValue(_ key: String, from source: String) -> String? {
        let pattern = #"\#(key)\s*=\s*\"([^\"]+)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, range: range), match.numberOfRanges > 1 else { return nil }
        guard let valueRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[valueRange])
    }

    private static func extractMusicBlock(from source: String) -> String {
        if let relativeRange = source.range(of: "\\relative"),
           let block = balancedBlock(after: relativeRange.upperBound, in: source) {
            return block
        }

        if let scoreRange = source.range(of: "\\score"),
           let block = balancedBlock(after: scoreRange.upperBound, in: source) {
            return block
        }

        return source
    }

    private static func balancedBlock(after start: String.Index, in source: String) -> String? {
        guard let open = source[start...].firstIndex(of: "{") else { return nil }
        var index = source.index(after: open)
        var depth = 1
        var result = ""

        while index < source.endIndex {
            let char = source[index]
            if char == "{" {
                depth += 1
                result.append(char)
            } else if char == "}" {
                depth -= 1
                if depth == 0 { return result }
                result.append(char)
            } else {
                result.append(char)
            }
            index = source.index(after: index)
        }

        return nil
    }

    private static func parseNotes(from music: String) -> [LilyNote] {
        let spaced = music
            .replacingOccurrences(of: "|", with: " | ")
            .replacingOccurrences(of: "{", with: " { ")
            .replacingOccurrences(of: "}", with: " } ")

        let tokens = spaced.split { $0.isWhitespace }.map(String.init)
        var notes: [LilyNote] = []
        var measure = 1
        var lastDuration = 4
        var skipTokens = 0

        for raw in tokens {
            var token = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            token = token.trimmingCharacters(in: CharacterSet(charactersIn: ";"))

            if token == "|" {
                measure += 1
                continue
            }

            if skipTokens > 0 {
                skipTokens -= 1
                continue
            }

            if token == "\\key" {
                skipTokens = 2
                continue
            }

            if token == "\\time" || token == "\\clef" || token == "\\tempo" || token == "\\bar" {
                skipTokens = 1
                continue
            }

            if token.hasPrefix("\\") || token == "{" || token == "}" || token.hasPrefix("\"") {
                continue
            }

            guard let parsed = parseNoteToken(token, defaultDuration: lastDuration) else {
                continue
            }

            lastDuration = parsed.duration
            notes.append(LilyNote(pitch: parsed.pitch, duration: parsed.duration, measure: measure, token: raw))
        }

        return notes
    }

    private static func parseNoteToken(_ token: String, defaultDuration: Int) -> (pitch: String, duration: Int)? {
        guard let first = token.first?.lowercased(), "abcdefgr".contains(first) else { return nil }

        var pitch = ""
        var digits = ""
        var readingDuration = false

        for char in token {
            if char.isNumber {
                readingDuration = true
                digits.append(char)
            } else if readingDuration {
                if char == "." { continue }
                break
            } else {
                if char.isLetter || char == "'" || char == "," {
                    pitch.append(char)
                } else {
                    break
                }
            }
        }

        guard !pitch.isEmpty else { return nil }
        let duration = Int(digits) ?? defaultDuration
        guard [1, 2, 4, 8, 16, 32].contains(duration) else { return nil }
        return (pitch, duration)
    }
}

enum LilyPDFRenderer {
    static func render(title: String, notes: [LilyNote], source: String) -> Data {
        let page = CGRect(x: 0, y: 0, width: 842, height: 595)
        let renderer = UIGraphicsPDFRenderer(bounds: page)

        return renderer.pdfData { context in
            context.beginPage()
            let cg = context.cgContext

            UIColor.white.setFill()
            cg.fill(page)

            drawHeader(title: title, page: page)
            drawStaff(notes: notes, page: page, context: cg)
            drawFooter(source: source, page: page)
        }
    }

    private static func drawHeader(title: String, page: CGRect) {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 28),
            .foregroundColor: UIColor.black
        ]
        let subtitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 13),
            .foregroundColor: UIColor.darkGray
        ]

        NSString(string: title).draw(in: CGRect(x: 48, y: 36, width: page.width - 96, height: 36), withAttributes: titleAttributes)
        NSString(string: "Generated offline by LilyPad Swift subset compiler").draw(in: CGRect(x: 48, y: 74, width: page.width - 96, height: 22), withAttributes: subtitleAttributes)
    }

    private static func drawStaff(notes: [LilyNote], page: CGRect, context cg: CGContext) {
        let margin: CGFloat = 56
        let staffTop: CGFloat = 170
        let lineSpacing: CGFloat = 12
        let staffWidth = page.width - margin * 2
        let bottomLine = staffTop + lineSpacing * 4

        cg.setStrokeColor(UIColor.black.cgColor)
        cg.setLineWidth(1)

        for line in 0..<5 {
            let y = staffTop + CGFloat(line) * lineSpacing
            cg.move(to: CGPoint(x: margin, y: y))
            cg.addLine(to: CGPoint(x: margin + staffWidth, y: y))
            cg.strokePath()
        }

        drawClef(at: CGPoint(x: margin + 8, y: staffTop - 12))

        let startX = margin + 74
        let endX = page.width - margin - 24
        let available = max(endX - startX, 1)
        let step = available / CGFloat(max(notes.count, 1))
        var previousMeasure = notes.first?.measure ?? 1

        for (index, note) in notes.enumerated() {
            let x = startX + CGFloat(index) * step + step * 0.35

            if note.measure != previousMeasure {
                let barX = x - step * 0.45
                cg.move(to: CGPoint(x: barX, y: staffTop))
                cg.addLine(to: CGPoint(x: barX, y: bottomLine))
                cg.strokePath()
                previousMeasure = note.measure
            }

            drawNote(note, atX: x, bottomLine: bottomLine, lineSpacing: lineSpacing, context: cg)
        }
    }

    private static func drawClef(at point: CGPoint) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 42),
            .foregroundColor: UIColor.black
        ]
        NSString(string: "𝄞").draw(at: point, withAttributes: attributes)
    }

    private static func drawNote(_ note: LilyNote, atX x: CGFloat, bottomLine: CGFloat, lineSpacing: CGFloat, context cg: CGContext) {
        let y = yPosition(for: note.pitch, bottomLine: bottomLine, lineSpacing: lineSpacing)
        let oval = CGRect(x: x - 7, y: y - 5, width: 14, height: 10)

        UIColor.black.setFill()
        cg.fillEllipse(in: oval)

        if note.duration >= 4 {
            cg.setLineWidth(1.5)
            cg.move(to: CGPoint(x: x + 7, y: y))
            cg.addLine(to: CGPoint(x: x + 7, y: y - 42))
            cg.strokePath()
        }

        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        NSString(string: note.displayName).draw(in: CGRect(x: x - 18, y: bottomLine + 24, width: 42, height: 14), withAttributes: textAttributes)
    }

    private static func yPosition(for pitch: String, bottomLine: CGFloat, lineSpacing: CGFloat) -> CGFloat {
        let base = pitch.lowercased().first ?? "c"
        let halfStep = lineSpacing / 2

        switch base {
        case "c": return bottomLine + halfStep * 2
        case "d": return bottomLine + halfStep
        case "e": return bottomLine
        case "f": return bottomLine - halfStep
        case "g": return bottomLine - halfStep * 2
        case "a": return bottomLine - halfStep * 3
        case "b": return bottomLine - halfStep * 4
        case "r": return bottomLine - halfStep * 2
        default: return bottomLine
        }
    }

    private static func drawFooter(source: String, page: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.gray
        ]
        let footer = "LilyPad v0.2 MVP · Offline subset preview · \(Date().formatted(date: .abbreviated, time: .shortened))"
        NSString(string: footer).draw(in: CGRect(x: 48, y: page.height - 42, width: page.width - 96, height: 18), withAttributes: attributes)
    }
}
