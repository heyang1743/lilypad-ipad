# 真实 GNU LilyPond 离线引擎说明

## 结论

当前 `LilyPad-unsigned.ipa` **没有包含完整 GNU LilyPond 编译器**。

当前 IPA 内的功能是：

```text
Swift 写的 LilyPond 子集解析器/渲染器
↓
识别基础音符、时值、小节线
↓
用 UIKit/CoreGraphics 生成简单 PDF 预览
```

它不是：

```text
GNU LilyPond
Guile Scheme runtime
Ghostscript
Fontconfig/Freetype/Pango/Harfbuzz 完整工具链
```

所以，几百 KB 的 IPA 不可能等价于完整 LilyPond 离线编译器。

---

## 为什么不能直接把 lilypond 放进 IPA

桌面版 LilyPond 是一个命令行工具链，通常依赖：

- GNU LilyPond 主程序
- Guile Scheme 运行时
- Boehm GC
- 字体处理库
- PostScript/PDF 输出链路
- 一批内部 Scheme/字体/资源文件

iOS App 不能像 Linux/macOS 一样随便 `fork/exec` 一个外部命令行程序。即使把二进制文件塞进 IPA，也不等于能在 iPad 上运行。

要做真正 iPad 本地 LilyPond，需要把引擎改造成 iOS App 可调用的库或 WASM 模块。

---

## 真正完整 LilyPond 离线引擎的验收标准

如果以后声称“IPA 包含完整 LilyPond 离线引擎”，必须满足以下条件：

1. IPA 内有明确的引擎产物，例如：

```text
LilyPondEngine.framework
lilypond.wasm
Guile runtime resources
LilyPond scheme/font resources
```

2. 构建报告必须列出这些文件和大小。

3. CI 必须运行一个真实 `.ly` 渲染测试，例如：

```lilypond
\version "2.24.0"
{ c'4 d' e' f' }
```

并验证输出 PDF/SVG/MIDI 存在。

4. App 内必须明确显示引擎模式：

```text
GNU LilyPond engine
```

而不是：

```text
Swift subset renderer
```

5. 体积不应是几百 KB。完整引擎大概率会是数十 MB 甚至更大，具体取决于静态链接、资源裁剪和字体策略。

---

## 可行技术路线

### 路线 A：WASM LilyPond 引擎

目标：把 LilyPond 或兼容引擎编译为 WebAssembly，在 iOS App 内通过 `WKWebView` 或 JavaScriptCore 离线运行。

优点：

- 更适合 iOS 沙盒
- 不需要外部进程
- 可离线运行
- 可复用到网页版本

难点：

- LilyPond 依赖 Guile，WASM 化难度高
- PDF/MIDI 输出路径需要重新适配
- 需要打包字体和 Scheme 资源

### 路线 B：iOS 原生静态库/Framework

目标：移植 LilyPond、Guile、GC 和相关依赖到 iOS，封装成 Swift 可调用的 framework。

优点：

- 最接近真正 GNU LilyPond
- 不依赖浏览器容器

难点：

- 工程量很大
- Guile/Boehm GC/iOS 沙盒兼容性复杂
- 需要重写路径、资源加载和输出流程

### 路线 C：Swift 子集渲染器

这是当前已经实现的 MVP。

优点：

- 体积小
- 立刻可离线
- 能验证 iPad UI 和 PDF 预览工作流

缺点：

- 不是 GNU LilyPond
- 只能支持非常有限的 `.ly` 子集
- 不能声称是完整 LilyPond 编译器

---

## 当前项目状态

当前状态应该准确描述为：

```text
LilyPad is an iPad LilyPond editor shell with a Swift subset renderer prototype.
```

不应该描述为：

```text
LilyPad contains GNU LilyPond compiler.
```

---

## 下一步建议

如果目标是真正完整 LilyPond：

1. 先暂停扩展 Swift 子集渲染器。
2. 建立 `engine-research` 分支。
3. 调研 LilyPond WASM 是否已有可复用项目。
4. 如果没有，评估原生移植依赖树。
5. 在 CI 中加入真实引擎产物校验。
6. 只有当 IPA 内确实包含 engine artifact，并能渲染真实 `.ly`，才称为完整离线引擎。
