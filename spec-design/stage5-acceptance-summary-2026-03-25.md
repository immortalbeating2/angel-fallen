# Stage 5 统一验收摘要（2026-03-25）

## 一句话结论

- `Stage 5` 现在可以视为“已完成且可承接后续开发”的稳定基线；后续进入 `Stage 6` 时，不应再把叙事、营地、结局与隐藏层前置前台理解为未闭环状态。

## 当前可直接信任的 Stage 5 真值

- 数据真值：`ending_payoff_profiles`、`epilogue_chains`、`epilogue_branch_profiles`、`fragment_trigger_profiles`、`fragment_recap_profiles`、`hidden_layer_hooks`、`hidden_layer_story_profiles`、`hidden_layer_statuses` 已齐备。
- 运行时真值：`SaveManager` 已落盘 `route_style`、`ending_payoff`、`ending_epilogue_chain`、`epilogue_branch`、`fragment_recap`、`hidden_layer_hook`、`hidden_layer_story`、`hidden_layer_statuses`。
- 前台真值：安全营地、章节转场、结算页、主菜单 Last Run、Ending Archive、Memory Archive、Memory Altar、Hidden Layer Track 均已消费上述字段。
- 回归真值：本轮专项测试 `33` 项、`904` 个断言全部通过，并新增“三结局 + 首通/复通差异”专门回归测试。

## Stage 5 的完成边界

- 已完成：
  - 路线弧线与营地反思。
  - 三结局 payoff / epilogue chain / epilogue branch。
  - 碎片触发节奏与 fragment recap。
  - 隐藏层前置提示、故事与状态的前台闭环。
  - 结算页 / 主菜单 / 记忆祭坛 / 转场 / Hidden Layer Track 的统一展示。
- 不属于 Stage 5：
  - `FS2` 可玩房间/Boss/结算链路补完。
  - `CL1` 失败路径、非 Meta 奖励分支与营地回显。
  - `sigils` / `insight` 的资源体系升级。
  - `CL2+` 与更完整后期挑战层体系。
  - 视觉、音频、长局 smoke 的成品化验收。

## 后续 Session 最应该复用的证据入口

- `test/unit/test_narrative_camp_flow.gd`
- `test/unit/test_narrative_payoff_flow.gd`
- `test/unit/test_hidden_layer_achievement_flow.gd`
- `test/unit/test_narrative_route_style_config.gd`
- `test/unit/test_room_pacing_profiles.gd`
- `spec-design/stage5-closure-2026-03-25.md`
- `spec-design/stage5-acceptance-record-2026-03-25.md`

## 给 Stage 6 的直接输入

- 可以默认 Stage 5 的叙事字段和 UI 出口已经稳定存在，不需要重复搭桥。
- `Stage 6` 应直接接着补：
  1. `CL1` 失败路径、`Sigil Bundle` / `Archive Insight` 分支与营地预览回显。
  2. `FS2` 与 `FS1` 对齐的最小可玩闭环与回归测试。
  3. `sigils` / `insight` 的资源定位与 `CL2+` schema 泛化。
