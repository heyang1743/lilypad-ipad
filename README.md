# LilyPad iPad

LilyPad 是一个面向 iPad 的 LilyPond `.ly` 编辑器壳工程。

当前版本提供：

- SwiftUI iPad 三栏界面
- LilyPond 源码编辑区
- 示例 `.ly` 谱库
- 快捷插入按钮
- Swift LilyPond 子集离线预览/渲染原型（不包含 GNU LilyPond）
- PDFKit 乐谱预览
- 编译日志面板
- GitHub Actions 云端 unsigned IPA 构建

> 重要说明：当前 IPA **不包含完整 GNU LilyPond 编译器**，也不包含 Guile/Ghostscript/Fontconfig 等 LilyPond 依赖。当前功能只是 Swift 写的 LilyPond 子集解析 + PDF 渲染原型，用于验证 iPad 离线工作流。真正完整 LilyPond 离线引擎需要单独移植或 WASM 化，见 `docs/REAL_LILYPOND_ENGINE.md`。

## GitHub Actions 构建

仓库 push 后会自动运行：

```text
.github/workflows/build-unsigned.yml
```

产物位置：

```text
GitHub → Actions → Build unsigned iPad IPA → Artifacts
```

会生成：

```text
LilyPad-unsigned.ipa
LilyPad-build-report.txt
LilyPad-ipa-listing.txt
```

CI 会强制校验：

- `.app` 是否存在
- 主可执行文件是否存在且大小合理
- `Info.plist` 是否存在
- `Assets.car` 是否存在
- IPA 内部文件列表

这个 IPA 是未签名包，主要用于检查构建结果，通常不能直接安装到 iPad。

## 下一版本计划

下一版本目标：

```text
v0.2 Offline Compile + UI Refresh
```

重点：

- iPad 端完整 LilyPond 离线引擎研究
- 美化 iPad 三栏 UI
- 文件管理
- PDF 预览
- 编译日志
- 保留 unsigned IPA 云端构建

详细计划见：

```text
docs/NEXT_VERSION_PLAN.md
```

## 默认信息

```text
App Name: LilyPad
Bundle ID: io.github.heyang1743.lilypad
iPad only: yes
Deployment Target: iPadOS 17.0+
```

## 后续开发路线

1. 完善 `.ly` 文件管理。
2. 添加语法高亮和行号。
3. 扩展 Swift LilyPond 子集渲染器。
4. 改进 PDF 生成质量和 PDFKit 预览。
5. 研究并接入完整 GNU LilyPond/WASM 离线引擎。
