# Stage 7 Gemini 提示词包：Effects / Fonts / Shaders（2026-03-24）

## 1. 目的

本文档补齐 `assets/sprites/effects/`、`assets/fonts/`、`assets/shaders/` 三类目录的 Gemini 专用提示词包，作为以下文档的继续执行层：

- `spec-design/stage7-asset-production-guide-2026-03-24.md`
- `spec-design/stage7-gemini-batch-production-manual-2026-03-24.md`
- `spec-design/stage7-gemini-copyable-prompt-pack-2026-03-24.md`

目标：

- 为通用 VFX 参考图提供可直接复制的提示词
- 为字体选型与字体系统定义提供可直接复制的文本任务
- 为通用 shader 方案设计提供可直接复制的概念与技术草案任务

说明：

- `effects` 适合让 Gemini 直接生成概念参考图或特效方向板。
- `fonts` 不适合让 Gemini 直接生成最终字体文件，更适合生成字体风格规范、字体搭配建议、标题/正文字体选型 brief。
- `shaders` 不适合先让 Gemini 生成高耦合最终演出 shader，更适合先生成轻量通用 shader 设计 brief、参数表、视觉目标描述，必要时再辅助输出 `.gdshader` 草案。

## 2. 固定风格锚词

以下关键词建议长期保留：

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

统一负面词：

```text
blurry, photorealistic, 3d render, noisy background, watermark, text, logo, low contrast, unreadable ui, messy composition, oversaturated, generic fantasy
```

视觉类统一追加尾词：

```text
no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

## 3. Effects 提示词包

目录：`assets/sprites/effects/`

### EFX-1 圣辉粒子

建议文件名：`fx_holy_glow_particles_v1.png`

```text
dark fantasy VFX concept sheet, fallen angel theme, holy glow particles, pale gold sacred light, broken halo sparks, floating embers of divine decay, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-2 堕落羽毛

建议文件名：`fx_fallen_feather_v1.png`

```text
dark fantasy effect concept, fallen angel feathers drifting through cold air, black and silver feathers with faint holy glow on the edges, solemn and tragic, readable layered silhouettes, suitable for game VFX reference, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-3 记忆碎片漂浮

建议文件名：`fx_memory_shard_glow_v1.png`

```text
memory shard VFX concept sheet, dark fantasy fallen angel world, glowing blue memory fragments, pale gold rune dust, floating shard clusters, sacred archive atmosphere, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-4 档案封印破裂

建议文件名：`fx_archive_seal_break_v1.png`

```text
archive seal break VFX concept, forbidden archive theme, sacred seal cracking open, fading gold runes, fragments of stone and light, restrained but dramatic, dark fantasy, readable effect silhouettes, game effect concept art, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-5 虚空裂隙

建议文件名：`fx_void_rift_v1.png`

```text
void rift effect concept for a dark fantasy fallen angel game, black-purple fracture in sacred space, restrained abyss corruption, stone dust and distorted light, readable layered silhouette, suitable for gameplay VFX reference, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-6 锻造火花

建议文件名：`fx_forge_sparks_v1.png`

```text
celestial forge spark VFX concept, dark fantasy sacred forge, ember sparks, hot metal fragments, faint holy fire, creation and corruption intertwined, readable gameplay effect silhouettes, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### EFX-7 解锁 / 奖励基础闪光

建议文件名：`fx_unlock_reward_flash_v1.png`

```text
unlock and reward flash VFX concept sheet, dark fantasy fallen angel game, archive unlock flare, relic reward sparkle, restrained holy shimmer, readable short-burst silhouettes, suitable for UI and game reward effects, transparent background when applicable, no text, no watermark, clear silhouette, production-ready game concept, consistent style
```

### Effects 筛选标准

- 优先选择轮廓清晰、容易像素化或重绘的结果。
- 优先选择能在深色 UI 或深色场景中保持识别度的结果。
- 避免过度烟雾化、过度模糊、中心发散不清的结果。

## 4. Fonts 提示词包

目录：`assets/fonts/`

说明：这一组不是让 Gemini 生成 `.ttf` / `.otf`，而是让 Gemini 输出字体方向 brief、字体搭配建议和命名方案，然后再去找或制作正式字体资源。

### FONT-1 UI 正文字体 brief

建议目标名：`font_ui_body_main`

```text
你现在是《堕落天使》的字体系统设计顾问。请基于 dark fantasy、fallen angel、sacred ruins、forbidden archive、solemn and tragic 的世界观，给出一套适合 UI 正文的字体 brief。要求：中文和英文都要易读，适合菜单、HUD、档案说明、奖励明细；避免过度花哨；给出字体气质描述、适用场景、字重建议、字号建议、行距建议，以及应避免的风格。
```

### FONT-2 标题字体 brief

建议目标名：`font_ui_title_relic`

```text
你现在是《堕落天使》的标题字体设计顾问。请为主菜单标题、章节标题、结算标题、结局标题定义一套标题字体 brief。世界观关键词：dark fantasy, fallen angel, broken halo, sacred ruins, forbidden archive。要求：庄严、克制、略带神圣残败感；允许有装饰性，但不能难以阅读；请输出字体气质、笔画倾向、适合的标题层级、和正文搭配原则。
```

### FONT-3 字体系统搭配建议

```text
请为《堕落天使》设计一套完整的游戏字体系统方案，包括：1 套正文字体方向，1 套标题字体方向，1 套数字/强调信息方向。请按菜单、HUD、档案页、章节转场、结算页分别给出推荐使用方式，并说明中英文混排时的注意事项。风格要求：dark fantasy, fallen angel, sacred ruins, solemn and tragic, high readability。
```

### FONT-4 字体收稿检查清单

```text
请为 Godot 2D 游戏《堕落天使》输出一份字体收稿检查清单。目标是验证中文常用字覆盖、英文与数字完整性、标点兼容、不同字号下的可读性、HUD 与正文的渲染效果，以及标题字体是否过度装饰。请按“必须检查 / 建议检查 / 可延后检查”三层列出。
```

### Fonts 输出使用方式

- 先用 Gemini 产出 brief 与检查清单。
- 再依据 brief 去筛选已有字体或决定是否自制/购买字体。
- 正式字体入库时仍遵守 `assets/fonts/README.md` 中的命名与覆盖要求。

## 5. Shaders 提示词包

目录：`assets/shaders/`

说明：这一组优先用于让 Gemini 输出 shader 设计说明、参数建议和轻量 `.gdshader` 草案，不建议一开始就产出与特定结局、隐藏层演出强耦合的复杂 shader。

### SHD-1 UI 微光 shader 设计 brief

建议目标名：`ui_holy_glow.gdshader`

```text
你现在是 Godot 4 shader 设计顾问，请为《堕落天使》设计一个轻量 UI 微光 shader brief。用途：按钮高亮、档案框边缘、奖励卡片强调。风格关键词：dark fantasy, fallen angel, sacred ruins, faded holy glow, restrained ornament。请输出：视觉目标、适用节点、建议参数、动画节奏建议、应避免的问题，以及是否适合写成 CanvasItem shader。
```

### SHD-2 记忆碎片脉冲 shader 设计 brief

建议目标名：`fx_memory_shard_pulse.gdshader`

```text
请为 Godot 4 游戏《堕落天使》设计一个记忆碎片脉冲 shader brief。用途：记忆祭坛碎片、碎片图标、相关特效节点。要求：淡蓝与淡金的缓慢脉冲，神圣与怀旧并存，效果轻量，可复用。请输出视觉目标、参数列表建议、时间控制建议、混色建议和性能注意事项。
```

### SHD-3 档案封印波动 shader 设计 brief

建议目标名：`fx_archive_seal_wave.gdshader`

```text
请为《堕落天使》设计一个 forbidden archive 封印波动 shader brief。用途：档案封印、挑战层记录节点、隐藏层封印入口。要求：克制、神圣、略带压迫感，不要过度花哨。请输出适用材质类型、参数建议、动画方向、适合的颜色范围、以及与 UI 或世界物件搭配时的注意事项。
```

### SHD-4 虚空裂隙扰动 shader 设计 brief

建议目标名：`fx_void_rift_distort.gdshader`

```text
请为 Godot 4 设计一个 dark fantasy void rift distortion shader brief，用于《堕落天使》的虚空裂隙、深渊污染点和挑战层异常节点。要求：轻量、可复用、可控制强度；视觉上是 restrained abyss corruption，不是科幻传送门。请输出：视觉目标、参数、UV 扰动思路、颜色建议、性能注意事项。
```

### SHD-5 Godot `.gdshader` 草案生成

```text
请基于以下 brief，输出一个 Godot 4 CanvasItem shader 草案，并为每个 uniform 写清楚用途说明。要求：命名清晰、参数少而有效、方便后续在 UI 和特效节点上复用。世界观：dark fantasy, fallen angel, sacred ruins, forbidden archive。视觉目标：<在这里填入具体 shader brief>。
```

### Shaders 筛选标准

- 优先保留参数少、复用性高、语义清晰的方案。
- 优先保留能服务多个界面或多个特效节点的方案。
- 淘汰明显只适合单一演出页面、或依赖复杂特殊输入的方案。

## 6. 推荐执行顺序

1. 先跑 `Effects`，补齐通用 VFX 参考图库。
2. 再跑 `Fonts`，先锁字体系统 brief 与验收清单。
3. 最后跑 `Shaders`，先定视觉目标与参数语义，再决定是否生成 `.gdshader` 草案。

## 7. 当前结论

- `effects` 现在已经适合直接开跑 Gemini 图像批次。
- `fonts` 更适合先做系统定义，不应直接把 Gemini 结果当最终字体文件。
- `shaders` 更适合先做通用 brief 与轻量草案，不应现在就进入高耦合最终演出 shader 阶段。
