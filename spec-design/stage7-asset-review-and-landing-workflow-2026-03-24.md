# Stage 7 资产筛选与落盘工作流（2026-03-24）

## 1. 目的

前面的 Stage 7 文档已经补齐了：

- 可单独开发资产范围
- Gemini 批量生成手册
- 首批任务清单
- 可复制提示词包
- 三档提示词体系
- 特效 / 字体 / Shader 补充提示词
- 角色 / 敌人 / 武器的阶段边界

当前还缺的一层，是把“生成出来的候选物”稳定变成“项目里可收稿、可归档、可后续接入的资产”。

本文档用于统一 Stage 7 资产的筛选、命名、版本、落盘、验收与后续接入流程，避免出现：

- 图生出来了，但不知道该不该入库
- 文件名混乱，后续找不到来源
- 同一目录里混入概念稿、候选稿、终稿，状态不清
- 运行时可用资产与方向稿混在一起，后续接入成本升高

## 2. 适用范围

适用于当前 Stage 7 全部主要资产目录：

- `assets/audio/`
- `assets/fonts/`
- `assets/shaders/`
- `assets/sprites/ui/`
- `assets/sprites/effects/`
- `assets/sprites/tiles/`
- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`

## 3. 统一状态分层

所有 Stage 7 资产建议按 4 个状态管理。

### 3.1 concept_candidate

含义：

- 刚由 Gemini 或其他工具生成
- 只完成初筛
- 还不能认为适合直接入项目正式目录

建议存放：

- 项目外部工作目录，或临时评审目录

说明：

- 不建议把大量未筛选垃圾稿直接丢进仓库。

### 3.2 style_anchor

含义：

- 已通过风格筛选
- 可作为后续扩产参考锚点
- 但未必是运行时终稿

适用：

- 主菜单背景锚点
- 安全营地背景锚点
- UI 风格板
- 图标母板
- 敌人族群方向板
- 武器方向板

### 3.3 production_ready

含义：

- 已符合项目目录、格式、命名规范
- 可以入库并作为后续切片、像素化、集成来源
- 但未必已经真正接到运行时

适用：

- UI 背景图正式候选
- UI 图标正式候选
- 音频正式候选
- 字体正式候选
- 通用 VFX 正式候选

### 3.4 runtime_final

含义：

- 已完成导入、切片、参数调整或脚本接入
- 已可以在 Godot 运行时被实际使用

说明：

- 当前 Stage 7 大多数目录，重点还是推进到 `style_anchor` 或 `production_ready`。
- `runtime_final` 只适合当前耦合较低、结构稳定的资源。

## 4. 推荐执行流程

### 第 1 步：按文档生成候选物

使用以下文档之一开始生成：

- `spec-design/stage7-gemini-first-batch-task-list-2026-03-24.md`
- `spec-design/stage7-gemini-copyable-prompt-pack-2026-03-24.md`
- `spec-design/stage7-gemini-effects-fonts-shaders-prompt-pack-2026-03-24.md`
- `spec-design/stage7-three-tier-prompt-system-2026-03-24.md`

要求：

- 关键锚点优先用 `完整版`
- 扩产再用 `标准版`
- 已锁风格后再用 `超短版`

### 第 2 步：先做批内筛选

每个任务建议至少生成 3 份候选。

筛选结果建议固定成：

- `1` 个主选
- `1` 个备选
- 其余淘汰

淘汰标准：

- 世界观不统一
- 过度写实或宣传海报感太强
- 中心构图不适合 UI 覆盖
- 轮廓脏乱，不利于后续切图/像素化

### 第 3 步：确定状态

筛选后立刻给每项资产确定状态：

- 只是参考方向：`style_anchor`
- 已能入项目目录：`production_ready`
- 已接入项目：`runtime_final`

### 第 4 步：统一命名

推荐格式：

```text
<category>_<subject>_<variant>_v<version>.<ext>
```

示例：

- `ui_bg_main_menu_ruined_halo_v1.png`
- `ui_icon_archive_systems_sheet_v1.png`
- `fx_memory_shard_glow_v1.png`
- `bgm_safe_camp_last_fire.ogg`
- `font_ui_title_relic.otf`
- `ui_holy_glow.gdshader`

说明：

- 方向稿、风格板、概念稿允许保留 `v1` / `v2` / `v3`
- 真正运行时资源不建议无限堆版本号；确认采用后可整理为稳定文件名

### 第 5 步：落到正确目录

#### UI / 背景

- `assets/sprites/ui/backgrounds/`
- `assets/sprites/ui/icons/`
- `assets/sprites/ui/panels/`
- `assets/sprites/ui/frames/`
- `assets/sprites/ui/cards/`
- `assets/sprites/ui/badges/`

#### 通用表现

- `assets/sprites/effects/`
- `assets/shaders/`
- `assets/fonts/`

#### 音频

- `assets/audio/bgm/`
- `assets/audio/ambience/`
- `assets/audio/sfx/`

#### 角色 / 敌人 / 武器

- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`

说明：

- 角色 / 敌人 / 武器当前优先落方向稿和规划稿，不要误当作最终运行时帧直接接入。

### 第 6 步：记录来源与用途

每个批次建议至少记录：

- 来源任务 ID，例如 `A1` / `B2` / `C1`
- 使用的提示词档位：完整版 / 标准版 / 超短版
- 是否是主选或备选
- 预期目标目录
- 当前状态：`style_anchor` / `production_ready` / `runtime_final`

如果不想额外建表，最少也要在提交批次说明或外部清单里记录这些信息。

## 5. 各类资产的最低入库标准

## 5.1 背景图

入库前至少确认：

- 有明确视觉中心
- 预留 UI 覆盖区
- 不出现文字、水印、Logo
- 色调符合世界观锚词
- 可继续分层或裁切

## 5.2 UI 图标

入库前至少确认：

- 缩小后仍可辨识
- 轮廓清楚，不靠微小细节表达
- 同系列线重、材质语义一致
- 黑底、灰底、亮底下都不至于完全糊掉

## 5.3 UI 面板 / 边框 / 卡片

入库前至少确认：

- 文本承载区足够大
- 装饰不过厚
- 没有烘焙固定文案
- 适合后续九宫格或局部切片

## 5.4 音频

入库前至少确认：

- `bgm` / `ambience` 可循环
- `sfx` 起音清晰
- 没有人声歌词
- 没有明显破音、爆音、过长尾音
- 命名已区分用途

## 5.5 字体

入库前至少确认：

- 中文常用字覆盖够用
- 英文、数字、标点完整
- 标题字体风格化但不影响辨认
- 正文字体在中小字号下仍清楚

## 5.6 Shader

入库前至少确认：

- 参数名清晰
- 参数数量不过度膨胀
- 优先通用化，不做页面写死逻辑
- 先服务 UI / 通用 VFX，再服务高耦合专场演出

## 5.7 角色 / 敌人 / 武器方向稿

入库前至少确认：

- 俯视角轮廓明确
- 角色、敌人、武器三类不会互相混淆
- 高密度战斗下仍有可读性基础
- 仅在“方向稿 / 规划稿”语义下入库，避免误判为运行时终稿

## 6. 哪些资产适合直接推进到 runtime_final

当前优先级建议：

### 适合较早推进

- `assets/audio/bgm/`
- `assets/audio/ambience/`
- `assets/audio/sfx/`
- `assets/fonts/`
- `assets/sprites/ui/icons/`
- `assets/sprites/ui/backgrounds/`
- `assets/sprites/ui/panels/`
- `assets/sprites/ui/frames/`
- `assets/sprites/ui/cards/`
- `assets/sprites/effects/` 的低耦合通用闪光 / 粒子类
- `assets/shaders/` 的轻量通用展示 Shader

### 暂时更适合停在 style_anchor / production_ready

- `assets/sprites/characters/`
- `assets/sprites/enemies/`
- `assets/sprites/weapons/`
- 与三结局、`FS1/FS2`、`CL1+` 最终专属演出强绑定的图形与 Shader

## 7. 批次验收模板

每次一批资产落库前，建议至少做一次这 8 项检查：

1. 是否符合世界观统一性
2. 是否命名正确
3. 是否进入了正确目录
4. 是否能分清当前状态是 `style_anchor`、`production_ready` 还是 `runtime_final`
5. 是否有明显水印、文字、来源污染
6. 是否具备后续切片 / 像素化 / 导入 Godot 的可操作性
7. 是否与现有目录 README 约定冲突
8. 是否值得真正进仓库，而不是继续留在外部工作区

## 8. 与当前目录 README 的配合方式

目录 README 负责回答“这个目录该放什么”。

本文档负责回答：

- 什么时候该放进去
- 放进去之前要通过什么筛选
- 放进去后怎么命名和标状态
- 哪些资源现在只能进概念层，不能假装已经是终稿

## 9. 当前建议的下一执行动作

如果继续沿 Stage 7 往下推进，最自然的顺序是：

1. 用三档提示词体系先产出首批背景 / UI / 图标候选。
2. 按本文档把它们筛成 `style_anchor` 与 `production_ready`。
3. 只把通过筛选的结果落到对应目录。
4. 再开始做真正的运行时替换或 Godot 接入。

## 10. 当前结论

- Stage 7 现在已经不缺“怎么写提示词”，缺的是“生成后怎么稳定落地”。
- 本文档补齐了这一步，把 Stage 7 从“会生成”推进到“可收稿、可归档、可接入”。
- 后续若继续补文档，最有价值的方向就是把首批真实产物做成 `asset intake ledger` 或批次验收记录模板。
