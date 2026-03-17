# 测试方案

## 1. 测试策略概述

### 1.1 测试层级

```
┌─────────────────────────────────┐
│     E2E / 集成测试 (手动)        │  完整游戏流程验证
├─────────────────────────────────┤
│     系统集成测试 (半自动)        │  多系统协作验证
├─────────────────────────────────┤
│     单元测试 (自动化)            │  单个系统/组件验证
├─────────────────────────────────┤
│     数据验证 (自动化)            │  配置表/Resource校验
└─────────────────────────────────┘
```

### 1.2 测试工具

- Godot 内置测试: `GdUnit4` 插件（GDScript单元测试框架）
- 性能分析: Godot Profiler + 自定义性能监控面板
- 自动化回归: CI/CD 通过 Godot headless 模式运行测试

---

## 2. 单元测试

### 2.1 伤害系统测试 (test_damage_system.gd)

| 测试ID | 测试用例 | 输入 | 预期输出 |
|--------|----------|------|----------|
| DMG-01 | 基础伤害计算 | base=10, mult=1.0, armor=0 | 10 |
| DMG-02 | 护甲减伤 | base=100, armor=0.3 | 70 |
| DMG-03 | 暴击伤害 | base=10, crit_rate=1.0, crit_mult=1.5 | 15 |
| DMG-04 | 伤害加成叠加 | base=10, bonus=+50% | 15 |
| DMG-05 | 最低伤害保底 | base=1, armor=0.99 | 1 (最低1点) |
| DMG-06 | 多重加成组合 | base=10, bonus=50%, crit=1.5x, armor=20% | 18 |
| DMG-07 | 状态效果-燃烧DOT | fire_dmg=100, burn_rate=10% | 10/tick |
| DMG-08 | 状态效果-冰冻减速 | slow=50%, base_speed=200 | speed=100 |
| DMG-09 | 神圣伤害无视护甲 | holy_dmg=50, armor=50%, ignore=30% | 42.5 |
| DMG-10 | 零伤害边界 | base=0 | 0 |

```gdscript
# 示例测试代码
class_name TestDamageSystem extends GdUnitTestSuite

func test_basic_damage() -> void:
    var result = DamageSystem.calculate(10.0, 1.0, 0.0, false, 1.0)
    assert_float(result.damage).is_equal(10.0)

func test_armor_reduction() -> void:
    var result = DamageSystem.calculate(100.0, 1.0, 0.3, false, 1.0)
    assert_float(result.damage).is_equal(70.0)

func test_critical_hit() -> void:
    # 强制暴击
    var result = DamageSystem.calculate(10.0, 1.0, 0.0, true, 1.5)
    assert_float(result.damage).is_equal(15.0)
    assert_bool(result.is_crit).is_true()

func test_minimum_damage() -> void:
    var result = DamageSystem.calculate(1.0, 1.0, 0.99, false, 1.0)
    assert_float(result.damage).is_greater_equal(1.0)
```

### 2.2 经验与升级测试 (test_level_system.gd)

| 测试ID | 测试用例 | 输入 | 预期输出 |
|--------|----------|------|----------|
| LVL-01 | 经验曲线计算 | level=1 | xp_needed=10 |
| LVL-02 | 经验曲线计算 | level=10 | xp_needed=199 |
| LVL-03 | 升级触发 | xp=10, level=1 | level=2, 触发升级事件 |
| LVL-04 | 连续升级 | xp=100, level=1 | 正确连续升级多次 |
| LVL-05 | 经验溢出 | xp=15, need=10 | 溢出5xp保留到下一级 |
| LVL-06 | XP倍率 | xp=10, mult=1.5 | 实际获得15xp |
| LVL-07 | 升级选项生成-无武器 | 0武器0被动 | 3个新武器/被动选项 |
| LVL-08 | 升级选项生成-满武器 | 6武器6被动全满级 | 无可用选项（跳过） |
| LVL-09 | 进化选项优先 | 进化条件满足 | 进化选项必定出现 |
| LVL-10 | 重随机制 | reroll_count=0, gold=50 | 成功重随，gold=0 |
| LVL-11 | 重随次数耗尽 | reroll_count=3 | 重随失败 |

### 2.3 武器系统测试 (test_weapon_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| WPN-01 | 武器装备 | 武器正确挂载到WeaponMount |
| WPN-02 | 武器上限 | 第7个武器无法装备 |
| WPN-03 | 武器升级 | 等级+1，属性正确更新 |
| WPN-04 | 武器满级 | 超过max_level不再升级 |
| WPN-05 | 冷却计算含CDR | CDR=30%, base_cd=1.0 → actual=0.7 |
| WPN-06 | 追踪弹寻敌 | 正确锁定最近敌人 |
| WPN-07 | 追踪弹无目标 | 直线飞行后超时销毁 |
| WPN-08 | 穿透弹 | pierce=3时穿透3个敌人后销毁 |
| WPN-09 | 环绕武器数量 | 升级后环绕体数量正确增加 |
| WPN-10 | 链式弹射 | 正确弹射指定次数，伤害衰减正确 |
| WPN-11 | 进化检测 | 武器+被动满级时检测到可进化 |
| WPN-12 | 进化执行 | 移除原武器和被动，生成进化武器 |

### 2.4 敌人系统测试 (test_enemy_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| ENM-01 | 敌人生成位置 | 在屏幕外围正确位置生成 |
| ENM-02 | 追踪AI | 敌人朝玩家方向移动 |
| ENM-03 | 远程AI | 保持距离并发射弹幕 |
| ENM-04 | 敌人死亡掉落 | 死亡后正确生成掉落物 |
| ENM-05 | 难度缩放 | 5分钟后敌人HP为1.5倍 |
| ENM-06 | 同屏上限 | 不超过配置的最大敌人数 |
| ENM-07 | 精英波次 | 定时触发精英波次 |
| ENM-08 | Boss阶段切换 | HP低于阈值时切换行为阶段 |
| ENM-09 | Boss技能预警 | 技能释放前显示预警 |
| ENM-10 | 对象池回收 | 死亡敌人正确回收到池中 |

### 2.5 地图生成测试 (test_map_generator.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| MAP-01 | BSP分割 | 生成的房间数在预期范围内 |
| MAP-02 | 房间不重叠 | 所有房间矩形无交集 |
| MAP-03 | 走廊连通性 | 所有房间可达（图连通） |
| MAP-04 | 房间类型分配 | 必有1个start/boss/shop |
| MAP-05 | Boss房间距离 | Boss房间距起点最远 |
| MAP-06 | 最小房间尺寸 | 所有房间 ≥ 最小尺寸 |
| MAP-07 | 种子确定性 | 相同种子生成相同地图 |
| MAP-08 | 不同种子差异性 | 不同种子生成不同地图 |
| MAP-09 | 楼层递进 | 高楼层房间数更多 |
| MAP-10 | 边界检查 | 房间和走廊不超出地图边界 |

### 2.6 存档系统测试 (test_save_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| SAV-01 | 新存档创建 | 无存档文件时创建默认MetaData |
| SAV-02 | 保存与加载 | 保存后加载数据一致 |
| SAV-03 | 数据完整性 | 篡改文件后校验失败，重置存档 |
| SAV-04 | 版本兼容 | 旧版本存档可迁移到新版本 |
| SAV-05 | 并发安全 | 快速连续保存不损坏文件 |
| SAV-06 | 大数据量 | 大量Meta数据保存/加载性能 ≤ 100ms |

---

## 3. 系统集成测试

### 3.1 战斗循环集成

| 测试ID | 测试场景 | 验证点 |
|--------|----------|--------|
| INT-01 | 武器攻击→敌人受伤→死亡→掉落→拾取→经验→升级 | 完整战斗循环 |
| INT-02 | 多武器同时攻击不同敌人 | 伤害独立计算，无冲突 |
| INT-03 | 被动技能影响武器伤害 | 属性加成正确传递 |
| INT-04 | 升级选择武器→武器正确装备并开始攻击 | 系统间数据流 |
| INT-05 | 进化触发→旧武器移除→新武器生成 | 进化流程完整 |

### 3.2 Roguelike 流程集成

| 测试ID | 测试场景 | 验证点 |
|--------|----------|--------|
| INT-06 | 进入房间→门关闭→敌人生成→清除→门开启 | 房间战斗流程 |
| INT-07 | 清除所有房间→进入Boss房→击败Boss→进入下一层 | 楼层推进 |
| INT-08 | 商店购买→金币扣除→物品获得 | 商店交互 |
| INT-09 | 随机事件触发→效果正确应用 | 事件系统 |
| INT-10 | 小地图实时更新探索状态 | UI与地图同步 |

### 3.3 Meta 进度集成

| 测试ID | 测试场景 | 验证点 |
|--------|----------|--------|
| INT-11 | 游戏结束→Meta货币计算→保存 | 结算流程 |
| INT-12 | Meta升级→下一局属性生效 | 永久升级效果 |
| INT-13 | 解锁角色→角色选择界面可选 | 解锁流程 |

---

## 4. 性能测试

### 4.1 帧率测试

| 测试ID | 场景 | 目标 | 测试方法 |
|--------|------|------|----------|
| PERF-01 | 空场景 | ≥ 60 FPS | 基准测试 |
| PERF-02 | 100敌人 + 50弹幕 | ≥ 60 FPS | 自动生成 |
| PERF-03 | 300敌人 + 100弹幕 | ≥ 60 FPS | 自动生成 |
| PERF-04 | 500敌人 + 200弹幕 | ≥ 55 FPS | 压力测试 |
| PERF-05 | 500敌人 + 200弹幕 + 100掉落物 | ≥ 50 FPS | 极限测试 |

### 4.2 内存测试

| 测试ID | 场景 | 目标 |
|--------|------|------|
| MEM-01 | 游戏启动 | ≤ 150 MB |
| MEM-02 | 正常游戏10分钟 | ≤ 350 MB |
| MEM-03 | 极限场景20分钟 | ≤ 512 MB |
| MEM-04 | 内存泄漏检测 | 30分钟运行无持续增长 |
| MEM-05 | 对象池效率 | 池对象复用率 ≥ 90% |

### 4.3 加载时间测试

| 测试ID | 操作 | 目标 |
|--------|------|------|
| LOAD-01 | 游戏启动到主菜单 | ≤ 3秒 |
| LOAD-02 | 主菜单到游戏开始 | ≤ 2秒 |
| LOAD-03 | 楼层切换 | ≤ 1.5秒 |
| LOAD-04 | 存档加载 | ≤ 1秒 |

### 4.4 性能监控面板

```gdscript
# 开发模式下的实时性能监控
class_name PerformanceMonitor extends CanvasLayer

func _process(_delta: float) -> void:
    fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
    enemy_label.text = "Enemies: %d" % get_tree().get_nodes_in_group("enemies").size()
    projectile_label.text = "Projectiles: %d" % get_tree().get_nodes_in_group("projectiles").size()
    memory_label.text = "Memory: %.1f MB" % (OS.get_static_memory_usage() / 1048576.0)
    draw_calls_label.text = "Draw Calls: %d" % RenderingServer.get_rendering_info(...)
```

---

## 5. 平衡性测试

### 5.1 自动化模拟

编写 AI 控制的自动游戏脚本，模拟不同策略：

| 策略 | 描述 | 验证指标 |
|------|------|----------|
| 随机选择 | 升级时随机选择 | 平均存活时间 5-8分钟 |
| 纯武器 | 优先选武器 | 平均存活时间 8-12分钟 |
| 纯被动 | 优先选被动 | 平均存活时间 6-10分钟 |
| 最优策略 | 优先进化组合 | 平均存活时间 15-25分钟 |
| 单武器 | 只升级一个武器 | 可通关但困难 |

### 5.2 数值平衡检查点

| 时间点 | 玩家预期状态 | 敌人预期状态 |
|--------|-------------|-------------|
| 2分钟 | Lv.3-5, 1-2武器 | 普通敌人为主 |
| 5分钟 | Lv.8-12, 3-4武器 | 开始出现精英 |
| 10分钟 | Lv.18-22, 5-6武器(部分满级) | 大量敌人+精英 |
| 15分钟 | Lv.25-30, 有进化武器 | 高强度+频繁精英 |
| 20分钟 | Lv.30+, 多个进化武器 | 极限难度 |

---

## 6. 兼容性测试

| 测试ID | 测试项 | 测试环境 |
|--------|--------|----------|
| COMPAT-01 | Windows 10 运行 | Win10 22H2 |
| COMPAT-02 | Windows 11 运行 | Win11 23H2 |
| COMPAT-03 | Linux 运行 | Ubuntu 22.04 |
| COMPAT-04 | macOS 运行 | macOS 14 Sonoma |
| COMPAT-05 | 低配GPU | Intel UHD 630 |
| COMPAT-06 | 手柄输入 | Xbox Controller |
| COMPAT-07 | 键盘+鼠标 | 标准外设 |
| COMPAT-08 | 4K分辨率 | 3840×2160 |
| COMPAT-09 | 超宽屏 | 21:9 比例 |
| COMPAT-10 | 低分辨率 | 1280×720 |

---

## 7. 回归测试与CI

### 7.1 CI 流水线

```yaml
# .github/workflows/test.yml
name: Game Tests
on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: chickensoft-games/setup-godot@v2
        with:
          version: 4.3.0
      - name: Run GdUnit4 Tests
        run: godot --headless --script addons/gdUnit4/bin/GdUnitCmdTool.gd --run-all

  data-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate JSON configs
        run: python scripts/validate_configs.py
      - name: Check Resource integrity
        run: python scripts/check_resources.py
```

### 7.2 数据验证脚本

自动检查：
- 所有 JSON 配置表格式正确
- 所有 Resource 文件引用的资源存在
- 武器等级数组长度 = max_level
- 进化配方引用的武器/被动ID存在
- 掉落表权重总和 > 0
- i18n 键值对完整（中英文都有对应翻译）
