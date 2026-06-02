# Gate 1 Guile iOS 执行清单

分支：`engine-research`

## 目标

验证 Guile 是否能在 iOS simulator / App 进程中稳定运行。

这不是 LilyPond 代码实现，不涉及引擎编程，只是验证准备与记录。

---

## 前提

- 需要 macOS + Xcode
- 需要 iOS simulator arm64 或真机 arm64
- 需要可交叉编译的 Guile / BDW-GC / libffi / libunistring / GMP 方案
- 需要一个最小的 XCTest 或 app target 作为启动容器

---

## Gate 1 顺序

### Step 1: 构建最小依赖

优先顺序：

1. BDW-GC
2. libffi
3. libunistring
4. GMP 或 mini-gmp
5. Guile

### Step 2: 建立最小容器

创建一个 iOS simulator 测试容器，只负责：

- 启动 app
- 调用 Guile 初始化
- 执行最小 Scheme 表达式
- 捕获输出

### Step 3: 最小 Scheme 验证

测试表达式：

```scheme
(+ 1 2)
```

或：

```scheme
(display "hello")
```

### Step 4: 结果回传

把 Guile 输出回传到：

- XCTest assertion
- Swift 日志面板
- 构建报告

---

## 成功标准

- Guile 初始化成功
- Scheme 表达式执行成功
- 没有崩溃
- 没有依赖外部 shell
- 没有依赖系统 `/usr/share`、`/usr/lib`
- 没有 JIT 相关崩溃
- 构建报告中有 Guile version、configure flags、测试结果

---

## 失败标准

任意一条出现即判定 Gate 1 失败：

- Guile 交叉编译失败
- BDW-GC 在 iOS 上不稳定
- 初始化 Guile 时崩溃
- Scheme 无法执行
- 必须依赖动态模块或外部路径
- 必须依赖 iOS 不允许的运行时能力

---

## 产物

Gate 1 成功后应得到：

- `GuileEngine.xcframework` 或可链接静态库
- 一个最小 XCTest / app smoke test
- 一份构建报告
- 一份风险结论：是否可以进入 LilyPond core 阶段

---

## 备注

当前仓库里已有：

- `docs/IOS_NATIVE_PORT_AUDIT.md`
- `docs/IOS_NATIVE_PORT_ROADMAP.md`
- `docs/GATE_1_GUILE_IOS_SPIKE.md`
- `native-engine-lab/README.md`

这份清单只是把 Gate 1 的执行动作再压缩成单页 checklist，方便后续真正开工。
