# Angel Fallen 当前开发状态与深度整理计划 - 2026-05-04

## 当前结论

Angel Fallen 已经从早期房间制 Roguelike 骨架推进到“可验证的类幸存者核心 v1”。当前自动化基线为：Godot 无头启动通过，JSON 语法与配置语义校验通过，全量 GUT 37 个脚本、155 个测试、8751 个断言通过。

当前最大问题不再是某个单点系统缺失，而是连续开发后文档、UI、运行时编排和测试证据堆积过快。下一阶段应先建立清晰真源和拆分边界，再继续大规模扩内容。

## 已完成主系统

| 领域 | 当前状态 | 代表文件 / 证据 |
|------|----------|----------------|
| 房间制 Roguelike 主循环 | 已具备角色选择、房间推进、商店/营地/挑战层/隐藏层、胜负结算和存档摘要 | `scripts/game/game_world.gd`、`test/integration/test_core_flow_regression.gd` |
| Stage 5/6 叙事与隐藏层 | 已有叙事路线、档案、结局、挑战层与回归测试 | `test/unit/test_narrative_*`、`test/unit/test_challenge_layer_flow.gd` |
| 主菜单与设置 UI | 已完成主菜单重排、运行设置、显示/音频/控制分页、难度选择与人工截图复核 | `scripts/ui/main_menu.gd`、`scripts/ui/runtime_settings_panel.gd`、`test/manual_review_evidence/` |
| HUD / 章节 / 死亡结算 | 已从早期大面板堆叠改为更合理的顶部 HUD、居中章节弹层和结算弹层 | `scripts/ui/hud.gd`、`scripts/ui/chapter_intro_panel.gd`、`scripts/ui/run_result_panel.gd` |
| 类幸存者战斗表现 | 已有自动攻击、命中反馈、击退、伤害数字、环绕武器、持续光环、地面持续伤害与基础音效 cue | `scripts/game/auto_weapon.gd`、`scripts/game/orbit_weapon.gd`、`scripts/game/aura_weapon.gd` |
| 类幸存者核心系统 v1 | 已有 Run Director、6+6 loadout、武器 1-8 级、宝箱进化、磁铁吸附、构筑面板、长局 probe | `scripts/systems/run_director.gd`、`scripts/systems/weapon_loadout.gd`、`scripts/tools/run_survivor_balance_probe.gd` |
| 自动化测试 | 核心系统、配置、叙事、UI 目标、资源验收与可视快照目标均有测试覆盖 | `test/unit/`、`test/integration/` |

## 仍缺或仍弱的内容

| 优先级 | 缺口 | 说明 |
|--------|------|------|
| P0 | 正式资产替换 | 当前角色、怪物、弹道、UI、音效仍大量依赖程序化占位。Stage 7 资产生产和接入仍是发布前主阻塞。 |
| P0 | 大文件拆分 | `game_world.gd`、`main_menu.gd`、`run_visual_snapshot_regression.gd` 已成为高风险文件，继续堆功能会降低稳定性。 |
| P1 | 类幸存者长局手感 | 已有系统骨架，但 20-30 分钟敌潮、升级池、宝箱节奏、DPS 曲线仍需要平衡 probe 和人工复核联合调参。 |
| P1 | 多武器执行器成熟度 | 当前副武器可独立发射并进化，但还没有完整的每武器专属执行器、冷却 UI、DPS 统计和升级动画。 |
| P1 | UI 视觉统一 | 主菜单、设置、HUD 已明显改善，但正式字体、图标、按钮态、面板层级和 4K 视觉密度仍需统一设计规范。 |
| P2 | 文档真源混乱 | `spec-design/` 同时包含历史大计划、阶段记录、验收记录、资产生产手册和最新计划，需要分层索引与归档策略。 |
| P2 | 人工复核证据体量 | 截图已集中到 `test/manual_review_evidence/`，但后续应按日期和主题维护 README，避免证据目录变成第二个无索引仓库。 |

## 文档整理目标结构

短期不强制移动历史文件，先建立“现行真源 + 历史参考”的阅读顺序：

1. `spec-design/README.md`：唯一入口，列出现行真源、历史参考、资产生产文档和版本记录。
2. `spec-design/current-project-status-and-cleanup-plan-2026-05-04.md`：当前开发状态、风险和整理路线。
3. `spec-design/2026-5-2-plan.md`：Stage 7 执行跟踪和人工复核 ledger 的承接计划。
4. `spec-design/survivor-core-development-plan-2026-05-03.md`：Stage 7.5 类幸存者核心补完计划。
5. `test/manual_review_evidence/README.md`：人工复核截图证据索引。

中期可新增 `spec-design/archive/`，把 2026-03 的冻结计划、旧 checklist、旧 prompt pack 迁入归档目录，并在 README 保留链接。迁移时必须单独提交，避免与功能开发混在一起。

## 代码整理路线

### 第一轮：只立边界，不改行为

- `game_world.gd`：冻结为运行编排入口，新增功能优先下沉到 `scripts/systems/`、`scripts/game/` 或 `scripts/ui/`。
- `main_menu.gd`：拆出 run setup、settings、archive/codex 渲染辅助，先通过 helper 脚本或子控件承接，不一次性重写场景。
- `auto_weapon.gd`：保留主执行器，但把不同武器族的 runtime profile、环绕/光环/地面区映射逐步迁入专门 resolver。
- `run_visual_snapshot_regression.gd`：拆成数据目标、截图执行、像素检查三段工具，降低单脚本维护成本。
- 测试大文件：按系统拆分新测试，不再继续扩大 `test_challenge_layer_flow.gd`、`test_hidden_layer_achievement_flow.gd`。

### 第二轮：建立守门规则

- 单个业务脚本超过 800 行时，不再往里面加新系统，只允许 bugfix 或抽取。
- 单个 UI 脚本超过 600 行时，新面板必须独立脚本/场景。
- 新增 JSON schema 字段必须同步 `scripts/validate_configs.py` 和对应 `test/unit/test_*_config.gd`。
- 所有人工复核截图必须落在 `test/manual_review_evidence/<date-or-topic>/` 并更新证据 README。

## 下一步开发建议

1. 先执行文档治理提交：README 分层、AGENTS.md 调优、当前状态文档落地。
2. 再做代码拆分计划，不直接大改；优先给 `game_world.gd` 和 `main_menu.gd` 标出可抽取函数群。
3. 启动 Stage 7 资产接入：角色、怪物、弹道、UI 图标、SFX/BGM 分批替换占位资源。
4. 做 5/10/20 分钟平衡 probe 与 Godot MCP 人工截图复核，调敌潮、升级、宝箱、掉落和伤害曲线。
5. 最后再进入发布门禁：导出包、平台 smoke、资源验收、兼容性 rehearsal。
