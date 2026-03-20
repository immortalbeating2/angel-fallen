# 幸存者Roguelike - OpenSpec 项目规格文档

## 项目概述

**项目名称**: Survivor Roguelike  
**类型**: 动作 Roguelike / 类吸血鬼幸存者  
**引擎**: Godot 4.x + GDScript  
**平台**: PC 桌面端 (Windows / Linux / macOS)  
**视角**: 俯视角 2D  

## 核心理念

将经典幸存者玩法（自动攻击、海量怪物、升级选技能）与 Roguelike 元素（随机地图生成、地牢探索、永久死亡、Meta 进度）深度融合，打造一款具有高重玩性的动作生存游戏。

## 文档索引

| 文档 | 说明 |
|------|------|
| [requirements.md](./requirements.md) | 功能需求与非功能需求规格 |
| [architecture.md](./architecture.md) | 系统架构与模块划分 |
| [core-systems.md](./core-systems.md) | 核心系统详细设计 |
| [data-structures.md](./data-structures.md) | 数据结构、资源定义与配置表 |
| [test-plan.md](./test-plan.md) | 测试方案与质量保证 |
| [roadmap.md](./roadmap.md) | 实施路线图与里程碑 |
| [level-design.md](./level-design.md) | 关卡设计：章节、楼层、房间、环境机制、Boss |
| [supplement-updates.md](./supplement-updates.md) | 计划外更新补充说明（含历史增量同步） |
| [truth-check-2026-03-20.md](./truth-check-2026-03-20.md) | 文档承诺与当前实现真值核对报告 |
| [development-plan-2026-03-20.md](./development-plan-2026-03-20.md) | 真值核对后的落地开发计划与推进记录 |
| [development-plan-supplement-2026-03-20-session.md](./development-plan-supplement-2026-03-20-session.md) | 基于 session 复盘的开发过程确认与计划补充（V2） |
| [content-depth-cycle-1-d1-freeze-2026-03-20.md](./content-depth-cycle-1-d1-freeze-2026-03-20.md) | 下一周期内容优先计划的 D1 冻结清单（目标阈值与新增 ID 锁定） |

## 版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1.0 | 2026-03-18 | 初始规格文档 |
| 0.2.0 | 2026-03-18 | 新增关卡设计文档，扩展至13+2层 |
| 0.3.0 | 2026-03-18 | 新增计划外更新补充文档，统一记录实现增量 |
| 0.3.1 | 2026-03-18 | 将补充文档中的稳定增量回写到 requirements/test-plan |
| 0.3.2 | 2026-03-19 | 补充 Run-Plan 生成系统与同步开发时间线图（supplement 更新） |
| 0.3.3 | 2026-03-20 | 新增全量真值核对与分阶段落地计划文档 |
| 0.3.4 | 2026-03-20 | 新增 session 复盘补充计划文档，并回写主计划的阶段 C 补充项 |
| 0.3.5 | 2026-03-20 | 阶段 C1 落地：宝藏房挑战模式闭环（参数外置 + 运行时接入 + 校验/测试护栏） |
| 0.3.6 | 2026-03-20 | 阶段 C2 落地：新增关键流程集成回归测试，并回写真值核对与主计划状态 |
| 0.3.7 | 2026-03-20 | 阶段 D 首轮落地：主场景地表与门区块 TileMap 化，并新增可视层回归测试 |
| 0.3.8 | 2026-03-20 | 阶段 D 第二轮落地：危害可视层 TileMap 化，完成主场景三层可视迁移 |
| 0.3.9 | 2026-03-20 | 阶段 D 第三轮落地：TileMap 切换为资源化 tileset（PNG atlas + .tres），并补充构建工具与测试断言 |
| 0.4.3 | 2026-03-20 | 下一周期 D4 落地：新增性能/兼容最小可重复采样基线（targets + headless 脚本 + 测试 + CI接入） |
| 0.4.0 | 2026-03-20 | 启动下一周期（内容优先），新增 D1 冻结清单并回写主计划/补充计划/真值文档 |
| 0.4.1 | 2026-03-20 | 下一周期 D2 完成：数据层内容扩容（角色/进化/商店池/记忆碎片）并回写进度文档 |
| 0.4.2 | 2026-03-20 | 下一周期 D3 完成：补齐新增内容消费逻辑、抬升深度阈值并新增集成回归断言 |
| 0.4.4 | 2026-03-20 | 下一周期 D5 完成：质量基线扩展为 medium/high/extreme 分层压力采样，并新增告警分级（critical/warning/info） |
| 0.4.5 | 2026-03-20 | 下一周期 D6 完成：章节化门/危害 tileset 资源落地并接入运行时动态切换与回归断言 |
| 0.4.6 | 2026-03-20 | 下一周期 D7 完成：危害图层新增章节化动画节奏参数与 atlas 变体轮换回归护栏 |
| 0.4.7 | 2026-03-20 | 下一周期 D8 完成：新增章节地表细节层与 detail atlas/tileset，并补充可视层章节切换护栏 |
| 0.4.8 | 2026-03-20 | 下一周期 D9 完成：新增章节环境特效层与 ambient fx atlas/tileset，并补充章节切换与动画回归护栏 |
| 0.4.9 | 2026-03-20 | 下一周期 D10 完成：新增章节 visual_profile 参数化（tint/alpha/scroll）并接入运行时与回归护栏 |
| 0.4.10 | 2026-03-20 | 下一周期 D11 完成：新增章节 visual_profile 脉冲参数（detail pulse + ambient wave）并接入运行时与回归护栏 |
| 0.4.11 | 2026-03-20 | 下一周期 D12 完成：手绘风格 atlas 管线落地（含 manifest 护栏）并增强材质细节表达 |
| 0.4.12 | 2026-03-20 | 下一周期 D13 完成：内容深度二轮扩容（角色/进化/商店/记忆）并补齐消费与回归护栏 |
| 0.4.13 | 2026-03-20 | 下一周期 D14 完成：补齐 8 类资源目录族最小可用 `.tres` 基线并接入结构校验护栏 |
| 0.4.14 | 2026-03-20 | 下一周期 D15 完成：质量基线新增 boss endurance 压测场景并将 CI 扩展为 ubuntu+windows 矩阵 |
| 0.4.15 | 2026-03-20 | 下一周期 D16 完成：新增 release gate 演练链路并接入 CI 发布阈值复核 |
| 0.4.16 | 2026-03-20 | 下一周期 D17 完成：新增 compatibility rehearsal profile 演练链路并接入 CI 兼容阈值复核 |
| 0.4.17 | 2026-03-20 | 下一周期 D18 完成：内容深度三轮扩容（角色/进化/商店/记忆）并补齐消费与回归护栏 |
| 0.4.18 | 2026-03-20 | 下一周期 D19 完成：资源目录族映射扩展（catalog + 自动同步脚本 + 覆盖护栏） |
| 0.4.19 | 2026-03-20 | 下一周期 D20 完成：资源目录族升级为材质参数资产化基线（stub_catalog_v3 + material_profiles） |
| 0.4.20 | 2026-03-20 | 下一周期 D21 完成：首批 production_ready 资源验收链路落地（stub_catalog_v4 + resource acceptance rehearsal） |
| 0.4.21 | 2026-03-20 | 下一周期 D22 完成：production_ready 比例扩容与跨场景验收加深（batch_2 + ready ratio/smoke-depth gates） |
| 0.4.22 | 2026-03-20 | 下一周期 D23 完成：acceptance_profile 分层语义与验收报告分层（stub_catalog_v5 + profile-layer gates） |
| 0.4.23 | 2026-03-20 | 下一周期 D24 完成：production_ready 覆盖扩容与分层趋势基线（stub_catalog_v6 + bucket trend gates） |
| 0.4.24 | 2026-03-20 | 下一周期 D25 完成：实料资产替换批次扩展与场景可视验收（stub_catalog_v7 + scene-visual gates） |
| 0.4.25 | 2026-03-20 | 下一周期 D26 完成：production_ready 近全量覆盖与可视验收加压（stub_catalog_v8 + bool_true + ratio-by-category gates） |
| 0.4.26 | 2026-03-20 | 下一周期 D27 完成：章节级可视快照回归链路（visual_snapshot_targets + visual snapshot rehearsal/trend gate） |
| 0.4.27 | 2026-03-20 | 下一周期 D28 完成：可视快照精度收敛与后端差异治理（chapter_snapshot_v2 + precision stddev gates + backend profiles） |
| 0.4.28 | 2026-03-20 | 下一周期 D29 完成：实机截图基线对齐与视觉差异白名单治理（chapter_snapshot_v3 + baseline_alignment + diff_whitelist） |
| 0.4.29 | 2026-03-20 | 下一周期 D30-1 完成：新增 JSON 语法快速失败闸门并前置到 CI 校验链路（check_json_syntax.py） |
| 0.4.30 | 2026-03-20 | 下一周期 D30-2 完成：可视快照跨版本基线对比与分层报告收敛（chapter_snapshot_v4 + report_layers + cross_version_baseline） |
| 0.4.31 | 2026-03-20 | 下一周期 D30-3 完成：跨后端可视差异归因与白名单收敛自动化（chapter_snapshot_v5 + backend_attribution + whitelist_convergence） |
| 0.4.32 | 2026-03-20 | 下一周期 D30-4 完成：可视回归例外生命周期治理与自动回收策略（chapter_snapshot_v6 + exception_lifecycle） |
| 0.4.33 | 2026-03-20 | 下一周期 D31 完成：可视回归策略编排与发布级收敛模板化（chapter_snapshot_v7 + strategy_orchestration） |
| 0.4.34 | 2026-03-20 | 下一周期 D32 完成：可视回归策略发布清单与门禁模板固化（chapter_snapshot_v8 + release_gate_templates） |
| 0.4.35 | 2026-03-20 | 下一周期 D33 完成：跨后端矩阵治理与审批流程固化（chapter_snapshot_v9 + backend_matrix_governance + approval_workflow） |
| 0.4.36 | 2026-03-20 | 下一周期 D34 完成：审批记录持久化与跨流水线历史追溯（chapter_snapshot_v10 + approval_audit_trail） |
| 0.4.37 | 2026-03-20 | 下一周期 D35 完成：审批历史聚合与跨后端长期趋势归档（chapter_snapshot_v11 + approval_history_archive） |
| 0.4.38 | 2026-03-20 | 下一周期 D36 完成：审批历史分层阈值模板与发布候选追踪报告（chapter_snapshot_v12 + approval_threshold_templates + release_candidate_tracking） |
