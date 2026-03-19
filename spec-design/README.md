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

## 版本记录

| 版本 | 日期 | 说明 |
|------|------|------|
| 0.1.0 | 2026-03-18 | 初始规格文档 |
| 0.2.0 | 2026-03-18 | 新增关卡设计文档，扩展至13+2层 |
| 0.3.0 | 2026-03-18 | 新增计划外更新补充文档，统一记录实现增量 |
| 0.3.1 | 2026-03-18 | 将补充文档中的稳定增量回写到 requirements/test-plan |
| 0.3.2 | 2026-03-19 | 补充 Run-Plan 生成系统与同步开发时间线图（supplement 更新） |
| 0.3.3 | 2026-03-20 | 新增全量真值核对与分阶段落地计划文档 |
