# Angel Fallen 完整类幸存者核心系统补完开发计划

## Summary

目标：在现有房间制 Roguelike 骨架上，补齐成熟类幸存者游戏的主梁：时间制敌潮导演、多武器/被动栏位、武器等级、宝箱进化、吸附拾取、构筑查看与长局平衡工具。

本计划保留当前房间制结构，不把项目改成纯开放地图。类幸存者系统先服务 combat room 和长局压力曲线，Stage 5/6 叙事、隐藏层、挑战层保持现有边界。

## 分阶段推进

| 阶段 | 目标 | 关键产出 | 完成标准 |
|------|------|----------|----------|
| Phase A | 文档与接口冻结 | 本文档、`2026-5-2-plan.md`、`README.md` 索引 | `rg "survivor-core|类幸存者核心|Run Director" spec-design` 可检索 |
| Phase B | Run Director | `scripts/systems/run_director.gd`、刷怪器接入、单测 | 0/30/60/300 秒 profile 正确，120 秒内至少 4 次压力变化 |
| Phase C | Loadout + Weapon Level | `weapon_loadout.gd`、`weapon_levels.json`、配置校验 | 起始武器进 slot 0，重复获得升级，满槽不新增第 7 把武器 |
| Phase D | Evolution + Treasure Chest | 宝箱脚本/场景、进化触发源字段 | 满级武器 + 指定被动可由宝箱触发进化，条件不足不触发 |
| Phase E | Pickup Magnet / Vacuum | 拾取全屏吸附状态、新拾取类型、音效限频 | Magnet pickup 触发后所有 pickup 快速飞向玩家 |
| Phase F | Build Panel | 局内构筑查看面板 | 720p/1080p/4K 下可读，武器/被动/进化状态同步 |
| Phase G | Balance Harness | `run_survivor_balance_probe.gd`、JSON 报告 | headless 可输出 5 分钟压缩 probe 报告 |

## Public Interfaces

新增脚本 API：

- `RunDirector.get_current_wave_profile(elapsed_seconds: float) -> Dictionary`
- `EnemySpawner.apply_director_wave(profile: Dictionary) -> void`
- `WeaponLoadout.add_or_level_weapon(weapon_id: String) -> Dictionary`
- `WeaponLoadout.add_or_level_passive(passive_id: String) -> Dictionary`
- `AutoWeapon.apply_weapon_level_profile(profile: Dictionary) -> void`
- `Pickup.activate_vacuum(target: Node2D, speed_mult: float) -> void`

新增配置：

- `data/balance/weapon_levels.json`
- `data/balance/evolutions.json` 新增兼容字段：
  - `required_weapon_level`
  - `trigger_source`

新增测试/报告：

- `test/unit/test_run_director.gd`
- `test/unit/test_weapon_loadout.gd`
- `test/unit/test_treasure_chest_evolution.gd`
- `test/unit/test_pickup_vacuum.gd`
- `test/unit/test_survivor_balance_probe_config.gd`
- `test/reports/survivor_balance_probe.json`

## 实施记录

### 2026-05-03 v1 落地边界

- Run Director 先作为 combat room 内的压力曲线输入，不替代现有房间刷怪、Boss、挑战层逻辑。
- Weapon Loadout v1 已完成状态、等级、UI 和进化条件；2026-05-04 追加多武器运行时 profile，非主武器可作为独立冷却的投射物执行器参与自动攻击。
- 宝箱 v1 使用现有程序化 UI 风格，2026-05-04 已从 pickup 接入运行时开奖：满足任意武器栏满级进化条件时优先进化，否则结算普通金币/矿石/食物奖励。
- 构筑面板 v1 以可读信息为主，DPS 只记录运行内估算字段，不做复杂图表。
- 平衡探针 v1 输出可机器读取 JSON，用于后续长局调参，不默认纳入 20 分钟 CI 门禁。

### 2026-05-04 续补记录

- 多武器执行器：`AutoWeapon` 读取 `WeaponLoadout.weapon_slots`，为每个武器槽生成独立运行时 profile 与冷却，主武器继续沿用角色起始武器执行器，副武器以自身 `projectile_style`、等级、数量、命中数和溅射参数自动发射。
- 宝箱运行时：`chest_common` / `chest_rare` pickup 不再直接换金币，而是调用 TreasureChest 流程。`chest_rare` 可开奖 3 个普通奖励；若 `LevelUpSystem.get_available_treasure_evolutions()` 有候选，则优先调用 `apply_evolution_recipe()` 并标记 loadout 槽位已进化。
- 副武器进化：宝箱进化候选会检查 6 武器栏中的任意满级武器。副武器进化只更新对应 loadout 槽位的 evolved/profile，不覆盖角色起始主武器执行器。
- 回归护栏：`test_core_flow_regression.gd` 新增运行时宝箱进化、副武器宝箱进化和多武器实际发射集成断言。

## Test Plan

每阶段最低验证：

```bash
godot --headless --path . --quit
godot --headless --path . -s addons/gut/gut_cmdln.gd -gtest=res://test/integration/test_core_flow_regression.gd -gexit
python scripts/tools/check_json_syntax.py
python scripts/validate_configs.py
```

阶段完成后补充：

```bash
godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -ginclude_subdirs -gexit
godot --headless --path . -s res://scripts/tools/run_survivor_balance_probe.gd
git diff --check
```
