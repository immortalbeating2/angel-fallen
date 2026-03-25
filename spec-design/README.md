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
| [full-game-content-plan-2026-03-22.md](./full-game-content-plan-2026-03-22.md) | 完整版内容完工总计划：完整版目标、顺序执行阶段与当前执行项 |
| [remaining-game-content-checklist-2026-03-22.md](./remaining-game-content-checklist-2026-03-22.md) | 当前阶段剩余游戏开发内容清单，聚焦 Stage 5 收口与下一阶段切换 |
| [full-development-remaining-checklist-2026-03-22.md](./full-development-remaining-checklist-2026-03-22.md) | 从当前进度到完整游戏收尾的剩余内容总清单与推荐 session 顺序 |
| [stage5-closure-2026-03-25.md](./stage5-closure-2026-03-25.md) | Stage 5 正式收口说明：明确已完成真值、Stage 5/6/7 边界与本轮自动化验收基线 |
| [stage5-acceptance-record-2026-03-25.md](./stage5-acceptance-record-2026-03-25.md) | Stage 5 验收记录：回写三路线、三结局、首通/复通差异与主要 UI 出口的通过结论 |
| [stage5-acceptance-summary-2026-03-25.md](./stage5-acceptance-summary-2026-03-25.md) | Stage 5 统一验收摘要：为后续 Stage 6 session 提供最短承接基线 |
| [mvp-release-freeze-2026-03-22.md](./mvp-release-freeze-2026-03-22.md) | D43 后的可发布 MVP 冻结范围、发布阻塞项与最短执行路径 |
| [release-smoke-checklist-2026-03-22.md](./release-smoke-checklist-2026-03-22.md) | MVP 发布前的自动化门禁、三平台导出命令与人工 smoke checklist |
| [export-template-setup-2026-03-22.md](./export-template-setup-2026-03-22.md) | Godot 4.6.1 导出模板安装要求、本机 CLI 约定与导出前置校验 |
| [release-rehearsal-record-2026-03-22.md](./release-rehearsal-record-2026-03-22.md) | 首轮发布演练记录：自动化通过、三平台导出产物已生成，待人工 smoke 收口 |
| [stage7-asset-production-guide-2026-03-24.md](./stage7-asset-production-guide-2026-03-24.md) | Stage 7 可单独开发资产清单、统一风格圣经、Gemini 提示词模板、项目路径与文件格式要求 |
| [stage7-gemini-batch-production-manual-2026-03-24.md](./stage7-gemini-batch-production-manual-2026-03-24.md) | Stage 7 Gemini 批量生成执行手册：批次拆分、提示词母版、筛选标准与落盘建议 |
| [stage7-gemini-first-batch-task-list-2026-03-24.md](./stage7-gemini-first-batch-task-list-2026-03-24.md) | Stage 7 首批 Gemini 生成任务清单：可立即开跑的首批背景、UI、图标与音频提示词任务卡 |
| [stage7-gemini-copyable-prompt-pack-2026-03-24.md](./stage7-gemini-copyable-prompt-pack-2026-03-24.md) | Stage 7 Gemini 可复制提示词包：面向首批任务的直接投喂文本、变体提示词与筛选口径 |
| [stage7-gemini-effects-fonts-shaders-prompt-pack-2026-03-24.md](./stage7-gemini-effects-fonts-shaders-prompt-pack-2026-03-24.md) | Stage 7 Gemini 提示词包补充：覆盖 effects、fonts、shaders 三类目录的可执行文本、brief 与草案任务 |
| [stage7-character-enemy-weapon-asset-strategy-2026-03-24.md](./stage7-character-enemy-weapon-asset-strategy-2026-03-24.md) | Stage 7 角色/敌人/武器资产生成策略：明确三类精灵目录的阶段边界、生成流程、命名与 Gemini 使用方式 |
| [stage7-three-tier-prompt-system-2026-03-24.md](./stage7-three-tier-prompt-system-2026-03-24.md) | Stage 7 三档提示词总表：为全部主要资产类别统一提供完整版、标准版、超短版提示词 |
| [stage7-asset-review-and-landing-workflow-2026-03-24.md](./stage7-asset-review-and-landing-workflow-2026-03-24.md) | Stage 7 资产筛选与落盘工作流：统一候选筛选、状态分层、命名、目录落点与入库验收流程 |
| [stage7-asset-intake-ledger-template-2026-03-24.md](./stage7-asset-intake-ledger-template-2026-03-24.md) | Stage 7 资产 intake ledger 模板：统一记录批次、任务 ID、主选/备选、提示词档位、状态与落盘目录 |
| [stage7-first-batch-intake-ledger-template-2026-03-24.md](./stage7-first-batch-intake-ledger-template-2026-03-24.md) | Stage 7 首批批次收稿模板：预填 A1-A4、B1-B3、C1-C2、G1-G2 的首轮收稿表与验收清单 |

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
| 0.4.39 | 2026-03-21 | 下一周期 D37 完成：发布候选稳定性分层评分与审批收敛看板（chapter_snapshot_v13 + stability_scoring/stability_tiers/convergence_dashboard/ci_signal_contract） |
| 0.4.40 | 2026-03-21 | 下一周期 D38 完成：收敛趋势强化与异常生命周期联动治理（chapter_snapshot_v14 + convergence_trend_reinforcement/exception_lifecycle_linkage） |
| 0.4.41 | 2026-03-21 | 下一周期 D39 完成：视觉门禁与性能基线联评（chapter_snapshot_v15 + visual_performance_cogate） |
| 0.4.42 | 2026-03-21 | 下一周期 D40 完成：联评阈值模板化与跨平台对齐治理（chapter_snapshot_v16 + cogate_threshold_templates/cross_platform_alignment） |
| 0.4.43 | 2026-03-21 | 下一周期 D41 完成：高压场景性能压测标准化与对齐看板细化（chapter_snapshot_v17 + pressure_scenario_standardization/alignment_dashboard_refinement） |
| 0.4.44 | 2026-03-21 | 下一周期 D42 完成：高压场景对齐收敛门禁与回归周期开窗治理（chapter_snapshot_v18 + pressure_alignment_convergence_gate/regression_cycle_window_governance） |
| 0.4.45 | 2026-03-22 | 下一周期 D43 完成：多周期自适应门禁与发布回灌治理（chapter_snapshot_v19 + multi_cycle_adaptive_gate/release_feedback_governance） |
| 0.4.46 | 2026-03-22 | 新增可发布 MVP 冻结清单，明确最短发布路径、P0 阻塞项与延期范围 |
| 0.4.47 | 2026-03-22 | 补齐 Win/Linux/macOS 导出预设并新增 MVP 发布 smoke checklist |
| 0.4.48 | 2026-03-22 | 新增导出模板准备文档与首轮发布演练记录，明确当前发布阻塞为 export templates 缺失 |
| 0.4.49 | 2026-03-22 | 安装 Godot 4.6.1 export templates 并打通三平台首轮导出，发布阻塞收敛为产物级人工 smoke 与归档 |
| 0.4.50 | 2026-03-22 | 补充三平台产物大小与 SHA256 归档，并确认 Windows 最小启动 smoke 已通过 |
| 0.4.51 | 2026-03-22 | 新增完整版内容完工总计划，并完成第 1 顺位内容基线对齐（角色解锁链 + 33 条记忆碎片 + 测试护栏） |
| 0.4.52 | 2026-03-22 | 推进第 2 顺位主线章节与环境补完第一批：四章 room_profiles、chapter_3/4 新环境机制与测试护栏 |
| 0.4.53 | 2026-03-22 | 推进第 2 顺位主线章节与环境补完第二批：章节房间节奏 profile、route brief 文案差异与房间 pacing 测试 |
| 0.4.54 | 2026-03-22 | 推进第 2 顺位主线章节与环境补完第三批：chapter_progression_profiles、章节化 clear/transition/event 表达与 room_history 节奏护栏 |
| 0.4.55 | 2026-03-22 | 推进第 2 顺位主线章节与环境补完第四批并完成阶段收口：mainline nodes + history recap 运行时表达、schema 护栏与测试补齐 |
| 0.4.56 | 2026-03-22 | 推进第 3 顺位 Boss 与敌群成品化第一批：寒霜君王/虚空之主阶段技能差异、Boss 协同召唤与对象池统计修复 |
| 0.4.57 | 2026-03-22 | 推进第 3 顺位 Boss 与敌群成品化第二批：阶段转折压制、Mini-Boss 协同召唤增强与行为测试补齐 |
| 0.4.58 | 2026-03-22 | 推进第 3 顺位 Boss 与敌群成品化第三批并完成阶段收口：Boss 演出节奏音频联动、跨章 Mini-Boss 强度曲线与专项回归测试 |
| 0.4.59 | 2026-03-22 | 推进第 4 顺位构筑与成长深度第一批：流派锚点体系与锻造-商店-进化首轮联动（含专项回归测试） |
| 0.4.60 | 2026-03-22 | 推进第 4 顺位构筑与成长深度第二批：锻造配方化与 shop 配置驱动联动（含 schema 护栏与行为回归） |
| 0.4.61 | 2026-03-22 | 推进第 4 顺位构筑与成长深度第三批：章节 Boss 饰品掉落与构筑锚点联动（含行为回归测试） |
| 0.4.62 | 2026-03-22 | 推进第 4 顺位构筑与成长深度第四批并完成阶段收口：跨章节收益曲线、长局房间倍率与奖励曲线专项测试 |
| 0.4.63 | 2026-03-22 | 推进第 5 顺位叙事、营地与结局闭环第一批：路线弧线摘要、营地反思文本与章节转场叙事增强 |
| 0.4.64 | 2026-03-22 | 推进第 5 顺位叙事、营地与结局闭环第二批：三结局兑现、后记链路、碎片触发节奏与 payoff/epilogue 结算展示 |
| 0.4.65 | 2026-03-22 | 新增剩余游戏开发内容清单与完整开发剩余内容清单，供新 session 直接承接后续阶段 |
| 0.4.66 | 2026-03-24 | 按当前代码/测试真值同步 Stage 5/6 文档：补记叙事前台闭环、隐藏层档案进度与 `CL1` 挑战层最小闭环，并明确剩余未完成项 |
| 0.4.67 | 2026-03-24 | 新增 Stage 7 资产生产规范文档，明确可单独开发资产、Gemini 统一风格提示词、项目路径与文件格式要求 |
| 0.4.68 | 2026-03-24 | 新增 Stage 7 Gemini 批量生成执行手册，并为新增资产目录补占位文件以固定版本控制结构 |
| 0.4.69 | 2026-03-24 | 新增 Stage 7 首批 Gemini 生成任务清单，按背景、UI、图标与音频提示词拆成可直接执行的首批批次 |
| 0.4.70 | 2026-03-24 | 新增 Stage 7 Gemini 可复制提示词包，并为首批关键资产目录补充 README 收稿说明 |
| 0.4.71 | 2026-03-24 | 新增 effects/fonts/shaders 三类目录的 Gemini 提示词补充文档，覆盖通用 VFX、字体系统 brief 与 shader 设计草案任务 |
| 0.4.72 | 2026-03-24 | 新增角色/敌人/武器三类精灵目录的资产生成策略文档，并补目录 README 与阶段性生成边界说明 |
| 0.4.73 | 2026-03-24 | 新增 Stage 7 三档提示词总表，为背景、UI、音频、VFX、字体、shader、tiles、角色、敌人、武器与高耦合概念提供完整版/标准版/超短版口径 |
| 0.4.74 | 2026-03-24 | 新增 Stage 7 资产筛选与落盘工作流，并补 `assets/README.md` 统一说明候选资产的筛选、状态与入库规则 |
| 0.4.75 | 2026-03-24 | 新增 Stage 7 intake ledger 通用模板与首批批次收稿模板，补齐批次记录、主选/备选追踪与首轮验收表 |
| 0.4.76 | 2026-03-25 | 完成 Stage 5 正式收口：新增收口文档/验收记录/统一摘要，补三结局首通-复通差异回归测试，并将总计划状态回写为 completed |
| 0.4.77 | 2026-03-25 | 推进 Stage 6 Session 4：补齐 `CL1` 失败路径、`Sigil Bundle` / `Archive Insight` 分支与营地回显，并回写剩余清单状态 |
| 0.4.78 | 2026-03-25 | 推进 Stage 6 Session 5/6：补齐 `FS2` Forge Trial 最小可玩闭环回归，明确 `sigils` / `insight` 继续停留在 Archive Ledger/UI 字段，并完成 `CL2+` challenge schema 基线泛化 |
| 0.4.79 | 2026-03-25 | 推进 Stage 6 中期第一步：为隐藏层重复清档新增 `Archive Return` Meta Return 里程碑，并在隐藏层 settlement 文案中接入长期回流提示 |
| 0.4.80 | 2026-03-25 | 推进 Stage 6 中期第二步：落地首个真实 `CL2` 挑战层闭环，补齐 `Archive Return` 解锁后的营地预览、Entry/Elite/Boss/Settlement 流程、强化奖励档位与 challenge plan 回归 |
| 0.4.81 | 2026-03-25 | 推进 Stage 6 中期第三步：扩展隐藏层复清与 `CL1/CL2` 闭环成就，补主菜单 `Challenge Layer` 成就分组，并回写 Stage 6 进度文档 |
| 0.4.82 | 2026-03-25 | 推进 Stage 6 中期第四步：扩展 archive codex 覆盖 `Archive Return` 与 `CL1/CL2` 挑战层闭环，补齐 Meta Return / Challenge Layer detail 与 Stage 6 文档回写 |
| 0.4.83 | 2026-03-25 | 推进 Stage 6 中期第五步：落地首个更深层 `CL3` 挑战层闭环，补齐 `CL2` 清档后的 `O` 热键、Entry/Elite/Combat/Boss/Settlement 五段流程、第三档奖励与 Stage 6 文档回写 |
| 0.4.84 | 2026-03-25 | 推进 Stage 6 中期第六步：补齐 `CL3` 对应的 challenge-specific achievement / archive codex，扩展 `Sovereign Curator` 与 `Sovereign Echo Archive`，并回写 Stage 6 文档与回归结果 |
| 0.4.85 | 2026-03-25 | 完成 Stage 6 正式收口：落地最终 `CL4` 与 `Apex Return`、补齐 `CL4` 对应成就/codex、追加 `char_curator` / `wpn_reliquary_orb` / `evo_zenith_reliquary` 最小内容包，并将总计划状态回写为 completed |
