# Stage 7 角色/敌人/武器资产生成策略（2026-03-24）

## 1. 目的

本文档用于补齐以下三类目录在 `Stage 7` 中的资产策略与生成边界：

- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`

与 UI、背景、通用 VFX 不同，这三类资产和运行时表现、动画拆分、命中体积、可读性、像素规格强耦合，因此需要明确：

- 什么现在可以做
- 什么现在只能做概念层
- 什么要等玩法和表现进一步冻结后再定稿

## 2. 当前定位

### 2.1 现在适合做的内容

- 角色立绘方向稿
- 角色俯视角造型方向稿
- 敌人族群风格板
- 武器/弹幕外观方向稿
- 动画拆分规划表
- 像素化前的概念参考图
- 同世界观下的 silhouette 统一测试

### 2.2 现在不适合直接定稿的内容

- 最终运行时角色 spritesheet
- 最终运行时敌人 spritesheet
- 最终武器攻击帧与弹幕帧终稿
- 已和 hitbox/hurtbox、攻击判定强绑定的最终序列帧

原因：

- 这些资产直接影响战斗可读性。
- 它们和 Godot 动画拆分、碰撞体积、朝向表达、技能节奏强耦合。
- 当前 `Stage 5/6` 仍在推进后半内容，过早定稿返工率高。

## 3. 三类目录的生产原则

### 3.1 角色 `assets/sprites/characters/`

先做：

- 俯视角角色概念图
- 角色职业识别度测试
- 主色与轮廓测试
- `idle / run / attack / hurt / death` 动画拆分规划

后做：

- 最终像素 spritesheet
- 逐帧攻击动画
- 技能特化动作

角色必须优先保证：

- 在俯视角下职业差异明显
- 与地表、敌人、特效层不混色
- 即使缩小也能看出武器方向和主体轮廓

### 3.2 敌人 `assets/sprites/enemies/`

先做：

- 敌人族群概念板
- 普通敌/精英/召唤物轮廓分层
- 章节敌群风格统一测试
- Boss 与普通敌的体型语言差异方向稿

后做：

- 最终 spritesheet
- 多阶段 Boss 演出帧
- 与真实攻击判定完全绑定的终稿动画

敌人必须优先保证：

- 敌我识别清楚
- 精英与普通敌差异一眼可见
- Boss 体型和危险度表达明确

### 3.3 武器 `assets/sprites/weapons/`

先做：

- 武器本体方向稿
- 投射物方向稿
- 命中特效搭配方向稿
- 进化前后视觉差异方案

后做：

- 最终攻击序列帧
- 与具体伤害节奏绑定的终稿弹幕帧
- 高密度武器特效终稿

武器必须优先保证：

- 玩家攻击来源一眼可见
- 弹幕和敌方投射物不混淆
- 高密度战斗下仍保持轮廓干净

## 4. 统一规格建议

### 4.1 像素规格

建议先按以下基准做概念转像素规划：

- 角色主体：`32x32` ~ `48x48`
- 普通敌：`24x24` ~ `48x48`
- 精英敌：`48x48` ~ `64x64`
- Boss：`64x64` ~ `128x128`
- 武器/投射物：按实际占屏范围规划，但必须先做缩放可读性测试

### 4.2 动画拆分建议

建议所有角色与敌人的规划表先按以下动作层定义：

- `idle`
- `run` 或 `move`
- `attack`
- `hurt`
- `death`

若是 Boss 或特殊敌人，再额外定义：

- `cast`
- `phase_transition`
- `summon`
- `telegraph`

### 4.3 命名建议

角色：

- `char_knight_idle_sheet_v1.png`
- `char_mage_run_sheet_v1.png`

敌人：

- `enemy_slime_idle_sheet_v1.png`
- `enemy_skeleton_attack_sheet_v1.png`

武器：

- `wpn_holy_cross_projectile_v1.png`
- `wpn_magic_missile_hit_v1.png`

概念稿：

- `char_knight_topdown_concept_v1.png`
- `enemy_chapter_3_family_board_v1.png`
- `wpn_archive_relic_set_v1.png`

## 5. Gemini 使用边界

### 5.1 适合直接让 Gemini 做的

- 职业概念设定图
- 敌人族群风格板
- 武器方向稿
- 俯视角 silhouette 测试图
- 动画拆分说明文本
- 角色/敌人/武器的风格 brief

### 5.2 不建议直接用 Gemini 产最终成品的

- 最终可直接进游戏的像素 spritesheet
- 严格对齐网格的 tileset 级精灵帧
- 最终高一致性的逐帧战斗动画

推荐流程：

1. 先用 Gemini 出方向稿和风格板。
2. 再手工或用其他工具做像素化、切帧、统一调色板。
3. 最后按 Godot 运行时需要整理为 spritesheet / SpriteFrames。

## 6. 可复制提示词模板

### 6.1 角色俯视角方向稿

```text
top-down dark fantasy character concept for a fallen angel roguelike, sacred ruins survivor, broken halo motif, readable silhouette, clear class identity, restrained color palette, suitable for later pixel art adaptation, game asset concept, no text, no watermark, consistent style
```

### 6.2 敌人族群方向稿

```text
dark fantasy enemy family concept sheet, fallen angel world, sacred ruins corrupted by abyss, multiple enemy silhouettes with clear hierarchy between normal enemy, elite enemy, and dangerous variant, readable top-down game asset concept, no text, no watermark, consistent style
```

### 6.3 武器与投射物方向稿

```text
dark fantasy weapon and projectile concept sheet, fallen angel theme, sacred relic weapon forms, readable projectile silhouettes, clear player-owned attack language, suitable for top-down 2D roguelike, no text, no watermark, consistent style
```

### 6.4 角色动画规划文本任务

```text
你现在是《堕落天使》的 2D 动画规划顾问。请为一个俯视角角色制定 spritesheet 规划表，包含 idle、run、attack、hurt、death 五类动作。请给出每类动作建议帧数、节奏说明、是否需要前摇/后摇、以及在高密度战斗下保持可读性的建议。世界观关键词：dark fantasy, fallen angel, sacred ruins。
```

### 6.5 敌人动画规划文本任务

```text
请为 Godot 俯视角动作 Roguelike《堕落天使》设计一套敌人 spritesheet 规划建议，区分普通敌、精英敌、Boss。请分别给出建议动作集、每类动作的建议帧数、危险动作 telegraph 的表现重点，以及如何保证玩家在混战中快速识别敌方动作。
```

### 6.6 武器表现规划文本任务

```text
请为《堕落天使》设计一套武器与投射物表现规划建议，覆盖武器本体、弹幕、命中特效、进化后视觉升级。要求：玩家攻击与敌方攻击绝不混淆，俯视角下轮廓清晰，高密度战斗仍可读。请输出分层建议、颜色建议、亮度建议、以及需要避免的问题。
```

## 7. 目录落地建议

- `assets/sprites/characters/`：先放职业方向稿、俯视角概念、后续再放 spritesheet
- `assets/sprites/enemies/`：先放敌群 family board、章节敌群方向稿、后续再放 spritesheet
- `assets/sprites/weapons/`：先放武器/投射物方向稿、进化前后对比稿、后续再放最终帧资源

## 8. 当前结论

- 这三类目录现在最适合做“方向稿 + 规划表 + silhouette 测试”。
- 不适合在当前阶段把 Gemini 直接当最终 spritesheet 生成器。
- 真正的终稿应放在玩法节奏、攻击表现、判定需求更稳定后再推进。
