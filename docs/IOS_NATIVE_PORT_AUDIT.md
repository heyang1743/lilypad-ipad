# iOS 原生 GNU LilyPond 移植依赖审计

分支：`engine-research`  
目标：评估把真正 GNU LilyPond 引擎移植为 iOS App 内可调用 native engine 的可行性。  
范围：调研文档，不包含引擎代码。

---

## 0. 结论先行

当前项目里的 Swift 子集渲染器不是 GNU LilyPond。要实现真正 iPad 离线编译，必须移植 LilyPond 及其运行时依赖。

初步结论：

1. **原生 iOS 移植可做，但难点集中在 Guile、Boehm GC、Fontconfig/Pango/Cairo、Ghostscript/libgs、资源路径和 GPL/AGPL 许可。**
2. LilyPond 目前是明显的命令行程序结构：`main()` → `parse_argv()` → `setup_paths()` → `scm_boot_guile()`。
3. iOS App 不能依赖外部 `lilypond` 进程；必须改造成库 API，例如 `lilypond_compile(...)`。
4. 完整引擎体积不会是几百 KB。以 Alpine aarch64 包估算，未裁剪运行时和资源很容易达到几十 MB 以上。
5. 第一验证点不是 LilyPond，而是 **Guile 能否在 iOS app/simulator 进程中稳定启动并执行 Scheme**。

---

## 1. 已审计版本

本次参考版本：

```text
GNU LilyPond 2.25.17
Guile 3.0.9
Alpine Linux aarch64 package set
```

说明：

- 2.25.17 是当前 Alpine 包版本。
- 真正移植时仍需比较 `2.24.x stable` 与 `2.26.x stable`。
- 优先建议从 2.24/2.26 stable 中选一个，而不是直接追开发版。

---

## 2. Alpine 运行时依赖审计

`apk info -R lilypond` 显示 LilyPond 运行时依赖：

```text
ghostscript
guile
python3
libc
cairo
fontconfig
freetype
gc / Boehm GC
glib
gobject
guile-3.0
intl
pango
pangoft2
libpng
zlib
libstdc++
```

`ldd /usr/bin/lilypond` 显示动态库链路中还会间接拉入：

```text
pcre2
libffi
libunistring
gmp
gio
harfbuzz
fribidi
expat
bz2
brotli
pixman
libgcc_s
gmodule
mount/blkid 等 Linux 相关库
X11 / Xext / Xrender / xcb 等桌面图形相关库
```

注意：

- X11/xcb 主要来自 Cairo/字体栈在 Linux 上的构建方式。
- iOS 原生移植应避免 X11/xcb，改走 iOS 可用后端或禁用相关 backend。

---

## 3. 体积审计

在当前 Alpine 环境中：

```text
/usr/bin/lilypond             3.4 MB
/usr/lib/lilypond             11 MB
/usr/share/lilypond           8.4 MB
/usr/share/guile              5.7 MB
/usr/lib/guile                47 MB
/usr/share/ghostscript        18 MB
```

关键 apk 包安装体积：

```text
lilypond                      20 MB
guile                         50 MB
ghostscript                   61 MB
glib                          5.7 MB
cairo                         1.1 MB
fontconfig                    987 KB
freetype                      706 KB
harfbuzz                      1.2 MB
pango                         744 KB
Boehm GC                      326 KB
libpng                        193 KB
zlib                          129 KB
```

LilyPond 自身资源统计：

```text
/usr/share/lilypond/2.25.17 文件数：308
.ly include 文件数：62
fonts 目录文件数：124
/usr/lib/lilypond/2.25.17 文件数：71
```

推论：

- 如果真的打包完整引擎，IPA 体积大概率是 **几十 MB 级别**。
- 如果包含 Ghostscript/Guile 大量资源，可能更大。
- 几百 KB 的 IPA 不可能包含完整 GNU LilyPond。

---

## 4. LilyPond configure 级依赖

`configure.ac` 显式检查：

```text
Python 3.10+
Bison
Flex
Guile development files
BDW-GC / Boehm GC
FontForge       # build-time
T1ASM           # build-time
Fontconfig >= 2.13
Freetype >= 2.10
GLib >= 2.64
GObject >= 2.64
PangoFT2 >= 1.44.5
Cairo >= 1.16
libpng >= 1.6
zlib
Ghostscript executable gs
optional libgs API: --enable-gs-api
```

Ghostscript 相关 configure 片段显示：

```text
--enable-gs-api
link to libgs and use Ghostscript API instead of invoking the executable.
Beware of licensing implications.
```

对 iOS 的含义：

- 不能依赖 `gs` 外部命令。
- 如果 LilyPond 某些路径需要 Ghostscript，应优先研究 `libgs` API 或绕开相关输出路径。
- `libgs` 会引入额外许可和体积问题。

---

## 5. LilyPond 入口结构审计

`lily/main.cc` 显示当前是命令行程序结构：

```text
main(int argc, char **argv)
  parse_argv(argc, argv)
  setup_paths(argv[0])
  scm_boot_guile(argc, argv, main_with_guile, 0)
```

还依赖命令行参数：

```text
--pdf / --svg / --png / --ps / --eps
--output
--include
--init
--loglevel
--evaluate
--define-default
```

并读取环境变量：

```text
LILYPOND_DATADIR
LILYPOND_LOCALEDIR
LILYPOND_RELOCDIR
FONTCONFIG_FILE
FONTCONFIG_PATH
GS_FONTPATH
GS_LIB
GUILE_LOAD_PATH
PANGO_RC_FILE
PANGO_PREFIX
PATH
```

对 iOS 的含义：

- 不能把 `main()` 原封不动作为 App 内接口。
- 需要封装 library API。
- 需要把 argv/options 变成 Swift/C API 参数。
- 需要把环境变量改造成引擎初始化配置。
- 需要把 stdout/stderr/logging 改造成 callback。
- 需要保证不能 `exit()` 终止 App 进程。

---

## 6. 需要移植/替代的模块

### 必须验证

```text
Boehm GC
GMP
libffi
libunistring
Guile
Freetype
Fontconfig 或 iOS 替代字体索引
HarfBuzz
GLib/GObject
PangoFT2
Cairo
libpng
zlib
LilyPond core
LilyPond resources
```

### 高风险模块

```text
Guile
Boehm GC
Fontconfig
PangoFT2
Cairo output backend
Ghostscript/libgs
LilyPond main-to-library 改造
```

### 可裁剪/需确认

```text
Python3：多为脚本和 helper，运行时是否必须需要确认。
Ghostscript：是否可以只支持 cairo-pdf/svg，避免 PS/EPS/PNG 路径。
X11/xcb：iOS 不应引入，需改 Cairo/Pango 构建选项。
FontForge/T1ASM/TeX：应为 build-time，不能进 IPA。
```

---

## 7. iOS 原生集成目标形态

期望最终 App 包结构：

```text
LilyPad.app/
  Frameworks/
    LilyPondEngine.framework 或 LilyPondEngine.xcframework slice
  LilyPondResources.bundle/
    ly/
    fonts/
    scheme/
    guile/
    fontconfig/
  LilyPad
  Info.plist
```

Swift 目标 API：

```swift
let result = try await LilyPondEngine.compile(
    sourceURL: lyFile,
    outputDirectory: outputDir,
    options: .init(formats: [.pdf, .midi])
)
```

C/C++ 层候选 API：

```c
int lilypond_engine_init(const char *resource_dir, LilyPondLogCallback log);
int lilypond_engine_compile_file(
    const char *input_ly,
    const char *output_dir,
    const char *const *argv_like_options,
    LilyPondResult *result
);
void lilypond_engine_shutdown(void);
```

---

## 8. 第一阶段验证标准

### Gate 1：Guile iOS 最小运行

必须证明：

```text
iOS simulator app/test target
↓
链接 Guile + Boehm GC
↓
调用 scm_boot_guile 或等价初始化
↓
执行 (display "hello")
↓
不崩溃
```

如果 Gate 1 失败，LilyPond 原生移植暂停。

### Gate 2：Font/Cairo 最小输出

必须证明：

```text
iOS simulator
↓
Cairo PDF surface
↓
Freetype/Fontconfig/PangoFT2 能加载 bundle 内字体
↓
生成 PDF 文件
```

### Gate 3：LilyPond core 编译

必须证明：

```text
LilyPond C++ core 能以 iOS arm64 target 编译通过
```

不要求立即可运行，但要能产出静态库或 framework。

### Gate 4：真实 .ly → PDF

最小测试：

```lilypond
\version "2.24.0"
{ c'4 d' e' f' }
```

成功标准：

```text
真实 GNU LilyPond engine 输出 PDF
CI 验证 PDF 存在且非空
App 内 PDFKit 可打开
```

---

## 9. 初步风险判断

| 风险 | 等级 | 说明 |
| --- | --- | --- |
| Guile iOS 运行 | 极高 | 这是最大不确定性 |
| Boehm GC iOS 兼容 | 高 | 需要验证栈扫描/线程/内存权限 |
| LilyPond main 改 library | 高 | 当前是 CLI 结构 |
| Fontconfig/Pango/Cairo iOS 构建 | 高 | 需要避免 X11/xcb |
| Ghostscript/libgs | 高 | 体积和许可风险 |
| GPL/AGPL 合规 | 高 | 必须确认分发方式 |
| GitHub Actions 交叉编译 | 中 | macOS runner 可做，但缓存/耗时需控制 |
| SwiftUI/PDFKit 集成 | 低 | 已验证方向可行 |

---

## 10. 下一步建议

下一步不应继续写 App UI，应建立最小 engine proof-of-concept：

```text
1. 创建 native-engine-lab 目录
2. 先只构建 Boehm GC + Guile for iphonesimulator-arm64
3. 建一个 Xcode test target 调用 Guile
4. CI 跑 simulator test
5. 如果成功，再进入 Font/Cairo/Pango 阶段
```

在此之前，不应再声称 App 包含 GNU LilyPond。
