# Stage 7 Gemini 可复制提示词包（2026-03-24）

## 1. 目的

本文档在以下文档基础上继续下钻：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-batch-production-manual-2026-03-24.md`
- `spec-design/stage7-gemini-first-batch-task-list-2026-03-24.md`

目标不是再讲原则，而是提供可以直接复制到 Gemini 的首批提示词包，减少临场改写成本，并确保首批产出继续服从统一世界观。

## 2. 固定使用规则

### 2.1 固定世界观锚词

以下词组建议长期保留，不要在单次任务里随意删空：

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

### 2.2 固定负面词

```text
blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
```

### 2.3 统一追加尾词

视觉任务统一补：

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

UI 任务再补：

```text
functional game UI, readable hierarchy, clean framing, transparent background when applicable
```

## 3. 推荐投喂模板

建议每次都按这个结构投喂，避免 Gemini 输出方向飘散：

```text
你现在是《堕落天使》的视觉概念设计师，请严格保持同一世界观。

任务类型：<填写任务名>
目标用途：<填写用途>
输出数量：3
必须保留元素：<填写>
禁止出现元素：<填写>

风格锚词：dark fantasy, fallen angel, sacred ruins, broken halo, memory fragments, forbidden archive, divine decay, solemn and tragic, high readability, game asset
负面词：blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
统一尾词：no text, no watermark, clear silhouette, production-ready game concept, consistent style

请直接输出可用于游戏资产筛选的图像结果。
```

## 4. 首批背景提示词包

### A1 主菜单背景

用途：`assets/sprites/ui/backgrounds/ui_bg_main_menu_ruined_halo_v1.png`

基础版：

```text
dark fantasy title background for a top-down 2D action roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏神圣废墟版：

```text
dark fantasy main menu background, fallen angel world, abandoned cathedral plaza, giant broken halo relic, fallen angel statue fragments, cold moonlight through shattered stained glass, faded gold and cold stone palette, solemn and tragic, sacred ruins with divine decay, readable center space for title and menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏深渊侵蚀版：

```text
top-down dark fantasy title screen background, fallen angel theme, ruined sanctuary overtaken by abyss corruption, broken halo monument, black ash, cracked marble, dim sacred light struggling against void haze, tragic and restrained mood, strong composition for menu readability, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A2 安全营地背景

用途：`assets/sprites/ui/backgrounds/ui_bg_safe_camp_last_fire_v1.png`

基础版：

```text
top-down dark fantasy safe camp, survivors resting inside a ruined chapel courtyard, candles, relic forge, memory altar, archive table, broken angel carvings, warm sanctuary light against surrounding darkness, sacred refuge after battle, stylized game environment concept, clear gameplay landmarks, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏疗愈版：

```text
dark fantasy safe camp environment, ruined holy courtyard used as a fragile sanctuary, warm firelight, candles, relic workbench, archive desk, memory altar, broken halo motifs, survivors' refuge after battle, sacred but exhausted mood, readable gameplay landmarks, top-down 2D game environment concept, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏营地功能分区版：

```text
top-down safe camp in a fallen angel world, ruined chapel camp with clear zones for forge, archive table, memory altar, rest fire, and relic storage, warm lights inside cold sacred ruins, solemn but hopeful, dark fantasy game environment concept, readable interaction landmarks, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A3 记忆祭坛背景

用途：`assets/sprites/ui/backgrounds/ui_bg_memory_altar_echoes_v1.png`

基础版：

```text
memory altar in a fallen angel world, ancient altar of glowing memory shards, soft holy light mixed with melancholy blue haze, floating fragments, engraved runes, sacred archive mood, dark fantasy, top-down 2D game environment concept, readable central interaction point, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏碎片漂浮版：

```text
dark fantasy memory altar, floating memory shards orbiting a broken halo altar, engraved stone, soft pale gold and blue glow, sacred ruins mixed with nostalgia and sorrow, fallen angel world, readable center interaction point, top-down game background concept, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏档案感版：

```text
ancient memory altar inside a forbidden archive sanctuary, glowing fragments, sealed books, rune-etched pedestal, blue haze and faded holy light, solemn and tragic dark fantasy atmosphere, top-down 2D game environment concept, readable central interaction space, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### A4 档案 / 挑战档案背景

用途：`assets/sprites/ui/backgrounds/ui_bg_challenge_archive_v1.png`

基础版：

```text
forbidden challenge archive hall, dark fantasy sacred bureaucracy, ritual records, sealed gates, stone circles, dim holy light, austere and oppressive, designed as a readable game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏隐藏档案室版：

```text
dark fantasy archive chamber, fallen angel world, sealed records, relic shelves, broken halo motifs, forbidden archive atmosphere, sacred ruins turned into a record hall, mournful and restrained, readable as a game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

偏挑战归档版：

```text
endgame challenge archive background, ritual gates, sealed challenge ledgers, austere stone circle, glowing archive sigils, sacred bureaucracy turned into combat record system, dark fantasy, oppressive but readable menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## 5. 首批 UI 提示词包

### B1 UI 总风格板

用途：`assets/sprites/ui/panels/ui_style_board_cathedral_relic_v1.png`

基础版：

```text
dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, fantasy HUD and menu components, buttons cards tabs modal panels, cohesive design system, no text, no watermark, functional game UI, readable hierarchy, clean framing, consistent style
```

偏菜单系统版：

```text
dark fantasy menu UI style board, fallen angel theme, archive-inspired interface, aged silver, cracked black stone, faded holy gold, broken halo motifs, readable buttons panels tabs and headings, restrained ornament, clear information hierarchy, no text, no watermark, functional game UI, clean framing, consistent style
```

偏 HUD 兼容版：

```text
dark fantasy interface style board for HUD and menu, sacred ruins material language, archive relic motifs, readable health bars, reward cards, tabs, side panels, title ornaments, elegant but restrained, high readability, no text, no watermark, functional game UI, clean framing, consistent style
```

### B2 奖励卡片风格板

用途：`assets/sprites/ui/cards/ui_card_reward_archive_v1.png`

基础版：

```text
reward card designs for a dark fantasy game UI, fallen angel theme, archive reward presentation, aged metal frame, dark stone base, soft holy glow, readable hierarchy, restrained ornament, multiple card states, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

偏挑战奖励版：

```text
dark fantasy reward cards for archive and challenge systems, relic-like frame, sealed record motif, faded gold edge, dark stone base, readable icon area, title area, detail area, restrained sacred glow, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

偏结算面板版：

```text
run result reward card set, dark fantasy fallen angel theme, archive ledger presentation, elegant layered frame, readable rarity and reward zones, restrained detail, suitable for reward choice and recap screens, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

### B3 通用边框 / 面板风格板

用途：`assets/sprites/ui/frames/ui_frame_archive_relic_v1.png`

基础版：

```text
dark fantasy ornamental UI frames, archive and relic theme, cathedral-inspired border system, aged silver metal, cracked stone, subtle holy glow, restrained decoration, usable for menu panels and codex pages, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

偏档案页版：

```text
dark fantasy codex and archive page frames, broken halo ornaments, sealed corner details, faded gold trim over black stone, elegant but restrained, highly readable inner content area, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

偏祭坛 / 隐藏层追踪版：

```text
ornamental dark fantasy UI frame system for memory altar and hidden layer track, sacred ruins, relic seals, archive metalwork, readable large content windows and title bars, restrained glow accents, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

## 6. 首批图标提示词包

### C1 路线 / 结局图标组

用途：`assets/sprites/ui/icons/ui_icon_route_outcomes_sheet_v1.png`

基础版：

```text
dark fantasy game icon set, fallen angel theme, route marker, redemption icon, fall icon, balance icon, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

扩展版：

```text
dark fantasy route and ending icon sheet, redemption, fall, balance, chapter route marker, sacred relic symbols, broken halo language, high contrast silhouettes, elegant line weight, transparent background, no text, no watermark, functional game UI, consistent style
```

### C2 记忆 / 档案 / 隐藏层 / 挑战层图标组

用途：`assets/sprites/ui/icons/ui_icon_archive_systems_sheet_v1.png`

基础版：

```text
dark fantasy game icon set, fallen angel theme, memory shard, archive seal, hidden layer icon, challenge badge, forge ember, relic symbol, void sigil, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

扩展版：

```text
system icons for a dark fantasy fallen angel game, memory fragment, archive ledger, hidden layer gate, challenge archive badge, forge spark, relic token, void sigil, holy shard, clear silhouette, high contrast, consistent stroke language, transparent background, no text, no watermark, functional game UI, consistent style
```

## 7. 首批音频提示词包

### G1 主菜单 / 营地 / 祭坛

主菜单：

```text
dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells, slow strings, sacred ruin atmosphere, melancholic but grand, loopable game soundtrack, no sudden climax, no lyrical vocal
```

安全营地：

```text
warm sanctuary music inside a ruined holy camp, soft choir, light harp, low strings, fragile hope after battle, dark fantasy but comforting, loopable background music, no lyrical vocal
```

记忆祭坛：

```text
mystical memory altar ambience, suspended piano notes, ethereal choir, glass harmonics, sacred and nostalgic mood, dark fantasy, loopable, introspective, no lyrical vocal
```

### G2 UI / 解锁 / 奖励短音效

UI 确认：

```text
short game ui stinger, holy relic activation, dark fantasy, bright metallic shimmer with ancient rune pulse, under 1 second
```

奖励领取：

```text
reward claim stinger, sacred archive unlock, dark fantasy, elegant metallic resonance, subtle choir sparkle, under 1.5 seconds
```

隐藏层解锁：

```text
hidden layer unlock sound, forbidden archive seal opening, dark fantasy, restrained impact, low ritual resonance, under 2 seconds
```

挑战层解锁：

```text
challenge layer unlock stinger, sealed archive gate opening, austere ritual tone, dark fantasy, metallic stone resonance, restrained sacred tension, under 2 seconds
```

## 8. 推荐筛选口径

筛图时优先保留：

- 能一眼看出 `fallen angel + sacred ruins + forbidden archive` 母题的结果。
- 中心构图清晰、能承载菜单或交互区覆盖层的结果。
- UI 和图标里轮廓最明确、最容易二次切图的结果。
- 能继续外推出同风格后续批次的结果。

优先淘汰：

- 过度写实、像宣传海报而不像游戏资产的结果。
- 高饱和紫黑泛滥、偏通用奇幻模板的结果。
- 画面信息过满、中心交互区不清晰的结果。
- 图标边缘发糊、内部结构过细、不适合缩小使用的结果。

## 9. 建议执行方式

1. 先跑 `A1-A4`，选出世界观锚点。
2. 再跑 `B1-B3`，锁 UI 材质与边框语言。
3. 再跑 `C1-C2`，统一系统层图标语义。
4. 最后整理 `G1-G2` 到单独音频生成工具。
5. 所有入选图建议先按本文档命名落到目标目录，再开始二次拆图或重绘。

## 10. 当前结论

- 现有三份 Stage 7 文档已经完成“规范、手册、任务拆分”。
- 本文档补齐了“可直接复制执行”的最后一层。
- 下一步若继续推进，最自然的是为 `assets/sprites/ui/backgrounds/`、`assets/sprites/ui/icons/`、`assets/audio/` 等目录补目录级 README，明确收稿标准与命名落盘方式。
