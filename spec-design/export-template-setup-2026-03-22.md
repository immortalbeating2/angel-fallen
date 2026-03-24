# Godot 导出模板与发布环境准备（2026-03-22）

## 目标

- 消除当前 MVP 发布闭环中的环境级阻塞项：Godot `4.6.1.stable` 导出模板缺失。
- 统一本机 CLI、导出模板目录与导出校验命令，避免后续每轮发布演练重复踩坑。

## 当前阻塞

- `export_presets.cfg` 已补齐 `Windows Desktop`、`Linux/X11`、`macOS` 三个平台 preset。
- Godot CLI 已能识别 3 个 preset，但实际导出仍失败。
- 当前失败根因不是 preset 结构错误，而是本机缺少 Godot `4.6.1.stable` export templates。

## 当前缺失模板

Godot 当前查找的模板目录为：`%APPDATA%/Godot/export_templates/4.6.1.stable/`

至少需要以下文件：

| 平台 | 必需模板 |
|------|----------|
| Windows | `windows_debug_x86_64.exe`、`windows_release_x86_64.exe` |
| Linux/X11 | `linux_debug.x86_64`、`linux_release.x86_64` |
| macOS | `macos.zip` |

## 推荐安装方式

### 方式 A：通过 Godot Editor 安装（优先）

1. 打开 Godot `4.6.1` Editor。
2. 进入 `Editor -> Manage Export Templates`。
3. 安装与当前引擎版本完全一致的模板：`4.6.1.stable`。
4. 安装完成后，确认模板落到 `%APPDATA%/Godot/export_templates/4.6.1.stable/`。

### 方式 B：手动安装

1. 下载与本机引擎版本完全一致的官方模板包：`4.6.1.stable`。
   - 当前可用发布资源：`Godot_v4.6.1-stable_export_templates.tpz`
   - GitHub Release：`https://github.com/godotengine/godot-builds/releases/tag/4.6.1-stable`
2. 解压模板包。
3. 将模板文件复制到 `%APPDATA%/Godot/export_templates/4.6.1.stable/`。
4. 确认上述 5 个关键模板文件存在。

## Windows CLI 约定

- 若 `godot` 命令仍命中错误 wrapper，发布校验阶段统一直接使用真实可执行文件：

```powershell
& "C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . --quit
```

- 该约定只影响本机命令入口，不影响仓库内 `export_presets.cfg`。

## 安装后验证命令

```powershell
& "C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . --export-release "Windows Desktop" "builds/windows/angel-fallen.exe"
& "C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . --export-release "Linux/X11" "builds/linux/angel-fallen.x86_64"
& "C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . --export-release "macOS" "builds/macos/angel-fallen.zip"
```

## 完成标准

- 三个平台导出命令都不再报“指定路径不存在导出模板”。
- `builds/windows/`、`builds/linux/`、`builds/macos/` 能生成首轮可追溯产物。
- 首轮导出结果写入发布演练记录，再进入人工 smoke checklist。
