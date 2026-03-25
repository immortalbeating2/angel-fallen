# 完整版内容完工总计划（2026-03-22）

## 目标

- 将项目目标从“先完成 MVP 发布”切换为“先完成完整版内容，形成真正完整可玩的成品”。
- 完整版范围按 `spec-design/level-design.md`、`spec-design/requirements.md`、`spec-design/core-systems.md` 为内容真值，按 `spec-design/roadmap.md` 的 `MVP + v1.1 + v1.2 + v1.3` 总量推进。
- 执行策略采用“完整版目标、主线优先、扩展后置”：先打通完整主线，再补隐藏层与后期内容，最后做表现与发布收口。

## 完整版完成线

### 第一完成线：完整主线成品

- `F1-F13` 主线完整可玩。
- `4` 个主线 Boss 全部具备独立阶段、技能与演出。
- `3` 条结局（救赎 / 堕落 / 平衡）全部可达成。
- 章节转场、路线系统、安全营地、记忆碎片主链完整闭环。

### 第二完成线：完整版内容

- 隐藏层 `FS1`、`FS2` 可解锁并通关。
- 角色扩展到完整版目标，路线图中的后续角色、武器、进化、饰品、图鉴、成就、高难度全部补齐。
- 音频、视觉、引导、长局测试达到“完整游戏”标准，而不是只保留骨架闭环。

## 当前实现判断

- 当前仓库已具备：主菜单 -> 角色选择 -> 开局 -> 房间推进 -> 商店/事件/Boss -> 结算落盘的基础可玩链路。
- 当前已不止基础可玩链路：Stage 5 的叙事/营地/结局前台闭环已基本落地，隐藏层档案/状态体系、`FS1` 最小闭环，以及 `CL1` 挑战层最小闭环也已进入代码与测试真值。
- 当前主要缺口不是“无法运行”，而是“隐藏层/挑战层尚未扩成完整版体量、长期动机与资源体系尚未完全兑现、表现层仍偏占位”。
- 最先要补的不是重新搭骨架，而是基于现有真值继续完成 Stage 5 正式收口、Stage 6 深化与 Stage 7 成品化。

## 执行原则

1. 先修内容链断裂，再扩章节内容；避免在断裂数据上继续堆新功能。
2. 先做主线成品，再补隐藏层和后期扩展；避免主线未闭环时扩散范围。
3. 先保证每一章都有独立敌人/Boss/环境/叙事手感，再做额外收藏与系统装饰。
4. 每完成一轮内容扩张，都补对应测试与配置校验，避免内容回归失控。

## 顺序执行计划

### 阶段 1：内容基线对齐

目标：修正当前“已经承诺但数据不一致”的基础内容，给后续完整版扩张建立稳定底板。

包含事项：
- 角色解锁链与成就表对齐。
- 记忆碎片数量与索引目标对齐到 `33`。
- 关键配置中的显性断裂项先清零。
- 为这些基线补充单元测试。

完成标准：
- 角色解锁不再引用不存在的 achievement id。
- `narrative_index.json` 中的 `memory_fragments.total` 与 `narrative_content.json` 实际条目一致。
- 对应校验与 GUT 测试通过。

### 阶段 2：完整主线章节与环境

目标：把主线从当前骨架扩到 `F1-F13` 的完整章节体验。

包含事项：
- 第三章、第四章完整房间节奏与章节规则。
- 冻伤、极光、暴风雪、冰晶折射、虚空腐蚀、空间扭曲等环境机制兑现。
- 地图/房间池从“泛化战斗房”提升为章节化房间体验。

完成标准：
- 四章主线都有明确差异化的环境压力与房间体验。
- 可从开局连续推进到 `F13`，且章节差异明确可感知。

### 阶段 3：Boss 与敌群成品化

目标：让四章 Boss 和敌群从“参数变化”升级为“战斗记忆点”。

包含事项：
- `寒霜君王`、`虚空之主` 完整实现。
- 已有 Boss 重做为独立技能/阶段/机制战。
- Mini-Boss 与章节敌群协同补齐。

完成标准：
- 四个主线 Boss 都具备清晰阶段差异与独特压力。
- 敌群与章节环境有明显联动，而不是单纯数值上升。

### 阶段 4：构筑、经济与成长深度

目标：把局内 build 从“可升级”扩到“有明显流派”。

包含事项：
- 完整 6 类基础武器与后续扩展武器接入。
- 被动、进化、饰品、商店、锻造、Boss 掉落联动。
- 角色差异、解锁节奏、Meta 与局内成长深度同步增强。

完成标准：
- 至少 6 角色 / 6 基础武器 / 完整进化链在实战中可形成可区分流派。
- 锻造不再只是临时按钮，而是实际系统。

### 阶段 5：叙事、营地与结局闭环

目标：把“能播的叙事”升级为“完整故事体验”。

包含事项：
- 三段章节过渡与路线追踪深化。
- `33` 个记忆碎片完整兑现。
- 安全营地功能层做满：商店、锻造、碎片解读、剧情推进、下一章预告。
- 三结局与后记、隐藏层解锁条件补齐。

完成标准：
- 玩家能明确感受到路线选择、章节推进、结局分化与长期目标回流。

### 阶段 6：隐藏层与后期系统

目标：补齐完整版相对主线版新增的高阶内容。

包含事项：
- `FS1`、`FS2` 隐藏层。
- 后期挑战层体系（当前已有 `CL1` 最小闭环）。
- 图鉴、成就、高难度。
- 额外角色、额外武器、全武器进化路线。

完成标准：
- 主线通关后仍有明确的后期目标与重复游玩动机。

### 阶段 7：成品表现与最终验收

目标：把“系统完整”推进到“像完整游戏”。

包含事项：
- 音频内容与播放链接入。
- 关键角色/敌人/Boss/武器/UI 占位资源替换。
- 首局引导、完整通关回归、结局回归、长局平衡验证。

完成标准：
- 不只是能通关，而是具备成品表现、成品反馈和成品级回归保障。

## 当前顺序与执行状态

| 顺位 | 任务 | 状态 | 说明 |
|---|---|---|---|
| 1 | 内容基线对齐 | completed | 已修复 achievement 解锁链、补齐 33 条记忆碎片，并补充测试护栏 |
| 2 | 主线章节与环境补完 | completed | 第一至四批已落地：四章 room_profiles、新环境机制、章节房间节奏、推进事件/历史节奏、主线节点表达与历史回看摘要 |
| 3 | Boss 与敌群成品化 | completed | 第一至三批已落地：阶段技能差异、阶段转折压制、Mini-Boss协同与演出节奏/强度曲线收口 |
| 4 | 构筑与成长深度 | completed | 第一至四批已落地：流派锚点、锻造配方化、饰品/Boss掉落联动、跨章节收益曲线与长局平衡首轮收口 |
| 5 | 叙事、营地与结局闭环 | completed | 已完成正式收口文档、验收记录与统一摘要回写；结算页 / 主菜单 / 记忆祭坛 / 转场已形成稳定前台闭环 |
| 6 | 隐藏层与后期系统 | completed | 已落地 `FS1/FS2` 解锁与档案状态基础、`FS1/FS2` 最小可玩闭环、`CL1` 挑战层最小闭环、`CL1` 失败/替代奖励分支与营地回显、真实 `CL2/CL3/CL4` 挑战层闭环、`CL2+` challenge schema 基线、隐藏层重复清档的 `Archive Return` 与最终 `Apex Return` Meta Return 链、覆盖隐藏层复清与 `CL1/CL2/CL3/CL4` 的成就扩展、覆盖 `Archive Return` / `Apex Return` / `CL1` / `CL2` / `CL3` / `CL4` 的 archive codex 扩展，以及 `char_curator` / `wpn_reliquary_orb` / `evo_zenith_reliquary` 的最小内容包 |
| 7 | 成品表现与最终验收 | pending | 音频、视觉替换、通关回归 |

## 本轮执行记录

- 本文档创建后，立即按顺序执行第 1 项：`内容基线对齐`。
- 本轮已完成：
  - 补齐 `ach_guardian_200`、`ach_vanguard_300`，修复角色 achievement 解锁链缺失。
  - 将 `narrative_content.json` 的记忆碎片补齐到 `33` 条，与 `narrative_index.json` 对齐。
  - 在 `test/unit/test_content_depth_targets.gd` 中补充 achievement 对齐断言与 `33` 条记忆碎片护栏。
  - 已通过 JSON 语法、配置校验、资源检查与 Godot unit tests。
- 当前已推进第 2 项第一批：
  - 在 `environment_config.json` 为四章补齐 `room_profiles`，让 `combat / elite / boss / safe_camp` 等房型拥有独立 hazard 与 visual override。
  - 在 `game_world.gd` 中接入 room-profile 驱动的 hazard 组合、visual profile merge 与 hazard pressure。
  - 为 `chapter_3` / `chapter_4` 新增简化但可感知的 `blizzard`、`crystal_reflection`、`spatial_distortion` 环境机制。
  - 在 `validate_configs.py` 补齐 `room_profiles` / `hazard_pressure` / `visual_profile_overrides` schema 护栏。
  - 在 `test/unit/test_visual_tilemap_layers.gd` 增加房型 hazard 差异和新环境机制状态影响测试。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py` 与 Godot unit tests（`49/49 passed`）。
- 当前已推进第 2 项第二批：
  - 在 `map_generation.json` 新增四章 `chapter_room_profiles`，为 `combat / elite / boss / event / treasure / shop / safe_camp` 定义章节化 `title / objective / route_tag / status_hint / required_kills_mult / reward_mult`。
  - 在 `game_world.gd` 中接入章节房间节奏 profile，让 combat / elite / treasure challenge 的 required kills 与奖励倍率按章节变化，并让 room status、safe camp、shop、boss、route brief 体现章节化标签。
  - 在 `test/unit/test_map_generation_config.gd` 补 `chapter_room_profiles` schema 与 late-chapter pacing 断言。
  - 新增 `test/unit/test_room_pacing_profiles.gd`，覆盖 route brief、required kills 缩放、treasure reward multiplier，以及 chapter_3 camp/boss 章节化文本。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py` 与 Godot unit tests（`51/51 passed`）。
- 当前已推进第 2 项第三批：
  - 在 `map_generation.json` 新增四章 `chapter_progression_profiles`，落地 `clear_banner / transition_intro / transition_resolved / event_resolved / camp_recovery_note / checkpoint_label / history_pace_tags`。
  - 在 `game_world.gd` 接入章节推进文案与房间历史节奏：非 boss clear 文案、transition 开始/结束文案、event 结束文案、camp recovery note、history pace/checkpoint 记录。
  - 在 `validate_configs.py` 增加 `chapter_progression_profiles` schema 护栏（字段完整性、长度限制、七房型 pace tags）。
  - 在 `test/unit/test_map_generation_config.gd` 与 `test/unit/test_room_pacing_profiles.gd` 增加第三批断言，覆盖 progression profile 结构和 clear/transition/event/room_history 行为。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py` 与 Godot unit tests（`53/53 passed`）。
- 当前已推进第 2 项第四批（阶段 2 收口）：
  - 在 `map_generation.json` 的四章 `chapter_progression_profiles` 增加 `history_recap_prefix / history_recap_limit / mainline_nodes`，补齐主线节点标签和章节历史回看模板。
  - 在 `game_world.gd` 接入第四批运行时表达：
    - `room_history` 记录 `mainline_node`
    - clear / transition / event / shop / camp 文案追加 `Mainline` 与章节 history recap
    - 新增 `_get_chapter_history_recap_prefix`、`_get_chapter_history_recap_limit`、`_get_chapter_mainline_node`、`_build_chapter_history_recap`。
  - 在 `validate_configs.py` 扩展 `chapter_progression_profiles` 校验，新增 `history_recap_prefix`、`history_recap_limit`、`mainline_nodes` 的非空、类型与长度/范围护栏。
  - 在 `test/unit/test_map_generation_config.gd` 补第四批 schema 断言；在 `test/unit/test_room_pacing_profiles.gd` 补第四批行为断言（Mainline 文案、history recap 前缀/窗口、`mainline_node` 落盘）。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py` 与 Godot unit tests（`54/54 passed`）。
- 当前已推进第 3 项第一批：
  - 在 `scripts/game/enemy.gd` 为 `boss_frost_king`、`boss_void_lord` 增加阶段差异技能（寒霜碎裂冲击 / 虚空引力井），并按阶段调整冷却与额外伤害反馈。
  - 在 `scripts/systems/enemy_spawner.gd` 新增 Boss 协同召唤链路：根据 Boss 当前 phase 在阈值转折时触发一次性支援波次，并按 Frost/Void 章节映射不同 archetype 组合。
  - 修复支援存活统计误计对象池预热节点的问题（`_get_boss_support_alive_count` 过滤 `ObjectPool` 父节点），避免错误触发 alive limit 阻断召唤。
  - 在 `scripts/game/enemy.gd` 暴露 `get_phase_index()`，并在 `test/unit/test_boss_phase_mechanics.gd` 增补阶段驱动与协同召唤行为测试。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`57/57 passed`）。
- 当前已推进第 3 项第二批：
  - 在 `scripts/game/enemy.gd` 增加 Boss 阶段转折压制（phase transition pressure），在阶段切换时触发 burst 伤害与方向性击退/拉扯反馈，且 Frost/Void 方向与强度差异化。
  - 在 `scripts/systems/enemy_spawner.gd` 增强 Boss 协同召唤波次：phase 2+ 引入 `miniboss_frost_warden`，void late phase 引入 `miniboss_void_harbinger`，并对 mini-boss 支援附加独立强度系数。
  - 在 `test/unit/test_boss_phase_mechanics.gd` 新增并扩展第二批行为测试，覆盖阶段转折压制向量差异与 mini-boss 支援波次出现条件。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`58/58 passed`）。
- 当前已推进第 3 项第三批（阶段 3 收口）：
  - 在 `scripts/autoload/audio_manager.gd` 增加 Boss 演出占位音频联动与快照接口：`play_boss_phase_cue`、`play_boss_support_cue`、`get_last_boss_phase_cue_snapshot`、`get_last_boss_support_cue_snapshot`。
  - 在 `scripts/game/enemy.gd` 接入阶段转折音频 cue，并新增 `play_boss_support_stage_cue` 作为支援波次视觉脉冲演出。
  - 在 `scripts/systems/enemy_spawner.gd` 增加跨章 Boss 支援强度曲线：`_build_boss_support_curve`、`get_boss_support_curve_snapshot`、`get_last_boss_support_snapshot`，并将支援波次结果升级为包含 `curve/includes_miniboss` 的快照。
  - 新增 `test/unit/test_boss_phase_showcase_curve.gd`，覆盖 Boss 阶段/支援 cue 快照与跨章曲线强度对比（Void 晚期 mini-boss > Frost）。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`60/60 passed`）。
- 当前已推进第 4 项第一批：
  - 在 `scripts/systems/level_up_system.gd` 新增构筑锚点体系：`offense/tempo/precision/survival/economy`，并接入被动升级、商店购买、锻造行为的锚点增量入口。
  - 将进化候选从“纯随机挑选”升级为“锚点权重驱动”的首轮联动：`_pick_weighted_evolution_option` + `get_evolution_anchor_weight`，使被动进度与构筑倾向可影响进化曝光概率。
  - 在 `scripts/game/game_world.gd` 接入 `LevelUpSystem` 联动，`_apply_shop_item_effect`、`_try_forge_damage`、`_try_forge_speed` 成功路径会回灌锚点事件。
  - 新增 `test/unit/test_build_anchor_links.gd`，覆盖锚点累积、进化权重偏好、GameWorld -> LevelUpSystem 通知链路。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`63/63 passed`）。
- 当前已推进第 4 项第二批：
  - 在 `data/balance/shop_items.json` 新增 `forge_recipes`（`damage` / `speed`），将锻造成本、效果、锚点与成功文案参数化。
  - 在 `scripts/game/game_world.gd` 接入锻造配方执行链路：`_forge_recipes`、`_default_forge_recipes`、`_sanitize_forge_recipes`、`_try_forge_recipe`，并让 camp UI 动态显示配方 ore cost。
  - 保留原快捷键（F/G）的同时，将执行逻辑切换为数据驱动配方；锻造成功时按配方回灌构筑锚点（`anchor` + `anchor_amount`）。
  - 在 `scripts/validate_configs.py` 扩展 `shop_items.forge_recipes` schema 护栏（required recipes、效果字段范围、anchor/文案约束）。
  - 在 `test/unit/test_shop_economy_config.gd` 与 `test/unit/test_build_anchor_links.gd` 补第二批断言，覆盖配方字段范围与数据驱动 cost/message 行为。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`65/65 passed`）。
- 当前已推进第 4 项第三批：
  - 在 `scripts/game/game_world.gd` 增加章节 Boss 饰品联动：`CHAPTER_BOSS_ACCESSORY`、`_boss_accessory_claimed`，并在 boss clear 分支触发 `_grant_boss_stage_accessory(chapter_id)`。
  - 将饰品授予流程统一为 `_grant_specific_accessory(...)`，支持随机掉落、指定拾取 ID（`acc_*`）与 Boss 清房奖励共用同一套逻辑。
  - 新增 `ACCESSORY_ANCHOR_BONUS` 与 `_apply_accessory_anchor_bonus(...)`，饰品装备后按配置回灌构筑锚点（precision/offense/survival 等）。
  - `test/unit/test_build_anchor_links.gd` 补第三批行为断言，覆盖 Boss 章节饰品“只发放一次”、饰品锚点来源标记、`acc_*` 拾取直授链路。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`67/67 passed`）。
- 当前已推进第 4 项第四批（阶段 4 收口）：
  - 在 `data/balance/drop_tables.json` 新增 `chapter_reward_profiles` 与 `long_run_room_curve`，为四章 XP/金币/矿石/宝藏收益定义跨章节曲线与长局房间倍率。
  - 在 `scripts/game/game_world.gd` 接入 `_get_reward_curve_profile`、`_get_long_run_room_curve`、`_get_reward_curve_multiplier`、`_get_long_run_reward_bonus`、`_scale_reward_amount`，让 XP 宝石、金币/矿石掉落与 treasure reward 随章节与房间深度增长。
  - 在 `scripts/validate_configs.py` 扩展 `drop_tables.json` 校验，新增 `chapter_reward_profiles` 与 `long_run_room_curve` 的范围与结构护栏。
  - 新增 `test/unit/test_reward_curve_profiles.gd`，覆盖章节奖励曲线结构、late chapter XP/矿石成长，以及 late-run treasure 金币/矿石倍率。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`70/70 passed`）。
- 当前已推进第 5 项第一批：
  - 在 `data/balance/narrative_content.json` 新增 `route_arc_profiles` 与 `camp_reflections`，为 `balance / redeem / fall` 路线弧线与四章营地反思补齐文本基础。
  - 在 `scripts/systems/narrative_system.gd` 新增 `get_route_arc_summary`、`get_camp_reflection`、`get_recent_choice_summary` 等 helper，把 alignment / route_style / unlocked fragments / recent choices 汇聚为可直接消费的叙事摘要。
  - 在 `scripts/game/game_world.gd` 的 camp、memory altar、chapter transition 流程接入 Route arc / Fragment progress / Camp reflection / Recent vows 文本，增强营地中场与章节过渡的叙事连续性。
  - 在 `scripts/ui/chapter_transition_panel.gd` 扩展 `show_transition(...)` 参数，使章节过渡面板能够展示路线弧线、碎片进度与最近选择摘要。
  - 在 `scripts/validate_configs.py` 扩展 `narrative_content.json` 护栏，新增 `route_arc_profiles` 与 `camp_reflections` 的结构与非空校验。
  - 新增 `test/unit/test_narrative_camp_flow.gd`，并扩展 `test/unit/test_narrative_route_style_config.gd`，覆盖路线弧线、营地反思、camp text 与 transition summary 行为。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`74/74 passed`）。
- 当前已推进第 5 项第二批：
  - 在 `data/balance/narrative_content.json` 新增 `ending_payoff_profiles`、`epilogue_chains`、`fragment_trigger_profiles`，为三结局路线兑现、后记链路与章节碎片触发节奏提供数据来源。
  - 在 `scripts/systems/narrative_system.gd` 新增 `get_ending_payoff`、`get_epilogue_chain`、`get_fragment_trigger_payload`，将 alignment / route_style / chapter / trigger type 聚合为运行时可消费的结局与碎片 payload。
  - 在 `scripts/autoload/save_manager.gd` 扩展 run result 持久化，记录 `route_style`、`ending_payoff`、`ending_epilogue_chain`、`fragment_triggers`，使结局兑现与后记链路能随 run 一起保存。
  - 在 `scripts/game/game_world.gd` 接入 `camp` / `event` / `transition` 的碎片触发节奏，并让 memory altar 与 run result 能读取最新触发结果。
  - 在 `scripts/ui/run_result_panel.gd` 增强结算页，展示 `Payoff`、`Epilogue Chain` 与 `Fragments` 列表，形成三结局兑现后的可视化后记链路。
  - 在 `scripts/validate_configs.py` 扩展 `narrative_content.json` 护栏，新增 `ending_payoff_profiles`、`epilogue_chains`、`fragment_trigger_profiles` 的结构与非空校验。
  - 新增 `test/unit/test_narrative_payoff_flow.gd`，并扩展 `test/unit/test_narrative_route_style_config.gd`，覆盖 SaveManager payoff 持久化、GameWorld pacing fragment、RunResultPanel 展示，以及新 narrative config section 的结构断言。
  - 已通过 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py`、`python -m py_compile scripts/validate_configs.py scripts/check_resources.py` 与 Godot unit tests（`78/78 passed`）。
- 当前已推进第 5 项第三批（前台闭环基本完成）：
  - 在叙事数据、`NarrativeSystem`、`SaveManager`、`game_world.gd`、`run_result_panel.gd`、`main_menu.gd`、`chapter_transition_panel.gd` 与记忆祭坛链路中接入 `epilogue_branch_profiles`、`fragment_recap_profiles`、`hidden_layer_hooks`、`hidden_layer_story_profiles` 与 `hidden_layer_statuses`。
  - 将 `fragment_recap`、`hidden_layer_hook`、`hidden_layer_story`、`hidden_layer_statuses`、`ending_payoff`、`ending_epilogue`、`epilogue_branch`、`ending_epilogue_chain` 同步到结算页、主菜单 Last Run、Ending Archive / Hidden Layer Track / Memory Altar 等前台入口。
  - `chapter_transition_panel.gd` 已补齐 route echo、forward note、hidden progress、fragment recap、camp loop、checkpoint/mainline/history recap，以及 `Chapter hazards ahead`、`Active chapter effects`、`Next route` 预测行。
  - 相关测试已扩至 `test/unit/test_narrative_camp_flow.gd`、`test/unit/test_narrative_payoff_flow.gd`、`test/unit/test_hidden_layer_achievement_flow.gd`、`test/unit/test_room_pacing_profiles.gd`。
- 当前已推进第 6 项第一批：
  - `FS1/FS2` 的解锁、状态归档、故事归档、成就/档案/Meta Return 联动已接入 `SaveManager`、结算页、主菜单 Last Run、记忆祭坛与 Hidden Layer Track。
  - `FS1` 已验证营地入口、最小房间推进、结算文案与档案回写的运行时闭环；`FS2` 已具备解锁与档案状态基线。
- 当前已推进第 6 项第二批：
  - 新增 `CL1` 挑战层最小闭环：通过 Meta Return 链解锁，安全营地预览 -> 入口 staging -> 战斗环 -> 结算营地 -> 奖励选择 -> `SaveManager` 落盘 -> 结算页/主菜单 Challenge 摘要。
  - `challenge_layer_record` 已持久化 `attempts`、`clears`、`best_rooms`、`best_kills`、`total_meta_bonus`、`total_sigils`、`total_insight`、`last_reward_title` 等字段，并在 UI 中展示 Reward Ledger / Archive Stats / Last Reward。
- 当前已推进第 6 项第三批：
  - 在 `scripts/game/game_world.gd` 补齐 `CL1` 失败结算语义：失败时不再伪造 reward / settlement 数据，而是明确记录 `archived without payout` 与失败房间标题。
  - 将挑战层 reward summary 调整为基于实际已选奖励生成，使 `Sigil Bundle` / `Archive Insight` 分支在结算营地、结算页与主菜单 Last Run 中回显真实选择，而不再沿用默认 `Meta +40` 摘要。
  - 在 `test/unit/test_challenge_layer_flow.gd` 新增失败路径、`Sigil Bundle` 分支、`Archive Insight` 分支与安全营地预览回显测试；并补跑 `test/unit/test_hidden_layer_achievement_flow.gd` 确认摘要 UI 未回归。
  - 本轮已通过 `test/unit/test_challenge_layer_flow.gd`（`5/5 passed`, `205` asserts）与 `test/unit/test_hidden_layer_achievement_flow.gd`（`9/9 passed`, `198` asserts），合计 `14` tests / `403` asserts / all passed。
- 当前已推进第 6 项第四批：
  - 在 `test/unit/test_narrative_camp_flow.gd` 新增 `test_safe_camp_can_enter_fs2_and_finish_forge_settlement_loop()`，锁定 `FS2` 从安全营地入口、五段 Forge Trial、Boss 到 Settlement 的最小可玩闭环。
  - `FS2` 运行时结算已由真实 `GameWorld` payload 回写 `SaveManager`，并验证 `recipe_drafts=3`、`relic_merges=2`、`trial_labels=5`、`deepest_trial_label=Forge Trial V: Genesis Core` 等关键档案字段。
  - 本轮已通过 `test/unit/test_narrative_camp_flow.gd`（`5/5 passed`, `158` asserts），确认 `FS2` 已从“只有解锁/档案状态”升级为“具备对齐的最小可玩基线”。
- 当前已推进第 6 项第五批：
  - 在 `scripts/autoload/save_manager.gd` 泛化 `_sanitize_challenge_layer_records(...)`，不再只保留 `CL1`，从而为 `CL2+` 保留 challenge record row 与后续展示扩展入口。
  - 在 `test/unit/test_challenge_layer_flow.gd` 新增 `test_save_manager_preserves_future_challenge_layer_records()`，直接锁定未来 `CL2+` challenge record 不会在 sanitize 过程中丢失。
  - 同时明确 Stage 6 当前资源策略：`sigils` / `insight` 继续停留在挑战层 Archive Ledger / UI 字段，不升级为真实全局资源，以避免过早耦合主 Meta 经济与多系统消费链路。
  - 本轮已通过 `test/unit/test_challenge_layer_flow.gd`（`6/6 passed`, `215` asserts），确认 `CL2+` schema 基线与资源口径已稳定。
- 当前已推进第 6 项第六批：
  - 在 `scripts/autoload/save_manager.gd` 为 Meta Return 新增 `Archive Return` 里程碑：当 `FS1` 与 `FS2` 都已封档，且隐藏层总清档次数达到 `3` 次时，再给一次 `+10% Meta` 的长期回流奖励。
  - 在 `scripts/game/game_world.gd` 的隐藏层 settlement 文案中接入 `Meta Return` 当前倍率与下一条提示，让玩家在 `FS1/FS2` 结算出口直接看到重复清档仍有回流价值。
  - 在 `test/unit/test_meta_return_progression.gd` 扩展回归，锁定“首通双档案 + 一次重复清档 -> 解锁 `Archive Return` -> 总倍率到 `x1.50`”的完整链路；并补跑 `test/unit/test_meta_shop_progression.gd`、`test/unit/test_narrative_camp_flow.gd`。
  - 本轮已通过 `test/unit/test_meta_return_progression.gd`（`1/1 passed`, `32` asserts）、`test/unit/test_meta_shop_progression.gd`（`1/1 passed`, `27` asserts）与 `test/unit/test_narrative_camp_flow.gd`（`5/5 passed`, `158` asserts），合计 `7` tests / `217` asserts / all passed。
- 当前已推进第 6 项第七批：
  - 在 `scripts/autoload/save_manager.gd` 新增 `CHALLENGE_LAYER_CL2` 常量与 `camp_challenge_layer_2` 输入绑定（`I`），并让 `archive_meta_return` 成为第二挑战层的解锁门槛。
  - 在 `scripts/systems/map_generator.gd` 新增首个真实 `CL2` 运行时计划：`Entry -> Elite -> Boss -> Settlement` 四段链路，含独立 `Archive Crucible` / `Crown Trial` / `Challenge Layer II Settlement` 文案与更高档奖励预览。
  - 在 `scripts/game/game_world.gd` 接入 `CL2` 营地预览、动态 entry prompt、第二挑战层奖励档位（`Deep Meta Cache` / `Sigil Crate` / `Insight Bundle`）与结算回显。
  - 在 `test/unit/test_challenge_layer_flow.gd` 新增 `test_safe_camp_can_enter_challenge_layer_two_and_finish_boss_settlement_loop()`，并在 `test/unit/test_map_generation_config.gd` 新增 `CL1/CL2` challenge runtime plan 断言。
  - 本轮已通过 `test/unit/test_challenge_layer_flow.gd`（`7/7 passed`, `274` asserts）、`test/unit/test_map_generation_config.gd`（`6/6 passed`, `708` asserts）与 `test/unit/test_meta_return_progression.gd`（`1/1 passed`, `32` asserts），合计 `14` tests / `1014` asserts / all passed。
- 当前已推进第 6 项第八批：
  - 在 `data/balance/achievements.json` 新增 `Archive Return`、`Archive Initiate`、`Crown Archivist` 三条 Stage 6 成就，分别覆盖隐藏层复清回流、`CL1` 首通与 `CL2` 首通。
  - 在 `scripts/autoload/save_manager.gd` 扩展成就条件判定，新增 `hidden_layer_repeat_archive_return`、`challenge_layer_clear_cl1`、`challenge_layer_clear_cl2` 三类条件，无需引入额外全局状态即可基于现有隐藏层/挑战层结果落盘解锁。
  - 在 `scripts/ui/main_menu.gd` 将成就分组从 `Run / Hidden Layer / Difficulty` 扩展为 `Run / Hidden Layer / Difficulty / Challenge Layer`，让 Stage 6 新成就不会混入 Run 分类。
  - 在 `test/unit/test_hidden_layer_achievement_flow.gd` 新增 `test_archive_return_and_challenge_layer_clears_expand_achievement_groups()`，并同步更新现有进度/分组断言；同时补跑 `test/unit/test_content_depth_targets.gd` 与 `test/unit/test_challenge_layer_flow.gd`。
  - 本轮已通过 `test/unit/test_hidden_layer_achievement_flow.gd`（`10/10 passed`, `223` asserts）、`test/unit/test_content_depth_targets.gd`（`5/5 passed`, `56` asserts）与 `test/unit/test_challenge_layer_flow.gd`（`7/7 passed`, `274` asserts），合计 `22` tests / `553` asserts / all passed。
- 当前已推进第 6 项第九批：
  - 在 `scripts/autoload/save_manager.gd` 新增 Stage 6 archive codex 解锁链路：`archive_return_protocol`、`cl1_challenge_archive`、`cl2_crown_archive`。
  - 在 `scripts/ui/main_menu.gd` 的 `ARCHIVE_CODEX_ENTRIES` 新增上述三条条目，并补齐 Meta Return / Challenge Layer detail 页面与 `Meta Return Unlock` / `Challenge Layer Clear` source label。
  - 在 `test/unit/test_codex_archive_flow.gd` 更新 archive catalog 断言，并新增 `test_archive_return_and_challenge_layers_unlock_codex_entries_and_show_archive_details()` 回归，覆盖新条目解锁、catalog 展示、detail 页面与 source 文案。
  - 本轮已通过 `test/unit/test_codex_archive_flow.gd`（`4/4 passed`, `106` asserts）、`test/unit/test_meta_return_progression.gd`（`1/1 passed`, `32` asserts）与 `test/unit/test_challenge_layer_flow.gd`（`7/7 passed`, `274` asserts），合计 `12` tests / `412` asserts / all passed。
- 当前已推进第 6 项第十批：
  - 在 `scripts/autoload/save_manager.gd` 新增 `CHALLENGE_LAYER_CL3` 常量与 `camp_challenge_layer_3` 输入绑定（`O`），为更深层挑战层提供独立营地入口。
  - 在 `scripts/game/game_world.gd` 接入 `CL3` 解锁链路（`CL2` 清档后开放）、第三挑战层热键、第三档奖励（`Sovereign Meta Cache` / `Sigil Matrix` / `Insight Reliquary`）与结算回显。
  - 在 `scripts/systems/map_generator.gd` 新增首个真实 `CL3` 运行时计划：`Entry -> Elite -> Combat -> Boss -> Settlement` 五段链路，含独立 `Null Gauntlet` / `Archive Breach` / `Sovereign Echo` / `Challenge Layer III Settlement` 文案与更高档奖励预览。
  - 在 `test/unit/test_challenge_layer_flow.gd` 新增 `test_safe_camp_can_enter_challenge_layer_three_and_finish_sovereign_settlement_loop()`，并在 `test/unit/test_map_generation_config.gd` 将 challenge runtime plan 断言扩到 `CL1/CL2/CL3`。
  - 本轮已通过 `test/unit/test_challenge_layer_flow.gd`（`8/8 passed`, `340` asserts）、`test/unit/test_map_generation_config.gd`（`6/6 passed`, `719` asserts）与 `test/unit/test_meta_return_progression.gd`（`1/1 passed`, `32` asserts），合计 `15` tests / `1091` asserts / all passed。
- 当前已推进第 6 项第十一批：
  - 在 `data/balance/achievements.json` 新增 `ach_cl3_clear`（`Sovereign Curator`），让首个 `CL3` 清档正式进入 Stage 6 成就矩阵。
  - 在 `scripts/autoload/save_manager.gd` 扩展 `challenge_layer_clear_cl3` 成就判定，并让 archive codex 解锁链新增 `cl3_sovereign_archive`。
  - 在 `scripts/ui/main_menu.gd` 的 `ARCHIVE_CODEX_ENTRIES` 新增 `Sovereign Echo Archive`，沿用现有 Challenge Layer detail 页面展示 `CL3` 的 ledger / clear / last reward 档案信息。
  - 在 `test/unit/test_hidden_layer_achievement_flow.gd` 与 `test/unit/test_codex_archive_flow.gd` 将既有 `CL1/CL2` 回归扩到 `CL3`，同步更新 Stage 6 成就总数、主菜单分组进度、archive catalog 与 detail 断言；并补跑 `test/unit/test_content_depth_targets.gd`、`test/unit/test_challenge_layer_flow.gd`。
  - 本轮已通过 `test/unit/test_hidden_layer_achievement_flow.gd`（`10/10 passed`, `227` asserts）、`test/unit/test_codex_archive_flow.gd`（`4/4 passed`, `114` asserts）、`test/unit/test_challenge_layer_flow.gd`（`8/8 passed`, `340` asserts）与 `test/unit/test_content_depth_targets.gd`（`5/5 passed`, `56` asserts），合计 `27` tests / `737` asserts / all passed。
- 当前已推进第 6 项第十二批（阶段 6 收口）：
  - 在 `scripts/autoload/save_manager.gd` 与 `scripts/autoload/game_manager.gd` 新增 `CHALLENGE_LAYER_CL4`、`camp_challenge_layer_4`（`P`）以及最终 `apex_meta_return` / `Apex Return` 链路，让 `CL4` 清档可把长期回流倍率补齐到 `Return x1.60`。
  - 在 `scripts/game/game_world.gd` 与 `scripts/systems/map_generator.gd` 落地最终 `CL4`：`CL3` 清档后开放第四挑战层，具备安全营地预览、Entry -> Elite -> Combat -> Elite -> Boss -> Settlement 六段流程、第四档奖励（`Apex Meta Cache` / `Sigil Constellation` / `Insight Throne`）与 Archive 回显。
  - 在 `data/balance/achievements.json`、`scripts/ui/main_menu.gd`、`scripts/autoload/save_manager.gd` 补齐 `ach_cl4_clear`、`Apex Return Protocol`、`Apex Throne Archive` 等最终 Stage 6 成就 / archive codex 行。
  - 在 `data/balance/characters.json`、`data/balance/shop_items.json`、`data/balance/evolutions.json`、`data/balance/resource_acceptance_targets.json` 以及 `resources/characters/char_curator.tres`、`resources/weapons/wpn_reliquary_orb.tres`、`resources/evolutions/evo_zenith_reliquary.tres`、`resources/forge_recipes/forge_zenith_reliquary.tres` 中补齐最小内容包：`char_curator`、`wpn_reliquary_orb`、`evo_zenith_reliquary` / `wpn_zenith_reliquary` 与对应验收资源桩。
  - 在 `test/unit/test_challenge_layer_flow.gd`、`test/unit/test_map_generation_config.gd`、`test/unit/test_meta_return_progression.gd`、`test/unit/test_hidden_layer_achievement_flow.gd`、`test/unit/test_codex_archive_flow.gd`、`test/unit/test_content_depth_targets.gd` 中将 Stage 6 回归扩到 `CL4` / `Apex Return` / 最终内容包。
  - 本轮已通过 `test/unit/test_challenge_layer_flow.gd`（`9/9 passed`, `410` asserts）、`test/unit/test_map_generation_config.gd`（`6/6 passed`, `731` asserts）、`test/unit/test_meta_return_progression.gd`（`1/1 passed`, `37` asserts）、`test/unit/test_hidden_layer_achievement_flow.gd`（`10/10 passed`, `231` asserts）、`test/unit/test_codex_archive_flow.gd`（`4/4 passed`, `127` asserts）、`test/unit/test_content_depth_targets.gd`（`5/5 passed`, `59` asserts）、`test/unit/test_character_weapon_profiles.gd`（`2/2 passed`, `112` asserts）、`test/unit/test_narrative_camp_flow.gd`（`5/5 passed`, `158` asserts）、`test/unit/test_meta_shop_progression.gd`（`1/1 passed`, `27` asserts），合计 `43` tests / `1892` asserts / all passed，并补跑 `python scripts/tools/check_json_syntax.py`、`python scripts/validate_configs.py`、`python scripts/check_resources.py` 全部通过。
- 当前已推进第 5 项收口：
  - 新增 `spec-design/stage5-closure-2026-03-25.md`、`spec-design/stage5-acceptance-record-2026-03-25.md`、`spec-design/stage5-acceptance-summary-2026-03-25.md`，正式沉淀 Stage 5 的已完成真值、验收口径与后续承接基线。
  - 在 `test/unit/test_narrative_payoff_flow.gd` 新增 `test_save_manager_covers_all_endings_and_distinguishes_first_vs_repeat_unlocks()`，直接锁定三结局与首通/复通差异。
  - 本轮已补跑 Stage 5 相关专项测试：`33` tests / `904` asserts / all passed。
- 下一步只保留一条主线推进：Stage 6 已正式完成，后续直接转入 Stage 7 的音频/视觉成品化、完整联合回归与最终验收。
