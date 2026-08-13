# LeoLauncher

macOS 空间分区启动器。为了补上系统 Launchpad 变难用、以及 TagLauncher 性能差、分类会重复、换机器丢失布局的问题。

## 特点

- **呼出即开**：`⌥ Space`。弹出后直接打字搜索，支持拼音；点空白或 `Esc` 关闭。
- **四种背景**：玻璃、毛玻璃、透明、墨色，可在设置里切换；也能上传自己的半透明墙纸。
- **三种视图**：分类分区、按图标主色排成色谱、按最近使用和安装时间做时间轴。
- **每个应用只进一个分类**：用 Bundle ID 而不是文件路径。
- **iCloud 同步**：分类、隐藏、排序和使用记录随 Apple 账号走。
- **拖一下就能改**：把图标拖到别的分区，立刻覆盖分类并同步。

## 快捷键

| 动作 | 按键 |
| --- | --- |
| 打开启动器 | `⌥ Space` 或 `⌥⇧ Space` |
| 打开并搜索 | `⌃ Space` |
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
