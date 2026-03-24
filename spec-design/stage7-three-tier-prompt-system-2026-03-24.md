# Stage 7 三档提示词总表（2026-03-24）

## 1. 目的

本文档把 `Stage 7` 资产统一整理为三档提示词体系：

- 完整版
- 标准版
- 超短版

适用目标：

- 在不丢失世界观统一性的前提下，提高 Gemini 批量生产效率
- 让不同阶段的资产生成使用不同长度的提示词
- 覆盖当前 `Stage 7` 的主要资产类别

关联文档：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-batch-production-manual-2026-03-24.md`
- `spec-design/stage7-gemini-copyable-prompt-pack-2026-03-24.md`
- `spec-design/stage7-gemini-effects-fonts-shaders-prompt-pack-2026-03-24.md`
- `spec-design/stage7-character-enemy-weapon-asset-strategy-2026-03-24.md`

## 2. 三档使用原则

### 2.1 完整版

适用：

- 第一次定风格
- 世界观锚点图
- 重要界面主视觉
- 风格明显容易漂的任务

特点：

- 信息最完整
- 世界观最稳
- 适合首轮筛选主选图

### 2.2 标准版

适用：

- 锚点已确定后的常规生产
- 同系列扩产
- 中等复杂度任务

特点：

- 保留关键世界观和功能约束
- 长度适中
- 稳定性和效率平衡最好

### 2.3 超短版

适用：

- 已锁定风格后的批量扩产
- 同系列变体补图
- 快速测试方向

特点：

- 效率最高
- 漂移风险最高
- 产出不稳时应立刻回退到标准版或完整版

## 3. 固定锚词与负面词

### 3.1 固定世界观锚词

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

### 3.3 统一视觉尾词

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### 3.4 UI 追加尾词

```text
functional game UI, readable hierarchy, clean framing, transparent background when applicable
```

## 4. 背景与空间类

### 4.1 主菜单背景

用途：`assets/sprites/ui/backgrounds/`

完整版：

```text
dark fantasy title background for a top-down 2D action roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy main menu background, fallen angel world, ruined sanctuary, broken halo relic, cracked stained glass, ash, solemn and tragic atmosphere, readable center space for menu overlay, game background art, no text, no watermark, clear silhouette, consistent style
```

超短版：

```text
fallen angel dark fantasy main menu background, ruined sanctuary, broken halo, ash, readable center, consistent style
```

### 4.2 安全营地背景

用途：`assets/sprites/ui/backgrounds/`

完整版：

```text
top-down dark fantasy safe camp, survivors resting inside a ruined chapel courtyard, candles, relic forge, memory altar, archive table, broken angel carvings, warm sanctuary light against surrounding darkness, sacred refuge after battle, stylized game environment concept, clear gameplay landmarks, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy safe camp in ruined holy courtyard, candles, forge, memory altar, archive desk, warm refuge light inside sacred ruins, readable gameplay landmarks, no text, no watermark, clear silhouette, consistent style
```

超短版：

```text
fallen angel safe camp, ruined chapel courtyard, candles, forge, altar, warm refuge light, readable layout
```

### 4.3 记忆祭坛背景

用途：`assets/sprites/ui/backgrounds/`

完整版：

```text
memory altar in a fallen angel world, ancient altar of glowing memory shards, soft holy light mixed with melancholy blue haze, floating fragments, engraved runes, sacred archive mood, dark fantasy, top-down 2D game environment concept, readable central interaction point, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy memory altar, glowing memory shards, pale gold and blue haze, engraved runes, sacred archive atmosphere, readable center interaction point, no text, no watermark, clear silhouette, consistent style
```

超短版：

```text
fallen angel memory altar, glowing shards, blue gold haze, sacred archive mood, readable center
```

### 4.4 档案室 / Hidden Layer Track / Challenge Archive 背景

用途：`assets/sprites/ui/backgrounds/`

完整版：

```text
forbidden archive hall in a fallen angel world, sealed records, ritual gates, relic shelves, broken halo motifs, sacred bureaucracy and sacred ruins mixed together, austere and oppressive, designed as a readable game menu background, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy archive chamber, sealed records, ritual gates, broken halo motifs, forbidden archive atmosphere, readable menu background, no text, no watermark, clear silhouette, consistent style
```

超短版：

```text
forbidden archive background, sealed records, ritual gate, broken halo, readable menu space
```

### 4.5 通用章节氛围图

用途：`assets/sprites/ui/backgrounds/` 或 `assets/sprites/tiles/`

完整版：

```text
dark fantasy chapter environment concept, fallen angel world, sacred ruins in decay, broken holy architecture, chapter-specific atmosphere, readable layout for later top-down adaptation, restrained palette, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy chapter environment concept, sacred ruins, broken holy architecture, readable top-down adaptation, restrained palette, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy chapter environment, sacred ruins, broken holy architecture, top-down readable
```

## 5. UI 系统类

### 5.1 UI 总风格板

用途：`assets/sprites/ui/panels/`

完整版：

```text
dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, fantasy HUD and menu components, buttons cards tabs modal panels, cohesive design system, no text, no watermark, functional game UI, readable hierarchy, clean framing, consistent style
```

标准版：

```text
dark fantasy UI style board, aged silver, black stone, faded gold trim, sacred runes, relic panels, readable buttons tabs cards and frames, no text, no watermark, functional game UI, consistent style
```

超短版：

```text
fallen angel dark fantasy UI kit, aged silver, black stone, faded gold, relic panels, readable game UI
```

### 5.2 面板 / 边框

用途：`assets/sprites/ui/panels/`、`assets/sprites/ui/frames/`

完整版：

```text
dark fantasy ornamental UI frames and panels, archive and relic theme, cathedral-inspired border system, aged silver metal, cracked stone, subtle holy glow, restrained decoration, usable for menu panels and codex pages, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

标准版：

```text
dark fantasy UI frames and panels, archive relic theme, aged silver, cracked stone, subtle holy glow, readable content area, no text, no watermark, transparent background, functional game UI, consistent style
```

超短版：

```text
dark fantasy UI frame, archive relic style, aged silver, cracked stone, readable content area
```

### 5.3 奖励卡 / 档案卡

用途：`assets/sprites/ui/cards/`

完整版：

```text
reward card designs for a dark fantasy game UI, fallen angel theme, archive reward presentation, aged metal frame, dark stone base, soft holy glow, readable hierarchy, restrained ornament, multiple card states, no text, no watermark, transparent background when applicable, functional game UI, consistent style
```

标准版：

```text
dark fantasy reward card set, archive presentation, aged frame, dark stone base, readable icon title and detail areas, no text, no watermark, transparent background, functional game UI, consistent style
```

超短版：

```text
dark fantasy reward cards, archive style, aged frame, readable icon and detail layout
```

### 5.4 状态徽记 / badges

用途：`assets/sprites/ui/badges/`

完整版：

```text
dark fantasy UI badge set, fallen angel theme, archive seals, holy marks, hidden layer and challenge layer status badges, restrained ornament, high contrast, readable small-size silhouettes, transparent background, no text, no watermark, functional game UI, consistent style
```

标准版：

```text
dark fantasy UI badges, archive seals, holy marks, challenge and hidden layer badges, readable small silhouettes, transparent background, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy UI badges, archive seals, challenge badges, readable small icons
```

### 5.5 图标系统

用途：`assets/sprites/ui/icons/`

完整版：

```text
dark fantasy game icon set, fallen angel theme, route marker, redemption icon, fall icon, balance icon, memory shard, archive seal, hidden layer icon, challenge badge, forge ember, relic symbol, void sigil, clean silhouette, high contrast, consistent line weight, transparent background, no text, no watermark, functional game UI, readable hierarchy, consistent style
```

标准版：

```text
dark fantasy icon set, route, ending, memory shard, archive seal, hidden layer, challenge badge, forge ember, clean silhouette, high contrast, transparent background, no text, no watermark, functional game UI, consistent style
```

超短版：

```text
fallen angel dark fantasy icon set, route, memory shard, archive seal, challenge badge, high contrast
```

## 6. 音频类

### 6.1 主菜单 BGM

用途：`assets/audio/bgm/`

完整版：

```text
dark fantasy menu theme, fallen angel tragedy, solemn choir textures, distant bells, slow strings, sacred ruin atmosphere, melancholic but grand, loopable game soundtrack, no sudden climax, no lyrical vocal
```

标准版：

```text
dark fantasy menu music, solemn choir, distant bells, slow strings, sacred ruin mood, melancholic and loopable, no lyrical vocal
```

超短版：

```text
dark fantasy menu theme, solemn choir, bells, slow strings, loopable
```

### 6.2 安全营地 BGM

用途：`assets/audio/bgm/`

完整版：

```text
warm sanctuary music inside a ruined holy camp, soft choir, light harp, low strings, fragile hope after battle, dark fantasy but comforting, loopable background music, no lyrical vocal
```

标准版：

```text
dark fantasy safe camp music, soft choir, light harp, low strings, warm refuge after battle, loopable, no lyrical vocal
```

超短版：

```text
safe camp dark fantasy music, soft choir, harp, warm refuge, loopable
```

### 6.3 记忆祭坛 BGM / ambience

用途：`assets/audio/bgm/`、`assets/audio/ambience/`

完整版：

```text
mystical memory altar ambience, suspended piano notes, ethereal choir, glass harmonics, sacred and nostalgic mood, dark fantasy, loopable, introspective, no lyrical vocal
```

标准版：

```text
memory altar ambience, suspended piano, ethereal choir, glass harmonics, sacred nostalgic mood, loopable, no lyrical vocal
```

超短版：

```text
memory altar ambience, piano, ethereal choir, sacred nostalgic, loopable
```

### 6.4 环境音 / challenge cue / UI SFX

用途：`assets/audio/ambience/`、`assets/audio/sfx/`

完整版：

```text
dark fantasy game sound design pack, archive ambience, sanctuary ambience, ritual gate cue, challenge cue, UI confirm, reward claim, unlock stinger, restrained sacred metallic resonance, short readable game sounds, no lyrical vocal
```

标准版：

```text
dark fantasy sound pack, archive ambience, challenge cue, UI confirm, reward claim, unlock stinger, sacred metallic resonance, readable game sounds
```

超短版：

```text
dark fantasy sound pack, archive ambience, challenge cue, UI confirm, reward unlock
```

## 7. 通用 VFX / Effects

### 7.1 通用 VFX 板

用途：`assets/sprites/effects/`

完整版：

```text
dark fantasy VFX concept sheet, fallen angel theme, holy glow, fallen feathers, floating memory shards, archive seal breaking, void crack energy, forge sparks, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy VFX concept sheet, holy glow, fallen feathers, memory shards, archive seal break, void crack, forge sparks, readable silhouettes, transparent background, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy VFX sheet, holy glow, feathers, shards, seal break, void crack, forge sparks
```

### 7.2 单项特效示例：记忆碎片

用途：`assets/sprites/effects/`

完整版：

```text
memory shard VFX concept sheet, dark fantasy fallen angel world, glowing blue memory fragments, pale gold rune dust, floating shard clusters, sacred archive atmosphere, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

标准版：

```text
dark fantasy memory shard effect, glowing blue fragments, pale gold rune dust, floating clusters, readable silhouettes, transparent background, no text, no watermark, consistent style
```

超短版：

```text
memory shard effect, blue glow, gold rune dust, floating fragments
```

## 8. 字体类

说明：字体类三档不是生成字体文件，而是生成 brief 的长短版本。

### 8.1 正文字体 brief

用途：`assets/fonts/`

完整版：

```text
你现在是《堕落天使》的字体系统设计顾问。请基于 dark fantasy、fallen angel、sacred ruins、forbidden archive、solemn and tragic 的世界观，给出一套适合 UI 正文的字体 brief。要求：中文和英文都要易读，适合菜单、HUD、档案说明、奖励明细；避免过度花哨；给出字体气质描述、适用场景、字重建议、字号建议、行距建议，以及应避免的风格。
```

标准版：

```text
请为《堕落天使》设计一套 UI 正文字体 brief，要求中英文易读，适合菜单、HUD、档案说明、奖励明细，风格为 dark fantasy、fallen angel、sacred ruins、solemn and tragic。请给出气质、字重、字号和应避免的问题。
```

超短版：

```text
为《堕落天使》写一份 UI 正文字体 brief，中英文易读，dark fantasy，适合菜单和档案
```

### 8.2 标题字体 brief

用途：`assets/fonts/`

完整版：

```text
你现在是《堕落天使》的标题字体设计顾问。请为主菜单标题、章节标题、结算标题、结局标题定义一套标题字体 brief。世界观关键词：dark fantasy, fallen angel, broken halo, sacred ruins, forbidden archive。要求：庄严、克制、略带神圣残败感；允许有装饰性，但不能难以阅读；请输出字体气质、笔画倾向、适合的标题层级、和正文搭配原则。
```

标准版：

```text
请为《堕落天使》写一份标题字体 brief，适用于主菜单、章节、结算和结局标题，风格庄严、克制、神圣残败感，需说明笔画倾向和与正文字体的搭配原则。
```

超短版：

```text
写一份《堕落天使》标题字体 brief，庄严克制，神圣残败感，可与正文搭配
```

## 9. Shaders 类

说明：shader 类三档也是 brief 长短版本，优先服务轻量通用 shader。

### 9.1 UI 微光 shader brief

用途：`assets/shaders/`

完整版：

```text
你现在是 Godot 4 shader 设计顾问，请为《堕落天使》设计一个轻量 UI 微光 shader brief。用途：按钮高亮、档案框边缘、奖励卡片强调。风格关键词：dark fantasy, fallen angel, sacred ruins, faded holy glow, restrained ornament。请输出：视觉目标、适用节点、建议参数、动画节奏建议、应避免的问题，以及是否适合写成 CanvasItem shader。
```

标准版：

```text
请为《堕落天使》写一个 Godot 4 UI 微光 shader brief，用于按钮高亮、档案框边缘、奖励卡片强调。要求轻量、可复用、风格克制，说明参数和动画节奏建议。
```

超短版：

```text
写一个《堕落天使》UI 微光 shader brief，Godot 4，轻量可复用，按钮和档案框可用
```

### 9.2 记忆碎片 / 封印 / 虚空裂隙 shader brief

用途：`assets/shaders/`

完整版：

```text
请为《堕落天使》设计一组 Godot 4 通用 shader brief，覆盖记忆碎片脉冲、档案封印波动、虚空裂隙扰动。要求：轻量、可复用、参数清晰、适合 UI 与世界物件复用，视觉上保持 dark fantasy、fallen angel、forbidden archive、restrained abyss corruption。
```

标准版：

```text
请为《堕落天使》写一组通用 shader brief，覆盖记忆脉冲、封印波动、虚空扰动，要求轻量可复用，并给出建议参数。
```

超短版：

```text
写一组《堕落天使》通用 shader brief：记忆脉冲、封印波动、虚空扰动，轻量可复用
```

## 10. Tiles / 环境装饰类

### 10.1 章节地砖与装饰

用途：`assets/sprites/tiles/`

完整版：

```text
pixel art top-down dungeon tileset, fallen angel dark fantasy, broken chapel stone floor, cracked marble, ash dust, faint holy glyphs, sacred ruins in decay, 16-color palette, seamless tile, game asset, clean grid alignment, no text, no watermark, clear silhouette, consistent style
```

标准版：

```text
pixel art dark fantasy tileset, broken chapel floor, cracked marble, ash dust, faint holy glyphs, seamless top-down tile, clean grid alignment, no text, no watermark, consistent style
```

超短版：

```text
pixel art dark fantasy floor tile, cracked chapel marble, ash dust, holy glyphs, seamless
```

### 10.2 门框 / 祭坛 / 书架 / 封印台装饰

用途：`assets/sprites/tiles/`

完整版：

```text
top-down dark fantasy environment prop sheet, sacred ruins, broken doors, altar, statue, bookshelf, sealed archive pedestal, readable silhouettes, suitable for later pixel art adaptation, game asset concept, no text, no watermark, consistent style
```

标准版：

```text
dark fantasy top-down prop sheet, broken doors, altar, statue, bookshelf, sealed pedestal, readable silhouettes, game asset concept, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy top-down prop sheet, broken door, altar, bookshelf, sealed pedestal
```

## 11. 角色 / 敌人 / 武器类

### 11.1 角色俯视角方向稿

用途：`assets/sprites/characters/`

完整版：

```text
top-down dark fantasy character concept for a fallen angel roguelike, sacred ruins survivor, broken halo motif, readable silhouette, clear class identity, restrained color palette, suitable for later pixel art adaptation, game asset concept, no text, no watermark, consistent style
```

标准版：

```text
top-down dark fantasy character concept, fallen angel survivor, broken halo motif, readable class silhouette, restrained palette, suitable for pixel art adaptation, no text, no watermark, consistent style
```

超短版：

```text
top-down fallen angel character concept, readable class silhouette, restrained palette
```

### 11.2 敌人族群方向稿

用途：`assets/sprites/enemies/`

完整版：

```text
dark fantasy enemy family concept sheet, fallen angel world, sacred ruins corrupted by abyss, multiple enemy silhouettes with clear hierarchy between normal enemy, elite enemy, and dangerous variant, readable top-down game asset concept, no text, no watermark, consistent style
```

标准版：

```text
dark fantasy enemy family concept, fallen angel world, sacred ruins corruption, clear hierarchy for normal enemy, elite enemy and dangerous variant, readable top-down silhouettes, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy enemy family sheet, top-down silhouettes, normal elite dangerous variants
```

### 11.3 武器 / 投射物方向稿

用途：`assets/sprites/weapons/`

完整版：

```text
dark fantasy weapon and projectile concept sheet, fallen angel theme, sacred relic weapon forms, readable projectile silhouettes, clear player-owned attack language, suitable for top-down 2D roguelike, no text, no watermark, consistent style
```

标准版：

```text
dark fantasy weapon and projectile concept sheet, sacred relic forms, readable projectile silhouettes, clear player attack language, top-down 2D roguelike, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy weapon and projectile sheet, sacred relic forms, readable player attack silhouettes
```

## 12. 高耦合后置资产

说明：以下资产也给三档，但仅用于概念方向，不建议现在当最终稿。

### 12.1 三结局最终演出

完整版：

```text
dark fantasy ending scene concept for a fallen angel roguelike, final redemption or fall or balance outcome, sacred ruins, broken halo symbolism, memory fragments, solemn emotional climax, readable composition for later narrative presentation, no text, no watermark, clear silhouette, consistent style
```

标准版：

```text
dark fantasy ending concept, redemption or fall or balance, broken halo symbolism, memory fragments, solemn emotional composition, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy ending concept, redemption fall or balance, broken halo, solemn emotion
```

### 12.2 FS1 / FS2 / CL1+ 最终包装概念

完整版：

```text
dark fantasy late-game content concept, fallen angel world, hidden layer or challenge layer final packaging, sacred ruins, forbidden archive, broken halo, readable top-down adaptation, strong atmosphere but not final layout locked, no text, no watermark, clear silhouette, consistent style
```

标准版：

```text
dark fantasy hidden or challenge layer concept, sacred ruins, forbidden archive, broken halo, readable top-down adaptation, no text, no watermark, consistent style
```

超短版：

```text
dark fantasy hidden challenge layer concept, forbidden archive, broken halo, top-down readable
```

## 13. 使用建议

### 推荐流程

1. 首轮定风格：只用完整版。
2. 锚点确认后批量生产：优先标准版。
3. 已经非常稳定的同类扩产：再使用超短版。
4. 任何一类结果开始漂移：立即回退到标准版或完整版。

### 最适合用完整版的任务

- 主菜单背景
- 安全营地背景
- 记忆祭坛背景
- UI 总风格板
- 图标母板
- 角色 / 敌人 / 武器首轮风格板

### 最适合用超短版的任务

- 已确定风格后的同类变体
- 同系列图标扩充
- 同系列 VFX 扩充
- 同主题 tiles 细节扩图

## 14. 当前结论

- `Stage 7` 现有资产体系已经补齐三档提示词口径。
- 后续生成时不需要在“完整版 or 超短版”之间二选一，而是按阶段切换。
- 最稳的实际工作流是：`完整版定锚 -> 标准版扩产 -> 超短版提速`。
