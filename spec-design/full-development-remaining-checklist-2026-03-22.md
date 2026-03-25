# 完整开发剩余内容清单（2026-03-22，已于 2026-03-24 按代码真值同步）

## A. Stage 5：叙事、营地与结局闭环

### 已完成部分

- [x] 路线弧线摘要。
- [x] 营地反思文本。
- [x] 章节转场叙事增强。
- [x] 三结局 payoff 数据与运行时接入。
- [x] 后记链路 `epilogue_chains`。
- [x] 碎片触发节奏 `fragment_trigger_profiles`。
- [x] 结算页基础展示（Payoff / Epilogue Chain / Fragments）。
- [x] `epilogue_branch_profiles` 已接入结算页、主菜单 Last Run 与 Ending Archive 回看入口。
- [x] `fragment_recap_profiles` 已接入结算页、主菜单 Last Run、记忆祭坛与回看入口。
- [x] `hidden_layer_hooks` 已接入营地/转场/结算页/主菜单，并形成可见的隐藏层前置提示。
- [x] `hidden_layer_story` / `hidden_layer_statuses` 已接入结算页、主菜单 Last Run、记忆祭坛与 Hidden Layer Track。
- [x] `chapter_transition_panel` 已补齐 route echo、forward note、hidden progress、fragment recap、camp loop、checkpoint/mainline/history recap，以及 `Chapter hazards ahead` / `Active chapter effects` / `Next route` 预测行。
- [x] Stage 5 相关专项测试已覆盖核心前台闭环：`test/unit/test_narrative_camp_flow.gd`、`test/unit/test_narrative_payoff_flow.gd`、`test/unit/test_hidden_layer_achievement_flow.gd`、`test/unit/test_room_pacing_profiles.gd`。
- [x] Stage 5 正式收口文档、验收记录与统一摘要已回写：`stage5-closure-2026-03-25.md`、`stage5-acceptance-record-2026-03-25.md`、`stage5-acceptance-summary-2026-03-25.md`。
- [x] 已新增三结局 + 首次/重复解锁分支差异回归测试：`test_save_manager_covers_all_endings_and_distinguishes_first_vs_repeat_unlocks()`。

### 待完成部分

- [x] Stage 5 正式收口文档、验收标准与「已完成/未完成边界」总结回写。
- [x] 三路线、三结局、首次解锁/重复解锁差异的端到端验收记录已补齐（自动化断言为主，视觉/音频 smoke 留待 Stage 7）。
- [x] 叙事/营地/结局/隐藏层提示的统一验收摘要已整理完成。

## B. Stage 6：隐藏层与后期系统

### 已完成/已启动部分

- [x] `FS1` / `FS2` 的解锁条件、状态归档、故事归档、成就与档案联动已接入 `SaveManager`、结算页、主菜单 Last Run、记忆祭坛与 Hidden Layer Track。
- [x] 隐藏层与主线结局、路线风格、碎片回看之间的关系，已通过 `hidden_layer_hook` / `hidden_layer_story` / `hidden_layer_statuses` 形成基础前台闭环。
- [x] `FS1` 已验证营地入口、最小房间推进、结算文案与档案回写的运行时闭环。
- [x] `FS2` 已验证营地入口、五段 Forge Trial -> Boss -> Settlement 的最小可玩闭环、结算奖励与档案回写；对应回归锁定在 `test/unit/test_narrative_camp_flow.gd`。
- [x] 后期挑战层已启动最小实现：`CL1` 已接入解锁链、安全营地预览、入口/战斗/结算三段流程、奖励选择、`SaveManager` 持久化，以及结算页/主菜单摘要。
- [x] 首个真实 `CL2` 已落地：`Archive Return` 解锁后可进入第二挑战层，具备安全营地预览、Entry -> Elite -> Boss -> Settlement 闭环、强化奖励档位与 Archive 回显。
- [x] 首个更深层 `CL3` 已落地：`CL2` 清档后可进入第三挑战层，具备 `O` 热键、安全营地预览、Entry -> Elite -> Combat -> Boss -> Settlement 闭环、第三档奖励与 Archive 回显。
- [x] 最终 `CL4` 已落地：`CL3` 清档后可进入第四挑战层，具备 `P` 热键、安全营地预览、Entry -> Elite -> Combat -> Elite -> Boss -> Settlement 闭环、第四档奖励与 Archive 回显。
- [x] 最终 Meta Return 已接入：`CL4` 清档后可解锁 `Apex Return`，将长期回流倍率补齐到 `Return x1.60`。
- [x] Stage 6 成就扩展已补齐：新增 `Archive Return`、`CL1`、`CL2`、`CL3`、`CL4` 五条成就，覆盖隐藏层复清与挑战层新闭环，并将主菜单成就分组扩到 `Challenge Layer`。
- [x] Stage 6 图鉴扩展已补齐：archive codex 新增 `Archive Return Protocol`、`Apex Return Protocol`、`Challenge Layer Archive`、`Crown Trial Archive`、`Sovereign Echo Archive`、`Apex Throne Archive`，并补齐 Meta Return / Challenge Layer detail 与 source label 展示。
- [x] `challenge_layer_record` 已持久化 `attempts`、`clears`、`best_rooms`、`best_kills`、`total_meta_bonus`、`total_sigils`、`total_insight`、`last_reward_title` 等字段，并在 UI 中展示 Archive Stats / Reward Ledger / Last Reward。
- [x] `CL1` 失败路径、`Sigil Bundle` / `Archive Insight` 奖励分支，以及非 Meta 奖励后的安全营地预览回显已补齐，并由 `test/unit/test_challenge_layer_flow.gd` 锁定。
- [x] `sigils` / `insight` 已明确继续作为挑战层账本/UI 字段，不升级为真实全局资源；`CL2+` 继续沿用 Archive Ledger 口径。
- [x] `SaveManager` 的 challenge schema 已完成 `CL2+` 基线泛化，并由 `test_save_manager_preserves_future_challenge_layer_records()` 锁定未来 challenge row 不会被清洗丢失。
- [x] 已补齐最小内容包：新增 `char_curator`、`wpn_reliquary_orb`、`evo_zenith_reliquary` / `wpn_zenith_reliquary`，并同步更新 `shop_items.json`、`resource_acceptance_targets.json` 与四类 `.tres` 资源桩。

### 待完成部分

- [x] 隐藏层通关后的重复游玩动机、长期回流奖励、与主线/营地的二次承接已补齐到 Stage 6 目标线（`Archive Return` + `Apex Return`）。
- [x] 图鉴系统已补齐到 Stage 6 目标线（archive codex 覆盖 `Archive Return` / `Apex Return` 与 `CL1/CL2/CL3/CL4`）。
- [x] 成就扩展已补齐到 Stage 6 目标线（隐藏层复清与 `CL1/CL2/CL3/CL4` 闭环全部入矩阵）。
- [x] 更完整的高难度/后期挑战层体系已补齐到 Stage 6 目标线（已扩到真实 `CL4` 并拉开层间差异）。
- [x] 额外角色、额外武器、全武器进化路线已补齐到 Stage 6 目标线。
- [x] 后期内容的解锁节奏、Meta 回流与长期目标设计已补齐到 Stage 6 目标线。

## C. Stage 7：成品表现与最终验收

### 表现层

- [ ] 音频资源从占位升级为正式内容。
- [ ] 关键角色、敌人、Boss、武器、UI 视觉资源替换。
- [ ] 首局引导、章节转场、结局反馈、隐藏层提示的表现强化。
- [ ] 营地、Boss、结算页的视觉与音频一致性收口。

### 质量与验收

- [ ] 主线完整通关回归。
- [ ] 三结局回归。
- [ ] 隐藏层回归。
- [ ] 长局平衡验证。
- [ ] 多轮构筑流派可玩性验证。
- [ ] 配置校验、资源检查、GUT、人工 smoke 全链路复核。

## 推荐新 Session 启动顺序

### 推荐顺序 1：先收口 Stage 5（已完成）

- Session 1：已完成，回写 Stage 5 正式收口文档，整理 `epilogue_branch / fragment_recap / hidden_layer_hook / hidden_layer_story / hidden_layer_statuses` 的已完成真值与剩余边界。
- Session 2：已完成，以自动化断言为主补齐三路线、三结局、首次解锁/重复解锁差异的验收记录。
- Session 3：已完成，整理 Stage 5 统一验收摘要，沉淀为后续 Stage 6 的输入基线。

### 推荐顺序 2：再进入 Stage 6 深化

- Session 4：已完成，补齐 `CL1` 失败路径、非 `Meta Cache` 奖励分支、Archive Ledger 回显与相关测试。
- Session 5：已完成，补 `FS2` 与 `FS1` 对齐的可玩路径/结算闭环，并由 `test/unit/test_narrative_camp_flow.gd` 锁定 Forge Trial -> Boss -> Settlement 回归。
- Session 6：已完成决策与基线泛化，`sigils` / `insight` 明确保留为账本/UI 字段，`SaveManager` challenge schema 已支持 `CL2+`；随后首个真实 `CL2` 与首个更深层 `CL3` 已补齐并锁定基础闭环。
- Session 7：已完成 Stage 6 收口，补齐 `CL4`、`Apex Return`、`CL4` 对应成就/图鉴，以及最小内容包 `char_curator` / `wpn_reliquary_orb` / `evo_zenith_reliquary`，Stage 6 自此转为 completed。

### 推荐顺序 3：最后做 Stage 7 成品化

- Session 8：音频与关键 UI/结算表现替换。
- Session 9：完整主线 + 三结局 + 隐藏层 + 挑战层联合回归。
- Session 10：长局平衡、构筑深度、最终文档与验收清单收口。
