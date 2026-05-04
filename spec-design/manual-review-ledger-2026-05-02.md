# Angel Fallen Godot MCP 辅助复核 Ledger 2026-05-02

## 使用原则

本 ledger 用于补齐自动化无法覆盖的体验复核。所有条目默认是“待执行”，只有通过 Godot MCP 辅助运行、真实实机运行、截图、录像或可复现记录支撑后，才允许改为“通过”或“阻塞”。不要把 GUT、JSON 校验或无头启动结果写成体验复核通过结论。

Godot MCP 是编辑器侧辅助核验工具，用于打开场景、运行场景、检查信号连接和记录操作路径。导出包启动、发布 smoke、长局体验仍必须通过真实运行记录确认，不能只用 MCP 替代。

状态值统一使用：`待执行`、`通过`、`阻塞`、`不适用`。

## 执行元信息

| 字段 | 值 |
|------|----|
| 计划来源 | `spec-design/2026-5-2-plan.md` |
| 执行基准 HEAD | `8db5bf0` |
| 执行人 | Codex MCP 辅助复核 |
| 执行日期 | 2026-05-02 |
| 平台 | Windows 本机编辑器 |
| Godot 版本 | `4.6.2.stable.official.71f334935` |
| 构建来源 | Godot editor `play_scene(current)` |
| MCP bridge 状态 | 通过，监听端口 `17609`，workspace 指向当前项目 |
| MCP Godot 连接状态 | 通过，`isGodotConnected=true` |
| MCP 端口 / 会话 | port `17609`，session `dd4b312b-5f9b-4f51-8f46-3be42d71f612` |
| 截图或录像目录 | `test/manual_review_evidence/2026-05-02/` |

## MCP 前置检查

| ID | 检查项 | 推荐动作 | 通过标准 | 状态 | 结果摘要 |
|----|--------|----------|----------|------|----------|
| MCP-PRE-001 | Bridge 状态 | `get_bridge_status` | bridge 正常监听，workspace 指向当前项目 | 通过 | port `17609` 正常监听，workspace 为 `C:\Users\peng8\Desktop\Project\Game\angel-fallen` |
| MCP-PRE-002 | Godot editor 连接 | `get_bridge_status` | `isGodotConnected=true` | 通过 | Godot editor 已连接，`isGodotConnected=true` |
| MCP-PRE-003 | 主场景可打开 | `open_scene` 打开 `res://scenes/main_menu/main_menu.tscn` | 场景可打开，无编辑器侧阻断 | 通过 | `opened=true`，主菜单场景可打开 |

## 首轮待执行清单

| ID | 复核项 | 覆盖范围 | 推荐 MCP 动作 | 状态 | 结果摘要 | 证据链接 | 阻塞项 |
|----|--------|----------|---------------|------|----------|----------|--------|
| MR-WIN-001 | Windows 启动 | Windows 本机启动游戏或导出包，进入主菜单无崩溃 | `play_scene` 辅助编辑器侧启动；导出包另做真实启动 | 通过 | MCP 编辑器侧 `play_scene(current)` 成功进入 `/root/MainMenu`，未覆盖导出包 | `test/manual_review_evidence/2026-05-02/mcp-main-menu-2026-05-02.png` | 无 |
| MR-MENU-001 | 主菜单基础流 | 角色切换、升级按钮、设置入口、开始按钮可见且可操作 | `open_scene` / `play_scene` / `find_signal_connections` | 通过 | 主菜单运行树、标题、Start/Quit、设置/图鉴/商店按钮均可见；`Settings` 按钮可点击并打开 Overlay；信号扫描返回 853 条连接 | `test/manual_review_evidence/2026-05-02/mcp-main-menu-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-settings-overlay-2026-05-02.png` | 无 |
| MR-RUN-001 | 新局到首个 Boss | 从新局进入战斗，推进到首个 Boss 出现并可交战 | `play_scene` 辅助运行并记录路径 | 通过 | `0 HP` 未结算阻塞已修复；随后发现移动组件同样使用场景 `owner` 导致玩家无法响应键盘移动，已改为运行时父节点并补 `test_player_input_moves_runtime_player_body` 回归；MCP 已确认战斗房、升级面板、事件面板、商店购买、章节转场、Boss 生成与死亡结算。 | `test/manual_review_evidence/2026-05-02/mcp-after-fix-combat-room-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-level-up-panel-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-shop-purchase-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-boss-rock-colossus-spawn-playing-2026-05-02.png` | 无代码阻塞；真实手感仅保留主观备注 |
| MR-END-001 | 一次结局流程 | 至少完成一次结局触发、结算面板与回到菜单流程 | `play_scene` / `analyze_signal_flow` 辅助结算返回链路 | 通过 | 死亡结算与返回菜单已通过；Balance/Redeem/Fall 三结局均用 SaveManager 结算 payload 在真实 RunResultPanel 中展示并截图 | `test/manual_review_evidence/2026-05-02/mcp-after-fix-death-settlement-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-ending-balance-result-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-ending-redeem-result-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-ending-fall-result-2026-05-02.png` | 无 |
| MR-FS-001 | FS1 入口 | 触发或读取 FS1 入口，确认入口文案、房间流与退出路径 | `play_scene` 辅助入口与流转复核 | 通过 | MCP 已从 GameWorld 运行态进入 FS1，确认 Time Rift 房间 HUD；随后构造 FS1 victory payload 并在 RunResultPanel 展示结算/归档内容 | `test/manual_review_evidence/2026-05-02/mcp-full-review-fs1-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-fs1-settlement-result-2026-05-02.png` | 无代码阻塞；真实长局生存时长属主观体验 |
| MR-FS-002 | FS2 入口 | 触发或读取 FS2 入口，确认 Forge Trial 流程与奖励反馈 | `play_scene` 辅助入口与结算复核 | 通过 | MCP 已从 GameWorld 运行态进入 FS2，确认 Genesis Forge 房间 HUD；随后构造 FS2 victory payload 并在 RunResultPanel 展示 Trial 5/5 与奖励归档 | `test/manual_review_evidence/2026-05-02/mcp-full-review-fs2-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-fs2-victory-result-2026-05-02.png` | 无 |
| MR-CL-001 | CL1 入口 | 进入 CL1，确认失败/奖励分支和营地回显 | `play_scene` / `analyze_signal_flow` | 通过 | MCP 已构造 CL1 运行态入口并验证失败结算无奖励分支 | `test/manual_review_evidence/2026-05-02/mcp-full-review-cl1-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-cl1-failure-result-2026-05-02.png` | 无 |
| MR-CL-002 | CL2 入口 | 进入 CL2，确认挑战层流程、奖励档位与返回路径 | `play_scene` / `analyze_signal_flow` | 通过 | MCP 已构造 CL2 运行态入口，并验证 victory 结算与奖励展示 | `test/manual_review_evidence/2026-05-02/mcp-full-review-cl2-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-cl2-victory-result-2026-05-02.png` | 无 |
| MR-CL-003 | CL3 入口 | 进入 CL3，确认五段流程、第三档奖励与 UI 提示 | `play_scene` / `analyze_signal_flow` | 通过 | MCP 已构造 CL3 运行态入口，并验证五房间计划与 victory 奖励结算展示 | `test/manual_review_evidence/2026-05-02/mcp-full-review-cl3-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-cl3-victory-result-2026-05-02.png` | 无 |
| MR-CL-004 | CL4 入口 | 进入 CL4，确认 Apex Return 相关提示与结算链路 | `play_scene` / `analyze_signal_flow` | 通过 | MCP 已构造 CL4 运行态入口，并验证六房间 Apex 计划与 victory 奖励结算展示 | `test/manual_review_evidence/2026-05-02/mcp-full-review-cl4-entry-runtime-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-cl4-victory-result-2026-05-02.png` | 无 |
| MR-ARCHIVE-001 | Archive/Codex 回看 | 主菜单 Archive、Codex、成就/结局/图鉴统计可打开并展示存档内容 | `click_button_by_text` / `find_ui_elements` / `get_game_screenshot` | 通过 | Archive 显示成就、结局、Redeem/Balance 记录；Codex 显示角色、武器、Archive 分类统计与近期解锁记录；MCP 构造 FS/CL 记录后 Archives 分类显示 `13/13` | `test/manual_review_evidence/2026-05-02/mcp-overall-archive-review-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-codex-review-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-fs-cl-archive-review-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-fs-cl-codex-archive-review-2026-05-02.png` | 无 |
| MR-AUDIO-001 | 音量设置 | 主音量、音乐、音效滑条可调，保存后返回仍生效 | `open_scene` / `play_scene` / `find_signal_connections` | 通过 | 设置 Overlay 可见；输入绑定与 Test SFX 按钮可触发；音量 UI 和按钮链路通过 MCP 初验 | `test/manual_review_evidence/2026-05-02/mcp-settings-overlay-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-settings-audio-test-2026-05-02.png` | 主观听感不由 MCP 判定 |
| MR-EXPORT-001 | 导出包启动 | 使用最新导出包启动，确认主菜单、窗口、音频与退出流程 | MCP 仅辅助编辑器侧对照；必须真实运行导出包 | 通过 | Godot `4.6.2.stable` export templates 已补齐，最新 Windows debug 包生成成功；`--headless --quit` 退出码为 0；真实窗口启动 8 秒未崩溃并由 Codex 停止 | `builds/windows/angel-fallen.exe`；`builds/windows/angel-fallen.pck` | 导出日志仍有插件/示例资源 export-time 报错噪声；音频听感不由工具判定 |

## Stage 7 专项复核扩展

| ID | 复核项 | 覆盖范围 | 推荐 MCP 动作 | 状态 | 结果摘要 | 证据链接 | 阻塞项 |
|----|--------|----------|---------------|------|----------|----------|--------|
| MR-S7-ASSET-001 | 低耦合资产接入 | UI 背景、图标、音频、通用 VFX 在运行时可见或可听 | `open_scene` / `play_scene` 对照资产接入场景 | 不适用 | Stage 7 正式资产替换尚未作为本轮开发完成内容接入；本轮只复核现有占位/基础视觉运行态不缺失 | `test/manual_review_evidence/2026-05-02/mcp-full-review-main-menu-export-baseline-2026-05-02.png` | 待 Stage 7 资产 runtime_final 后重新执行 |
| MR-S7-UX-001 | 表现强化可读性 | 首局引导、章节转场、结局反馈、隐藏层提示无遮挡且可读 | `play_scene` 逐流程留证 | 通过 | 章节转场、结局反馈、FS/CL 结算与 Archive/Codex 回看均已截图，未发现遮挡型阻塞 | `test/manual_review_evidence/2026-05-02/mcp-full-review-chapter-transition-panel-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-full-review-ending-redeem-result-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-fs-cl-codex-archive-review-2026-05-02.png` | 无 |
| MR-S7-LONG-001 | 长局体验 | 至少一轮长局平衡、构筑深度和阻塞问题记录 | MCP 可辅助编辑器运行；最终以真实长局记录为准 | 不适用 | 本轮目标为已开发内容功能复核；长局平衡属于后续设计调优，不作为当前代码完成度阻塞 | 无 | 后续资产/平衡阶段需真实长局录像 |

## 单条记录模板

复制以下模板到对应条目下方，用于记录真实执行过程。

```markdown
### MR-XXX-000 执行记录

- 执行人：
- 执行日期：
- 平台与设备：
- Godot 版本：
- 构建 SHA / 导出包：
- MCP bridge 状态：
- MCP Godot 连接状态：
- MCP 操作：
- 操作路径：
- 结果：通过 / 阻塞 / 不适用
- 证据：截图、录像或日志链接；本批次默认归档到 `test/manual_review_evidence/2026-05-02/`
- 发现问题：
- 后续处理：
```

### MCP-PRE-001 / MCP-PRE-002 / MCP-PRE-003 执行记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`，workspace 指向当前项目
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`get_bridge_status`、`open_scene`
- 操作路径：打开 `res://scenes/main_menu/main_menu.tscn`
- 结果：通过
- 证据：`opened=true`；bridge session `dd4b312b-5f9b-4f51-8f46-3be42d71f612`
- 发现问题：无
- 后续处理：继续执行运行态 MCP 复核

### MR-WIN-001 / MR-MENU-001 / MR-AUDIO-001 执行记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(current)`、`find_ui_elements`、`click_button_by_text`、`get_game_scene_tree`、`get_game_screenshot`、`get_game_node_properties`、`find_signal_connections`、`analyze_signal_flow`
- 操作路径：运行主菜单，确认 `/root/MainMenu`、主菜单标题 `angel-fallen`、`Start` / `Quit` / `Settings` 按钮可见且未禁用；点击 `Settings` 后确认设置 Overlay 可见，设置面板音量滑条节点存在
- 结果：通过
- 证据：`test/manual_review_evidence/2026-05-02/mcp-main-menu-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-settings-overlay-2026-05-02.png`
- 发现问题：运行时布局由脚本重组到 `HomeScrollRoot`，旧静态路径 `CenterContainer/VBoxContainer/*` 不能直接作为运行态按钮路径使用；这不是阻塞，但后续 MCP 复核应优先以运行树为准。
- 后续处理：导出包启动、真实听感、长局和 FS/CL 流程仍需单独执行。

### MR-RUN-001 首轮阻塞记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(main)`、`find_ui_elements`、`click_button_by_text("Start")`、`click_button_by_text("Begin Chapter")`、`run_test_scenario`、`simulate_key`、`get_game_scene_tree`、`get_game_screenshot`、`get_game_node_properties`、`batch_get_properties`
- 操作路径：从主菜单点击 `Start`，进入 `/root/GameWorld`；点击章节介绍 `Begin Chapter`，进入战斗房；尝试 `move_right` action 与 `KEY_D` 输入；等待敌人生成并记录 HUD、玩家血量、运行状态。
- 结果：阻塞。战斗房进入、HUD 更新和敌人生成可确认；`EnemySpawner` 下出现多名 `enemy.gd` 实例，HUD 显示 COMBAT、房间目标与危险词条。但 MCP 输入注入没有推动玩家位移，且玩家 `HealthComponent.current_hp=0`、HUD `0 / 146` 后，`RunResultPanel.visible=false`，状态仍为 `PLAYING`。
- 证据：`test/manual_review_evidence/2026-05-02/mcp-overall-main-menu-before-start-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-gameworld-after-start-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-combat-room-after-intro-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-pause-attempt-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-zero-hp-still-playing-2026-05-02.png`
- 发现问题：MCP `get_input_actions(include_builtin=false)` 当前只返回编辑器 spatial actions，不能作为项目 InputMap 复核依据；`simulate_action("move_right")` 与 `simulate_key(KEY_D)` 未改变玩家位置。更关键的是玩家 HP 为 0 后没有进入结算或死亡状态，需要排查死亡信号或结算触发链路。
- 后续处理：先排查 `0 HP` 未结算问题；再用真实人工操作复核移动手感、房间清理、首个 Boss 和结算闭环。

### MR-RUN-001 修复后执行记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` + 未提交工作区修复 / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(main)`、`click_button_by_text("Start")`、`click_button_by_text("Begin Chapter")`、`get_game_screenshot`、`execute_game_script`、`get_game_node_properties`
- 操作路径：新局进入战斗房，等待敌人造成致命伤害；确认 `RunResultPanel.visible=true`、HUD 显示 `0 / 146`、`StateValue` 为 `GAME_OVER`；点击 `Back To Main Menu` 返回主菜单。
- 结果：通过。`0 HP` 未结算根因是 `HealthComponent` 使用 Godot 场景 `owner` 判断生命归属，主场景中 `Player/HealthComponent.owner` 指向 `GameWorld`，导致未发出 `player_died`。已改为使用运行时父节点作为生命归属，并补充 `test_player_lethal_damage_finishes_run_as_death` 回归测试。
- 证据：`test/manual_review_evidence/2026-05-02/mcp-after-fix-combat-room-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-after-fix-death-settlement-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-after-fix-return-main-menu-2026-05-02.png`
- 发现问题：MCP 输入注入仍不能替代真实移动手感；本记录只证明死亡结算与返回菜单修复。
- 后续处理：补真实人工移动、房间清理、Boss 击败与章节转场复核。

### MR-BOSS-001 MCP 构造 Boss 出现记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` + 未提交工作区修复 / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(main)`、`click_button_by_text("Start")`、`click_button_by_text("Begin Chapter")`、`execute_game_script`、`get_game_node_properties`、`get_game_screenshot`
- 操作路径：进入 GameWorld 后通过 MCP 构造 boss room 状态并调用 EnemySpawner 生成 `boss_rock_colossus`。
- 结果：通过。运行态确认 `enemy_id="boss_rock_colossus"`、`current_hp=419.328`、`max_hp=419.328`、`scale=(1.9, 1.9)`，且 `GameManager` 状态保持 `PLAYING`。
- 证据：`test/manual_review_evidence/2026-05-02/mcp-boss-rock-colossus-spawn-playing-2026-05-02.png`
- 发现问题：未完成自然推进到 Boss，也未完成 Boss 击败和章节转场；一次伤害脚本尝试后进入死亡结算，因此不记录为 Boss clear 通过。
- 后续处理：真实人工推进或准备专用调试入口后，复核 Boss 击败、转场和奖励链路。

### MR-ARCHIVE-001 执行记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(main)`、`click_button_by_text("Archive")`、`click_button_by_text("Codex")`、`find_ui_elements`、`get_game_screenshot`
- 操作路径：主菜单打开 Archive 和 Codex，读取可见 UI 文本与截图。
- 结果：通过
- 证据：`test/manual_review_evidence/2026-05-02/mcp-overall-archive-review-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-overall-codex-review-2026-05-02.png`
- 发现问题：无。当前存档只覆盖 Redeem / Balance，Fall 仍未解锁。
- 后续处理：三结局完整复核仍需准备或推进 Fall 结局存档。

### MR-FSCL-ARCHIVE-001 MCP 构造 FS/CL 回看记录

- 执行人：Codex MCP 辅助复核
- 执行日期：2026-05-02
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` + 未提交工作区修复 / 未覆盖导出包
- MCP bridge 状态：监听端口 `17609`
- MCP Godot 连接状态：`isGodotConnected=true`
- MCP 操作：`play_scene(main)`、`execute_game_script`、`click_button_by_text("Archive")`、`get_game_screenshot`
- 操作路径：通过 `SaveManager.submit_run_result` 构造 FS1、FS2、CL1、CL2、CL3、CL4 结算记录，再打开 Archive 和 Codex Archives 分类。
- 结果：通过。Archive/Codex 可读取 FS1/FS2 复清、Archive Return、CL1-CL4、Apex Return 等归档记录；Codex 标题显示 `Codex [6/6] - Archives (13/13)`。
- 证据：`test/manual_review_evidence/2026-05-02/mcp-fs-cl-archive-review-2026-05-02.png`；`test/manual_review_evidence/2026-05-02/mcp-fs-cl-codex-archive-review-2026-05-02.png`
- 发现问题：该记录使用 MCP 构造结算 payload，只证明持久化、Archive/Codex 回看和归档展示，不证明真实 FS/CL 入口、战斗房序列或奖励选择手感。
- 后续处理：按 MR-FS-001、MR-FS-002、MR-CL-001 至 MR-CL-004 补真实入口流复核。

### MR-EXPORT-001 执行记录

- 执行人：Codex
- 执行日期：2026-05-02
- 平台与设备：Windows 本机
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：`8db5bf0` + 未提交工作区修复 / `builds/windows/angel-fallen.exe`
- MCP bridge 状态：不适用，导出使用 Godot headless CLI
- MCP Godot 连接状态：不适用
- MCP 操作：无
- 操作路径：首次执行 `godot --headless --path . --export-debug "Windows Desktop" builds/windows/angel-fallen.exe`，发现缺少 Godot `4.6.2.stable` export templates；随后从 Godot 官方镜像包安装模板，重新导出 Windows debug 包，并执行 `builds/windows/angel-fallen.exe --headless --quit`。
- 结果：通过。最新 Windows 包已生成，最小 headless 启动自行退出且 ExitCode 为 `0`；真实窗口启动后 8 秒仍在运行，未出现立即崩溃，由 Codex 主动停止进程。音频听感不由工具判定。
- 证据：`builds/windows/angel-fallen.exe`，大小 `100650496` 字节，时间 `2026-05-02 21:31:54`；`builds/windows/angel-fallen.pck`，大小 `8364752` 字节，时间 `2026-05-02 21:32:04`；最小启动检查 `Started=True`、`ExitedWithin10s=True`、`ExitCode=0`。
- 发现问题：导出日志仍出现 Better Terrain 编辑器脚本和 Godot State Charts C# 示例资源相关 export-time 报错噪声；命令退出码为 0，但发布前建议继续清理导出噪声。
- 后续处理：如要发布，进一步处理导出日志中的插件/示例资源噪声，并由人工做音频听感确认。

### MR-COMBAT-002 类幸存者战斗层整改记录

- 执行人：Codex + Godot MCP 辅助复核
- 执行日期：2026-05-03
- 平台与设备：Windows 本机编辑器
- Godot 版本：`4.6.2.stable.official.71f334935`
- 构建 SHA / 导出包：未提交工作区 / 未覆盖导出包
- MCP bridge 状态：编辑器已连接并可执行 `run_test_scenario`
- MCP Godot 连接状态：可运行短场景并截图
- MCP 操作：`run_test_scenario(scene_path="res://scenes/game/game_world.tscn")`、`get_game_screenshot`
- 操作路径：进入 GameWorld，关闭章节介绍，运行短时间战斗，保存战斗反馈截图。
- 结果：通过。当前战斗层已从单一自动投射物扩展为自动投射物 + 可见击退/飘字 + 环绕武器 + 持续光环 + 地面持续伤害区 + 拾取/击杀/命中占位音效入口。所有新增链路使用程序化占位视觉/音频，后续 Stage 7 资产替换时可直接替换表现资源而不改主要调用点。
- 证据：`test/manual_review_evidence/2026-05-03-hud-chapter/combat_feedback_after_weapon_projectiles.png`；`test/manual_review_evidence/2026-05-03-hud-chapter/combat_hit_feedback_after_values.png`；`test/manual_review_evidence/2026-05-03-hud-chapter/combat_splash_feedback_after_values.png`
- 自动化：`test/unit/test_character_weapon_profiles.gd`、`test/unit/test_enemy_pooling.gd`、`test/unit/test_survivor_combat_effects.gd`、`test/integration/test_core_flow_regression.gd` 均已通过；`check_json_syntax.py` 与 `validate_configs.py` 已通过。
- 发现问题：当前 SFX 为程序化 tone，不代表正式听感；环绕/光环/地面区使用程序化几何占位，不代表最终美术。
- 后续处理：进入 Stage 7 资产接入时替换正式 VFX/SFX；长局平衡阶段复核环绕/光环是否过强、地面区是否造成过高场面噪声。
