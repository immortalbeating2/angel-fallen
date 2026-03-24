# Stage 7 Gemini 批量生成执行手册（2026-03-24）

## 1. 目的

本文档是 `spec-design/stage7-asset-production-guide-2026-03-24.md` 的执行版补充，用于把 Stage 7 可单独开发资产拆成可直接交给 Gemini 的批量生产任务。

适用目标：

- 统一风格前提下的概念图、UI 风格图、图标集、背景图、通用 VFX 草图批量生成
- 批量生成时的提示词结构统一
- 输出结果能直接映射到项目路径与文件命名规范

不适用目标：

- 最终像素角色精灵表
- 最终 tileset 成品切片
- 正式大批量可循环音频母带
- 高耦合的结局 / 隐藏层 / 挑战层最终演出定稿

## 2. 与项目目录的对应关系

本手册默认以下目录为 Stage 7 资产落点：

- `assets/audio/bgm/`
- `assets/audio/ambience/`
- `assets/audio/sfx/`
- `assets/sprites/ui/icons/`
- `assets/sprites/ui/panels/`
- `assets/sprites/ui/frames/`
- `assets/sprites/ui/cards/`
- `assets/sprites/ui/badges/`
- `assets/sprites/ui/backgrounds/`
- `assets/sprites/tiles/`
- `assets/sprites/effects/`
- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`
- `assets/fonts/`
- `assets/shaders/`

说明：

- Gemini 现阶段优先用于视觉概念、风格探索和提示词母版生成。
- 其中 `characters / enemies / weapons` 目录可以先放概念稿参考，不建议直接作为最终运行时精灵表定稿来源。

## 3. 批量生成总流程

推荐固定采用 5 步：

1. 先锁风格锚点
2. 再按批次生成候选图
3. 从每批候选中选 1 到 2 张风格正确者
4. 用入选结果继续做同风格扩展
5. 人工筛选后再进入切图、像素化、音频后处理或导入

### 3.1 风格锚点固定词

每一批提示词都应保留以下母题：

- `dark fantasy`
- `fallen angel`
- `sacred ruins`
- `broken halo`
- `memory fragments`
- `forbidden archive`
- `divine decay`
- `solemn and tragic`
- `high readability`
- `game asset`

### 3.2 固定负面词

```text
blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
```

### 3.3 输出约束模板

视觉类提示词末尾统一追加：

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

若是 UI：

```text
functional game UI, readable hierarchy, clean framing, transparent background when applicable
```

若是 tile / 像素方向：

```text
pixel art, top-down 2D, seamless tile when needed, clean grid alignment
```

## 4. 批次拆分建议

## Batch A：世界观基准图

### 目标

先生成全项目统一气质参考图，用于后续所有批次做风格锚定。

### 建议产量

- 主菜单气质图：3 张
- 安全营地气质图：3 张
- 记忆祭坛气质图：3 张
- 档案室 / Challenge Archive 气质图：3 张

### 建议保存位置

- 工作中间稿：项目外部参考目录
- 入选稿：`assets/sprites/ui/backgrounds/`

### 示例提示词

#### A1 主菜单

```text
dark fantasy title background for a top-down 2D action roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

#### A2 安全营地

```text
top-down dark fantasy safe camp, survivors resting inside a ruined chapel courtyard, candles, relic forge, memory altar, archive table, broken angel carvings, warm sanctuary light against surrounding darkness, sacred refuge after battle, stylized game environment concept, clear gameplay landmarks, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

#### A3 记忆祭坛

```text
memory altar in a fallen angel world, ancient altar of glowing memory shards, soft holy light mixed with melancholy blue haze, floating fragments, engraved runes, sacred archive mood, dark fantasy, top-down 2D game environment concept, readable central interaction point, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## Batch B：UI 风格系统

### 目标

先做 UI 的风格统一，不直接追求最终排版，而是先锁组件气质。

### 建议产量

- UI 风格板：2 套
- 通用按钮组：2 套
- 面板 / 边框组：2 套
- 卡片 / 徽记组：2 套

### 建议保存位置

- `assets/sprites/ui/panels/`
- `assets/sprites/ui/frames/`
- `assets/sprites/ui/cards/`
- `assets/sprites/ui/badges/`

### 示例提示词

#### B1 UI 总风格板

```text
dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, fantasy HUD and menu components, buttons cards tabs modal panels, cohesive design system, no text, no watermark, functional game UI, readable hierarchy, clean framing, consistent style
```

#### B2 奖励卡片

```text
reward card designs for a dark fantasy game UI, fallen angel theme, archive reward presentation, aged metal frame, dark stone base, soft holy glow, readable hierarchy, restrained ornament, multiple card states, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

## Batch C：通用图标集

### 目标

优先生成信息架构稳定、可长期复用的图标。

### 建议图标题材

- route
- redeem
- fall
- balance
- memory shard
- hidden layer
- challenge layer
- forge
- archive
- relic
- meta reward
- insight
- sigil

### 建议保存位置

- `assets/sprites/ui/icons/`

### 示例提示词

```text
dark fantasy game icon set, fallen angel theme, memory shard, holy relic, void sigil, archive seal, challenge badge, forge ember, route marker, redemption icon, fall icon, balance icon, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

## Batch D：章节背景与档案空间

### 目标

补游戏稳定场所的正式背景图或背景概念。

### 建议产量

- 主菜单：2 张
- Ending Archive：2 张
- Hidden Layer Track：2 张
- Challenge Archive：2 张

### 建议保存位置

- `assets/sprites/ui/backgrounds/`

### 示例提示词

#### D1 Hidden Layer Track

```text
dark fantasy archive chamber for hidden layer tracking, fallen angel world, forbidden records, sealed relic shelves, broken halo motifs, sacred ruin library atmosphere, elegant but mournful, designed as a readable game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

#### D2 Challenge Archive

```text
forbidden challenge archive hall, dark fantasy sacred bureaucracy, ritual records, sealed gates, stone circles, dim holy light, austere and oppressive, designed as a readable game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## Batch E：隐藏层 / 挑战层概念图

### 目标

先做场景级概念，不直接做最终运行时拼图。

### 建议保存位置

- 参考图可先外部保存
- 入选稿可同步到 `assets/sprites/ui/backgrounds/` 或 `assets/sprites/tiles/`

### 示例提示词

#### E1 FS1

```text
dark fantasy hidden layer, time rift beneath a ruined choir crypt, fractured time shards, ghostly hymn echoes, broken clock motifs, frozen choir hall, sacred ruins distorted by temporal anomalies, top-down 2D game environment concept, eerie but elegant, strong navigational silhouettes, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

#### E2 FS2

```text
dark fantasy hidden layer, genesis forge deep inside a divine ruin, ancient celestial forge, molten metal, sacred machinery, chained relic cores, ember sparks and holy fire, creation and corruption intertwined, top-down 2D game environment concept, heavy industrial cathedral mood, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

#### E3 CL1

```text
endgame challenge layer environment, forbidden archive arena, sealed records, ritual gates, glowing archive sigils, austere stone circles, sacred bureaucracy turned into combat trial, dark fantasy, top-down 2D game arena concept, clean combat readability, minimal clutter, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## Batch F：通用 VFX 草图

### 目标

先产出可供后续像素化或手工重绘的 VFX 参考。

### 建议题材

- 圣辉闪烁
- 堕落羽毛
- 记忆碎片漂浮
- 解锁闪光
- 档案封印破裂
- 虚空裂隙

### 建议保存位置

- 概念参考：`assets/sprites/effects/`

### 示例提示词

```text
dark fantasy VFX sheet concepts, holy glow, fallen feathers, floating memory shards, archive seal breaking, void crack energy, forge sparks, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, consistent style
```

## Batch G：音频提示词母版

### 目标

Gemini 不负责最终音频母带，但可以先统一写出音频提示词母版，再交给专门音频工具生成。

### 建议保存位置

- 最终音频成品：
  - `assets/audio/bgm/`
  - `assets/audio/ambience/`
  - `assets/audio/sfx/`

### 音频提示词模板

#### G1 主菜单 BGM

```text
dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells, slow strings, sacred ruin atmosphere, melancholic but grand, loopable game soundtrack, no sudden climax, no lyrical vocal
```

#### G2 安全营地 BGM

```text
warm sanctuary music inside a ruined holy camp, soft choir, light harp, low strings, fragile hope after battle, dark fantasy but comforting, loopable background music, no lyrical vocal
```

#### G3 记忆祭坛 BGM

```text
mystical memory altar ambience, suspended piano notes, ethereal choir, glass harmonics, sacred and nostalgic mood, dark fantasy, loopable, introspective, no lyrical vocal
```

#### G4 FS1 氛围

```text
time-rift choir crypt ambience, reversed choir fragments, cold drones, distant ticking, sacred decay, eerie temporal instability, dark fantasy game background loop, no lyrical vocal
```

#### G5 FS2 氛围

```text
celestial forge ambience, low industrial resonance, glowing furnace pulse, metallic ritual percussion, holy fire, creation and corruption, dark fantasy loopable game music, no lyrical vocal
```

#### G6 CL1 氛围

```text
forbidden archive challenge theme, tense ritual percussion, restrained choir, sealed-record atmosphere, austere and oppressive, dark fantasy loopable combat music, no lyrical vocal
```

## 5. 每批产出后的筛选标准

每次批量生成后，按以下标准筛选：

- 是否仍然是同一个世界观，而不是“另一款奇幻游戏”
- 是否保留 `fallen angel / sacred ruins / forbidden archive / memory fragments` 的母题
- 是否有足够可读性
- 是否适合转成 UI / tile / 像素 / 游戏背景
- 是否避免了过度写实、过度赛博、过度高饱和

## 6. 推荐批量执行顺序

1. 先跑 Batch A，选出风格锚点
2. 再跑 Batch B 和 Batch C，锁 UI 语言
3. 然后跑 Batch D 和 Batch E，补背景与场景方向
4. 再跑 Batch F，建立通用 VFX 参考
5. 最后用 Batch G 为音频工具统一生成提示词

## 7. 命名与落盘建议

### UI

- `ui_icon_memory_shard_v1.png`
- `ui_icon_archive_seal_v1.png`
- `ui_panel_archive_frame_v1.png`
- `ui_bg_hidden_track_v1.png`

### 背景 / 场景

- `bg_main_menu_ruined_halo_v1.png`
- `bg_safe_camp_last_fire_v1.png`
- `bg_memory_altar_echoes_v1.png`
- `bg_challenge_archive_v1.png`

### VFX

- `fx_memory_shard_glow_v1.png`
- `fx_archive_seal_break_v1.png`
- `fx_fallen_feather_v1.png`

### 音频成品

- `bgm_main_menu_fallen_sanctuary.ogg`
- `bgm_safe_camp_last_fire.ogg`
- `amb_memory_altar_echoes.ogg`
- `sfx_ui_confirm_01.wav`

## 8. 当前结论

- Gemini 最适合承担批量风格统一、提示词母版和概念图初稿的职责。
- 若目标是“风格统一”，必须先跑世界观锚点批次，再做其他批次扩展。
- `Stage 7` 的可单独开发资产，已经可以按本手册直接分批推进。
