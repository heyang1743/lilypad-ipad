# Engine Research 文档索引

分支：`engine-research`

本分支只做 iOS 原生 GNU LilyPond 引擎移植调研与设计，不包含引擎实现代码。

---

## 1. 当前结论

当前 LilyPad IPA 不包含 GNU LilyPond。真正目标应是：

```text
SwiftUI App
↓
LilyPondEngine.framework / native library
↓
Guile + BDW-GC + LilyPond core + resources
↓
.ly → PDF/MIDI
```

进入 LilyPond core 之前，必须先通过 Gate 1：

```text
Guile iOS simulator smoke test
```

---

## 2. 已完成文档

### 总体说明

- `docs/REAL_LILYPOND_ENGINE.md`  
  说明当前 IPA 不包含 GNU LilyPond，以及真实引擎应满足什么标准。

- `docs/IOS_NATIVE_PORT_AUDIT.md`  
  LilyPond/Guile/依赖体积、源码入口、运行时资源和高风险点审计。

- `docs/IOS_NATIVE_PORT_ROADMAP.md`  
  从 Guile 到 LilyPond core 到 App 集成的分阶段路线图。

### Gate 1 设计

- `docs/GATE_1_GUILE_IOS_SPIKE.md`  
  Guile iOS 最小验证方案。

- `docs/GATE_1_EXECUTION_CHECKLIST.md`  
  Gate 1 执行清单。

- `docs/GATE_1_GUILE_SMOKE_TEST_DESIGN.md`  
  Guile iOS smoke test 设计。

- `docs/GATE_1_GUILE_IOS_BUILD_MATRIX.md`  
  最小构建矩阵：pthreads / null threads / mini-gmp / full GMP。

- `docs/GATE_1_GUILE_BUILD_SCRIPT_DESIGN.md`  
  最小构建脚本设计。

### 本次补齐文档

- `docs/GATE_1_XCTEST_HARNESS_DESIGN.md`  
  iOS simulator XCTest harness 设计。

- `docs/GATE_1_CI_WORKFLOW_DESIGN.md`  
  GitHub Actions Gate 1 CI 流水线设计。

- `docs/GATE_1_DEPENDENCY_SOURCE_MATRIX.md`  
  Gate 1 依赖版本、来源、构建顺序和风险矩阵。

- `docs/GATE_1_RISK_REGISTER.md`  
  Gate 1 风险登记表。

- `docs/PROGRAMMING_HANDOFF_CHECKLIST.md`  
  进入编程前的交接清单。

---

## 3. 进入编程前必须明确

进入代码阶段前需要用户明确授权，因为下一步会新增脚本、Xcode 工程、CI workflow 或 native-engine-lab 代码。

建议下一条命令是：

```text
开始编写 Gate 1 构建脚本和 XCTest harness
```

在收到该命令前，本分支停止在文档阶段。
