# Stage 5 正式收口说明（2026-03-25）

## 收口结论

- `Stage 5：叙事、营地与结局闭环` 现已正式收口，可以从 `in_progress` 切换为 `completed`。
- 本阶段的完成定义是：把路线选择、营地反思、章节转场、三结局兑现、碎片回看、隐藏层前置提示与档案状态做成稳定的运行时 + 持久化 + 前台展示闭环。
- 本阶段**不包含** `FS2` 与 `CL1/CL2+` 的完整版后期玩法扩张；这些内容继续归入 `Stage 6`。

## 已完成能力真值

### 1. 路线弧线、营地反思与章节转场闭环

- `route_arc_profiles`、`camp_reflections`、`fragment_trigger_profiles` 已接入运行时。
- 安全营地、章节转场与记忆祭坛已经稳定展示：`Route arc`、`Camp reflection`、`Fragment progress`、`Recent vows`、`Forward note`、`Camp loop` 等 Stage 5 核心摘要。
- 章节房间节奏与历史回看也已归并进 Stage 5 的叙事前台，而不再只是底层配置存在。
- 关键证据：`test/unit/test_narrative_camp_flow.gd`、`test/unit/test_room_pacing_profiles.gd`、`scripts/game/game_world.gd`、`scripts/ui/chapter_transition_panel.gd`。

### 2. 三结局 payoff、后记链路与首通/复通分支闭环

- 三结局 `nar_ending_balance` / `nar_ending_fall` / `nar_ending_redeem` 均具备：
  - `ending_payoff`
  - `ending_epilogue_chain`
  - `epilogue_branch_profiles.first_unlock`
  - `epilogue_branch_profiles.repeat_unlock`
- `SaveManager` 已将结局分支真值落盘，`run_result_panel` 与 `main_menu` 已能展示当前结局、后记链路与分支模式。
- 本轮已新增回归测试，直接锁定“三结局 + 首通/复通差异”的运行时行为，避免后续只剩配置存在、但结算分支退化。
- 关键证据：`test/unit/test_narrative_payoff_flow.gd`、`test/unit/test_narrative_route_style_config.gd`、`test/unit/test_hidden_layer_achievement_flow.gd`、`scripts/autoload/save_manager.gd`、`scripts/ui/run_result_panel.gd`、`scripts/ui/main_menu.gd`。

### 3. 碎片回顾、档案时间线与回看入口闭环

- `fragment_recap_profiles`、`fragment_triggers`、结局/碎片/成就解锁时间线元数据已经形成统一档案入口。
- 主菜单与记忆祭坛已能按解锁顺序、`run_index`、时间戳回看结局与碎片，而不只是显示“已解锁/未解锁”。
- Stage 5 的“故事回流”目标已经从运行时结果延伸到档案回看入口。
- 关键证据：`test/unit/test_hidden_layer_achievement_flow.gd`、`test/unit/test_narrative_payoff_flow.gd`、`scripts/ui/main_menu.gd`。

### 4. 隐藏层前置钩子、故事与状态前台闭环

- `hidden_layer_hooks`、`hidden_layer_story_profiles`、`hidden_layer_statuses` 已接入：
  - 营地文本
  - 章节转场
  - 结算页
  - 主菜单 Last Run
  - 记忆祭坛 / Hidden Layer Track
- 这里的 Stage 5 完成定义是“前置提示与故事/状态回写闭环已完成”，不是“隐藏层完整版玩法已经全部做完”。
- 因此 `FS1/FS2` 的玩法规模、反复游玩动机与后期奖励扩张仍然属于 `Stage 6`。
- 关键证据：`test/unit/test_narrative_camp_flow.gd`、`test/unit/test_narrative_payoff_flow.gd`、`test/unit/test_hidden_layer_achievement_flow.gd`、`scripts/game/game_world.gd`、`scripts/autoload/save_manager.gd`。

### 5. Stage 5 统一验收资料已补齐

- 本轮已补齐三份 Stage 5 收口资料：
  - `spec-design/stage5-closure-2026-03-25.md`
  - `spec-design/stage5-acceptance-record-2026-03-25.md`
  - `spec-design/stage5-acceptance-summary-2026-03-25.md`
- 后续新 session 不需要再从测试文件和 UI 文案中反向猜测 Stage 5 是否完成，可直接以这三份文档为承接基线。

## 已完成 / 未完成边界

| 归属 | 内容 | 当前结论 |
|---|---|---|
| Stage 5 | 路线弧线、营地反思、章节转场叙事增强 | 已完成 |
| Stage 5 | 三结局 payoff、epilogue chain、首通/复通 epilogue branch | 已完成 |
| Stage 5 | fragment recap、Ending Archive / Memory Archive / Hidden Layer Track 前台闭环 | 已完成 |
| Stage 5 | `hidden_layer_hook`、`hidden_layer_story`、`hidden_layer_statuses` 的结算页 / 主菜单 / 记忆祭坛接入 | 已完成 |
| Stage 6 | `FS2` 与 `FS1` 对齐的可玩入口、房间/Boss/结算闭环 | 未完成 |
| Stage 6 | `CL1` 失败路径、`Sigil Bundle` / `Archive Insight` 分支、非 Meta 奖励后的营地预览回显 | 未完成 |
| Stage 6 | `sigils` / `insight` 是否升级为真实全局资源 | 未定案 |
| Stage 6 | `CL2+` schema 与更完整挑战层体系 | 未完成 |
| Stage 7 | 营地 / 转场 / Boss / 结算页的视觉与音频成品化 | 未完成 |

## 本轮自动化验收基线

- 执行基线：`2befea1`
- Godot 版本：`4.6.1.stable.official.14d19694e`
- 本轮已执行并通过的 Stage 5 相关专项测试：
  - `test/unit/test_narrative_camp_flow.gd`：`4/4 passed`，`94` asserts
  - `test/unit/test_narrative_payoff_flow.gd`：`7/7 passed`，`125` asserts
  - `test/unit/test_hidden_layer_achievement_flow.gd`：`9/9 passed`，`198` asserts
  - `test/unit/test_room_pacing_profiles.gd`：`5/5 passed`，`60` asserts
  - `test/unit/test_narrative_route_style_config.gd`：`8/8 passed`，`427` asserts
- 合计：`5` 个脚本、`33` 个测试、`904` 个断言，全部通过。

## 收口后的下一步

1. 先按既定顺序进入 `Stage 6 Session 4`：补 `CL1` 失败路径、替代奖励分支与营地回显。
2. 再做 `Stage 6 Session 5`：补 `FS2` 与 `FS1` 对齐的可玩闭环和回归测试。
3. `sigils` / `insight` 的资源定位与 `CL2+` schema 泛化，放在上述最小可玩闭环之后处理。
