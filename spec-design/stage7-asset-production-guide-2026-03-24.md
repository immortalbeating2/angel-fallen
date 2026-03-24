# Stage 7 资产生产与统一风格规范（2026-03-24）

## 1. 目的

本文档用于约束 `Stage 7` 中可单独开发的正式音频、美术、UI 资源与表现基础层，确保：

- 资产生产可与 `Stage 5/6` 并行推进。
- 风格统一，不因 AI 批量生成而产生项目割裂感。
- 资产路径、文件格式、命名规范与当前项目结构一致。
- 对“可立即开发”和“应后置定稿”的范围做清晰边界划分。

## 2. 当前代码真值与目录基线

### 当前已存在目录

- `assets/audio/bgm/`
- `assets/audio/ambience/`
- `assets/audio/sfx/`
- `assets/sprites/tiles/`
- `assets/sprites/ui/`

### 文档规划中已存在但当前仓库尚未完全落地的目录

参考 `spec-design/architecture.md`，后续可在需要时补齐：

- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`
- `assets/sprites/effects/`
- `assets/fonts/`
- `assets/shaders/`

### 路径使用原则

- 地图、章节、瓦片相关正式替换，优先继续使用当前真值路径 `assets/sprites/tiles/`。
- UI 图标、装饰、背景、面板等，统一放在 `assets/sprites/ui/` 下继续细分子目录。
- 音频继续使用现有 `bgm / ambience / sfx` 三分结构。
- 新增 `characters / enemies / weapons / effects / fonts / shaders` 时，以 `architecture.md` 约定为准。

## 3. 可单独开发资产清单

### 3.1 可立即并行开发

这些资产与 `Stage 5/6` 的后续逻辑改动耦合较低，可先做统一风格版本。

#### A. 音频基础包

适合先做的内容：

- 主菜单 BGM
- 安全营地 BGM
- 记忆祭坛 BGM
- 结算页 BGM
- 章节基础环境音
- UI 点击、确认、升级、奖励、解锁提示音
- Boss phase cue / challenge cue 的基础音色包

放置路径：

- `assets/audio/bgm/`
- `assets/audio/ambience/`
- `assets/audio/sfx/`

格式要求：

- `BGM`: `.ogg`
- `Ambience`: `.ogg`
- `SFX`: `.wav`

技术要求：

- 采样率：`44.1kHz`
- 位深：`16-bit`
- `BGM/Ambience` 需可循环
- `SFX` 优先短音频、起音清晰、尾部可控
- 避免歌词人声，优先氛围化、器乐化、圣咏化

#### B. UI 设计系统资产

适合先做的内容：

- 按钮
- 面板
- 页签
- 奖励卡片
- 档案卡片
- 标签条
- 通用边框
- 标题装饰
- 状态徽记
- 路线、结局、隐藏层、挑战层通用图标

放置路径：

- `assets/sprites/ui/icons/`
- `assets/sprites/ui/panels/`
- `assets/sprites/ui/frames/`
- `assets/sprites/ui/cards/`
- `assets/sprites/ui/badges/`
- `assets/sprites/ui/backgrounds/`

注：这些子目录当前未必已创建，但建议后续按此结构补齐。

格式要求：

- 最终运行时资源：`.png`
- 透明背景
- 图标优先单色/双色高对比版本
- 面板优先九宫格友好切片设计
- 可保留源文件为 `.psd`、`.kra`、`.svg`，但运行时入库以 `.png` 为准

技术要求：

- UI 图标建议基准尺寸：`64x64` / `128x128`
- 面板建议按可切片方式设计，避免烘焙死文字
- 所有 UI 资产需考虑中英文本长度变化

#### C. 场景背景与世界观概念图

适合先做的内容：

- 主菜单背景
- 安全营地背景
- 记忆祭坛背景
- 档案室 / Hidden Layer Track 背景
- 挑战层档案空间背景
- 通用章节氛围图

放置路径：

- `assets/sprites/ui/backgrounds/`
- `assets/sprites/tiles/`（如果最终拆入地图装饰层）
- 概念稿可先外部保存，最终运行时图再导入项目

格式要求：

- 最终运行时：`.png`
- 需要滚动或分层视差的背景，拆成多层 `.png`
- 若作为静态展示图，可先单张图导入

#### D. 通用 VFX 语言

适合先做的内容：

- 圣辉粒子
- 堕落羽毛
- 记忆碎片漂浮
- 档案封印
- 虚空裂隙
- 锻造火花
- 解锁、奖励、结局基础闪光

放置路径：

- `assets/sprites/effects/`
- 着色器脚本放置到 `assets/shaders/`

格式要求：

- 精灵特效：`.png`
- 序列帧：sprite sheet `.png`
- 着色器：`.gdshader`

#### E. 章节地表与通用装饰替换

适合先做的内容：

- 章节地砖重绘
- 地表细节
- 门框
- 危害层视觉
- 环境特效层
- 通用祭坛、雕像、书架、封印台装饰

放置路径：

- `assets/sprites/tiles/`

格式要求：

- `.png`
- 与现有 atlas / tiles 方案兼容
- 保持 tile 尺寸统一，不混用不同基准

技术要求：

- 推荐以 `16x16` 或 `32x32` 网格统一
- tile、overlay、detail、ambient fx 分层设计
- 与现有 `atlas_manifest.json` 风格保持一致

### 3.2 可并行做，但要接受返工

内容：

- 主菜单最终包装
- 结算页正式皮肤
- 章节转场正式皮肤
- 记忆祭坛正式包装
- Hidden Layer Track / Ending Archive 正式包装

原因：

这些页面结构已经相对稳定，但 `Stage 5/6` 仍可能继续增加字段、区块或状态行，因此可以先做视觉模板，不宜过早做死最终排版。

### 3.3 应后置定稿

内容：

- 三结局最终演出
- `FS1/FS2` 完整关卡专属最终包装
- `CL1/CL2+` 挑战层最终专属演出
- 首局引导与完整通关流程最终表现强化
- 最终统一页面排版微调

原因：

这些内容最依赖 `Stage 5/6` 的最终信息结构、流程时序与玩法反馈，过早定稿返工概率高。

## 4. 统一风格圣经

### 4.1 世界观母题

统一提示词必须长期保持以下核心母题：

- fallen angel
- sacred ruins
- broken halo
- memory fragments
- forbidden archive
- redemption / fall / balance
- divine decay
- abyss corruption

### 4.2 色彩方向

主色：

- 冷灰石色
- 褪色圣金
- 暗银
- 炭黑
- 灰蓝

点缀色：

- 枯血红
- 记忆青蓝
- 圣辉淡金
- 虚空紫黑（仅少量点缀，不可泛滥）

### 4.3 材质语言

- 残破石材
- 旧银
- 失光金边
- 裂纹玻璃
- 灰烬
- 羽毛
- 封印符文
- 圣坛烛火
- 古旧档案纸张与封蜡

### 4.4 形状语言

- 尖拱
- 圆环
- 破碎光环
- 十字 / 圣坛 / 祭坛
- 封印纹路
- 书页 / 档案匣
- 断裂长廊
- 对称但破损的神圣结构

### 4.5 UI 气质

- 庄严
- 克制
- 可读性优先
- 细节不喧宾夺主
- 禁止通用紫白奇幻模板感
- 禁止过度赛博、过度华丽、过度高饱和

## 5. Gemini 统一生成规范

### 5.1 推荐定位

Gemini 用作：

- 风格板生成器
- 提示词母版生成器
- 场景概念图初稿生成器
- UI 风格探索图生成器
- 图标概念生成器

不建议直接把 Gemini 当作唯一最终量产工具去生成：

- 像素角色精灵表
- 规范化 tileset
- 大量最终 UI 切片
- 正式批量循环音乐和音效包

### 5.2 固定提示词骨架

所有视觉提示词都应由 4 层组成：

1. 世界观层
2. 功能层
3. 风格层
4. 输出层

示例关键词：

- 世界观层：`dark fantasy`, `fallen angel`, `sacred ruins`, `forbidden archive`, `broken halo`, `divine decay`
- 功能层：`main menu background`, `safe camp environment`, `memory altar`, `challenge archive arena`, `ui icon set`, `relic panel`
- 风格层：`solemn`, `tragic`, `restrained`, `high readability`, `game asset`, `clear silhouette`
- 输出层：`transparent background`, `top-down 2D`, `pixel art`, `seamless tile`, `ui panel`, `icon set`

### 5.3 统一负面提示词

```text
blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
```

## 6. 可直接复用的 Gemini 提示词模板

### 6.1 主菜单背景

```text
dark fantasy title screen for a top-down 2D action roguelike, fallen angel theme, ruined holy sanctuary, broken halo statue, cracked stained glass, ash drifting in cold air, sacred ruins mixed with abyss corruption, solemn and tragic atmosphere, strong focal composition, high readability for menu overlay, game background art, no text
```

### 6.2 安全营地

```text
top-down dark fantasy safe camp, survivors resting inside a ruined chapel courtyard, candles, relic forge, memory altar, archive table, broken angel carvings, warm sanctuary light against surrounding darkness, sacred refuge after battle, stylized game environment concept, clear gameplay landmarks, no text
```

### 6.3 记忆祭坛

```text
memory altar in a fallen angel world, ancient altar of glowing memory shards, soft holy light mixed with melancholy blue haze, floating fragments, engraved runes, sacred archive mood, dark fantasy, top-down 2D game environment concept, readable central interaction point, no text
```

### 6.4 FS1：Time Rift / Choir Undercrypt

```text
dark fantasy hidden layer, time rift beneath a ruined choir crypt, fractured time shards, ghostly hymn echoes, broken clock motifs, frozen choir hall, sacred ruins distorted by temporal anomalies, top-down 2D game environment concept, eerie but elegant, strong navigational silhouettes, no text
```

### 6.5 FS2：Genesis Forge

```text
dark fantasy hidden layer, genesis forge deep inside a divine ruin, ancient celestial forge, molten metal, sacred machinery, chained relic cores, ember sparks and holy fire, creation and corruption intertwined, top-down 2D game environment concept, heavy industrial cathedral mood, no text
```

### 6.6 CL1：Challenge Archive

```text
endgame challenge layer environment, forbidden archive arena, sealed records, ritual gates, glowing archive sigils, austere stone circles, sacred bureaucracy turned into combat trial, dark fantasy, top-down 2D game arena concept, clean combat readability, minimal clutter, no text
```

### 6.7 UI 图标集

```text
dark fantasy game icon set, fallen angel theme, memory shard, holy relic, void sigil, archive seal, challenge badge, forge ember, route marker, redemption icon, fall icon, balance icon, clean silhouette, high contrast, consistent line weight, transparent background, no text
```

### 6.8 UI 面板风格板

```text
dark fantasy game UI kit, cathedral-inspired interface, aged silver metal, black stone, faded gold trim, stained glass highlights, sacred runes, relic panels, elegant but readable, fantasy HUD and menu components, buttons cards tabs modal panels, cohesive design system, no text
```

### 6.9 像素瓦片模板

```text
pixel art top-down dungeon tileset, fallen angel dark fantasy, broken chapel stone floor, cracked marble, ash dust, faint holy glyphs, 16-color palette, seamless tile, game asset, clean grid alignment, no text
```

## 7. Stage 7 资产放置路径与文件格式要求

| 资产类别 | 建议项目路径 | 最终格式 | 备注 |
|---|---|---|---|
| 主菜单 BGM | `assets/audio/bgm/` | `.ogg` | 可循环 |
| 营地 / 祭坛 / 结算 BGM | `assets/audio/bgm/` | `.ogg` | 可循环 |
| 环境音 | `assets/audio/ambience/` | `.ogg` | 长循环 |
| UI / 奖励 / 解锁 SFX | `assets/audio/sfx/` | `.wav` | 短音、清晰 |
| 章节地砖 / 门 / 危害层 | `assets/sprites/tiles/` | `.png` | 与现有 tile 方案一致 |
| UI 图标 | `assets/sprites/ui/icons/` | `.png` | 透明背景 |
| UI 面板 / 边框 / 卡片 | `assets/sprites/ui/panels/`, `assets/sprites/ui/frames/`, `assets/sprites/ui/cards/` | `.png` | 九宫格友好 |
| 菜单 / 档案 / 祭坛背景 | `assets/sprites/ui/backgrounds/` | `.png` | 可拆分层 |
| 通用 VFX 精灵 | `assets/sprites/effects/` | `.png` | sprite sheet 或单张 |
| Shader | `assets/shaders/` | `.gdshader` | 仅程序材质 |
| 字体 | `assets/fonts/` | `.ttf` / `.otf` | 中英文字体分开管理 |
| 角色精灵 | `assets/sprites/characters/` | `.png` | 后续定稿再补 |
| 敌人精灵 | `assets/sprites/enemies/` | `.png` | 后续定稿再补 |
| 武器 / 弹幕 | `assets/sprites/weapons/` | `.png` | 后续定稿再补 |

## 8. 命名规范

### 音频

- `bgm_main_menu_fallen_sanctuary.ogg`
- `bgm_safe_camp_last_fire.ogg`
- `amb_memory_altar_echoes.ogg`
- `sfx_ui_confirm_01.wav`
- `sfx_unlock_hidden_layer_01.wav`

### UI

- `ui_icon_memory_shard.png`
- `ui_icon_hidden_layer_fs1.png`
- `ui_panel_archive_frame.png`
- `ui_card_reward_challenge.png`
- `ui_bg_main_menu_ruined_halo.png`

### Tiles / Effects

- `tile_ch1_floor_a_01.png`
- `tile_challenge_archive_gate.png`
- `fx_memory_shard_glow_sheet.png`
- `fx_archive_seal_break.png`

## 9. 当前建议执行顺序

1. 先产出风格圣经与参考图锚点。
2. 再批量生成 BGM、ambience、UI 图标、UI 面板、场景背景概念。
3. 然后补通用 VFX 与章节 tiles 替换。
4. 等 `Stage 5/6` 关键流程冻结后，再定稿三结局、FS1/FS2、CL1/CL2+ 的最终表现层。

## 10. 当前结论

- `正式音频` 最适合先独立开发。
- `UI 与通用视觉资产` 适合先做统一风格的基础层。
- `结局 / 隐藏层 / 挑战层的最终专属表现` 仍应后置定稿。
- Gemini 可以直接承担风格板、概念稿、提示词母版与部分正式资产的生成工作，但所有资产必须先服从同一套风格圣经。
