import SwiftUI
import UIKit

struct ContentView: View {
    @State private var lilyCode = """
    \\version "2.24.0"
    \\language "english"

    \\header {
      title = "LilyPad Demo"
      composer = "iPad"
      tagline = ##f
    }

    \\paper {
      #(set-paper-size "a4landscape")
    }

    \\score {
      \\relative c' {
        \\key c \\major
        \\time 4/4
        c4 d e f | g2 g |
        a4 g f e | d2 c \\bar "|."
      }
      \\layout { }
      \\midi { }
    }
    """

    @State private var logText = "LilyPad 已就绪。当前版本是 iPad LilyPond 编辑器壳，后续可接入本地编译核心或云端编译。"

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 12) {
                Text("LilyPond 源码")
                    .font(.title2.bold())

                TextEditor(text: $lilyCode)
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack {
                    Button("复制源码") {
                        UIPasteboard.general.string = lilyCode
                        logText = "已复制 LilyPond 源码到剪贴板。"
                    }
                    .buttonStyle(.bordered)

                    Button("检查示例") {
                        logText = basicCheck(code: lilyCode)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("LilyPad")
        } detail: {
            VStack(alignment: .leading, spacing: 12) {
                Text("输出 / 日志")
                    .font(.title2.bold())

                ScrollView {
                    Text(logText)
                        .font(.system(.body, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                Text("提示：真正本地编译 LilyPond 需要移植 LilyPond/Guile，不能直接在 iOS App 内运行 Linux 命令行。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("预览")
        }
    }

    private func basicCheck(code: String) -> String {
        var messages: [String] = []
        if code.contains("\\version") {
            messages.append("✅ 找到 \\version")
        } else {
            messages.append("⚠️ 建议添加 \\version")
        }

        if code.contains("\\score") {
            messages.append("✅ 找到 \\score")
        } else {
            messages.append("⚠️ 没有找到 \\score")
        }

        if code.contains("\\midi") {
            messages.append("✅ 包含 MIDI 输出块")
        } else {
            messages.append("ℹ️ 如果需要 MIDI，可添加 \\midi { }")
        }

        messages.append("\n当前只是语法提示，不是真正 LilyPond 编译。")
        return messages.joined(separator: "\n")
    }
}

#Preview {
    ContentView()
}
