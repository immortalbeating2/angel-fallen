# MVP 发布 Smoke Checklist（2026-03-22）

## 目标

- 在正式发布或外部试玩包导出前，统一自动化门禁、三平台导出命令与人工 smoke 检查项。
- 让当前项目从“能通过 CI”推进到“有可追溯发布记录”。

## 使用范围

- 适用于当前 MVP 冻结范围：`2章(F1-F6) + 2 Boss + 3角色 + Meta + 存档 + 基础设置`。
- 当前导出预设：`Windows Desktop`、`Linux/X11`、`macOS`。

## 发布前自动化门禁

- `python scripts/tools/check_json_syntax.py`
- `python scripts/validate_configs.py`
- `python scripts/check_resources.py`
- `python -m py_compile scripts/validate_configs.py scripts/check_resources.py`
- `godot --headless --path . --quit`
- `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit`
- `godot --headless --path . -s res://scripts/tools/run_quality_baseline.gd`
- `godot --headless --path . -s res://scripts/tools/run_release_gate.gd`
- `godot --headless --path . -s res://scripts/tools/run_compatibility_rehearsal.gd`
- `godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd`
- `godot --headless --path . -s res://scripts/tools/run_visual_snapshot_regression.gd`

## Windows 本机命令备注

- 若 `godot` 命令已正确指向可用 CLI，可直接使用上面的统一命令。
- 若当前 Windows 环境仍命中错误 wrapper，可临时改用真实可执行文件：

```powershell
& "C:/software/Godot/Godot Engine/Godot_v4.6.1-stable_win64.exe" --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit
```

## 三平台导出命令

```bash
godot --headless --path . --export-release "Windows Desktop" builds/windows/angel-fallen.exe
godot --headless --path . --export-release "Linux/X11" builds/linux/angel-fallen.x86_64
godot --headless --path . --export-release "macOS" builds/macos/angel-fallen.zip
```

## 产物命名与记录

- 构建目录固定为 `builds/windows/`、`builds/linux/`、`builds/macos/`。
- 发布记录至少包含：提交 SHA、构建时间、导出平台、使用的 Godot 版本、自动化门禁结果、人工 smoke 结论。
- 若某平台导出失败，必须记录失败命令、报错摘要、处理结论，不能只口头说明。

## 人工 Smoke Checklist

- [ ] 启动游戏进入 `scenes/main_menu/main_menu.tscn`，无启动报错或明显卡死。
- [ ] 主菜单可进入角色选择，至少浏览 3 个角色并正常开始游戏。
- [ ] 首局开始后，移动、自动攻击、受伤、经验拾取、升级选择均正常。
- [ ] 至少完成 1 次商店或事件交互，并确认 UI 可关闭、状态可继续推进。
- [ ] 完成第 1 个 Boss 战，确认结算、掉落或章节推进无阻断。
- [ ] 至少推进到第 2 章并验证房间切换、章节转场、危险地形/视觉效果无明显异常。
- [ ] 完成第 2 个 Boss 战或记录死亡/撤退分支，确认结算页与返回主菜单链路正常。
- [ ] 关闭并重开游戏，确认 `user://meta_save.json` 存档可读取，Meta/设置不丢失。
- [ ] 修改至少 1 项设置（如音量或输入），重开后确认持久化生效。
- [ ] 检查窗口模式、分辨率/缩放在当前平台下无致命 UI 错位。

## 平台专项检查

- `Windows`
  - [ ] 可执行文件可直接启动，无缺 DLL 或 Defender 级阻断提示。
  - [ ] 控制台/窗口模式符合预期，关闭行为正常。
- `Linux/X11`
  - [ ] 可执行文件具备运行权限，启动后能正常进入主菜单。
  - [ ] 常见桌面环境下窗口创建、输入与音频输出无致命异常。
- `macOS`
  - [ ] `zip` 解压后 `.app` 能启动。
  - [ ] 未签名状态下的启动限制已在发布说明中提示。

## 发布阻断条件

- 任一自动化门禁失败。
- 任一平台导出失败或产物缺失。
- 主循环关键节点失败：开局、升级、商店/事件、Boss、结算、存档重开。
- 出现阻断型崩溃、卡死、坏档、严重 UI 错位或无法完成一轮 MVP 流程。

## 执行后归档

- 将本次执行结果追加到 session 文档或专门发布记录中。
- 至少记录：通过项、失败项、阻断项、是否允许发包。
- 若未通过，下一轮发布 smoke 前先清理阻断项，不继续扩 D44+ 治理范围。
