# Gate 1：Guile iOS 最小构建矩阵

分支：`engine-research`

## 目标

定义 **Guile iOS 最小可行构建矩阵**，用于 Gate 1 smoke test。

这不是完整 LilyPond 构建矩阵。  
这里只验证 Guile / BDW-GC / 最小 Scheme runtime 能否在 iOS simulator 内启动。

---

## 1. 设计原则

1. **先最小可运行，再扩大矩阵。**
2. **只保留能帮助判断 iOS 原生移植可行性的组合。**
3. **优先 simulator arm64，不先上真机矩阵。**
4. **优先 Debug smoke test，不先上 Release。**
5. **优先最少依赖组合：mini-gmp / 禁用 JIT / 禁用动态模块。**

---

## 2. 最小矩阵定义

### 主目标 lane

| Lane | 平台 | 架构 | 线程模型 | GMP 方案 | JIT | 动态模块 | 用途 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A | iOS Simulator | arm64 | pthreads | mini-gmp | off | off | 主验证 lane |

### 回退 lane

| Lane | 平台 | 架构 | 线程模型 | GMP 方案 | JIT | 动态模块 | 用途 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| B | iOS Simulator | arm64 | null threads | mini-gmp | off | off | 当 pthreads 失败时的回退验证 |

### 观察 lane（非 Gate 必需）

| Lane | 平台 | 架构 | 线程模型 | GMP 方案 | JIT | 动态模块 | 用途 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C | iOS Simulator | arm64 | pthreads | full GMP | off | off | 仅用于对比体积/性能，不作为 Gate 必需 |

---

## 3. 为什么只选 simulator arm64

Gate 1 的目标不是打包最终 IPA，而是验证 Guile runtime 的最小可行性。

优先顺序：

```text
simulator arm64
↓
Guile smoke test
↓
再考虑真机 arm64
```

理由：

- simulator 调试更快
- 崩溃日志更容易看
- 依赖问题更容易定位
- 先验证 runtime 可行性，避免把时间花在打包细节上

---

## 4. 构建配置

### 必需构建状态

- `Debug`
- `iphonesimulator-arm64`
- `xcodebuild test`
- `XCTest` 或最小 App smoke test

### 不纳入最小矩阵的项

- `Release`
- `iphoneos-arm64` 真机
- `x86_64` simulator（可作为旧机器兼容观察项，不是当前最小目标）
- 完整 LilyPond core
- Ghostscript 输出链
- MIDI 输出

---

## 5. Guile 建议 configure 组合

最小矩阵中建议统一使用以下保守裁剪方向：

```text
--disable-jit
--disable-networking
--disable-tmpnam
--with-modules=no
--without-64-calls
--enable-mini-gmp
```

线程模型按 lane 区分：

- Lane A：`--with-threads=pthreads`
- Lane B：`--with-threads=null`
- Lane C：`--with-threads=pthreads`

说明：

- `pthreads` 是主路径，因为它更接近真实运行环境。
- `null threads` 是回退路径，用于判断失败是否来自线程/GC 交互。
- `mini-gmp` 先降低体积和依赖复杂度。

---

## 6. 构建产物矩阵

Gate 1 最小构建矩阵建议输出以下产物：

| 产物 | 说明 |
| --- | --- |
| `libgc-ios.a` / `libgc.xcframework` | BDW-GC |
| `libffi-ios.a` / `libffi.xcframework` | libffi |
| `libunistring-ios.a` / `libunistring.xcframework` | libunistring |
| `libguile-ios.a` / `GuileEngine.xcframework` | Guile runtime |
| `GuileSmokeTest.app` 或测试 bundle | smoke test 容器 |
| `Gate1-report.txt` | 构建和执行报告 |

如果第一个阶段只做静态库，也可以先不做最终 framework，但必须能被 iOS test target 链接。

---

## 7. 成功标准

### lane A 成功标准

- BDW-GC 编译通过
- Guile 编译通过
- iOS simulator arm64 链接成功
- 最小 Scheme 表达式执行成功
- XCTest 通过
- smoke test 日志可读

### lane B 成功标准

- 在 lane A 失败时，lane B 可作为判定备用
- 如果 B 成功、A 失败，说明问题更可能在 pthreads/GC 耦合
- 如果 A/B 都失败，说明 Guile iOS 路线有更深层问题

### lane C 成功标准

- 仅用于观测，不作为 Gate 必需
- 通过后用于比较体积和符号数量

---

## 8. 失败判定

任何一项失败，都要记录在 Gate 1 报告中：

- Guile 不能交叉编译到 iOS simulator
- BDW-GC 不可稳定运行
- JIT 相关问题
- 动态模块 / dlopen 问题
- `pthreads` 下崩溃
- `null threads` 也失败
- `mini-gmp` 无法替代
- Scheme 无法执行

---

## 9. 推荐 CI 运行顺序

建议 GitHub Actions 运行顺序如下：

1. `deps-bdwgc`
2. `deps-libffi`
3. `deps-libunistring`
4. `deps-guile` lane A
5. `smoke-test` lane A
6. `deps-guile` lane B（仅当 A 失败或作为对照）
7. `smoke-test` lane B
8. `lane C` 仅在资源允许时做测量

---

## 10. 建议的报告字段

每个 lane 的报告至少包含：

- lane 名称
- host macOS / Xcode 版本
- target triple
- configure flags
- 产物大小
- smoke test 表达式
- 执行结果
- 崩溃日志（如有）
- 失败原因摘要

---

## 11. 当前结论

Gate 1 的最小构建矩阵应当是：

```text
1 个主 lane + 1 个回退 lane + 1 个观测 lane
```

也就是：

- A：`pthreads + mini-gmp + JIT off + modules off`
- B：`null threads + mini-gmp + JIT off + modules off`
- C：`pthreads + full GMP + JIT off + modules off`（可选）

这已经足够判断 Guile iOS 路线能不能继续往下走。
