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

### 待完成部分

- [ ] Stage 5 正式收口文档、验收标准与「已完成/未完成边界」总结回写。
- [ ] 三路线、三结局、首次解锁/重复解锁差异的端到端验收记录（自动化结果 + 人工 walkthrough）仍需补齐。
- [ ] 叙事/营地/结局/隐藏层提示的统一验收摘要仍需整理，避免只分散在测试脚本与运行时文案中。

## B. Stage 6：隐藏层与后期系统

### 已完成/已启动部分

- [x] `FS1` / `FS2` 的解锁条件、状态归档、故事归档、成就与档案联动已接入 `SaveManager`、结算页、主菜单 Last Run、记忆祭坛与 Hidden Layer Track。
- [x] 隐藏层与主线结局、路线风格、碎片回看之间的关系，已通过 `hidden_layer_hook` / `hidden_layer_story` / `hidden_layer_statuses` 形成基础前台闭环。
- [x] `FS1` 已验证营地入口、最小房间推进、结算文案与档案回写的运行时闭环。
- [x] 后期挑战层已启动最小实现：`CL1` 已接入解锁链、安全营地预览、入口/战斗/结算三段流程、奖励选择、`SaveManager` 持久化，以及结算页/主菜单摘要。
- [x] `challenge_layer_record` 已持久化 `attempts`、`clears`、`best_rooms`、`best_kills`、`total_meta_bonus`、`total_sigils`、`total_insight`、`last_reward_title` 等字段，并在 UI 中展示 Archive Stats / Reward Ledger / Last Reward。

### 待完成部分

- [ ] `FS2` 仍需补齐与 `FS1` 同等级的可玩入口、房间/Boss/结算闭环与端到端回归。
- [ ] 隐藏层通关后的重复游玩动机、长期回流奖励、与主线/营地的二次承接仍需加强。
- [ ] `CL1` 仍缺失败路径语义、`Sigil Bundle` / `Archive Insight` 端到端分支覆盖、非 Meta 奖励后的营地预览回显，以及 `CL2+` 扩展所需的 schema 泛化。
- [ ] `sigils` / `insight` 目前仍主要是挑战层账本/UI 字段，是否升级为真实全局资源体系尚未定案。
- [ ] 图鉴系统。
- [ ] 成就扩展到完整版目标。
- [ ] 更完整的高难度/后期挑战层体系。
- [ ] 额外角色、额外武器、全武器进化路线补齐。
- [ ] 后期内容的解锁节奏、Meta 回流与长期目标设计。

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

### 推荐顺序 1：先收口 Stage 5

- Session 1：回写 Stage 5 正式收口文档，整理 `epilogue_branch / fragment_recap / hidden_layer_hook / hidden_layer_story / hidden_layer_statuses` 的已完成真值与剩余边界。
- Session 2：做三路线完整 run 验证，补齐首次解锁/重复解锁/结局差异的人机联合验收记录。
- Session 3：整理 Stage 5 统一验收摘要，沉淀为后续 Stage 6 的输入基线。

### 推荐顺序 2：再进入 Stage 6 深化

- Session 4：先补 `CL1` 失败路径、非 `Meta Cache` 奖励分支、Archive Ledger 回显与相关测试。
- Session 5：补 `FS2` 与 `FS1` 对齐的可玩路径/结算闭环，并做隐藏层双层联动回归。
- Session 6：决定 `sigils` / `insight` 是否升级为真实全局资源，再继续 `CL2+` 与后期挑战层扩展。
- Session 7：补隐藏层与主线结局、营地回流、档案/图鉴的更深联动。

### 推荐顺序 3：最后做 Stage 7 成品化

- Session 8：音频与关键 UI/结算表现替换。
- Session 9：完整主线 + 三结局 + 隐藏层 + 挑战层联合回归。
- Session 10：长局平衡、构筑深度、最终文档与验收清单收口。
