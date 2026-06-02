# Gate 1：Guile iOS 最小构建脚本设计

分支：`engine-research`

## 1. 目标

设计一个最小构建脚本，用来在 macOS + Xcode 环境下为 iOS simulator arm64 构建 Guile Gate 1 的最小依赖链。

脚本目标不是构建完整 LilyPond，而是为 Guile smoke test 准备以下内容：

- BDW-GC
- libffi
- libunistring
- GMP 或 mini-gmp
- Guile
- iOS simulator smoke test 产物

---

## 2. 脚本职责边界

### 应做

- 检查 macOS / Xcode / SDK 环境
- 下载或解压依赖源代码
- 按顺序编译最小依赖
- 为 iOS simulator arm64 产出可链接静态库 / framework
- 生成 smoke test 容器
- 运行最小 Scheme 验证
- 输出构建报告

### 不应做

- 不编译 LilyPond core
- 不编译 PDF / MIDI 输出链
- 不做真机签名分发
- 不做 App Store 打包
- 不做完整字体排版移植
- 不做 Ghostscript 集成

---

## 3. 推荐脚本名称

建议命名：

```text
build-guile-ios.sh
```

脚本应只服务 Gate 1，不与后续 LilyPond 阶段混用。

---

## 4. 输入参数设计

建议脚本支持以下输入：

```text
--sdk iphonesimulator
--arch arm64
--threads pthreads|null
--gmp mini|full
--enable-jit yes|no
--enable-modules yes|no
--output <dir>
--report <file>
```

最小矩阵默认值建议：

```text
sdk=iphonesimulator
arch=arm64
threads=pthreads
gmp=mini
enable-jit=no
enable-modules=no
```

---

## 5. 脚本执行阶段

### Stage 0：环境检查

必须检查：

- `xcodebuild`
- `xcrun`
- iOS simulator SDK 是否可用
- `clang` / `ar` / `ranlib`
- `pkg-config` 或等效依赖定位方式

失败时应立刻退出并输出：

```text
missing Xcode / missing SDK / missing toolchain
```

---

### Stage 1：依赖准备

构建顺序建议：

1. BDW-GC
2. libffi
3. libunistring
4. GMP 或 mini-gmp
5. Guile

每个依赖都应该有独立的构建目录：

```text
build/bdwgc/
build/libffi/
build/libunistring/
build/gmp/
build/guile/
```

建议每个阶段输出：

- 配置日志
- 编译日志
- 安装到中间前缀的文件列表
- 产物大小

---

### Stage 2：Guile 配置

最小构建脚本建议显式固定裁剪选项：

```text
--disable-jit
--disable-networking
--disable-tmpnam
--with-modules=no
--without-64-calls
--with-threads=pthreads 或 --with-threads=null
--enable-mini-gmp
```

脚本应记录最终实际使用的 configure flags。

---

### Stage 3：产物打包

建议输出：

```text
GuileEngine.xcframework
```

或初期静态库集合：

```text
libgc-ios.a
libffi-ios.a
libunistring-ios.a
libguile-ios.a
```

脚本应同时输出资源目录：

```text
GuileResources.bundle
```

如果只是最小验证，也可以先只打包静态库，不做完整 framework，但要能链接进 iOS test target。

---

### Stage 4：smoke test 编译

脚本应生成一个最小测试容器，用来验证：

- Guile 能初始化
- Scheme 能运行
- 结果能回传

测试表达式建议固定为：

```scheme
(+ 1 2)
```

或：

```scheme
(display "hello")
```

---

### Stage 5：XCTest / App 运行

脚本应调用：

```text
xcodebuild test
```

或先 build 再 test：

```text
xcodebuild build
xcodebuild test
```

脚本应捕获：

- XCTest 结果
- simulator 崩溃日志
- stdout/stderr
- 退出码

---

## 6. 环境变量设计

建议脚本支持以下环境变量：

```text
DEVELOPER_DIR
SDKROOT
ARCHS
BUILD_DIR
PREFIX_DIR
GUILE_PREFIX
BDWGC_PREFIX
LIBFFI_PREFIX
LIBUNISTRING_PREFIX
GMP_PREFIX
```

如果未设置，脚本应给出清晰默认值，并把最终值写入报告。

---

## 7. 输出目录结构

建议统一输出：

```text
out/
  logs/
  build/
  prefix/
  products/
  report/
```

其中：

- `logs/`：每个依赖的配置和编译日志
- `build/`：中间构建目录
- `prefix/`：交叉编译安装前缀
- `products/`：最终静态库 / framework / bundle
- `report/`：构建报告和测试结果

---

## 8. 构建报告要求

脚本最终必须输出一份报告，至少包含：

- host macOS / Xcode 版本
- target SDK / architecture
- Guile 版本
- BDW-GC 版本
- configure flags
- 每个依赖的产物大小
- smoke test 是否通过
- 失败原因摘要（如失败）

建议文件名：

```text
Gate1-Guile-iOS-build-report.txt
```

---

## 9. 失败处理设计

脚本应遵循“尽早失败、明确错误”的原则。

例如：

- SDK 不存在 → 立即退出
- 某个依赖 configure 失败 → 立即退出并保留日志
- Guile 链接失败 → 退出并标明是哪个符号/库失败
- smoke test 崩溃 → 退出并保留 crash log

不应继续掩盖错误，也不应默默跳过。

---

## 10. 与 GitHub Actions 的关系

这个最小脚本最终应被 GitHub Actions 调用，但脚本本身不依赖 CI。

CI 里建议的调用方式：

```text
run: ./scripts/build-guile-ios.sh --sdk iphonesimulator --arch arm64 --threads pthreads --gmp mini
```

如果主 lane 失败，CI 可以再跑回退 lane：

```text
run: ./scripts/build-guile-ios.sh --sdk iphonesimulator --arch arm64 --threads null --gmp mini
```

---

## 11. 最小可接受设计

如果只做最小版本，这个脚本只需要支持：

- 单一平台：iOS simulator arm64
- 两种线程模式：pthreads / null
- 两种 GMP 方案：mini / full
- 一种 smoke test 表达式
- 一份文本报告

这已经足以支持 Gate 1。

---

## 12. 结论

这个脚本的本质不是“构建全部 LilyPond”，而是：

```text
为 Guile iOS smoke test 搭建最小交叉编译与验证流水线。
```

只要这个脚本跑通，才能进入下一阶段：

```text
Guile -> 字体/PDF -> LilyPond core
```
