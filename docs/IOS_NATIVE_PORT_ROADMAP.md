# iOS 原生 LilyPond 移植执行路线图

分支：`engine-research`  
目标：把真正 GNU LilyPond 移植为 iPad App 内可调用原生引擎。  
本文是执行路线，不包含代码实现。

---

## 总原则

1. 不再把 Swift 子集渲染器当成 LilyPond 编译器。
2. 先验证依赖链，尤其是 Guile。
3. 每一阶段必须有可验证产物。
4. 只有真实 GNU LilyPond 能把 `.ly` 输出 PDF/MIDI，才恢复“编译”字样。
5. iOS App 不能依赖外部 `lilypond` 进程，必须是 framework/static library/WASM 这类 App 内引擎。

---

## Phase 0：冻结现有原型

状态：已完成。

目的：

```text
停止误导性说法，保留 Swift 子集渲染器作为 UI placeholder。
```

产物：

```text
docs/REAL_LILYPOND_ENGINE.md
```

通过标准：

- README 明确写当前 IPA 不包含 GNU LilyPond。
- App UI 明确写当前是 Swift 子集渲染器。
- CI 不再使用 compiler marker，而使用 not-GNU-LilyPond marker。

---

## Phase 1：依赖审计

状态：进行中。

产物：

```text
docs/IOS_NATIVE_PORT_AUDIT.md
```

已确认：

```text
LilyPond 2.25.17 runtime depends on:
- Guile
- Boehm GC
- Cairo
- Fontconfig
- Freetype
- GLib/GObject
- PangoFT2
- libpng
- zlib
- Ghostscript
- Python3
```

通过标准：

- 明确 build-time 依赖和 runtime 依赖。
- 明确哪些依赖必须进 IPA。
- 明确哪些依赖可以裁剪。
- 明确最大风险模块。

当前结论：

```text
Guile 是最高风险模块。
Ghostscript/libgs 是体积和许可高风险模块。
Fontconfig/Pango/Cairo 是 iOS 适配高风险模块。
```

---

## Phase 2：Guile iOS 最小验证

这是第一个真正技术 Gate。

目标：

```text
在 iOS simulator arm64 中链接并运行 Guile。
```

最小测试：

```scheme
(display "hello")
```

验证目标：

```text
xcodebuild test
↓
iOS simulator test target
↓
调用 Guile 初始化
↓
执行 Scheme
↓
捕获输出 hello
↓
测试通过
```

需要构建：

```text
Boehm GC
GMP
libffi
libunistring
Guile
```

失败条件：

- Guile 无法交叉编译到 iOS。
- Guile 能编译但 simulator 启动崩溃。
- Boehm GC 在 iOS 栈扫描/线程模型下不可用。
- Guile 运行时强依赖 iOS 不允许的动态加载或文件路径。

如果 Phase 2 失败：

```text
原生 LilyPond 移植暂停，转向 WASM 或替代引擎。
```

---

## Phase 3：字体与 PDF 输出最小验证

只有 Phase 2 成功后才做。

目标：

```text
验证 iOS App 内可以使用 Cairo/Freetype/Fontconfig/Pango 生成 PDF。
```

需要构建：

```text
zlib
libpng
Freetype
Fontconfig
HarfBuzz
GLib/GObject
PangoFT2
Cairo
```

最小测试：

```text
加载 Bundle 内字体
↓
创建 cairo_pdf_surface
↓
绘制文字/五线谱测试图形
↓
生成 PDF
↓
PDFKit 打开
```

关键裁剪目标：

```text
禁用 X11/xcb backend
禁用不需要的 image/font backend
使用 Bundle 内 fontconfig 配置
```

失败条件：

- Cairo/Pango 强依赖 X11/xcb。
- Fontconfig 无法在 iOS 沙盒中稳定加载 Bundle 字体。
- 生成 PDF 失败或 PDFKit 无法打开。

---

## Phase 4：LilyPond C++ core 交叉编译

目标：

```text
让 LilyPond core 编译成 iOS arm64 静态库或 framework。
```

重点工作：

```text
1. 使用 iOS toolchain 编译 C++ core
2. 禁用或替换外部命令路径
3. 不直接使用 main()
4. 抽出 library entrypoint
5. 改造日志输出
6. 改造路径和资源加载
```

候选 C API：

```c
int lilypond_engine_init(const char *resource_dir, LilyPondLogCallback log);
int lilypond_engine_compile_file(const char *input_ly, const char *output_dir, LilyPondResult *result);
void lilypond_engine_shutdown(void);
```

通过标准：

- 能产出 `LilyPondEngine.framework` 或静态库。
- simulator test 能链接该库。
- 初始化不会崩溃。

---

## Phase 5：资源打包

目标：

```text
把 LilyPond runtime resources 打进 App Bundle。
```

资源包括：

```text
ly include files
Scheme files / ccache
Emmentaler fonts
fontconfig config
Guile runtime files
locale/config as needed
```

候选结构：

```text
LilyPondResources.bundle/
  lilypond/2.xx.x/ly/
  lilypond/2.xx.x/fonts/
  lilypond/2.xx.x/ccache/
  guile/3.0/
  fontconfig/
```

通过标准：

- engine 能从 Bundle 路径加载资源。
- 不依赖 `/usr/share`、`/usr/lib`、`PATH`。
- build report 列出资源文件数量和总大小。

---

## Phase 6：真实 `.ly` → PDF

目标：

```text
真实 GNU LilyPond engine 在 iOS simulator 中编译最小 .ly。
```

测试文件：

```lilypond
\version "2.24.0"
{ c'4 d' e' f' }
```

通过标准：

```text
输入 .ly
↓
GNU LilyPond native engine
↓
输出 PDF
↓
CI 检查 PDF 非空
↓
PDFKit 能打开
```

CI 必须记录：

```text
LilyPond version
Guile version
PDF file size
engine framework size
resource bundle size
compile log
```

---

## Phase 7：MIDI 输出

只有 PDF 成功后再做。

目标：

```text
真实 LilyPond 输出 MIDI。
```

通过标准：

- 最小 `.ly` 能输出 `.midi`。
- App 可以用本地播放器或文件分享打开 MIDI。

---

## Phase 8：App 集成

目标：

```text
把 placeholder Swift subset renderer 替换为 GNU LilyPond Native engine。
```

UI 文案恢复为：

```text
Engine: GNU LilyPond Native
Mode: Offline
Version: x.y.z
```

按钮恢复为：

```text
编译 LilyPond
```

通过标准：

- App 内真实编译 `.ly`。
- App 内显示 PDF。
- 日志显示 GNU LilyPond 输出。
- IPA build report 显示 engine 和 resources。

---

## Phase 9：许可合规

必须在实际分发前完成。

检查项：

```text
LilyPond GPL-3.0-or-later
Guile LGPL/GPL 组合
Ghostscript AGPL/GPL 风险
Font libraries licenses
静态链接 GPL 影响
IPA 分发是否需要公开完整源码和构建脚本
```

通过标准：

- LICENSE 文档完整。
- 源码公开策略明确。
- 第三方依赖许可证清单完整。
- 如果使用 libgs/Ghostscript，明确其许可影响。

---

## 推荐立即执行的下一步

如果继续执行，不要直接碰 LilyPond core。

应该先做：

```text
Phase 2: Guile iOS 最小验证
```

具体任务：

```text
1. 创建 native-engine-lab/
2. 写 iOS cross compile 脚本，只构建 Boehm GC + GMP + libffi + libunistring + Guile
3. 生成 GuileEngine.xcframework
4. 建 iOS simulator test target
5. 测试 Scheme hello world
```

只有这个通过，才值得继续做 LilyPond native port。
