# Stage 7 首批 Gemini 生成任务清单（2026-03-24）

## 1. 目的

本文档把 `Stage 7` 当前最适合立即启动的 Gemini 生成任务拆成首批可执行清单，方便直接按批次投喂 AI 工具。

本批次遵循两个原则：

- 先做低耦合、可复用、风格统一价值最高的资产。
- 不在本批次中直接定稿高返工风险的结局演出、隐藏层最终包装、挑战层最终专属表现。

关联文档：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-batch-production-manual-2026-03-24.md`

## 2. 本批次目标

首批目标是一次性产出以下 4 类资产的候选稿：

1. 世界观与菜单级背景锚点
2. UI 设计系统锚点
3. 通用图标集锚点
4. 音频提示词母版

这些产物的作用不是立刻全部进游戏，而是先锁定项目统一风格，再决定后续扩展批次。

## 3. 执行前统一参数

### 3.1 固定世界观关键词

所有视觉任务都应长期保留以下关键词：

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

### 3.3 视觉统一追加词

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### 3.4 本批次筛选规则

每个小任务建议至少生成 `3` 张，按以下规则筛选：

- 选 `1` 张主选图
- 选 `1` 张备选图
- 淘汰所有偏离项目气质的图

主选图需要满足：

- 一眼看出属于同一个世界
- 可读性足够
- 可以被继续扩展为 UI / 背景 / 图标 / 音频方向锚点

## 4. 首批任务总表

| 批次 | 任务 | 建议数量 | 输出去向 |
|---|---|---:|---|
| A1 | 主菜单背景锚点 | 3 | `assets/sprites/ui/backgrounds/` |
| A2 | 安全营地背景锚点 | 3 | `assets/sprites/ui/backgrounds/` |
| A3 | 记忆祭坛背景锚点 | 3 | `assets/sprites/ui/backgrounds/` |
| A4 | 档案/挑战档案背景锚点 | 3 | `assets/sprites/ui/backgrounds/` |
| B1 | UI 总风格板 | 3 | `assets/sprites/ui/panels/` |
| B2 | 奖励卡片风格板 | 3 | `assets/sprites/ui/cards/` |
| B3 | 通用边框/面板风格板 | 3 | `assets/sprites/ui/frames/` |
| C1 | 通用图标组：路线/结局 | 3 | `assets/sprites/ui/icons/` |
| C2 | 通用图标组：记忆/档案/隐藏层/挑战层 | 3 | `assets/sprites/ui/icons/` |
| G1 | 主菜单/营地/祭坛音频提示词母版 | 3 套 | `assets/audio/bgm/`、`assets/audio/ambience/` |
| G2 | UI/解锁/奖励音效提示词母版 | 3 套 | `assets/audio/sfx/` |

## 5. 详细任务卡

### A1 主菜单背景锚点

- 目标：锁定全项目视觉第一印象
- 建议输出路径：`assets/sprites/ui/backgrounds/`
- 建议文件名：`ui_bg_main_menu_ruined_halo_v1.png`

提示词：

```text
dark fantasy title background for a top-down 2D action roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A2 安全营地背景锚点

- 目标：锁定中场休整空间的温度与神圣残败感
- 建议输出路径：`assets/sprites/ui/backgrounds/`
- 建议文件名：`ui_bg_safe_camp_last_fire_v1.png`

提示词：

```text
top-down dark fantasy safe camp, survivors resting inside a ruined chapel courtyard, candles, relic forge, memory altar, archive table, broken angel carvings, warm sanctuary light against surrounding darkness, sacred refuge after battle, stylized game environment concept, clear gameplay landmarks, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A3 记忆祭坛背景锚点

- 目标：锁定记忆、回看、碎片解读的主视觉
- 建议输出路径：`assets/sprites/ui/backgrounds/`
- 建议文件名：`ui_bg_memory_altar_echoes_v1.png`

提示词：

```text
memory altar in a fallen angel world, ancient altar of glowing memory shards, soft holy light mixed with melancholy blue haze, floating fragments, engraved runes, sacred archive mood, dark fantasy, top-down 2D game environment concept, readable central interaction point, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A4 档案 / 挑战档案背景锚点

- 目标：锁定档案系统与挑战归档空间的共通气质
- 建议输出路径：`assets/sprites/ui/backgrounds/`
- 建议文件名：`ui_bg_challenge_archive_v1.png`

提示词：

```text
forbidden challenge archive hall, dark fantasy sacred bureaucracy, ritual records, sealed gates, stone circles, dim holy light, austere and oppressive, designed as a readable game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### B1 UI 总风格板

- 目标：统一面板、按钮、页签、标题装饰语言
- 建议输出路径：`assets/sprites/ui/panels/`
- 建议文件名：`ui_style_board_cathedral_relic_v1.png`

提示词：

```text
dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, fantasy HUD and menu components, buttons cards tabs modal panels, cohesive design system, no text, no watermark, functional game UI, readable hierarchy, clean framing, consistent style
```

### B2 奖励卡片风格板

- 目标：统一 run result、奖励选择、档案卡片的视觉语言
- 建议输出路径：`assets/sprites/ui/cards/`
- 建议文件名：`ui_card_reward_archive_v1.png`

提示词：

```text
reward card designs for a dark fantasy game UI, fallen angel theme, archive reward presentation, aged metal frame, dark stone base, soft holy glow, readable hierarchy, restrained ornament, multiple card states, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

### B3 通用边框 / 面板风格板

- 目标：统一档案页、记忆祭坛、隐藏层追踪、挑战层摘要的边框语言
- 建议输出路径：`assets/sprites/ui/frames/`
- 建议文件名：`ui_frame_archive_relic_v1.png`

提示词：

```text
dark fantasy ornamental UI frames, archive and relic theme, cathedral-inspired border system, aged silver metal, cracked stone, subtle holy glow, restrained decoration, usable for menu panels and codex pages, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

### C1 通用图标组：路线 / 结局

- 目标：统一 `redeem / fall / balance / route` 四类图标
- 建议输出路径：`assets/sprites/ui/icons/`
- 建议文件名：`ui_icon_route_outcomes_sheet_v1.png`

提示词：

```text
dark fantasy game icon set, fallen angel theme, route marker, redemption icon, fall icon, balance icon, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

### C2 通用图标组：记忆 / 档案 / 隐藏层 / 挑战层

- 目标：统一系统层图标
- 建议输出路径：`assets/sprites/ui/icons/`
- 建议文件名：`ui_icon_archive_systems_sheet_v1.png`

提示词：

```text
dark fantasy game icon set, fallen angel theme, memory shard, archive seal, hidden layer icon, challenge badge, forge ember, relic symbol, void sigil, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

### G1 主菜单 / 营地 / 祭坛音频提示词母版

- 目标：统一三类核心非战斗 BGM 方向
- 建议保存位置：`assets/audio/bgm/`、`assets/audio/ambience/`
- 建议文件名：先记录在人工清单，最终成品再按音频命名规范落盘

建议母版：

```text
dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells, slow strings, sacred ruin atmosphere, melancholic but grand, loopable game soundtrack, no sudden climax, no lyrical vocal
```

```text
warm sanctuary music inside a ruined holy camp, soft choir, light harp, low strings, fragile hope after battle, dark fantasy but comforting, loopable background music, no lyrical vocal
```

```text
mystical memory altar ambience, suspended piano notes, ethereal choir, glass harmonics, sacred and nostalgic mood, dark fantasy, loopable, introspective, no lyrical vocal
```

### G2 UI / 解锁 / 奖励音效提示词母版

- 目标：统一短音效音色方向
- 建议保存位置：`assets/audio/sfx/`

建议母版：

```text
short game ui stinger, holy relic activation, dark fantasy, bright metallic shimmer with ancient rune pulse, under 1 second
```

```text
reward claim stinger, sacred archive unlock, dark fantasy, elegant metallic resonance, subtle choir sparkle, under 1.5 seconds
```

```text
hidden layer unlock sound, forbidden archive seal opening, dark fantasy, restrained impact, low ritual resonance, under 2 seconds
```

## 6. 推荐执行顺序

### 第 1 天

- 跑 `A1`、`A2`、`A3`
- 从中选出 3 张风格锚点图

### 第 2 天

- 跑 `A4`、`B1`、`B2`、`B3`
- 先锁 UI 与档案空间语言

### 第 3 天

- 跑 `C1`、`C2`
- 同时整理图标拆分与命名

### 第 4 天

- 用 Gemini 生成 `G1`、`G2` 音频提示词母版
- 再交给专门音频工具继续产出

## 7. 本批次完成标准

- 至少获得 3 张稳定世界观锚点图
- 至少获得 1 套可继续扩展的 UI 风格板
- 至少获得 1 套可拆分的通用图标方向
- 至少获得 6 条可直接交给音频工具的提示词母版
- 所有入选结果都能映射到项目目录和命名规范

## 8. 当前不纳入首批的内容

以下内容暂不纳入本批次：

- `FS1/FS2` 完整关卡最终包装
- `CL1/CL2+` 最终专属演出
- 像素角色精灵表终稿
- 最终 tileset 切片定稿
- 三结局最终镜头表现

原因：这些内容对 `Stage 5/6` 最终信息结构和玩法节奏仍有较高依赖。
