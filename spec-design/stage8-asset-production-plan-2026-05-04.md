# Stage 8 资产成品化分批规划 - 2026-05-04

## 目标

Stage 8 接续 Stage 7 的资产方向稿和提示词文档，将资产工作从“分散计划与占位候选”整理为可执行批次。第一轮只做清单、提示词、路径、格式、占位映射和二次处理规则，不直接生成或替换资产。

当前 `resources/resource_catalog.json` 中角色、武器、敌人等条目虽标记为 `production_ready`，但 preview texture 仍大量指向 `assets/sprites/tiles/*.png`。Stage 8 的真实目标是把这些 tile 预览占位逐步替换为与资源 ID 一一对应的正式候选资产。

## 批次总览

| 批次 | 目标 | 输出目录 | 第一轮产物 |
|------|------|----------|------------|
| S8-A UI / 图标 / 字体 | 统一主菜单、设置、HUD、构筑、宝箱、结算视觉语言 | `assets/sprites/ui/`、`assets/fonts/` | 复核已有 UI 资产，补齐缺口提示词 |
| S8-B 角色 | 覆盖 13 个角色的 topdown concept 和 silhouette | `assets/sprites/characters/` | 每角色 1 个概念提示词 + 1 个二次处理规则 |
| S8-C 敌人 | 覆盖 20 个敌人，按章节族群分组 | `assets/sprites/enemies/` | 每族群风格板 + 每敌人 topdown concept |
| S8-D 武器 / 进化 / 弹道 | 覆盖 loadout、shop、evolution 涉及武器 | `assets/sprites/weapons/`、`assets/sprites/effects/` | projectile、impact、evolved variant 提示词 |
| S8-E 音频 | 覆盖 UI、拾取、击杀、命中、宝箱、BGM/ambience | `assets/audio/` | SFX/BGM 提示词与命名规范 |
| S8-F 运行时替换验收 | 把候选资产逐批接入 Godot 并截图复核 | `resources/resource_catalog.json`、场景引用 | 每批替换记录、MCP 截图、资源验收结果 |

## 当前占位映射

| 类别 | 当前占位状态 | Stage 8 替换方向 |
|------|--------------|------------------|
| characters | `preview_texture` 使用 `assets/sprites/tiles/ground_ch1.png` | 替换为 `assets/sprites/characters/<char_id>_topdown_concept_v1.png` 或后续 spritesheet |
| weapons | `preview_texture` 使用 `assets/sprites/tiles/ambient_fx_ch2.png` | 替换为 `assets/sprites/weapons/<wpn_id>_projectile_v1.png` |
| enemies | `preview_texture` 使用 `assets/sprites/tiles/hazard_overlay_ch4.png` | 替换为 `assets/sprites/enemies/<enemy_id>_topdown_concept_v1.png` |
| evolutions | `preview_texture` 使用 `assets/sprites/tiles/ambient_fx_ch4.png` | 替换为 `assets/sprites/weapons/<result_wpn_id>_evolved_projectile_v1.png` |
| UI | 已有背景、面板、图标候选，仍缺统一应用规则 | 先完成 UI style guide，再逐屏接入 |
| audio | 已有音频提示词母版，但运行时仍以程序化 tone 为主 | 逐 cue 生成并接入 `AudioManager` |

## 资源 ID 范围

### 角色 13 个

`char_knight`、`char_mage`、`char_rogue`、`char_cleric`、`char_huntress`、`char_exile`、`char_templar`、`char_occultist`、`char_sentinel`、`char_witchblade`、`char_arbiter`、`char_oracle`、`char_curator`

### 敌人 20 个

- Shadow / Chapter 1：`enemy_shadowling`、`enemy_stalker`、`enemy_brute`、`enemy_hexcaster`、`enemy_rock_colossus`
- Flame / Chapter 2：`enemy_emberling`、`enemy_scorch_runner`、`enemy_burn_guard`、`enemy_flame_channeler`、`enemy_flame_lord`
- Frost / Chapter 3：`enemy_frostling`、`enemy_glacier_runner`、`enemy_ice_guard`、`enemy_blizzard_mage`、`enemy_frost_king`
- Void / Chapter 4：`enemy_voidling`、`enemy_rift_runner`、`enemy_abyss_guard`、`enemy_void_priest`、`enemy_void_lord`

### 武器与进化

- 基础/可获得武器：`wpn_magic_missile`、`wpn_holy_cross`、`wpn_shadow_fang`、`wpn_solar_lance`、`wpn_sacred_lance`、`wpn_void_chain`、`wpn_frost_orb`、`wpn_storm_bow`、`wpn_radiant_hammer`、`wpn_blood_rite`、`wpn_vowblade`、`wpn_nether_shard`、`wpn_astral_disc`、`wpn_reliquary_orb`
- 进化武器：`wpn_arcane_comet`、`wpn_holy_judgment`、`wpn_shadow_tempest`、`wpn_solar_supernova`、`wpn_seraph_lance`、`wpn_abyssal_chain`、`wpn_glacial_nova`、`wpn_radiant_cataclysm`、`wpn_tempest_onslaught`、`wpn_blood_requiem`、`wpn_vowstorm`、`wpn_nether_maelstrom`、`wpn_astral_horizon`、`wpn_zenith_reliquary`

## 命名与格式

| 类型 | 候选命名 | 入选命名 | 格式 |
|------|----------|----------|------|
| 角色概念 | `<char_id>_topdown_concept_candidate_01.png` | `<char_id>_topdown_concept_v1.png` | PNG |
| 角色轮廓 | `<char_id>_silhouette_candidate_01.png` | `<char_id>_silhouette_v1.png` | PNG |
| 敌人概念 | `<enemy_id>_topdown_concept_candidate_01.png` | `<enemy_id>_topdown_concept_v1.png` | PNG |
| 武器弹道 | `<wpn_id>_projectile_candidate_01.png` | `<wpn_id>_projectile_v1.png` | PNG |
| 进化弹道 | `<wpn_id>_evolved_projectile_candidate_01.png` | `<wpn_id>_evolved_projectile_v1.png` | PNG |
| UI 图标 | `<ui_asset_id>_candidate_01.png` | `<ui_asset_id>_v1.png` | PNG |
| SFX | `<cue_id>_candidate_01.wav` | `<cue_id>_v1.wav` | WAV |
| BGM / Ambience | `<track_id>_candidate_01.ogg` | `<track_id>_v1.ogg` | OGG |

## AI 原资产二次处理流程

1. 原图进入候选目录或候选命名，不直接覆盖正式文件。
2. 入选后执行裁切、透明背景、尺寸统一、调色板统一和缩放可读性检查。
3. 角色/敌人第一轮不直接产最终 spritesheet；先保留 topdown concept、silhouette 和动作拆分说明。
4. 武器第一轮优先产 projectile、impact、evolved variant；复杂逐帧攻击动画后置。
5. UI 资产需检查 720p、1080p、4K 下的面板密度和文字可读性。
6. 音频需检查响度、长度、循环点和 cue 限频，不把长 BGM 当 SFX 接入。

## 替换验收流程

每批资产进入运行时前，必须：

- 更新 `resources/resource_catalog.json` 或对应场景引用。
- 运行 `python scripts/check_resources.py`。
- 若修改 JSON，运行 `python scripts/tools/check_json_syntax.py` 与 `python scripts/validate_configs.py`。
- 若修改资源验收数据，运行 `godot --headless --path . -s res://scripts/tools/run_resource_acceptance.gd`。
- 用 Godot MCP 截图保存到 `test/manual_review_evidence/<date-or-topic>/`。
- 更新 `spec-design/2026-5-2-plan.md` 或本 Stage 8 文档的批次状态。

## 第一轮完成标准

- 新 Stage 8 计划和提示词文档成为当前资产真源。
- 每个角色、敌人、武器批次都有明确路径、命名和替换目标。
- 旧 Stage 7 文档仍作为历史参考保留，不再作为当前执行真源。
- 没有生成新图像、没有替换运行时占位、没有修改资源 catalog。
