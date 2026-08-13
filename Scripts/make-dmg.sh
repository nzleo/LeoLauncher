#!/usr/bin/env bash
#
# make-dmg.sh — package a shareable DMG for ordinary users.
#
# Usage:  ./Scripts/make-dmg.sh
# Output: dist/LeoLauncher-<version>.dmg
#
# DMG contents:
#   LeoLauncher.app     ad-hoc signed; drag into Applications
#   Applications        symlink for drag-install
#   安装说明.txt         Gatekeeper first-open steps
#
# Signing: ad-hoc only. No Apple Developer ID, no notarization.
# First open from a downloaded DMG will be blocked by Gatekeeper;
# that is expected. The install note explains how to allow it.
#
set -euo pipefail

APP_NAME="LeoLauncher"
VOL_NAME="LeoLauncher"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/Packaging/Info.plist")"
echo "==> version: ${VERSION}"

echo ""
echo "=== package app ==="
"$ROOT_DIR/Scripts/package-app.sh"

APP_SRC="$ROOT_DIR/dist/$APP_NAME.app"
if [[ ! -d "$APP_SRC" ]]; then
    echo "error: missing $APP_SRC" >&2
    exit 1
fi

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

PAYLOAD="$STAGE/payload"
mkdir -p "$PAYLOAD"
cp -R "$APP_SRC" "$PAYLOAD/"
ln -s /Applications "$PAYLOAD/Applications"

cat > "$PAYLOAD/安装说明.txt" <<GUIDE
LeoLauncher — 安装说明 / Install
========================================

需要 macOS 14 或更高。


第 1 步：安装 App
----------------------------------------
把 LeoLauncher.app 拖到旁边的 Applications（应用程序）文件夹。


第 2 步：首次打开（重要）
----------------------------------------
本 App 没有购买 Apple 开发者证书、也未做公证，所以首次打开会被系统拦下，
提示「无法打开，因为无法验证开发者」。这是正常的，按下面任一种方式放行：

方式 A（推荐）
  1. 在「应用程序」里找到 LeoLauncher
  2. 按住 Control 键点击它，选择「打开」
  3. 弹窗里再点一次「打开」

方式 B
  先双击一次（会被拦），然后打开
  系统设置 ▸ 隐私与安全性，往下翻找到相关提示，点「仍要打开」

方式 C（命令行，最快）
  在「终端」里执行：
      xattr -dr com.apple.quarantine /Applications/LeoLauncher.app


第 3 步：呼出启动器
----------------------------------------
默认快捷键是 Option + Space（⌥ Space）。弹出后直接打字搜索，支持拼音。
点空白或按 Esc 关闭。快捷键可在设置里改。


English
----------------------------------------
1. Drag LeoLauncher.app into Applications.
2. First launch is blocked by Gatekeeper (unsigned / not notarized). That is expected.
   Control-click the app → Open → Open again.
   Or: xattr -dr com.apple.quarantine /Applications/LeoLauncher.app
3. Press Option-Space (⌥ Space) to show the launcher.


项目主页 / Homepage
----------------------------------------
https://nzleo.github.io/LeoLauncher/
https://github.com/nzleo/LeoLauncher/releases/latest
GUIDE

echo ""
echo "=== create DMG ==="
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
DMG_PATH="$DIST_DIR/$APP_NAME-$VERSION.dmg"
rm -f "$DMG_PATH"

hdiutil create \
    -volname "$VOL_NAME" \
    -srcfolder "$PAYLOAD" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH" >/dev/null

echo ""
echo "Created $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
echo "First open needs Gatekeeper allow — see 安装说明.txt"
