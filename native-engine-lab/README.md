# Native Engine Lab: Gate 1

这个目录是 LilyPad 的 iOS 原生引擎实验区，当前只做 **Guile iOS 最小验证**，不包含 LilyPond core。

## 目标

验证以下链路是否可行：

```text
iOS simulator arm64
↓
BDW-GC
↓
Guile 3.0
↓
执行最小 Scheme 表达式
↓
返回结果到 XCTest / Swift
```

最小表达式：

```scheme
(+ 1 2)
```

或：

```scheme
(display "hello")
```

## 为什么先做 Guile

LilyPond 的启动路径最终会进入：

```text
scm_boot_guile(argc, argv, main_with_guile, 0)
```

所以如果 Guile 无法在 iOS 上稳定运行，LilyPond 原生移植就没法继续。

## 当前调研结论

已确认 Guile 3.0.9 的关键风险点：

- BDW-GC / Boehm GC
- JIT
- 动态模块 / dlopen
- POSIX / networking 裁剪
- pthreads / null threads
- libffi
- libunistring
- GMP / mini-gmp

## 建议的 Gate 1 构建顺序

1. BDW-GC
2. libffi
3. libunistring
4. GMP 或 mini-gmp
5. Guile
6. iOS simulator smoke test

## 建议的 Guile 配置方向

先尝试保守裁剪：

```text
--disable-jit
--disable-networking
--disable-tmpnam
--with-modules=no
--without-64-calls
--with-threads=pthreads 或 --with-threads=null
--enable-mini-gmp
```

## Gate 1 成功标准

- Xcode test target 通过
- Guile 可初始化
- Scheme 表达式可执行
- 不依赖外部 shell
- 不依赖 `/usr/share`、`/usr/lib`、`PATH`
- 结果可被 Swift 捕获

## Gate 1 失败标准

- Guile 不能交叉编译到 iOS
- 初始化时崩溃
- BDW-GC 不稳定
- JIT / dynamic modules / stack scanning 卡死
- 无法执行最小 Scheme

## 下一步

如果 Gate 1 继续推进，下一阶段才会进入：

```text
Phase 3: 字体与 PDF 输出验证
```

但在那之前，不应碰 LilyPond core。
