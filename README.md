<div align="center">

# LeoLauncher

**⌥⇧ Space 呼出的空间分区启动器。**

一个应用只进一个分类，布局随 iCloud 走。

[![macOS 14+](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://github.com/nzleo/LeoLauncher)
[![最新版本](https://img.shields.io/github/v/release/nzleo/LeoLauncher?label=%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC&color=2ea44f)](https://github.com/nzleo/LeoLauncher/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

**[🌐 项目主页](https://nzleo.github.io/LeoLauncher/)** · **[⬇️ 下载最新版 DMG](https://github.com/nzleo/LeoLauncher/releases/latest)**

同一作者的其他开源：
[Leo 风扇控制](https://nzleo.github.io/LeoMacFanControl/) ·
[LeoMDReader](https://nzleo.github.io/LeoMDReader/) ·
[TourBox × ChatGPT / Codex](https://nzleo.github.io/LeoTourBoxShare/)

</div>

---

macOS 空间分区启动器。系统 Launchpad 变难用了：分类弱、不好找、换机器布局不跟着走。所以做了 LeoLauncher：⌥⇧ Space 呼出，一个应用一个分类，布局随 iCloud。

## 下载与安装

### 第 1 步：下载并拖进「应用程序」

**[⬇️ 前往下载页](https://github.com/nzleo/LeoLauncher/releases/latest)**，下载 `LeoLauncher-*.dmg`。

打开 DMG，把 `LeoLauncher.app` 拖到旁边的 Applications（应用程序）文件夹。

> 需要 macOS 14 或更高。

### 第 2 步：首次打开要手动放行（重要）

这个 App 没有购买 Apple 开发者证书（每年 99 美元）、也未做公证，所以**首次打开一定会被系统拦下**，提示「无法打开，因为无法验证开发者」。

这是正常的，不是文件损坏。三种放行方式，任选一种：

**方式 A（推荐，不用命令行）**
1. 在「应用程序」里找到 LeoLauncher
2. **按住 Control 键点击**它，选择「打开」
3. 弹窗里再点一次「打开」

**方式 B**

先双击一次（会被拦），然后打开 **系统设置 ▸ 隐私与安全性**，往下翻找到相关提示，点「仍要打开」。

**方式 C（命令行最快）**

```bash
xattr -dr com.apple.quarantine /Applications/LeoLauncher.app
```

### 第 3 步：按 ⌥⇧ Space 呼出

默认快捷键是 **Option + Shift + Space**。弹出后直接打字搜索，支持拼音。点空白或 `Esc` 关闭。快捷键可在设置里改。

## 特点

- **呼出即开**：默认 `⌥⇧ Space`。弹出后直接打字搜索，支持拼音；点空白或 `Esc` 关闭。快捷键可在设置里改。
- **每次一句名言**：显示在底部分类栏，不占应用区域。
- **三种视图**：分类分区、按图标主色排成色谱、按安装时间轴（近 7 天 / 1 个月 / 3 个月 / 半年）。
- **每个应用只进一个分类**：用 Bundle ID 而不是文件路径。
- **iCloud 同步**：分类、隐藏、排序和使用记录随 Apple 账号走。
- **拖一下就能改**：把图标拖到别的分区，立刻覆盖分类并同步。

## 快捷键

| 动作 | 按键 |
| --- | --- |
| 打开启动器 | 默认 `⌥⇧ Space`（设置 → 快捷键 可改） |
| 打开并搜索 | 默认 `⌥⌃ Space`（设置 → 快捷键 可改） |
| 关闭 | `Esc` 或点击空白 |
| 搜索 | 打开后直接打字，支持拼音 |
| 打开选中应用 | `Enter` |
| 触控板 / TourBox | `leolauncher://show` |

## 从源码构建（开发者，可选）

一般用户请直接下载 DMG。需要自己编译时：

```bash
make dmg       # dist/LeoLauncher-<version>.dmg
make install   # 装进 /Applications
make run
```

需要 Xcode Command Line Tools。首次放进 `/Applications` 后，可在设置里打开「登录时启动」。
