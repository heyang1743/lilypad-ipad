# Gate 1：GitHub Actions CI Workflow 设计

目标：设计 Guile iOS smoke test 的 CI 流水线，不实现 workflow 文件。

---

## 1. CI 目标

CI 只验证 Gate 1：

```text
build minimal Guile for iOS simulator
↓
link XCTest harness
↓
run scheme smoke test
↓
upload report
```

不构建 LilyPad App，不构建 LilyPond core。

---

## 2. Runner 要求

建议：

```text
runs-on: macos-15
Xcode: 16.x
Target: iphonesimulator arm64
```

必须记录：

```text
xcodebuild -version
xcrun --sdk iphonesimulator --show-sdk-path
clang version
simulator runtime list
```

---

## 3. Job 结构

建议 workflow 分为：

### job: gate1-guile-smoke

步骤：

1. checkout
2. print environment
3. restore dependency cache
4. build BDW-GC
5. build libffi
6. build libunistring
7. build Guile lane A
8. build XCTest harness
9. run XCTest
10. upload report/logs

---

## 4. Matrix 设计

最小 matrix：

```text
lane=A threads=pthreads gmp=mini
lane=B threads=null     gmp=mini
```

其中：

- lane A 是必须跑的主 lane
- lane B 可设置为 fallback 或手动触发
- lane C full GMP 暂不纳入默认 CI

---

## 5. Cache 设计

建议缓存：

```text
native-engine-lab/out/source-cache
native-engine-lab/out/prefix-cache
```

缓存 key 应包含：

- Guile version
- BDW-GC version
- target SDK
- lane
- configure flags hash

避免不同 lane 混用不兼容产物。

---

## 6. Artifact 设计

CI 必须上传：

```text
Gate1-Guile-iOS-build-report.txt
logs/*.log
products/*.a 或 *.xcframework
xcode-test-results.xcresult
```

如果失败，也要上传日志。

---

## 7. 失败处理

CI 不应吞掉错误。

失败时应明确：

- 哪个依赖失败
- configure 失败还是 make 失败
- 链接失败还是 XCTest 失败
- 是否是 GC 崩溃
- 是否是 dyld/dlopen 相关问题

---

## 8. 不纳入 Gate 1 CI 的内容

- LilyPond core
- Ghostscript/libgs
- PDF 输出
- MIDI 输出
- App IPA
- 签名
- 真机测试

---

## 9. 进入编程阶段后的第一个 workflow

建议文件名：

```text
.github/workflows/gate1-guile-ios-smoke.yml
```

但现在不创建该 workflow，等用户明确允许编程后再做。
