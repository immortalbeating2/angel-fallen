# Stage 5 验收记录（2026-03-25）

## 结论

- 当前结论：`通过`。
- `Stage 5` 所要求的叙事、营地、结局、碎片回看与隐藏层前置提示闭环，已具备稳定的配置真值、运行时输出、落盘结果与前台展示。
- 本轮未单独做视觉/音频层面的人工点按 smoke；该部分继续归入 `Stage 7` 的成品化与最终验收，不阻塞 `Stage 5` 正式收口。

## 本次环境

- 提交基线：`2befea1`
- 验收时间：`2026-03-25T04:09:47+08:00`
- Godot 版本：`4.6.1.stable.official.14d19694e`
- 验收方式：以场景级 / 持久化级 GUT 断言为主，补充配置真值覆盖与前台出口检查。

## 自动化执行结果

| 项目 | 结果 | 备注 |
|---|---|---|
| `test/unit/test_narrative_camp_flow.gd` | 通过 | `4/4 passed`，`94` asserts |
| `test/unit/test_narrative_payoff_flow.gd` | 通过 | `7/7 passed`，`125` asserts |
| `test/unit/test_hidden_layer_achievement_flow.gd` | 通过 | `9/9 passed`，`198` asserts |
| `test/unit/test_room_pacing_profiles.gd` | 通过 | `5/5 passed`，`60` asserts |
| `test/unit/test_narrative_route_style_config.gd` | 通过 | `8/8 passed`，`427` asserts |

合计：`5` 个脚本、`33` 个测试、`904` 个断言，全部通过。

## 验收矩阵

| 验收项 | 覆盖证据 | 结果 | 说明 |
|---|---|---|---|
| 三路线弧线 `balance / redeem / fall` 存在并可被运行时消费 | `test_narrative_route_style_config.gd` 的 `test_route_arc_profiles_exist_for_all_alignment_outcomes`、`test_camp_reflections_cover_all_mainline_chapters_and_route_arcs` | 通过 | 覆盖路线弧线、营地反思与章节/触发维度完整性 |
| 三结局 `balance / fall / redeem` 均有 payoff 与 epilogue chain | `test_narrative_route_style_config.gd:124` | 通过 | 校验三结局 payoff 字段完整，且每条 epilogue chain 至少 3 段 |
| 三结局运行时解析正确 | `test_narrative_payoff_flow.gd` 的 `test_save_manager_covers_all_endings_and_distinguishes_first_vs_repeat_unlocks` | 通过 | 本轮新增回归测试，直接验证 `balance -> fall -> redeem -> redeem(repeat)` |
| 首次解锁 / 重复解锁分支差异存在且运行时可区分 | `test_narrative_route_style_config.gd:159`、`test_narrative_payoff_flow.gd` 的 `test_save_manager_persists_stage5_payoff_fields_on_victory` 与新回归测试 | 通过 | 配置层验证 `first_unlock` / `repeat_unlock` 非空，运行时验证 `branch_key` 正确切换 |
| 安全营地、章节转场可展示路线/碎片/隐藏层前置摘要 | `test_narrative_camp_flow.gd:68` | 通过 | 覆盖 camp text 与 transition panel 的 Stage 5 摘要文本 |
| 记忆祭坛可展示 fragment recap / hidden route / hidden layer track | `test_narrative_camp_flow.gd:154` | 通过 | 覆盖 Archive Recap、Hidden Route Lead、Hidden Layer Track |
| 结算页可展示 payoff / epilogue / recap / hidden-layer status | `test_narrative_payoff_flow.gd:289`、`test_narrative_payoff_flow.gd:389` | 通过 | 覆盖 EndingStory 与 Unlocks 两大区域 |
| 主菜单可展示最近结局顺序、碎片时间线、Last Run 摘要 | `test_hidden_layer_achievement_flow.gd:278`、`test_hidden_layer_achievement_flow.gd:335`、`test_hidden_layer_achievement_flow.gd:569` | 通过 | 覆盖 Ending Archive、Memory Archive、Recent metadata、Last Run |
| 隐藏层前置钩子/故事/状态前台闭环成立 | `test_narrative_camp_flow.gd:236`、`test_narrative_payoff_flow.gd:209`、`test_hidden_layer_achievement_flow.gd:22` | 通过 | 覆盖 `hidden_layer_hook`、`hidden_layer_story`、`hidden_layer_statuses` |

## 三结局与首通/复通差异记录

| 轮次 | alignment / route_style | 期望结局 | 期望分支 | 结果 |
|---|---|---|---|---|
| Run 1 | `0.0 / neutral` | `nar_ending_balance` | `first_unlock` | 通过 |
| Run 2 | `-72.0 / rebel` | `nar_ending_fall` | `first_unlock` | 通过 |
| Run 3 | `72.0 / vanguard` | `nar_ending_redeem` | `first_unlock` | 通过 |
| Run 4 | `72.0 / vanguard` | `nar_ending_redeem` | `repeat_unlock` | 通过 |

补充结论：重复完成 `redeem` 不会重复制造新的 ending unlock 条目；meta 中最终只保留 `3` 个唯一结局解锁。

## 人工 walkthrough 等价说明

- 本轮没有单独执行“从主菜单手动一路点到结算页”的长链路录像式 walkthrough。
- 取而代之的是：
  - 场景级 UI 断言覆盖安全营地、章节转场、记忆祭坛、结算页、主菜单。
  - 持久化级断言覆盖 `SaveManager` 落盘字段与 archive 顺序。
  - 配置真值断言覆盖三路线、三结局、首通/复通 profile 完整性。
- 对 `Stage 5` 的收口判断，以这些“可重复、可回归、可定位”的自动化断言为准；视觉与音频体感 smoke 留待 `Stage 7`。

## 遗留项说明

- `FS2` 最小可玩闭环、`CL1` 失败路径与替代奖励分支不属于本次 `Stage 5` 验收范围。
- `sigils` / `insight` 是否升级为真实全局资源，也不属于 `Stage 5` 验收项。
