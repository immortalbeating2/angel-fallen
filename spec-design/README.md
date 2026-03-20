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
