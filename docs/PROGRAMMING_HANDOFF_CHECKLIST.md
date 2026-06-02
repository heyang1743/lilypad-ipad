# 编程交接清单

本文件用于判断文档阶段是否完成、何时需要向用户请求进入编程阶段。

---

## 1. 文档阶段完成项

已完成：

- 真实 GNU LilyPond 引擎说明
- iOS 原生移植依赖审计
- iOS 原生移植路线图
- Gate 1 Guile iOS spike 方案
- Gate 1 执行清单
- Gate 1 smoke test 设计
- Gate 1 最小构建矩阵
- Gate 1 构建脚本设计
- Gate 1 XCTest harness 设计
- Gate 1 CI workflow 设计
- Gate 1 依赖来源矩阵
- Gate 1 风险登记表
- native-engine-lab 说明

---

## 2. 下一步必然进入编程

以下动作都属于编程/实现阶段，必须先向用户确认：

- 创建 `scripts/build-guile-ios.sh`
- 创建 `.github/workflows/gate1-guile-ios-smoke.yml`
- 创建 Xcode/XcodeGen smoke test 工程
- 创建 C bridge
- 创建 Swift XCTest
- 下载并编译 BDW-GC / Guile
- 修改现有 App 代码

---

## 3. 应向用户请求的确认语

建议下一次向用户确认：

```text
文档阶段已完成。下一步会开始写 Gate 1 构建脚本、XCTest harness 和 CI workflow，属于编程阶段。是否开始？
```

---

## 4. 编程阶段第一批任务

如果用户确认，第一批任务应是：

1. 新建 `native-engine-lab/scripts/build-guile-ios.sh`
2. 新建 `native-engine-lab/GuileSmokeTest/` 最小测试工程
3. 新建 `.github/workflows/gate1-guile-ios-smoke.yml`
4. 只跑 lane A：simulator arm64 + pthreads + mini-gmp
5. 如果 lane A 失败，再跑 lane B：null threads

---

## 5. 禁止事项

在用户确认前，不得：

- 写构建脚本
- 写 Xcode 工程
- 写 C/Swift bridge
- 新增 CI workflow
- 开始编译依赖
- 修改主 App 代码

---

## 6. 当前结论

文档阶段可以停止。下一步已经是编程阶段。
