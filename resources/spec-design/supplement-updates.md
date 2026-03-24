# supplement-updates.md — 计划外更新补充说明

## 文档目的

本文件用于记录 **roadmap 与主规格之外** 的已实现更新，避免实现与设计文档脱节。

- 主规格文档（requirements / architecture / core-systems / data-structures / level-design / test-plan / roadmap）仍是基线。
- 本文件记录新增能力、临时扩展、运行时优化与 UX 迭代。
- 当补充内容稳定后，应回写到对应主规格文档并标记“已吸收”。

---

## 同步范围（包含历史已完成项）

> 本节覆盖“之前已做但未写入计划文档”的迭代内容。

## 已吸收记录

| 日期 | 吸收目标 | 吸收内容 |
|------|----------|----------|
| 2026-03-18 | `requirements.md` | 回写 FR-N06~N08（事件权重/章节效果/后记回顾）、扩展 FR-U04 与 FR-U06、补充运行时设置存档要求 |
| 2026-03-18 | `test-plan.md` | 回写 NAR-10~NAR-15、EVT-06~EVT-08、新增 PAU-01~PAU-08 与 HUD-01~HUD-06 |

### A. 叙事与分支深化（已实现）

1. **章节事件权重路由**
   - 事件选择不再仅随机，改为基于 alignment / 已解锁结局 / 最近历史进行加权。
   - 支持 `requires_endings_any`、`forbid_endings_any` 进行事件门禁。

2. **章节持续效果（2~3房）**
   - 事件选项可附带 `chapter_effect`。
   - 效果可影响刷怪速率、敌人HP/伤害、危害强度、移速、伤害加成、临时护甲。
   - HUD 与房间状态文案可见剩余房间数。

3. **局内记忆祭坛（Safe Camp）**
   - 新增营地交互 `T` 打开 Memory Altar。
   - 可局内翻阅已解锁记忆碎片（上一条/下一条/关闭）。

4. **结局后记差分**
   - 结局文本区分“首次解锁”与“重复轮回”版本。
   - 结算面板显示后记内容。

5. **叙事可视化补全**
   - 结算面板新增本局叙事选择回顾（含截断与溢出提示）。
   - 主菜单新增记忆碎片回看轮播。
   - 修复祝福叠加漏洞：祝福改为互斥替换（应用前回滚旧祝福影响）。

---

### B. HUD 与局内反馈增强（已实现）

1. **HUD 事件吐司通知**
   - 监听并提示：成就解锁 / 结局解锁 / 碎片获得 / 饰品获得。

2. **HUD 迷你地图（3x5）**
   - 显示 15 房间网格、房型标记、当前房间高亮。
   - 已完成房间使用小写标记。

3. **章节效果 HUD 可读性增强**
   - 图标化正负向：`[+]` / `[-]` / `[~]`。
   - 显示剩余房间 `(nR)`。

---

### C. 暂停系统与运行时设置（已实现）

1. **暂停流程重构**
   - `Esc` 从“直接结算/返回”改为“暂停面板开关”。
   - 暂停面板支持：继续、撤退结算、回主菜单。

2. **暂停-设置子页（即时生效）**
   - 新增设置子页：Master/BGM/SFX/Ambience 音量、屏幕震动强度、UI 缩放。
   - 修改后即时应用并写入存档。

3. **运行时设置持久化**
   - SaveManager 新增 `runtime_settings` 字段及读写/清洗逻辑。
   - EventBus 新增 `settings_changed(settings: Dictionary)` 广播。
   - AudioManager 支持按比例设置总线音量。
   - 玩家相机震动强度受设置项控制。

---

### D. 校验链路强化（已实现）

1. **`validate_configs.py` 语义化升级**
   - 从“仅 JSON 语法检查”升级到 11 份配置文件结构与数值约束校验。
   - 覆盖敌人缩放、Boss阶段、掉落权重、叙事结构、成就条件、Meta升级等。

2. **`check_resources.py` 完整性增强**
   - 增加核心目录/脚本/场景必需项检查。
   - 校验 narrative_index 资源路径并输出告警。

3. **叙事资源占位补齐**
   - 新增 `resources/narrative/*.tres` 占位，消除资源路径缺失告警。

---

### E. 运行规划生成与开发时间线同步（已实现/在途）

1. **Run-Plan 生成系统（已实现）**
   - 新增 `map_generation.json` 作为房间生成配置基线。
   - 新增 `MapGenerator`，生成本局 `run_plan`（room_type/chapter_id/boss_id/show_intro）。
   - `GameWorld` 从 run_plan 驱动房间类型、章节归属、Boss 对应、胜利判定与迷你地图布局。
   - 房间推进从“固定 room+1”升级为“按 run_plan next_rooms 导航”，支持章节分支路线选择。

2. **房间类型扩展（已实现）**
   - 新增 `elite` 房型，接入独立房间流程与刷怪模式。
   - `EnemySpawner` 增加 elite 模式（精英密度与刷怪节奏独立于普通房）。

3. **配置与测试同步（已实现）**
   - `validate_configs.py` 新增 `map_generation.json` 的结构与约束校验。
   - 新增 `test/unit/test_map_generation_config.gd` 覆盖配置与生成结果不变量。

4. **分支路线风格层（已实现）**
   - 章节首次分支选择会绑定该章节路线风格（`vanguard` / `raider`，未绑定为 `neutral`）。
    - 路线风格已接入：
      - 事件权重（`weight_if_route_*` + `route_weight_mult`）
      - 商店经济（价格/折扣目标/加价阈值/矿石兑换增量）
      - 环境危害强度
      - 金币与矿石掉落量倾向
      - 章节视觉主题混色（hazard tint 与路线主题色融合）
      - Boss 轻量参数化（HP/伤害/速度/体型/主色）
   - 新增配置节：
     - `narrative_content.json -> route_styles`
     - `shop_items.json -> route_style_overrides`
   - 新增测试：`test/unit/test_narrative_route_style_config.gd`。
   - 可视化反馈补齐：
     - HUD 新增路线风格行（当前风格 + CH1~CH4 对比 + 最近锁定轨迹）
     - 结算面板新增路线风格演化摘要（章节对比 + 锁定时间线）

5. **开发时间线图（同步版）**

```text
2026-03 主体推进时间线（同步版）

W1  [基础骨架]  项目初始化 / Autoload / 可玩最小循环
W2  [战斗核心]  敌人+刷怪 / 投射物 / 升级三选一 / 房间清算
W3  [叙事层]    章节转场 / 事件房 / 记忆碎片 / 结局后记
W4  [系统深化]  章节效果 / 环境危害 / 暂停设置 / Codex
W5  [经济层]    动态商店经济 / 章节化商店权重与池偏置
W6  [结构补齐]  Run-Plan生成 / Elite房型 / 章节元数据驱动

下一阶段（建议 2~3 周）
  A. 地图表现层：TileMap落地 + 房间模板拼接（对齐 FR-R01）
  B. 武器进化链：进化配方/演出/测试补齐（对齐 FR-W04）
  C. 测试覆盖扩展：按 test-plan 补核心集成用例与CI流水线
```

---

## 关键落地文件（摘要）

- 叙事与分支：
  - `scripts/systems/narrative_system.gd`
  - `scripts/game/game_world.gd`
  - `scripts/ui/narrative_event_panel.gd`
  - `scripts/ui/chapter_transition_panel.gd`
  - `data/balance/narrative_content.json`

- 记忆祭坛与回顾：
  - `scripts/ui/memory_altar_panel.gd`
  - `scenes/ui/memory_altar_panel.tscn`
  - `scripts/ui/main_menu.gd`
  - `scripts/ui/run_result_panel.gd`

- HUD 与反馈：
  - `scripts/ui/hud.gd`
  - `scenes/ui/hud.tscn`

- 暂停与设置：
  - `scripts/ui/pause_panel.gd`
  - `scenes/ui/pause_panel.tscn`
  - `scripts/autoload/save_manager.gd`
  - `scripts/autoload/audio_manager.gd`
  - `scripts/autoload/event_bus.gd`
  - `scripts/game/player.gd`

- 校验与资源：
  - `scripts/validate_configs.py`
  - `scripts/check_resources.py`
  - `resources/narrative/*.tres`

- 运行规划与房间生成：
  - `scripts/systems/map_generator.gd`
  - `data/balance/map_generation.json`
  - `test/unit/test_map_generation_config.gd`

---

## 后续同步规则

1. 新增“计划外”功能后，必须同步本文件。
2. 若功能稳定并进入长期维护：
   - 回写到 `requirements.md`（需求层）
   - 回写到 `architecture.md` / `core-systems.md` / `data-structures.md`（设计层）
   - 回写到 `test-plan.md`（测试层）
3. 本文件仅记录增量与偏差，不替代主规格文档。
