# Gate 1：Guile iOS 最小验证方案

分支：`engine-research`  
目标：先验证 GNU LilyPond 最危险依赖 Guile 能否在 iOS App/Simulator 进程内运行。  
范围：调研与验证设计，不包含实现代码。

---

## 1. 为什么 Gate 1 是 Guile

LilyPond 主入口会调用：

```text
main()
↓
parse_argv()
↓
setup_paths()
↓
scm_boot_guile(argc, argv, main_with_guile, 0)
```

也就是说，LilyPond 的核心运行依赖 Guile Scheme。  
如果 Guile 不能在 iOS 上稳定运行，原生 LilyPond 移植基本无法继续。

---

## 2. Guile 源码风险点

从 Guile 3.0.9 `configure.ac` 可见：

```text
LT_INIT([dlopen win32-dll])
--with-modules[=FILES]
GUILE_ENABLE_JIT
--disable-posix
--disable-networking
--disable-regex
--disable-tmpnam
--enable-mini-gmp
--with-bdw-gc=PKG
--with-threads
```

关键依赖：

```text
Boehm GC / BDW-GC
libffi
libunistring
GMP 或 mini-gmp
pthread / null threads
动态模块 / dlopen
JIT
```

对 iOS 风险：

| 模块 | 风险 | 说明 |
| --- | --- | --- |
| BDW-GC | 极高 | iOS 栈扫描、线程、内存权限必须验证 |
| Guile JIT | 高 | iOS 对可执行内存/JIT 有限制，应先禁用 |
| dynamic modules | 高 | iOS App 内动态加载路径复杂，应先禁用或内建 |
| pthreads | 中高 | iOS 有 pthread，但 GC/Guile 配合需测 |
| libffi | 中 | 可交叉编译，但需确认 iOS ABI |
| libunistring | 中 | 体积和交叉编译风险 |
| GMP | 中 | 可尝试 mini-gmp 降低依赖 |
| POSIX/networking | 中 | 应先裁剪非必要接口 |

---

## 3. Gate 1 最小目标

不是编译 LilyPond。  
不是生成 PDF。  
不是移植完整 Guile 生态。

Gate 1 只验证：

```text
iOS simulator arm64
↓
链接 Guile + BDW-GC
↓
初始化 Guile runtime
↓
执行最小 Scheme 表达式
↓
返回结果到 Swift/XCTest
```

最小 Scheme：

```scheme
(+ 1 2)
```

或：

```scheme
(display "hello")
```

通过标准：

```text
XCTest 通过
没有崩溃
没有依赖外部 shell
没有依赖 /usr/share 或 /usr/lib
日志可被 App 捕获
```

---

## 4. 建议裁剪配置

初始 Guile iOS 配置应尽量保守：

```text
--host=arm64-apple-darwin
--disable-jit
--disable-networking
--disable-tmpnam
--without-64-calls
--with-modules=no
--with-threads=pthreads 或 --with-threads=null
```

待验证选项：

```text
--enable-mini-gmp
```

说明：

- `--disable-jit`：避免 iOS JIT/可执行内存限制。
- `--with-modules=no`：避免动态模块加载，先求最小可运行。
- `--disable-networking`：LilyPond 编译不应需要网络。
- `--without-64-calls`：Guile 源码对 Darwin 默认会避免 64-call 问题。
- `pthreads` 与 `null` 都要试：pthreads 更完整，null 更容易过最小测试。

---

## 5. 依赖构建顺序

Gate 1 只构建 Guile 需要的最小依赖：

```text
1. BDW-GC
2. libffi
3. libunistring
4. GMP 或 mini-gmp
5. Guile
6. iOS XCTest wrapper
```

如果使用 `--enable-mini-gmp`，可以先跳过完整 GMP：

```text
BDW-GC
libffi
libunistring
Guile --enable-mini-gmp
```

---

## 6. 产物目标

构建产物：

```text
GuileEngine.xcframework
```

或初期：

```text
libguile-ios.a
libgc-ios.a
libffi-ios.a
libunistring-ios.a
```

测试工程：

```text
native-engine-lab/GuileSmokeTest.xcodeproj
```

测试目标：

```text
GuileSmokeTests
```

---

## 7. CI 验收

GitHub Actions 应执行：

```text
1. 构建 iOS simulator arm64 依赖
2. 构建 GuileEngine wrapper
3. 运行 xcodebuild test
4. 输出 Guile version / configure flags / linked libraries
5. 上传 Gate1 report
```

报告必须包含：

```text
BDW-GC version
Guile version
configure flags
binary/framework size
Scheme test expression
test result
crash log if failed
```

---

## 8. 失败判定

Gate 1 失败条件：

```text
Guile 无法交叉编译到 iOS simulator
Guile 初始化崩溃
BDW-GC 在 iOS 上无法稳定运行
Guile 强依赖动态模块且无法静态内建
禁用 JIT 后 Guile 不可用
Scheme 表达式不能执行
```

若失败：

```text
停止 iOS native LilyPond 路线
转向 WASM LilyPond 或替代排版引擎
```

---

## 9. 成功后的下一步

如果 Gate 1 成功，进入 Gate 2：

```text
Font/Cairo/Pango iOS PDF 输出验证
```

然后再进入：

```text
LilyPond C++ core 交叉编译
```

不要在 Gate 1 前碰 LilyPond core，否则大概率浪费时间。
