# LilyPad iPad

LilyPad 是一个面向 iPad 的 LilyPond `.ly` 编辑器壳工程。

当前版本提供：

- SwiftUI iPad App 基础界面
- LilyPond 源码编辑区
- 示例 `.ly` 内容
- 复制/检查按钮
- GitHub Actions 云端构建
- 未签名 IPA Artifact 输出
- 后续可扩展为本地 LilyPond/WASM/远程编译器

> 注意：当前 App 还没有真正内置 LilyPond 编译核心。iOS 不能直接运行 Linux/macOS 的 `lilypond` 命令行程序；如果要做真正本地编译，需要移植 LilyPond/Guile 或接入 WASM 排版引擎。

## GitHub Actions 构建

仓库 push 后会自动运行：

```text
.github/workflows/build-unsigned.yml
```

产物位置：

```text
GitHub → Actions → Build unsigned iPad IPA → Artifacts
```

会生成：

```text
LilyPad-unsigned.ipa
```

这个 IPA 是未签名包，主要用于检查构建结果，通常不能直接安装到 iPad。

## 生成可安装 IPA

要生成可安装 IPA，需要 Apple 开发者签名资料，并在 GitHub Secrets 添加：

```text
BUILD_CERTIFICATE_BASE64
P12_PASSWORD
BUILD_PROVISION_PROFILE_BASE64
KEYCHAIN_PASSWORD
TEAM_ID
BUNDLE_ID
```

然后手动运行：

```text
.github/workflows/build-signed-ipa.yml
```

## 默认信息

```text
App Name: LilyPad
Bundle ID: io.github.heyang1743.lilypad
iPad only: yes
Deployment Target: iPadOS 17.0+
```

## 后续开发路线

1. 完善 `.ly` 文件管理。
2. 添加语法高亮。
3. 添加 PDF 预览。
4. 接入本地 WASM 或移植版 LilyPond。
5. 使用 GitHub Actions 输出签名 IPA。
