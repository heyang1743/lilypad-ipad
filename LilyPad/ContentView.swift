import SwiftUI
import Foundation
import UIKit

private enum CompileStatus {
    case idle
    case success
    case failed

    var title: String {
        switch self {
        case .idle: return "等待编译"
        case .success: return "离线编译成功"
        case .failed: return "编译失败"
        }
    }

    var symbol: String {
        switch self {
        case .idle: return "circle.dotted"
        case .success: return "checkmark.seal.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .idle: return .secondary
        case .success: return .green
        case .failed: return .orange
        }
    }
}

struct ContentView: View {
    @State private var selectedExampleID: String? = ExampleScore.all.first?.id
    @State private var documentName = "C 大调练习.ly"
    @State private var lilyCode = ExampleScore.all.first?.source ?? ""
    @State private var logText = "LilyPad v0.2 已就绪。点击“离线编译”会使用 Swift LilyPond 子集编译器生成 PDF 预览。"
    @State private var pdfData: Data?
    @State private var compileStatus: CompileStatus = .idle
    @State private var noteCount = 0

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationTitle("LilyPad")
        } content: {
            editorPane
                .navigationTitle(documentName)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button {
                            copySource()
                        } label: {
                            Label("复制", systemImage: "doc.on.doc")
                        }

                        Button {
                            compileOffline()
                        } label: {
                            Label("离线编译", systemImage: "play.fill")
                        }
                    }
                }
        } detail: {
            previewPane
                .navigationTitle("PDF 预览")
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedExampleID) { _, newValue in
            loadExample(id: newValue)
        }
    }

    private var sidebar: some View {
        List(selection: $selectedExampleID) {
            Section("工作区") {
                Button {
                    newScore()
                } label: {
                    Label("新建谱子", systemImage: "doc.badge.plus")
                }

                Button {
                    insertCommonSnippet()
                } label: {
                    Label("插入常用片段", systemImage: "text.badge.plus")
                }
            }

            Section("示例谱") {
                ForEach(ExampleScore.all) { example in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(example.title)
                            .font(.headline)
                        Text(example.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    .tag(example.id as String?)
                }
            }

            Section("离线编译状态") {
                statusCard
            }
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(compileStatus.title, systemImage: compileStatus.symbol)
                .foregroundStyle(compileStatus.color)
                .font(.headline)

            Text("识别音符：\(noteCount)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("当前引擎：Swift LilyPond 子集 MVP")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var editorPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerCard

            ZStack(alignment: .topLeading) {
                TextEditor(text: $lilyCode)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .scrollContentBackground(.hidden)
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )

                if lilyCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("在这里输入 LilyPond 源码…")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                        .padding(.top, 22)
                        .padding(.leading, 22)
                        .allowsHitTesting(false)
                }
            }

            quickInsertBar
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground).opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var headerCard: some View {
        HStack(spacing: 14) {
            Image(systemName: "music.note.list")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 4) {
                Text(documentName)
                    .font(.title3.bold())
                Text("iPad 离线编译 MVP · 美化三栏 UI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                compileOffline()
            } label: {
                Label("离线编译", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var quickInsertBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                snippetButton("\\score")
                snippetButton("\\relative")
                snippetButton("\\layout")
                snippetButton("\\midi")
                snippetButton("\\header")
                snippetButton("c4 d e f |")
            }
        }
    }

    private func snippetButton(_ text: String) -> some View {
        Button(text) {
            lilyCode += "\n" + text + " "
        }
        .font(.system(.caption, design: .monospaced))
        .buttonStyle(.bordered)
    }

    private var previewPane: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let pdfData {
                PDFKitPreview(data: pdfData)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            } else {
                previewPlaceholder
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("编译日志", systemImage: "terminal")
                        .font(.headline)
                    Spacer()
                    Text(compileStatus.title)
                        .font(.caption)
                        .foregroundStyle(compileStatus.color)
                }

                ScrollView {
                    Text(logText)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 180)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding()
    }

    private var previewPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.richtext")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text("还没有 PDF 预览")
                .font(.title3.bold())

            Text("点击“离线编译”，LilyPad 会在 iPad 端用 Swift 子集编译器生成 PDF 乐谱预览。")
                .multilineTextAlignment(.center)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 360)

            Button {
                compileOffline()
            } label: {
                Label("立即离线编译", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func compileOffline() {
        let result = LilySubsetCompiler.compile(lilyCode)
        pdfData = result.pdfData
        logText = result.log
        noteCount = result.notes.count
        compileStatus = result.success ? .success : .failed
    }

    private func loadExample(id: String?) {
        guard let id, let example = ExampleScore.all.first(where: { $0.id == id }) else { return }
        documentName = "\(example.title).ly"
        lilyCode = example.source
        pdfData = nil
        noteCount = 0
        compileStatus = .idle
        logText = "已加载示例：\(example.title)。点击“离线编译”生成 PDF 预览。"
    }

    private func newScore() {
        selectedExampleID = nil
        documentName = "Untitled.ly"
        lilyCode = """
        \\version "2.24.0"
        \\language "english"

        \\header {
          title = "Untitled"
          tagline = ##f
        }

        \\score {
          \\relative c' {
            \\key c \\major
            \\time 4/4
            c4 d e f | g2 g \\bar "|."
          }
          \\layout { }
        }
        """
        pdfData = nil
        noteCount = 0
        compileStatus = .idle
        logText = "已新建谱子。"
    }

    private func insertCommonSnippet() {
        lilyCode += """

        \\score {
          \\relative c' {
            c4 d e f | g1
          }
          \\layout { }
          \\midi { }
        }
        """
        logText = "已插入常用 LilyPond 片段。"
    }

    private func copySource() {
        UIPasteboard.general.string = lilyCode
        logText = "已复制 LilyPond 源码到剪贴板。"
    }
}

#Preview {
    ContentView()
}
