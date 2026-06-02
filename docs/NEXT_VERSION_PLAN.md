# LilyPad v0.2 下一版本计划

目标版本：`v0.2 Subset Preview + UI Refresh`

核心目标：

1. iPad 端 LilyPond 子集离线预览/渲染，不包含完整 GNU LilyPond
2. 美化 UI，做成真正可用的 iPad 编辑器
3. 保留 GitHub Actions 云端构建能力

---

## 1. 版本目标

### v0.2 必须实现

- iPad 横竖屏自适应编辑界面
- `.ly` 文件创建、打开、保存
- LilyPond 源码编辑器基础优化
- 本地子集离线预览/渲染技术原型
- 编译日志面板
- PDF 预览面板
- 示例谱库
- 更好看的 iPad 双栏/三栏 UI

### v0.2 不承诺完整实现

- 完整 LilyPond 100% 语法兼容
- App Store 上架
- 完整 Guile/LilyPond 原生移植完成

原因：iOS 不能像 Linux/macOS 一样直接运行 `lilypond` 命令行程序。真正子集离线预览/渲染需要把排版核心移植进 App。

---

## 2. iPad 子集离线预览/渲染技术路线

### 路线 A：WASM 子集离线预览/渲染核心，优先研究

目标：把 LilyPond 或兼容排版核心编译成 WebAssembly，然后在 iPad App 内通过 `WKWebView` 或 JavaScriptCore 离线运行。

架构：

```text
SwiftUI App
↓
.ly 编辑器
↓
本地 WASM 编译引擎
↓
PDF / SVG / MIDI 输出
↓
PDFKit / QuickLook 预览
```

优点：

- 更适合 iOS 沙盒
- 不需要运行外部命令
- 可离线
- 后续也可复用到网页版本

难点：

- LilyPond 依赖 Guile、字体库、排版库，WASM 移植复杂
- 需要验证 PDF/MIDI 输出能力
- 可能需要先做 LilyPond 语法子集

v0.2 目标：

- 做 WASM 可行性验证
- 至少实现一个子集离线预览/渲染 demo
- 如果完整 LilyPond 不现实，先支持 LilyPond 子集

---

### 路线 B：iOS 原生移植 LilyPond，长期路线

目标：把 LilyPond、Guile、Boehm GC、Freetype、Fontconfig、Ghostscript/输出模块移植为 iOS 可用静态库或 framework。

架构：

```text
SwiftUI
↓
C/C++/Scheme native bridge
↓
LilyPond core
↓
PDF/MIDI output
```

优点：

- 最接近真正 LilyPond
- 不依赖浏览器环境

难点：

- 移植工作量大
- Guile + GC 在 iOS 上难度高
- 字体、文件路径、沙盒权限要重写适配

v0.2 只做调研，不作为主线实现。

---

### 路线 C：Swift 内置轻量子集渲染器，作为 MVP 备选

如果完整 LilyPond 子集离线预览/渲染太难，先做一个 LilyPond 子集解释器/渲染器：

支持：

- `\version`
- `\relative`
- `\key`
- `\time`
- 基本音符：`c d e f g a b`
- 时值：`1 2 4 8 16`
- 小节线
- 简单和弦名

输出：

- PDF：CoreGraphics / PDFKit 生成
- MIDI：Swift MIDI 文件生成器

优点：

- 真正离线
- 可快速实现
- 适合作为 v0.2 MVP

缺点：

- 不是完整 LilyPond
- 只能支持子集语法

v0.2 推荐策略：

```text
先做 Swift LilyPond 子集渲染器 MVP（明确不是 GNU LilyPond）
同时并行研究 WASM 完整引擎
```

---

## 3. v0.2 功能模块拆分

### 3.1 文件系统

目标：让用户真的可以管理 `.ly` 文件。

任务：

- 新建文件
- 打开文件
- 保存文件
- 另存为
- 最近文件列表
- 示例文件列表
- iCloud Drive / Files App 文档选择器

优先级：高

---

### 3.2 编辑器 UI

目标：比普通 `TextEditor` 更像代码编辑器。

任务：

- 等宽字体
- 行号
- 当前行高亮
- 搜索
- 基础语法高亮
- 快捷插入按钮：
  - `\score`
  - `\relative`
  - `\layout`
  - `\midi`
  - `\header`
  - 常用音符
- iPad 键盘快捷键

优先级：高

---

### 3.3 编译面板

目标：形成完整工作流。

任务：

- 编译按钮
- 编译进度状态
- 编译日志
- 错误行提示
- 输出文件列表
- 重新编译
- 清理输出

优先级：高

---

### 3.4 PDF 预览

目标：编译后可以直接看谱。

任务：

- PDFKit 预览
- 翻页
- 缩放
- 横屏优化
- 导出 PDF
- 分享 PDF 到 Files / GoodNotes / forScore

优先级：高

---

### 3.5 MIDI 预览

目标：可以试听。

任务：

- 生成 `.mid`
- 本地播放 MIDI
- 播放/暂停
- 速度控制

优先级：中

---

## 4. UI 美化方向

### 4.1 iPad 三栏布局

推荐界面：

```text
左侧：文件 / 示例谱 / 最近项目
中间：LilyPond 源码编辑器
右侧：PDF 预览 / 编译日志
```

适配：

- 竖屏：双栏或标签页
- 横屏：三栏
- Stage Manager：动态宽度

---

### 4.2 视觉风格

方向：简洁、专业、偏音乐软件。

设计元素：

- 深色/浅色模式
- 类 Xcode/Frescobaldi 的编辑区
- 卡片式日志面板
- 毛玻璃工具栏
- 蓝紫色强调色
- 乐谱白色预览纸张阴影

---

### 4.3 首页设计

首页包含：

- 新建谱子
- 打开文件
- 最近项目
- 示例模板
- 子集离线预览/渲染状态
- LilyPond 引擎版本/模式

---

## 5. 推荐开发顺序

### 第 1 周：UI 骨架

- 三栏布局
- 文件侧边栏
- 编辑器区域
- 预览/日志区域
- README 更新

### 第 2 周：文件管理

- 新建/保存 `.ly`
- 示例谱
- 最近文件
- Share Sheet

### 第 3 周：子集离线预览/渲染 MVP

- Swift LilyPond 子集渲染器
- PDF 生成
- 编译日志
- 错误提示

### 第 4 周：PDF 预览和导出

- PDFKit 预览
- 导出 PDF
- 分享到其他 App

### 第 5 周：WASM/LilyPond 完整引擎调研

- WASM 可行性测试
- Guile/LilyPond 依赖分析
- 决定是否进入 v0.3

---

## 6. v0.2 验收标准

v0.2 完成时，应满足：

- App 在 iPad 上有完整编辑器 UI
- 可以新建并保存 `.ly`
- 可以离线把简单 `.ly` 子集编译成 PDF
- 可以在 App 内预览 PDF
- 可以分享导出 PDF
- GitHub Actions 能继续生成 unsigned IPA
- README 清楚说明当前支持范围

---

## 7. v0.3 展望

v0.3 目标：接近真正 LilyPond。

可能方向：

- 更完整的 LilyPond parser
- WASM LilyPond 引擎
- MIDI 播放
- 语法高亮增强
- 错误定位
- 模板库
- iCloud 同步
- Apple Pencil 批注 PDF
