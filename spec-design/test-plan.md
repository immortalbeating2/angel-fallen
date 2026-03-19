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

- Godot 内置测试: `GUT` 插件（GDScript单元测试框架）
- 性能分析: Godot Profiler + 自定义性能监控面板
- 自动化回归: CI/CD 通过 Godot headless 模式运行测试

---

## 2. 单元测试

### 2.1 伤害系统测试 (test_damage_system.gd)

| 测试ID | 测试用例 | 输入 | 预期输出 |
|--------|----------|------|----------|
| DMG-01 | 基础伤害计算 | weapon_damage=10, bonus=0%, armor=0 | 10 |
| DMG-02 | 护甲减伤 | weapon_damage=100, armor=30% | 70 |
| DMG-03 | 暴击伤害 | weapon_damage=10, crit_rate=100%, crit_mult=1.5 | 15 |
| DMG-04 | 伤害加成叠加 | weapon_damage=10, bonus=+50% | 15 |
| DMG-05 | 最低伤害保底 | weapon_damage=1, armor=99% | 1 (最低1点) |
| DMG-06 | 多重加成组合 | weapon_damage=10, bonus=50%, crit=1.5x, armor=20% | 18 |
| DMG-07 | 状态效果-燃烧DOT | fire_dmg=100, burn_rate=10% | 10/tick |
| DMG-08 | 状态效果-冰冻减速 | slow=50%, base_speed=200 | speed=100 |
| DMG-09 | 神圣伤害穿透护甲 | holy_dmg=50, armor=50%, penetration=30% | 32.5 |
| DMG-10 | 零伤害边界 | weapon_damage=0 | 0 |
| DMG-11 | 护甲上限75% | weapon_damage=100, armor=90% | 25 (按75%上限) |
| DMG-12 | 击退效果 | weapon_damage=10, knockback_mult=1.5 | knockback=150 |

```gdscript
# 示例测试代码（DamageSystem.calculate_damage 签名见 core-systems.md Section 1.2）
extends GutTest

var _player: Node2D
var _enemy: Node2D

func before_each() -> void:
    _player = Node2D.new()
    _enemy = Node2D.new()

func test_basic_damage() -> void:
    # DMG-01: weapon_damage=10, no bonus, no armor
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 10.0, DamageSystem.DamageType.PHYSICAL, 0.0, 0.0, 1.0)
    assert_eq(result.final_damage, 10.0)

func test_armor_reduction() -> void:
    # DMG-02: weapon_damage=100, armor=30%
    _enemy.get_node("StatsComponent").armor = 0.3
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 100.0, DamageSystem.DamageType.PHYSICAL, 0.0, 0.0, 1.0)
    assert_eq(result.final_damage, 70.0)

func test_critical_hit() -> void:
    # DMG-03: 强制暴击
    _player.get_node("StatsComponent").crit_rate = 1.0
    _player.get_node("StatsComponent").crit_damage = 1.5
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 10.0, DamageSystem.DamageType.PHYSICAL, 0.0, 0.0, 1.0)
    assert_eq(result.final_damage, 15.0)
    assert_true(result.is_crit)

func test_minimum_damage() -> void:
    # DMG-05: 护甲极高时仍有最低1点伤害
    _enemy.get_node("StatsComponent").armor = 0.99
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 1.0, DamageSystem.DamageType.PHYSICAL, 0.0, 0.0, 1.0)
    assert_gte(result.final_damage, 1.0)

func test_holy_penetration() -> void:
    # DMG-09: 神圣伤害穿透护甲: 50 × (1 - 0.5 × (1 - 0.3)) = 32.5
    _enemy.get_node("StatsComponent").armor = 0.5
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 50.0, DamageSystem.DamageType.HOLY, 0.0, 0.3, 1.0)
    assert_eq(result.final_damage, 32.5)

func test_armor_cap() -> void:
    # DMG-11: 护甲超过75%时按75%计算
    _enemy.get_node("StatsComponent").armor = 0.9
    var result = DamageSystem.calculate_damage(
        _player, _enemy, 100.0, DamageSystem.DamageType.PHYSICAL, 0.0, 0.0, 1.0)
    assert_eq(result.final_damage, 25.0)
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
| ENM-05 | 难度缩放(楼层) | F5敌人基础HP倍率=3.0x |
| ENM-06 | 难度缩放(房间时间) | 房间战斗60s后敌人HP×1.5 |
| ENM-07 | 同屏上限 | 不超过配置的最大敌人数 |
| ENM-08 | 精英波次 | 房间战斗时间达标后触发精英波次 |
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
| SAV-07 | 备份恢复 | 主存档损坏时自动从 .bak 恢复 |
| SAV-08 | 版本迁移 | v1→v2 存档迁移保留所有有效字段 |

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
| PERF-03 | 300敌人 + 100弹幕 | ≥ 55 FPS | 自动生成 |
| PERF-04 | 500敌人 + 200弹幕 | ≥ 55 FPS | 压力测试 |
| PERF-05 | 500敌人 + 200弹幕 + 100掉落物 | ≥ 50 FPS | 极限测试 |
| PERF-06 | 场景切换（楼层/营地） | ≤ 0.5秒 | SceneManager.transition_to |

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
| 随机选择 | 升级时随机选择 | 平均通关楼层 F3-F5 |
| 纯武器 | 优先选武器 | 平均通关楼层 F6-F8 |
| 纯被动 | 优先选被动 | 平均通关楼层 F4-F6 |
| 最优策略 | 优先进化组合 | 可通关F13（通关率30-50%） |
| 单武器 | 只升级一个武器 | 可达F8-F10但困难 |

### 5.2 数值平衡检查点

> 采用 **楼层进度** 而非时间点作为平衡基准（房间内计时机制下，不同玩家通关时间差异较大）。

| 楼层进度 | 玩家预期状态 | 敌人预期状态 |
|----------|-------------|-------------|
| F1-F2 | Lv.1-5, 1武器, 0-2被动 | 普通敌人为主，倍率1.0-1.5x |
| F3-F4 | Lv.5-10, 2武器, 3-5被动 | 出现精英，章Boss倍率2.5x |
| F5-F6 | Lv.10-16, 2-3武器, 5-7被动 | 环境伤害叠加，倍率3.0-4.0x |
| F7-F8 | Lv.16-22, 3武器(有锻造), 7-8被动 | 高压+精英频繁，章Boss倍率6.0x |
| F9-F10 | Lv.22-28, 3-4武器, 8-10被动 | 冰冻/冻伤系统，倍率7.0-8.5x |
| F11-F12 | Lv.28-34, 4武器, 10-11被动 | 极限强度，章Boss倍率12.0x |
| F13 | Lv.34-40, 4-5武器, 11-12被动 | 虚空腐蚀+全机制，最终Boss 15.0x |

---

## 6.5 叙事系统测试 (test_narrative_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| NAR-01 | 章节过渡触发 | 击败章Boss后正确加载 ChapterTransition 场景 |
| NAR-02 | 叙事段落推进 | 文字打字机效果正常，按键跳过/加速 |
| NAR-03 | 选择分支 | 选择UI正确显示，选择结果通过 EventBus.narrative_choice 发送 |
| NAR-04 | 路线亲和度更新 | 选择神圣选项 → alignment 增加，选择虚空选项 → alignment 减少 |
| NAR-05 | 记忆碎片拾取 | 拾取后加入 RunData.memory_fragments，EventBus.memory_fragment_found 触发 |
| NAR-06 | 记忆碎片解读 | 安全营地中薇拉处可查看已收集碎片 |
| NAR-07 | 结局触发-救赎 | alignment > 50 时触发救赎结局 |
| NAR-08 | 结局触发-堕落 | alignment < -50 时触发堕落结局 |
| NAR-09 | 结局触发-平衡 | -30 ≤ alignment ≤ 30 时触发平衡结局 |
| NAR-10 | 事件权重-路线联动 | alignment 偏神圣时 holy 权重事件出现率显著上升 |
| NAR-11 | 事件权重-结局联动 | 解锁对应结局后，`requires_endings_any` 事件可进入候选池 |
| NAR-12 | 事件门禁 | 命中 `forbid_endings_any` 条件时事件不会被选中 |
| NAR-13 | 章节效果持续 | 事件产生的 chapter_effect 在 2~3 房间后自动过期 |
| NAR-14 | 祝福互斥替换 | 新祝福应用前回滚旧祝福，属性不发生叠加膨胀 |
| NAR-15 | 结局后记差分 | 首次解锁与重复解锁展示不同 epilogue 文本 |

## 6.6 环境机制测试 (test_environment_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| ENV-01 | 水流推动 | 玩家/敌人在水流中受方向力影响 |
| ENV-02 | 孢子云伤害 | 进入孢子云区域受持续毒伤 |
| ENV-03 | 熔岩地形伤害 | 站在熔岩上持续火焰伤害 |
| ENV-04 | 冰面滑行 | MovementComponent 切换 ICE_SLIDE 模式，惯性+200% |
| ENV-05 | 冻伤累积 | 冰面停留时 frostbite 增加，离开后缓慢恢复 |
| ENV-06 | 冻伤阈值效果 | 50%→攻速-20%，80%→移速-30%+攻速-30%，100%→冰冻3s |
| ENV-07 | 篝火回复 | 篝火区域内冻伤值下降 |
| ENV-08 | 虚空腐蚀 | F13虚空区域累积 void_corruption |
| ENV-09 | 传送带移动 | 传送带地面施加强制方向力 |
| ENV-10 | 可破坏物 | 攻击可破坏物正确掉落奖励 |
| ENV-11 | 环境危害豁免 | 饰品"永燃之焰"免疫火焰伤害 |
| ENV-12 | 火山倒计时 | F7房间120s倒计时归零触发全屏岩浆雨 |

## 6.7 商店系统测试 (test_shop_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| SHOP-01 | 商品生成 | 品质权重受 floor_index 和 luck 影响 |
| SHOP-02 | 商品定价 | 价格 = base_price × quality_mult × floor_mult |
| SHOP-03 | 购买扣款 | 金币不足时无法购买，足够时正确扣除 |
| SHOP-04 | 刷新机制 | 刷新消耗 gold=30×(refresh_count+1)，商品池重新生成 |
| SHOP-05 | 品质上限 | F1-F4 不出现 legendary 品质 |

## 6.8 随机事件测试 (test_event_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| EVT-01 | 事件触发概率 | 事件房间触发概率分布符合权重配置 |
| EVT-02 | 赌博事件 | 50%双倍/50%全失，金币变化正确 |
| EVT-03 | 祭坛事件 | 牺牲HP获得对应属性加成 |
| EVT-04 | 灵魂商人 | 用HP换取稀有物品，HP扣除正确 |
| EVT-05 | 连续事件独立 | 同层多个事件房不相互影响 |
| EVT-06 | 事件近期历史抑制 | 同章重复事件权重下降，短窗口内不高频重复 |
| EVT-07 | 章节效果叠加解析 | 同时存在多种 chapter_effect 时修正值按规则合并 |
| EVT-08 | 章节效果HUD同步 | 效果图标/剩余房间数与实际状态一致 |

## 6.9 耐力系统测试 (test_stamina_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| STA-01 | 冲刺消耗 | 冲刺时耐力按30/s消耗 |
| STA-02 | 耐力恢复 | 停止冲刺0.5s后按20/s恢复 |
| STA-03 | 最低阈值 | 耐力<20时无法开始冲刺 |
| STA-04 | 环境影响 | 冰面冲刺消耗×1.5，水中×1.3 |

## 6.10 饰品系统测试 (test_accessory_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| ACC-01 | 饰品装备 | Boss掉落饰品正确添加到 RunData.accessories |
| ACC-02 | 上限检测 | 已有2个饰品时新饰品需要替换选择 |
| ACC-03 | 效果生效 | "矿脉之心"装备后矿石掉落率+50% |

## 6.11 路线系统测试 (test_route_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| RTE-01 | 被动选择影响 | 选择 route_tag="holy" 被动 → alignment +5~15 |
| RTE-02 | 叙事选择影响 | 选择神圣选项 → alignment +10~30 |
| RTE-03 | 阈值等级计算 | alignment=60 → 路线等级"救赎III" |
| RTE-04 | 外观变化触发 | alignment>50时通知角色外观切换 |

## 6.12 锻造系统测试 (test_forge_system.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| FRG-01 | 矿石消耗 | 锻造消耗正确数量矿石，RunData.ore_count 更新 |
| FRG-02 | 强化效果 | 强化+1后武器伤害+10% |
| FRG-03 | 附魔效果 | 附魔后武器附加火焰属性 |
| FRG-04 | 材料不足 | 矿石不够时无法锻造 |

## 6.13 暂停与运行时设置测试 (test_pause_settings.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| PAU-01 | ESC 暂停开关 | ESC 打开暂停面板，再次 ESC 恢复游戏 |
| PAU-02 | 暂停继续 | 选择 Resume 后游戏状态回到 PLAYING |
| PAU-03 | 暂停撤退 | 选择 Retreat 后触发本局结算并写入 last_run |
| PAU-04 | 暂停回主菜单 | 选择 Main Menu 时直接切回菜单且不追加撤退结算 |
| PAU-05 | 音量即时生效 | 调整 Master/BGM/SFX/Ambience 后 AudioBus 音量立即变化 |
| PAU-06 | 设置持久化 | 修改设置后重启，runtime_settings 与 UI 展示一致 |
| PAU-07 | UI缩放边界 | UI Scale 在 0.8~1.5 范围内 clamp，越界输入被修正 |
| PAU-08 | 屏幕震动强度 | Screen Shake=0 时玩家受击无震动，>0 时有可感知震动 |

## 6.14 HUD反馈测试 (test_hud_feedback.gd)

| 测试ID | 测试用例 | 预期行为 |
|--------|----------|----------|
| HUD-01 | 吐司队列顺序 | 多个事件连续触发时按入队顺序逐条显示 |
| HUD-02 | 吐司来源映射 | 成就/结局/碎片/饰品四类事件均显示正确标题 |
| HUD-03 | 迷你地图标记 | 房型标记（C/B/E/S/H）与房间类型一致 |
| HUD-04 | 当前房高亮 | 当前房间 token 显示高亮包裹（如 `>04B<`） |
| HUD-05 | 已完成房状态 | 已完成房间标记转为小写，且在下一房仍保留 |
| HUD-06 | 章节效果图标极性 | `[+]`/`[-]`/`[~]` 与效果净增益方向一致 |

---

## 7. 兼容性测试

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

## 8. 回归测试与CI

### 8.1 CI 流水线

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
      - name: Run GUT Tests
        run: godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit

  data-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Validate JSON configs
        run: python scripts/validate_configs.py
      - name: Check Resource integrity
        run: python scripts/check_resources.py
```

### 8.2 数据验证脚本

自动检查：
- 所有 JSON 配置表格式正确（xp_curve, enemy_scaling, drop_tables, evolutions, shop_items, environment_config, boss_phases, narrative_index, achievements）
- 所有 Resource 文件引用的资源存在
- 武器等级数组长度 = max_level
- 进化配方引用的武器/被动ID存在
- 掉落表权重总和 > 0
- enemy_scaling.floor_multipliers 覆盖全部15层（F1-F13 + FS1-FS2）
- boss_phases.json 每个Boss阶段HP范围连续（无间隙/无重叠）
- environment_config.json 每个chapter都有完整hazards定义
- narrative_index.json 所有narrative_id引用有效
- i18n 键值对完整（中英文都有对应翻译）
- 饰品定义的 effect_type 在代码中有对应处理
- 锻造配方的 ore_cost 和 max_uses 为正整数
