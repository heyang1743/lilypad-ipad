# LilyPad iPad

LilyPad 是一个面向 iPad 的 LilyPond `.ly` 编辑器壳工程。

当前版本提供：

- SwiftUI iPad 三栏界面
- LilyPond 源码编辑区
- 示例 `.ly` 谱库
- 快捷插入按钮
- Swift LilyPond 子集离线编译 MVP
- PDFKit 乐谱预览
- 编译日志面板
- GitHub Actions 云端 unsigned IPA 构建

> 注意：当前离线编译器是 LilyPond 子集 MVP，不是完整 GNU LilyPond。它先支持基础旋律、时值、小节线和 PDF 预览；完整 LilyPond/WASM 引擎作为后续研究方向。

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
```

这个 IPA 是未签名包，主要用于检查构建结果，通常不能直接安装到 iPad。

## 下一版本计划

下一版本目标：

```text
v0.2 Offline Compile + UI Refresh
```

重点：

- iPad 端离线编译 `.ly`
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
3. 扩展 Swift LilyPond 子集编译器。
4. 改进 PDF 生成质量和 PDFKit 预览。
5. 研究完整 LilyPond/WASM 离线引擎。
