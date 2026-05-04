extends GutTest

const WEAPON_LOADOUT_SCRIPT: Script = preload("res://scripts/systems/weapon_loadout.gd")


func test_starting_weapon_enters_slot_zero() -> void:
    var loadout: Node = WEAPON_LOADOUT_SCRIPT.new()
    add_child_autofree(loadout)

    var result: Dictionary = loadout.setup_starting_weapon("wpn_holy_cross", "knight_lance")
    var snapshot: Dictionary = loadout.get_snapshot()
    var weapons: Array = snapshot.get("weapon_slots", [])

    assert_true(bool(result.get("accepted", false)), "起始武器应被接收")
    assert_eq(str(weapons[0].get("id", "")), "wpn_holy_cross", "Knight 起始武器应进入 slot 0")
    assert_eq(int(weapons[0].get("level", 0)), 1, "起始武器等级应为 1")


func test_repeated_weapon_levels_instead_of_replacing() -> void:
    var loadout: Node = WEAPON_LOADOUT_SCRIPT.new()
    add_child_autofree(loadout)
    loadout.setup_starting_weapon("wpn_holy_cross", "knight_lance")

    var result: Dictionary = loadout.add_or_level_weapon("wpn_holy_cross")
    var snapshot: Dictionary = loadout.get_snapshot()
    var weapons: Array = snapshot.get("weapon_slots", [])

    assert_true(bool(result.get("upgraded", false)), "重复获得已有武器应升级")
    assert_eq(weapons.size(), 1, "重复武器不应占用新槽位")
    assert_eq(loadout.get_weapon_level("wpn_holy_cross"), 2, "重复获得后武器等级应提升")


func test_full_weapon_slots_reject_seventh_new_weapon() -> void:
    var loadout: Node = WEAPON_LOADOUT_SCRIPT.new()
    add_child_autofree(loadout)
    loadout.setup_starting_weapon("wpn_holy_cross")
    for id in ["wpn_magic_missile", "wpn_shadow_fang", "wpn_solar_lance", "wpn_sacred_lance", "wpn_void_chain"]:
        loadout.add_or_level_weapon(id)

    var rejected: Dictionary = loadout.add_or_level_weapon("wpn_storm_bow")
    assert_false(bool(rejected.get("accepted", true)), "6 个武器槽满后不应加入第 7 把武器")
    assert_eq(str(rejected.get("reason", "")), "weapon_slots_full", "拒绝原因应可定位")


func test_weapon_level_profiles_are_continuous_for_holy_cross() -> void:
    var loadout: Node = WEAPON_LOADOUT_SCRIPT.new()
    add_child_autofree(loadout)

    for level in range(1, 9):
        var profile: Dictionary = loadout.get_weapon_level_profile("wpn_holy_cross", level)
        assert_eq(int(profile.get("level", 0)), level, "holy_cross 应能读取连续 1-8 级 profile")
        assert_true(profile.has("damage_mult"), "等级 profile 应包含 damage_mult")


func test_reliquary_and_solar_profiles_scale_survivor_effects() -> void:
    var loadout: Node = WEAPON_LOADOUT_SCRIPT.new()
    add_child_autofree(loadout)

    var reliquary_1: Dictionary = loadout.get_weapon_level_profile("wpn_reliquary_orb", 1)
    var reliquary_8: Dictionary = loadout.get_weapon_level_profile("wpn_reliquary_orb", 8)
    assert_gt(int(reliquary_8.get("orbit_count", 0)), int(reliquary_1.get("orbit_count", 0)), "reliquary_orb 升级应提升环绕数量")
    assert_gt(float(reliquary_8.get("orbit_radius", 0.0)), float(reliquary_1.get("orbit_radius", 0.0)), "reliquary_orb 升级应提升环绕半径")

    var solar_1: Dictionary = loadout.get_weapon_level_profile("wpn_solar_lance", 1)
    var solar_8: Dictionary = loadout.get_weapon_level_profile("wpn_solar_lance", 8)
    assert_gt(float(solar_8.get("impact_radius", 0.0)), float(solar_1.get("impact_radius", 0.0)), "solar_lance 升级应扩大地面区半径")
    assert_gt(float(solar_8.get("duration", 0.0)), float(solar_1.get("duration", 0.0)), "solar_lance 升级应延长地面区持续时间")
