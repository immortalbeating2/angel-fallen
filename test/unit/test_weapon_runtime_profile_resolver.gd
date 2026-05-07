extends GutTest

const RESOLVER_SCRIPT: Script = preload("res://scripts/systems/weapon_runtime_profile_resolver.gd")


func test_secondary_slot_profile_keeps_independent_style_and_scaling() -> void:
    var profile: Dictionary = RESOLVER_SCRIPT.build_slot_profile({
        "id": "wpn_radiant_hammer",
        "level": 3,
        "stats": {
            "projectile_style": "radiant_hammer",
            "damage_mult": 1.4,
            "projectile_count": 2,
            "weapon_mode": "single",
            "impact_radius": 58.0,
        }
    }, 1, _make_defaults())

    assert_eq(str(profile.get("weapon_id", "")), "wpn_radiant_hammer", "副武器 profile 应保留自身 ID")
    assert_eq(str(profile.get("projectile_style", "")), "radiant_hammer", "副武器应保留自身弹道风格")
    assert_eq(str(profile.get("weapon_mode", "")), "spread", "多弹体副武器应自动转为 spread")
    assert_gt(float(profile.get("base_damage", 0.0)), 12.0, "副武器应应用等级数值修正")
    assert_eq(float(profile.get("impact_radius", 0.0)), 58.0, "副武器应保留配置的范围伤害半径")


func test_primary_slot_uses_base_executor_profile() -> void:
    var profile: Dictionary = RESOLVER_SCRIPT.build_slot_profile({
        "id": "wpn_holy_cross",
        "level": 2,
    }, 0, _make_defaults())

    assert_eq(str(profile.get("weapon_id", "")), "wpn_holy_cross", "主槽应使用角色起始武器 ID")
    assert_eq(float(profile.get("base_damage", 0.0)), 12.0, "主槽应直接使用 AutoWeapon 当前基础伤害")
    assert_eq(float(profile.get("impact_radius", -1.0)), 38.0, "主槽应解析默认范围伤害半径")


func test_effect_profile_lookup_matches_survivor_weapon_styles() -> void:
    var orbit: Dictionary = RESOLVER_SCRIPT.get_orbit_config("reliquary_orb")
    var aura: Dictionary = RESOLVER_SCRIPT.get_aura_config("holy_judgment")
    var crit_color: Color = RESOLVER_SCRIPT.get_weapon_color("mage_orb", true)

    assert_false(orbit.is_empty(), "reliquary_orb 应启用环绕武器配置")
    assert_false(aura.is_empty(), "holy_judgment 应启用持续光环配置")
    assert_gt(crit_color.r, 0.72, "暴击颜色应向金色反馈偏移")


func _make_defaults() -> Dictionary:
    return {
        "current_weapon_id": "wpn_holy_cross",
        "base_damage": 12.0,
        "attack_interval": 0.45,
        "weapon_mode": "single",
        "projectile_count": 1,
        "spread_angle_deg": 12.0,
        "spread_jitter_deg": 0.0,
        "projectile_hits": 1,
        "projectile_style": "holy_judgment",
        "impact_radius": 0.0,
        "impact_damage_mult": 0.42,
    }
