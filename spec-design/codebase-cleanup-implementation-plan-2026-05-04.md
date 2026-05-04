# Angel Fallen 代码整理阶段实施计划 - 2026-05-04

## 目标

本阶段只建立整理边界和后续拆分步骤，不改变运行时行为，不重排场景，不替换资产。目标是让后续代理在继续开发资产、UI 和长局平衡前，明确哪些大文件只能承接编排，哪些逻辑必须下沉到专门系统。

## 当前高风险文件

| 文件 | 当前问题 | 第一轮整理边界 |
|------|----------|----------------|
| `scripts/game/game_world.gd` | 已承担房间推进、拾取、宝箱、商店、叙事、结算、HUD 联动等过多职责 | 保留为运行编排入口；新增玩法系统必须放到 `scripts/systems/` 或独立 `scripts/game/` 脚本 |
| `scripts/ui/main_menu.gd` | 主菜单、设置、角色选择、档案、运行设置集中在一个 UI 脚本中 | 新菜单页、复杂弹层、分页设置必须拆独立场景或子脚本 |
| `scripts/game/auto_weapon.gd` | 主武器执行、副武器 profile、特效层、投射物发射和风格映射混在一起 | 保留自动攻击入口；武器族映射、特效层 resolver、构筑统计逐步外移 |
| `scripts/tools/run_visual_snapshot_regression.gd` | 工具脚本过长，目标定义、截图执行、像素检查混杂 | 后续拆为目标配置读取、截图执行、像素检查三层 |

## 第一轮拆分顺序

### Cleanup-1：宝箱与拾取结算边界

- 新建或规划 `scripts/systems/reward_resolution_system.gd`。
- 后续将 `chest` pickup、普通奖励、宝箱进化候选、金币/矿石/食物结算从 `game_world.gd` 迁出。
- `game_world.gd` 只保留入口调用、HUD 刷新、玩家节点引用。
- 回归命令：
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_core_flow_regression.gd -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_treasure_chest_evolution.gd -gexit`

### Cleanup-2：主菜单分页拆分

- 新建或规划 `scripts/ui/main_menu_run_setup_panel.gd`、`scripts/ui/main_menu_archive_panel.gd`。
- `main_menu.gd` 只负责导航、状态切换和 SaveManager/SceneManager 对接。
- 角色选择、难度选择、运行概览、档案详情分别进入子面板。
- 回归命令：
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_runtime_settings_difficulty_flow.gd -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_codex_archive_flow.gd -gexit`
  - Godot MCP 截图：主菜单、Run Setup、Settings、Archive。

### Cleanup-3：自动武器 profile resolver

- 新建或规划 `scripts/systems/weapon_runtime_profile_resolver.gd`。
- 将 `weapon_id`、`projectile_style`、orbit/aura/ground tags、impact radius、slot damage scaling 从 `auto_weapon.gd` 抽为纯 profile 解析。
- `auto_weapon.gd` 只处理目标选择、冷却推进、发射调用、运行时反馈。
- 回归命令：
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_weapon_loadout.gd -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/unit/test_survivor_combat_effects.gd -gexit`
  - `godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_core_flow_regression.gd -gexit`

## 禁止事项

- 不在整理提交中新增玩法、数值、资产或 UI 视觉改动。
- 不在同一次提交中同时拆 `game_world.gd`、`main_menu.gd` 和 `auto_weapon.gd`。
- 不直接删除旧函数；先抽出同等行为，再用回归测试确认。
- 不把历史文档迁移和代码拆分混在同一次提交。

## 提交策略

| 提交 | 内容 | 验证 |
|------|------|------|
| Cleanup Plan | 仅文档与整理边界 | `git diff --check`、JSON/resource 轻量校验 |
| Cleanup-1 | 宝箱/拾取结算系统抽取 | 核心回归 + 宝箱专项 |
| Cleanup-2 | 主菜单分页拆分 | UI/档案/设置测试 + MCP 截图 |
| Cleanup-3 | 自动武器 profile resolver | 武器/loadout/战斗表现测试 |

## 完成标准

- 新功能开发不再继续扩大上述大文件。
- 每次拆分都有对应测试命令和人工复核证据。
- `spec-design/README.md` 能引导代理找到当前真源、整理计划、资产计划和人工复核证据。
