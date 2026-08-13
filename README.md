# LeoLauncher

**[项目主页](https://nzleo.github.io/LeoLauncher/)** · **[下载 DMG](https://github.com/nzleo/LeoLauncher/releases/latest)**

macOS 空间分区启动器。系统 Launchpad 变难用了：分类弱、不好找、换机器布局不跟着走。所以做了 LeoLauncher：⌥ Space 呼出，一个应用一个分类，布局随 iCloud。

## 安装

1. 从 [Releases](https://github.com/nzleo/LeoLauncher/releases/latest) 下载 `LeoLauncher-*.dmg`。
2. 把 App 拖进「应用程序」。
3. 首次打开：按住 Control 点击 → 打开（未做 Apple 公证，Gatekeeper 拦截是正常的）。
4. 按 `⌥ Space` 呼出。

自己从源码打包是次要路径，见下方「开发」。

## 特点

- **呼出即开**：默认 `⌥ Space`。弹出后直接打字搜索，支持拼音；点空白或 `Esc` 关闭。快捷键可在设置里改。
- **每次一句名言**：显示在底部分类栏，不占应用区域。
- **三种视图**：分类分区、按图标主色排成色谱、按安装时间轴（近 7 天 / 1 个月 / 3 个月 / 半年）。
- **每个应用只进一个分类**：用 Bundle ID 而不是文件路径。
- **iCloud 同步**：分类、隐藏、排序和使用记录随 Apple 账号走。
- **拖一下就能改**：把图标拖到别的分区，立刻覆盖分类并同步。

## 快捷键

| 动作 | 按键 |
| --- | --- |
| 打开启动器 | 默认 `⌥ Space` 或 `⌥⇧ Space`（设置 → 快捷键 可改） |
| 打开并搜索 | 默认 `⌃ Space`（设置 → 快捷键 可改） |
| 关闭 | `Esc` 或点击空白 |
| 搜索 | 打开后直接打字，支持拼音 |
| 打开选中应用 | `Enter` |
| 触控板 / TourBox | `leolauncher://show` |

## 开发

```bash
make build
make install
make run
```

需要 Xcode Command Line Tools。首次放进 `/Applications` 后，可在设置里打开「登录时启动」。
