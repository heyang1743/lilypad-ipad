# Gate 1：iOS Simulator XCTest Harness 设计

目标：设计 Guile iOS smoke test 的最小 XCTest 容器，不实现代码。

---

## 1. Harness 目标

XCTest harness 只负责验证：

```text
Guile runtime 初始化
↓
执行最小 Scheme 表达式
↓
结果回传 XCTest
```

它不负责：

- LilyPond core
- PDF/MIDI 输出
- App UI
- 真机签名

---

## 2. 推荐目录结构

进入编程阶段后，建议结构如下：

```text
native-engine-lab/
  GuileSmokeTest/
    GuileSmokeTest.xcodeproj 或 project.yml
    Sources/
      GuileBridge.h
      GuileBridge.c
    Tests/
      GuileSmokeTests.swift
    Resources/
      guile/
  scripts/
    build-guile-ios.sh
  reports/
```

当前阶段只定义结构，不创建代码。

---

## 3. XCTest 测试用例设计

### Test 1：runtime 初始化

目的：确认 Guile 可以启动。

预期：

```text
init() returns success
```

失败即 Gate 1 失败。

### Test 2：最小表达式求值

输入：

```scheme
(+ 1 2)
```

预期：

```text
3
```

### Test 3：stdout 捕获

输入：

```scheme
(display "hello")
```

预期：

```text
hello
```

### Test 4：错误捕获

输入：

```scheme
(undefined-symbol)
```

预期：

```text
不会崩溃；返回 Guile error/exception
```

### Test 5：重复初始化/重复执行

目的：确认最小稳定性。

建议执行：

```text
连续执行 10 次 (+ 1 2)
```

预期：

```text
全部通过，无崩溃，无明显内存异常
```

---

## 4. Bridge 设计原则

Swift 不直接碰 Guile C API，而是通过一个极薄 C bridge。

概念接口：

```text
GuileBridgeInitialize(resourcePath)
GuileBridgeEvaluateString(expression)
GuileBridgeGetLastOutput()
GuileBridgeGetLastError()
GuileBridgeShutdown()
```

设计要求：

- 不调用 `exit()`
- 不依赖外部 shell
- 不读取 `/usr/share`、`/usr/lib`
- 不要求 JIT
- 不要求动态模块
- 错误必须回传，不得终止测试进程

---

## 5. 测试输出

XCTest 需要输出：

- Guile 版本
- BDW-GC 版本
- configure flags
- 表达式
- 结果
- stdout
- stderr/error
- 耗时

这些内容应进入 Gate 1 构建报告。

---

## 6. 成功标准

Harness 设计通过标准：

- 能被 GitHub Actions 的 macOS runner 执行
- 能运行 iOS simulator arm64
- 测试结果可机器判定
- 失败日志足够定位 Guile/GC/链接问题

---

## 7. 下一步

进入编程阶段时，先实现：

```text
Test 1 + Test 2
```

也就是：

```text
初始化 Guile
执行 (+ 1 2)
```
