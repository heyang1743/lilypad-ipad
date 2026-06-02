# Gate 1：风险登记表

目标：把进入编程前已知风险登记清楚，避免盲目实现。

---

## 风险总览

| ID | 风险 | 等级 | 影响 | 缓解措施 |
| --- | --- | --- | --- | --- |
| R1 | BDW-GC 在 iOS 上初始化失败 | 极高 | Guile 无法运行 | 先做最小 GC smoke test |
| R2 | Guile JIT 与 iOS 内存权限冲突 | 高 | 初始化或执行崩溃 | 默认 `--disable-jit` |
| R3 | Guile 动态模块/dlopen 不适合 iOS | 高 | 运行时找不到模块 | 默认 `--with-modules=no` |
| R4 | pthreads 与 GC 交互崩溃 | 高 | lane A 失败 | 设置 null threads 回退 lane |
| R5 | mini-gmp 不满足 Guile/LilyPond 需求 | 中 | 后续功能受限 | lane C 使用 full GMP 观察 |
| R6 | libffi iOS ABI 问题 | 中 | 链接/调用失败 | 单独记录符号和调用结果 |
| R7 | 交叉编译工具链不稳定 | 中 | CI 失败 | 固定 Xcode/macOS runner 版本 |
| R8 | 资源路径依赖宿主系统 | 高 | iOS 运行失败 | 强制 bundle path，不依赖 `/usr` |
| R9 | 许可证影响后续分发 | 高 | 无法合规分发 IPA | Gate 9 单独处理 |

---

## Gate 1 最高优先级风险

最优先验证：

```text
R1: BDW-GC
R2: JIT
R3: dynamic modules
R4: pthreads
```

因此最小构建矩阵必须覆盖：

```text
pthreads lane
null threads lane
JIT off
modules off
```

---

## 风险处置原则

1. 先暴露风险，不绕过风险。
2. 不因某个 lane 成功就直接进入 LilyPond core。
3. 如果 pthreads 失败但 null threads 成功，需要标记为“条件通过”，不能算完全通过。
4. 如果所有 lane 都失败，应停止 native port 路线。

---

## Gate 1 结论分类

### 通过

```text
lane A 通过，Guile 可稳定运行。
```

### 条件通过

```text
lane A 失败，lane B 通过。
说明 pthreads/GC 有问题，后续风险高。
```

### 失败

```text
lane A/B 均失败。
停止原生 LilyPond 路线。
```

---

## 编程前处理

进入代码阶段前必须确认：

- 是否接受条件通过继续研究
- 是否允许后续尝试 patch BDW-GC/Guile
- 是否把 WASM 作为并行备选路线
