# Stage 8.1 资产替换试点执行计划 - 2026-05-07

## 目标

本阶段跑通第一条可复用的资产替换流水线：清单冻结、候选生成、人工/工具审阅、二次处理、运行时接入、Godot MCP 截图复核、资源验收和文档回写。

第一批资产只追求运行中可读和可替换，不追求最终动画 spritesheet。角色、敌人先接 topdown concept / silhouette，武器先接 projectile / impact，音频先接短 SFX cue。

## 当前前置状态

- `resources/resource_catalog.json` 中第一批角色、敌人、武器仍大量使用 `assets/sprites/tiles/*.png` 作为 `preview_texture`。
- 当前本机未检测到 `.env`、`GEMINI_API_KEY`、`ELEVENLABS_API_KEY`，因此 API 批量生成需要等密钥就绪后执行。
- `assets/sprites/characters/`、`assets/sprites/enemies/`、`assets/sprites/weapons/` 目前主要是 README / `.gitkeep`，可作为第一批候选落库目录。
- `assets/audio/` 当前只有 README 和 Stage 7 提示词文档，SFX/BGM 正式文件仍待生成。
- 2026-05-07 已生成一批程序化 fallback candidate / v1 文件，用于先跑通审阅、接入和可读性验证链路；这些文件不是最终美术资产，后续可被 AI/人工成品资产替换。

## 第一批试点清单

| 批次 | asset_id / cue_id | 类型 | candidate_path | selected_path | 当前替换目标 | 状态 |
|------|-------------------|------|----------------|---------------|--------------|------|
| S8.1-C | `char_knight` | character concept | `assets/sprites/characters/char_knight_topdown_concept_candidate_01.png` | `assets/sprites/characters/char_knight_topdown_concept_v1.png` | `resources/characters/char_knight.tres` preview | fallback_ready |
| S8.1-C | `char_mage` | character concept | `assets/sprites/characters/char_mage_topdown_concept_candidate_01.png` | `assets/sprites/characters/char_mage_topdown_concept_v1.png` | `resources/characters/char_mage.tres` preview | fallback_ready |
| S8.1-C | `char_rogue` | character concept | `assets/sprites/characters/char_rogue_topdown_concept_candidate_01.png` | `assets/sprites/characters/char_rogue_topdown_concept_v1.png` | `resources/characters/char_rogue.tres` preview | fallback_ready |
| S8.1-E | `enemy_shadowling` | enemy concept | `assets/sprites/enemies/enemy_shadowling_topdown_concept_candidate_01.png` | `assets/sprites/enemies/enemy_shadowling_topdown_concept_v1.png` | `resources/enemies/enemy_shadowling.tres` preview | fallback_ready |
| S8.1-E | `enemy_brute` | enemy concept | `assets/sprites/enemies/enemy_brute_topdown_concept_candidate_01.png` | `assets/sprites/enemies/enemy_brute_topdown_concept_v1.png` | `resources/enemies/enemy_brute.tres` preview | fallback_ready |
| S8.1-W | `wpn_holy_cross` | weapon projectile | `assets/sprites/weapons/wpn_holy_cross_projectile_candidate_01.png` | `assets/sprites/weapons/wpn_holy_cross_projectile_v1.png` | `resources/weapons/wpn_holy_cross.tres` preview | fallback_ready |
| S8.1-W | `wpn_reliquary_orb` | weapon projectile | `assets/sprites/weapons/wpn_reliquary_orb_projectile_candidate_01.png` | `assets/sprites/weapons/wpn_reliquary_orb_projectile_v1.png` | `resources/weapons/wpn_reliquary_orb.tres` preview | fallback_ready |
| S8.1-W | `wpn_solar_lance` | weapon projectile | `assets/sprites/weapons/wpn_solar_lance_projectile_candidate_01.png` | `assets/sprites/weapons/wpn_solar_lance_projectile_v1.png` | 数据层存在，catalog 当前缺 `resources/weapons/wpn_solar_lance.tres`，先记录为 gap | fallback_ready_gap_pending |
| S8.1-W | `wpn_sacred_lance` | weapon projectile fallback | `assets/sprites/weapons/wpn_sacred_lance_projectile_candidate_01.png` | `assets/sprites/weapons/wpn_sacred_lance_projectile_v1.png` | `resources/weapons/wpn_sacred_lance.tres` preview | fallback_ready |
| S8.1-UI | `ui_hud_health_icon` | UI icon | `assets/sprites/ui/icons/ui_hud_health_icon_candidate_01.png` | `assets/sprites/ui/icons/ui_hud_health_icon_v1.png` | HUD HP / status icon candidate | fallback_ready |
| S8.1-UI | `ui_hud_xp_icon` | UI icon | `assets/sprites/ui/icons/ui_hud_xp_icon_candidate_01.png` | `assets/sprites/ui/icons/ui_hud_xp_icon_v1.png` | HUD XP / pickup icon candidate | fallback_ready |
| S8.1-A | `pickup_xp_small` | SFX | `assets/audio/sfx/pickup_xp_small_candidate_01.wav` | `assets/audio/sfx/pickup_xp_small_v1.wav` | small pickup cue | fallback_ready |
| S8.1-A | `weapon_impact_light` | SFX | `assets/audio/sfx/weapon_impact_light_candidate_01.wav` | `assets/audio/sfx/weapon_impact_light_v1.wav` | light hit cue | fallback_ready |
| S8.1-A | `enemy_kill` | SFX | `assets/audio/sfx/enemy_kill_candidate_01.wav` | `assets/audio/sfx/enemy_kill_v1.wav` | enemy kill cue | fallback_ready |

## 生成与二次处理步骤

1. 使用 `data/pipelines/stage8_asset_pilot_batch.json` 执行批量生成；若无 API 密钥，则使用当前程序化 fallback 资产继续跑通接入链路，并在后续成品资产生成后替换。
2. 所有候选先保留 `*_candidate_01`，人工确认后复制为 `*_v1`。
3. 图像候选必须完成透明背景、裁切、尺寸归一和 48px / 64px 缩放可读性检查。
4. 武器 projectile 必须在 25%、50%、100% 缩放下仍能和敌方威胁色区分。
5. SFX 必须裁到 0.2-1.5 秒，避免长尾混响，频繁 cue 需要后续走 `AudioManager` 限频。
6. 入库后只更新稳定资源 ID 的 preview/runtime path，不重命名 ID。

## 运行时接入顺序

1. 仅替换 preview：更新对应 `.tres` / catalog 的 `preview_texture`，跑资源校验。
2. 角色/敌人 concept 接入运行时显示前，先确认缩放和碰撞不受影响。
3. 武器 projectile 接入前，先确认 `AutoWeapon` 当前 style resolver 是否支持 texture path；不支持时先只做 preview。
4. SFX 接入前，先列出 `AudioManager` 已有 cue 名，避免新增重复入口。
5. 每个接入批次保存 MCP 截图到 `test/manual_review_evidence/stage8-asset-pilot/`。

## 验收命令

```bash
python scripts/tools/check_json_syntax.py
python scripts/validate_configs.py
python scripts/check_resources.py
godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd
godot --headless --path . --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_core_flow_regression.gd -gexit
```

## 风险记录

- `wpn_solar_lance` 在部分数据层存在，但当前 resource catalog 未登记对应 `.tres`；Stage 8.1 先记录为 gap，不在资产试点提交中强行改 schema。
- 当前 API 密钥缺失时，Phase 2 只能落地配置和人工生成入口，不能宣称候选资产已生成。
- `resources/resource_catalog.json` 内嵌的 `scene_visual_requirements` 仍可能滞后于 `data/balance/resource_acceptance_targets.json`；真正验收以 `run_resource_acceptance.gd` 读取的数据文件为准。

## 提交边界

- Phase 1 提交只包含本计划、批量生成配置、证据目录 README 和文档索引更新。
- Phase 2 才允许新增候选资产文件。
- Phase 3 才允许修改 catalog、`.tres` preview 或运行时引用。
