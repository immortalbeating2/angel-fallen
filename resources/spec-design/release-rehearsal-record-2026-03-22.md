# 发布演练记录（2026-03-22）

## 结论

- 当前结论：`阻塞，暂不可发包`。
- 自动化前置校验已通过，且已完成首轮三平台正式导出；当前阻塞已从“无法导出”收敛为“尚未完成基于产物的人工 smoke 与发布归档”。

## 本次环境

- 提交基线：`d3d0d49`
- Godot 版本：`4.6.1.stable.official.14d19694e`
- 本机 CLI：`C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe`
- 发布范围：`2章(F1-F6) + 2 Boss + 3角色 + Meta + 存档 + 基础设置`

## 自动化前置结果

| 项目 | 结果 | 备注 |
|------|------|------|
| `python scripts/tools/check_json_syntax.py` | 通过 | `20 files` |
| `python scripts/validate_configs.py` | 通过 | `Validated 18 JSON config files successfully.` |
| `python scripts/check_resources.py` | 通过 | `Basic resource structure check passed.` |
| `python -m py_compile scripts/validate_configs.py scripts/check_resources.py` | 通过 | 无报错 |
| `godot --headless --path . --quit` | 通过 | 项目可 headless 启动 |
| `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit` | 通过 | `16 scripts / 52 tests / 6217 asserts / All tests passed` |

## 导出演练结果

| 平台 | Preset 识别 | 导出结果 | 阻塞原因 |
|------|-------------|----------|----------|
| Windows Desktop | 是 | 通过 | 产物：`builds/windows/angel-fallen.exe` + `builds/windows/angel-fallen.pck` |
| Linux/X11 | 是 | 通过 | 产物：`builds/linux/angel-fallen.x86_64` + `builds/linux/angel-fallen.pck` |
| macOS | 是 | 通过 | 产物：`builds/macos/angel-fallen.zip` |

- 已安装模板目录：`C:/Users/彭小平/AppData/Roaming/Godot/export_templates/4.6.1.stable/`
- macOS 导出修正项：
  - `export_presets.cfg` 中 `macOS` preset 已切回 `binary_format/architecture="universal"`
  - `export_presets.cfg` 已显式启用 `texture_format/etc2_astc=true`
  - `project.godot` 已启用 `rendering/textures/vram_compression/import_etc2_astc=true`

## 产物归档

| 文件 | 大小（bytes） | SHA256 |
|------|---------------|--------|
| `builds/windows/angel-fallen.exe` | `104451072` | `1241d64d06fb53cef4f6a69d142864cd693b722a6a01d7fb011825f3600eaa5e` |
| `builds/windows/angel-fallen.pck` | `2977544` | `3a17c750b7738fbe7401bab8f2736b88d529d31425c0e4eb1038985bd06f381c` |
| `builds/linux/angel-fallen.x86_64` | `71047224` | `9e86efcd7578fa79af615c277dc6d6405609a099f5a317c3d17d76892133bb06` |
| `builds/linux/angel-fallen.pck` | `2977544` | `bafef8c6dc3f74ba93b84a41744ff97e1379da857ed510d3f0af458fe675b1ff` |
| `builds/macos/angel-fallen.zip` | `63380543` | `6295e263ad98f8815b1dc9b289e0438f73f090171d090fc5f293f399e77fee5b` |

## 当前可执行 Smoke

- `Windows`：已在当前主机直接运行 `builds/windows/angel-fallen.exe --headless --quit`，返回码 `0`，可完成最小启动 smoke。
- `macOS`：已确认 `builds/macos/angel-fallen.zip` 内包含 `angel-fallen.app/Contents/MacOS/angel-fallen` 与 `angel-fallen.pck`，但尚未在 macOS 主机实际启动。
- `Linux/X11`：已生成 `builds/linux/angel-fallen.x86_64` 与对应 `.pck`，但当前 Windows 主机无法做原生 Linux 运行 smoke。

## 人工 Smoke 执行状态

- 尚未开始，当前仍阻塞发布结论收口。
- 当前已具备平台级 smoke 条件，待按 `spec-design/release-smoke-checklist-2026-03-22.md` 基于现有产物执行并归档结果。
- 当前主机已完成的仅是 `Windows` 最小启动验证；`Linux/X11` 与 `macOS` 仍缺目标平台人工执行记录。

## 下一步

1. 按 `spec-design/release-smoke-checklist-2026-03-22.md` 对 Windows / Linux / macOS 产物完成首轮人工 smoke。
2. 为本次记录补齐执行人、执行时间与问题单链接。
3. 完整记录通过项、失败项、阻断项，并给出“是否允许发包”结论。
