# LeoLauncher

macOS 空间分区启动器。为了补上系统 Launchpad 变难用、以及 TagLauncher 性能差、分类会重复、换机器丢失布局的问题。

## 特点

- **呼出即开**：`⌥ Space`（同时兼容 TagLauncher 的 `⌥⇧ Space`）。弹出后直接打字搜索。
- **区域分解**：按使用场景拆成大小不同的玻璃分区，不是整屏平铺。
- **每个应用只进一个分类**：用 Bundle ID 而不是文件路径，避免 Telegram 同时出现在「沟通」和「系统」。
- **iCloud 同步**：分类、隐藏、使用记录写入 iCloud 云盘 `LeoLauncher/state.json`，同一 Apple 账号的 Mac 共用。
- **拖一下就能改**：把图标拖到别的分区或右侧标签，立刻覆盖分类并同步。
- **智能补全**：内置针对你这台机器应用的目录；未知应用再走 App Store 类型和本机 Foundation Models。

## 快捷键

| 动作 | 按键 |
| --- | --- |
| 打开启动器 | `⌥ Space` 或 `⌥⇧ Space` |
| 打开并搜索 | `⌃ Space` |
| 关闭 / 清空搜索 | `Esc` |
| 打开选中应用 | `Enter` |
| 触控板 / TourBox | `leolauncher://show` |

## 开发

```bash
make build
make install
make run
```

需要 Xcode Command Line Tools。首次放进 `/Applications` 后，可在设置里打开「登录时启动」。
