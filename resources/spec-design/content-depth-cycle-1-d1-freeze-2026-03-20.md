# 内容优先周期（2周）D1 冻结清单（2026-03-20）

## 目标

- 在不破坏现有可玩闭环与回归稳定性的前提下，先完成“内容扩容的 ID 与约束冻结”。
- 为 D2（数据落库）与 D3（逻辑消费+测试护栏）提供可直接执行的清单。

## 基线与目标（冻结时刻）

当前基线：

- `characters = 6`
- `evolutions = 4`
- `shop passive pool = 5`
- `shop weapon pool = 6`
- `memory_fragments = 4`

本周期目标（D3 完成时）：

- `characters >= 8`
- `evolutions >= 7`
- `shop passive pool >= 8`
- `shop weapon pool >= 9`
- `memory_fragments >= 10`

## D1 锁定新增 ID（仅追加，不改旧 ID）

### 角色（+2）

- `char_templar`
- `char_occultist`

### 武器池扩容（+3）

- `wpn_sacred_lance`
- `wpn_void_chain`
- `wpn_frost_orb`

### 被动池扩容（+3）

- `pas_fortune`
- `pas_resolve`
- `pas_momentum`

### 进化配方（+3）

- `evo_seraph_lance`
  - `weapon_id: wpn_sacred_lance`
  - `passive_id: pas_focus`
  - `result_weapon_id: wpn_seraph_lance`
- `evo_abyssal_chain`
  - `weapon_id: wpn_void_chain`
  - `passive_id: pas_force`
  - `result_weapon_id: wpn_abyssal_chain`
- `evo_glacial_nova`
  - `weapon_id: wpn_frost_orb`
  - `passive_id: pas_precision`
  - `result_weapon_id: wpn_glacial_nova`

### 记忆碎片（+6）

- `memory_ch1_route_vanguard`
- `memory_ch1_route_raider`
- `memory_ch2_route_vanguard`
- `memory_ch2_route_raider`
- `memory_ch3_route_vanguard`
- `memory_ch3_route_raider`

## D2 执行范围（数据层）

- `data/balance/characters.json`
- `data/balance/evolutions.json`
- `data/balance/shop_items.json`
- `data/balance/narrative_content.json`

## D3 执行范围（逻辑与测试）

- 逻辑消费：`scripts/game/game_world.gd`（商店文案与效果分支）
- 进化路径消费：`scripts/systems/level_up_system.gd`（仅在需要时补分支）
- 门槛测试更新：`test/unit/test_content_depth_targets.gd`
- 集成护栏补强：`test/integration/test_core_flow_regression.gd`（新增 1 条新内容可达断言）

## 执行约束（严格遵循 AGENTS）

- 命名遵循前缀规范：`char_` / `wpn_` / `pas_` / `evo_`。
- 仅追加内容，不重命名或删除既有 ID。
- 每个子阶段完成后必须执行：
  - `python scripts/validate_configs.py`
  - `python scripts/check_resources.py`
  - `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit`
- 每个子阶段完成后同步文档：
  - `spec-design/development-plan-2026-03-20.md`
  - `spec-design/truth-check-2026-03-20.md`
  - `spec-design/README.md`

## D1 验收结论

- D1 已完成：目标、ID、范围、约束均已冻结，可直接进入 D2 实施。
