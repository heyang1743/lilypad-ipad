# Gate 1：Guile iOS 最小 Smoke Test 设计

分支：`engine-research`  
目标：只验证 **Guile 是否能在 iOS simulator / App 进程中最小启动并执行 Scheme**。  
范围：设计文档，不包含任何引擎实现代码。

---

## 1. 设计目标

这个 smoke test 只回答一个问题：

> **Guile 能不能作为 iOS 原生 App 内的可调用 Scheme runtime？**

如果答案是“不能”，原生 LilyPond 移植路线就必须暂停，转向 WASM 或替代方案。

如果答案是“能”，才有资格继续进入 LilyPond core、字体、PDF 输出等后续阶段。

---

## 2. Smoke Test 的定义

这里的 smoke test 不是完整单元测试，也不是完整 LilyPond 编译测试，而是一个**最小可运行链路**：

```text
Xcode test target / App target
↓
链接 Guile + BDW-GC
↓
初始化 Guile runtime
↓
执行最小 Scheme 表达式
↓
把结果回传给 Swift / XCTest
```

最小表达式建议：

- `(+ 1 2)`
- `(display "hello")`
- `(string-append "a" "b")`

优先选择无需文件系统、无需网络、无需动态模块的表达式。

---

## 3. 为什么先做这个测试

LilyPond 的主入口最后会进入 Guile：

```text
main()
↓
parse_argv()
↓
setup_paths()
↓
scm_boot_guile(...)
```

也就是说，LilyPond 的真正运行核心不是 UI，而是 Guile runtime。

如果 Guile 无法在 iOS 上稳定初始化并执行 Scheme，后续即使把 LilyPond core 编译过来，也没有可用运行时支撑。

因此 Gate 1 的正确顺序是：

1. 先 Guile
2. 再字体 / PDF 输出
3. 再 LilyPond core
4. 最后才是 App 集成

---

## 4. Smoke Test 范围边界

### 4.1 这次要验证的内容

- Guile 是否能在 iOS simulator arm64 中初始化
- BDW-GC 是否能在 iOS 进程内稳定工作
- Scheme 表达式是否能执行
- 结果是否能安全回传给 Swift / XCTest
- 日志是否可收集
- 线程/栈/内存是否存在立即崩溃问题

### 4.2 这次不验证的内容

- LilyPond core
- PDF 生成
- MIDI 生成
- 字体排版质量
- 完整 `\ly` 语法
- 外部命令调用
- App Store 上架兼容性
- 许可合规最终结论

---

## 5. 推荐测试形态

Gate 1 最推荐的形态是：

### 方案 A：XCTest smoke test

建立一个最小 iOS test target。

优点：

- 结果明确
- 可在 GitHub Actions 上跑
- 失败时容易定位
- 适合做 CI Gate

### 方案 B：最小 App + 按钮触发

建立一个最小 App，点击按钮后启动 Guile 并执行 Scheme。

优点：

- 更贴近 App 内真实调用
- 便于后续集成到 LilyPad

### 推荐顺序

```text
先 XCTest，后 App 按钮
```

因为 Gate 1 的目标是“验证 runtime 可行性”，不是 UI。

---

## 6. 设计中的依赖顺序

最小依赖应优先构建：

1. BDW-GC
2. libffi
3. libunistring
4. GMP 或 mini-gmp
5. Guile

原因：

- Guile 依赖 BDW-GC
- Guile 需要 libffi、libunistring、GMP 相关支持
- 任何一个底层库不稳，Guile 都会失败

---

## 7. 建议的 Guile 裁剪方向

为了尽可能适配 iOS，初始 smoke test 建议采用保守裁剪：

- 关闭 JIT
- 关闭网络能力
- 关闭非必要 POSIX 功能
- 关闭动态模块加载
- 允许线程时先验证 pthreads，再考虑 null threads
- 尽量减少对 64-bit 特殊调用的依赖
- 优先尝试 mini-gmp，以降低体积和复杂度

目标不是功能完整，而是**最小可启动**。

---

## 8. 建议的测试 API 形态

为了让 Swift / XCTest 能调用 Guile，建议最终形成以下概念性 API：

- 初始化 runtime
- 执行一段 Scheme 字符串
- 获取 stdout/stderr/log
- 获取返回值或错误
- 关闭 runtime

这一步的核心原则：

- 不依赖 `main()`
- 不依赖 `argv` 驱动的 CLI
- 不依赖外部 shell
- 不依赖写死的系统路径
- 不允许 `exit()` 结束整个 App 进程

---

## 9. Smoke Test 的输入输出

### 输入

一个最小 Scheme 表达式，例如：

- `(+ 1 2)`
- `(display "hello")`
- `(list 1 2 3)`

### 输出

至少需要捕获：

- 是否成功执行
- 返回值
- 标准输出
- 错误输出
- 初始化日志
- 运行耗时

---

## 10. 成功标准

Gate 1 smoke test 成功时，必须同时满足：

- Guile 在 iOS simulator arm64 中初始化成功
- Scheme 表达式成功执行
- 结果可回传给 XCTest 或 Swift
- 没有崩溃
- 没有依赖外部进程
- 没有依赖 `/usr/share`、`/usr/lib` 或宿主环境路径
- 没有 JIT / 动态模块 / 栈扫描类硬失败
- 构建报告记录了版本和配置参数

建议的最低成功判据：

```text
(+ 1 2) => 3
```

或：

```text
(display "hello") 成功打印到日志
```

---

## 11. 失败标准

以下任一情况出现，都算 Gate 1 失败：

- Guile 无法交叉编译到 iOS simulator
- 初始化阶段崩溃
- BDW-GC 不稳定
- Scheme 无法执行
- 必须依赖动态模块
- 必须依赖 JIT
- 必须依赖网络能力
- 必须依赖桌面环境路径
- 测试只能在宿主 Linux/macOS 命令行运行，不能在 iOS target 里运行

---

## 12. 预期产物

如果 Gate 1 成功，应该能得到：

- 一个最小 iOS test target
- 一个 Guile runtime wrapper
- 一份 smoke test log
- 一份构建报告
- 一个明确结论：是否能继续进入 LilyPond core 阶段

---

## 13. 记录与报告要求

每次 smoke test 运行后，报告至少要包含：

- Guile 版本
- BDW-GC 版本
- configure flags
- iOS simulator 版本
- 测试表达式
- 执行耗时
- 成功/失败结论
- 崩溃日志（如果有）

这份记录后续要作为 Gate 2 / Gate 3 的输入。

---

## 14. 下一步的实际动作

真正进入开发时，建议顺序是：

1. 建立 `native-engine-lab/`
2. 先只搭 Guile smoke test 容器
3. 不碰 LilyPond core
4. 先跑最小 Scheme
5. 再决定是否进入字体 / PDF 路线

---

## 15. 结论

Gate 1 的设计核心非常简单：

```text
先证明 Guile 能在 iOS 里跑。
```

如果这一步不成立，后面所有 LilyPond 原生移植都没有意义。
