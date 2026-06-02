# Gate 1：依赖来源矩阵

目标：固定 Guile iOS Gate 1 的依赖来源、版本候选、构建顺序与风险。

---

## 1. 最小依赖链

```text
BDW-GC
libffi
libunistring
GMP 或 mini-gmp
Guile
XCTest harness
```

---

## 2. 版本候选

| 依赖 | 推荐版本 | 来源 | 备注 |
| --- | --- | --- | --- |
| BDW-GC | 8.2.x | hboehm/bdwgc | Guile 依赖，iOS 风险最高 |
| libffi | 3.4.x | libffi release | Guile foreign calls |
| libunistring | 1.x | GNU | Guile 字符串/Unicode |
| GMP | 6.x | GNU | 可先用 mini-gmp 降低复杂度 |
| Guile | 3.0.9 或 3.0.x | GNU | 与 LilyPond 2.25/2.26 匹配 |

---

## 3. 推荐优先级

### 首选最小组合

```text
BDW-GC 8.2.x
libffi 3.4.x
libunistring 1.x
Guile 3.0.9 --enable-mini-gmp
```

### 备用组合

```text
完整 GMP 6.x
Guile 3.0.9 without mini-gmp
```

备用组合只用于确认 mini-gmp 是否导致问题。

---

## 4. 构建顺序

```text
1. BDW-GC
2. libffi
3. libunistring
4. GMP/full 或跳过 full GMP
5. Guile
6. XCTest harness
```

---

## 5. 风险摘要

| 依赖 | 风险 | Gate 1 关注点 |
| --- | --- | --- |
| BDW-GC | 极高 | iOS 栈扫描、线程、内存权限 |
| Guile | 极高 | 初始化、动态模块、JIT、线程 |
| libffi | 中 | iOS ABI / symbol linkage |
| libunistring | 中 | 体积和交叉编译 |
| GMP | 中 | 体积；mini-gmp 可降低复杂度 |

---

## 6. 产物命名

建议：

```text
libgc-ios-sim-arm64.a
libffi-ios-sim-arm64.a
libunistring-ios-sim-arm64.a
libguile-ios-sim-arm64.a
GuileEngine.xcframework
```

---

## 7. 报告字段

每个依赖构建完成后记录：

- source URL
- version
- checksum
- configure flags
- build duration
- artifact size
- exported symbols count
- failure log if failed

---

## 8. 进入编程阶段前还需确定

- 是否固定 Guile 3.0.9
- 是否优先 mini-gmp
- BDW-GC 是否使用 release tarball 或 git tag
- 是否先只支持 simulator arm64

当前建议：

```text
Guile 3.0.9
mini-gmp first
simulator arm64 only
```
