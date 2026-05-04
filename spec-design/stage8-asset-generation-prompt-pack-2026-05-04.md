# Stage 8 资产生成提示词包 - 2026-05-04

## 使用方式

本文档是 Stage 8 当前资产生成真源。第一轮只用于复制提示词、生成候选、记录路径和后续替换目标，不直接要求 AI 生成最终 spritesheet。

通用世界观锚词：

```text
dark fantasy, fallen angel, sacred ruins, broken halo, memory fragments, forbidden archive, divine decay, solemn and tragic, high readability, game asset
```

通用负面词：

```text
blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
```

通用尾词：

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## 统一投喂模板

```text
你现在是《Angel Fallen》的游戏资产概念设计师。请严格保持同一世界观和可读性。

任务类型：<角色/敌人/武器/UI/音频>
资源 ID：<asset_id>
目标用途：<运行时/菜单/构筑面板/宝箱/音效 cue>
输出数量：3
必须保留元素：<核心视觉元素>
禁止出现元素：blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
风格锚词：dark fantasy, fallen angel, sacred ruins, broken halo, memory fragments, forbidden archive, divine decay, solemn and tragic, high readability, game asset

请输出可用于游戏资产筛选的候选结果。不要包含文字、水印或 logo。
```

## S8-A UI / 图标 / 字体

| 资产 | 输出路径 | 替换目标 | 提示词 |
|------|----------|----------|--------|
| 主菜单背景 | `assets/sprites/ui/backgrounds/ui_bg_main_menu_ruined_halo_v1.png` | 主菜单背景占位 | `dark fantasy title background for a top-down 2D survivor roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style` |
| 设置/通用面板风格板 | `assets/sprites/ui/panels/ui_style_board_cathedral_relic_v1.png` | 设置页、HUD、构筑面板、宝箱弹层 | `dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, buttons, cards, tabs, modal panels, cohesive design system, no text, no watermark, functional game UI, readable hierarchy, clean framing, consistent style` |
| 奖励卡片 | `assets/sprites/ui/cards/ui_card_reward_archive_v1.png` | 升级、宝箱、结算奖励卡 | `reward card designs for a dark fantasy game UI, fallen angel theme, archive reward presentation, aged metal frame, dark stone base, soft holy glow, readable hierarchy, restrained ornament, multiple card states, no text, no watermark, transparent background when applicable, functional game UI, consistent style` |
| 通用图标 sheet | `assets/sprites/ui/icons/ui_icon_archive_systems_sheet_v1.png` | 档案、记忆、隐藏层、挑战层、构筑 tags | `dark fantasy game icon set, fallen angel theme, memory shard, archive seal, hidden layer icon, challenge badge, forge ember, relic symbol, void sigil, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style` |

二次处理：UI 候选入选后裁切为透明背景 PNG；图标 sheet 后续需拆单图或建立 atlas；面板素材需在 720p、1080p、4K 下检查文字对比度。

## S8-B 角色

统一角色提示词模板：

```text
top-down dark fantasy playable character concept for Angel Fallen, <class_identity>, fallen angel survivor, sacred ruins, broken halo motif, readable silhouette, clear weapon direction, restrained palette, high contrast against dark ground, suitable for later pixel art adaptation, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

| 资源 ID | Class Identity | 输出路径 | 替换目标 |
|---------|----------------|----------|----------|
| `char_knight` | armored frontline knight, holy lance, sturdy posture | `assets/sprites/characters/char_knight_topdown_concept_v1.png` | `resources/characters/char_knight.tres` preview |
| `char_mage` | arcane caster, floating spell focus, robe silhouette | `assets/sprites/characters/char_mage_topdown_concept_v1.png` | `resources/characters/char_mage.tres` preview |
| `char_rogue` | agile shadow rogue, dual dagger outline, low stance | `assets/sprites/characters/char_rogue_topdown_concept_v1.png` | `resources/characters/char_rogue.tres` preview |
| `char_cleric` | sacred healer cleric, halo staff, calm posture | `assets/sprites/characters/char_cleric_topdown_concept_v1.png` | `resources/characters/char_cleric.tres` preview |
| `char_huntress` | storm huntress, bow silhouette, light cloak | `assets/sprites/characters/char_huntress_topdown_concept_v1.png` | `resources/characters/char_huntress.tres` preview |
| `char_exile` | solar exile, scorched cloak, radiant lance | `assets/sprites/characters/char_exile_topdown_concept_v1.png` | `resources/characters/char_exile.tres` preview |
| `char_templar` | sacred templar, heavy spear, shielded outline | `assets/sprites/characters/char_templar_topdown_concept_v1.png` | `resources/characters/char_templar.tres` preview |
| `char_occultist` | void occultist, chain relic, forbidden archive robes | `assets/sprites/characters/char_occultist_topdown_concept_v1.png` | `resources/characters/char_occultist.tres` preview |
| `char_sentinel` | radiant sentinel, hammer silhouette, defensive stance | `assets/sprites/characters/char_sentinel_topdown_concept_v1.png` | `resources/characters/char_sentinel.tres` preview |
| `char_witchblade` | blood witchblade, ritual blade, sharp crescent silhouette | `assets/sprites/characters/char_witchblade_topdown_concept_v1.png` | `resources/characters/char_witchblade.tres` preview |
| `char_arbiter` | oath arbiter, vowblade, austere judge armor | `assets/sprites/characters/char_arbiter_topdown_concept_v1.png` | `resources/characters/char_arbiter.tres` preview |
| `char_oracle` | astral oracle, disc relics, floating veil | `assets/sprites/characters/char_oracle_topdown_concept_v1.png` | `resources/characters/char_oracle.tres` preview |
| `char_curator` | archive curator, reliquary orb, scholar relic cloak | `assets/sprites/characters/char_curator_topdown_concept_v1.png` | `resources/characters/char_curator.tres` preview |

二次处理：入选后生成同名 `_silhouette_v1.png` 缩小检查图；后续 spritesheet 才按 `idle/run/attack/hurt/death` 切分。

## S8-C 敌人

族群风格板提示词：

```text
dark fantasy enemy family concept sheet for Angel Fallen, <chapter_theme>, fallen angel sacred ruins corrupted by abyss, multiple top-down enemy silhouettes, clear hierarchy between normal, fast, tank, ranged, and boss, readable in crowded survivor combat, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

| 族群 | 资源 ID | 输出路径规则 | 替换目标 |
|------|---------|--------------|----------|
| Shadow | `enemy_shadowling`、`enemy_stalker`、`enemy_brute`、`enemy_hexcaster`、`enemy_rock_colossus` | `assets/sprites/enemies/<enemy_id>_topdown_concept_v1.png` | 对应 `resources/enemies/<enemy_id>.tres` preview |
| Flame | `enemy_emberling`、`enemy_scorch_runner`、`enemy_burn_guard`、`enemy_flame_channeler`、`enemy_flame_lord` | `assets/sprites/enemies/<enemy_id>_topdown_concept_v1.png` | 对应 `resources/enemies/<enemy_id>.tres` preview |
| Frost | `enemy_frostling`、`enemy_glacier_runner`、`enemy_ice_guard`、`enemy_blizzard_mage`、`enemy_frost_king` | `assets/sprites/enemies/<enemy_id>_topdown_concept_v1.png` | 对应 `resources/enemies/<enemy_id>.tres` preview |
| Void | `enemy_voidling`、`enemy_rift_runner`、`enemy_abyss_guard`、`enemy_void_priest`、`enemy_void_lord` | `assets/sprites/enemies/<enemy_id>_topdown_concept_v1.png` | 对应 `resources/enemies/<enemy_id>.tres` preview |

单敌人提示词模板：

```text
top-down dark fantasy enemy concept for Angel Fallen, enemy id <enemy_id>, <role_description>, fallen angel sacred ruins, readable hostile silhouette, clear danger level, distinct from player projectiles and pickups, suitable for later pixel art adaptation, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

二次处理：普通敌保留 24-48px 可读性目标，精英 48-64px，Boss 64-128px；先做概念与 silhouette，不直接定终稿动画。

## S8-D 武器 / 进化 / 弹道

统一武器提示词模板：

```text
dark fantasy weapon projectile concept for Angel Fallen, weapon id <wpn_id>, <weapon_language>, fallen angel sacred relic attack, readable player-owned projectile silhouette, high contrast against enemies and ground, suitable for top-down survivor combat, include impact effect direction, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

| 类型 | 资源 ID | 输出路径 | 替换目标 |
|------|---------|----------|----------|
| 基础弹道 | `wpn_magic_missile`、`wpn_holy_cross`、`wpn_shadow_fang`、`wpn_solar_lance`、`wpn_sacred_lance`、`wpn_void_chain`、`wpn_frost_orb`、`wpn_storm_bow`、`wpn_radiant_hammer`、`wpn_blood_rite`、`wpn_vowblade`、`wpn_nether_shard`、`wpn_astral_disc`、`wpn_reliquary_orb` | `assets/sprites/weapons/<wpn_id>_projectile_v1.png` | `resources/weapons/<wpn_id>.tres` preview 与 projectile style |
| 进化弹道 | `wpn_arcane_comet`、`wpn_holy_judgment`、`wpn_shadow_tempest`、`wpn_solar_supernova`、`wpn_seraph_lance`、`wpn_abyssal_chain`、`wpn_glacial_nova`、`wpn_radiant_cataclysm`、`wpn_tempest_onslaught`、`wpn_blood_requiem`、`wpn_vowstorm`、`wpn_nether_maelstrom`、`wpn_astral_horizon`、`wpn_zenith_reliquary` | `assets/sprites/weapons/<wpn_id>_evolved_projectile_v1.png` | `resources/evolutions/evo_*.tres` preview 与 evolved projectile style |
| 命中特效 | projectile / orbit / aura / ground | `assets/sprites/effects/<style_id>_impact_v1.png` | `projectile.gd`、`orbit_weapon.gd`、`aura_weapon.gd` 后续视觉替换 |

二次处理：所有弹道必须额外生成 25%、50%、100% 缩放预览；玩家弹道使用神圣/冷色/金色高亮，敌方弹道后续使用红/紫/暗色，避免混淆。

## S8-E 音频

| Cue | 输出路径 | 提示词 |
|-----|----------|--------|
| UI 点击 | `assets/audio/sfx/ui_click_v1.wav` | `short dark fantasy UI click, soft stone and silver tap, clean transient, no reverb tail longer than 0.3 seconds, game menu sound effect` |
| 拾取小经验 | `assets/audio/sfx/pickup_xp_small_v1.wav` | `short magical pickup chime, memory shard sparkle, bright but gentle, suitable for frequent survivor game pickups, no harsh high frequencies` |
| 大拾取 / 磁铁 | `assets/audio/sfx/pickup_magnet_v1.wav` | `wide magical vacuum pickup sound, many tiny shards rushing inward, satisfying but not loud, short game sound effect` |
| 命中 | `assets/audio/sfx/weapon_impact_light_v1.wav` | `dark fantasy holy projectile impact, crisp hit, small burst of sacred light, short combat sound effect` |
| 击杀 | `assets/audio/sfx/enemy_kill_v1.wav` | `short enemy defeat sound, corrupted spirit dissolving, soft ash burst, readable combat feedback, not gore` |
| 宝箱开奖 | `assets/audio/sfx/treasure_chest_open_v1.wav` | `dark fantasy treasure chest opening, sacred lock release, relic shimmer, satisfying reward reveal, short UI reward sound` |
| 主菜单 BGM | `assets/audio/bgm/main_menu_ruined_halo_v1.ogg` | `dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells, slow strings, sacred ruin atmosphere, melancholic but grand, loopable game soundtrack, no lyrical vocal` |
| 战斗 BGM | `assets/audio/bgm/combat_survivor_pressure_v1.ogg` | `loopable dark fantasy survivor combat music, driving low strings, ritual percussion, sacred choir pads, escalating pressure without sudden climax, no lyrical vocal` |

二次处理：SFX 统一裁到 0.2-1.5 秒；BGM/ambience 输出 OGG 并检查循环点；运行时接入前需要在 `AudioManager` cue 限频下测试。

## 候选记录模板

```markdown
| asset_id | candidate_path | selected_path | status | notes |
|----------|----------------|---------------|--------|-------|
| char_knight | assets/sprites/characters/char_knight_topdown_concept_candidate_01.png | assets/sprites/characters/char_knight_topdown_concept_v1.png | pending_review | 需检查 48px 可读性 |
```

## 替换记录模板

```markdown
| asset_id | old_placeholder | new_asset | touched_runtime | validation |
|----------|-----------------|-----------|-----------------|------------|
| char_knight | assets/sprites/tiles/ground_ch1.png | assets/sprites/characters/char_knight_topdown_concept_v1.png | resource_catalog preview only | check_resources + MCP screenshot |
```
