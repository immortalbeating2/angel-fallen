extends RefCounted


# 统一解析武器运行时 profile，让 AutoWeapon 专注目标、冷却、发射和反馈。
static func build_slot_profile(slot: Dictionary, slot_index: int, defaults: Dictionary) -> Dictionary:
    var current_weapon_id: String = str(defaults.get("current_weapon_id", "wpn_magic_missile"))
    var projectile_style: String = str(defaults.get("projectile_style", "default"))
    var base_damage: float = float(defaults.get("base_damage", 12.0))
    var attack_interval: float = float(defaults.get("attack_interval", 0.45))
    var weapon_mode: String = str(defaults.get("weapon_mode", "single"))
    var projectile_count: int = int(defaults.get("projectile_count", 1))
    var spread_angle_deg: float = float(defaults.get("spread_angle_deg", 12.0))
    var spread_jitter_deg: float = float(defaults.get("spread_jitter_deg", 0.0))
    var projectile_hits: int = int(defaults.get("projectile_hits", 1))
    var impact_radius: float = float(defaults.get("impact_radius", 0.0))
    var impact_damage_mult: float = float(defaults.get("impact_damage_mult", 0.42))

    if slot_index == 0:
        return {
            "weapon_id": str(slot.get("id", current_weapon_id)),
            "level": maxi(1, int(slot.get("level", 1))),
            "base_damage": base_damage,
            "attack_interval": attack_interval,
            "weapon_mode": weapon_mode,
            "projectile_count": projectile_count,
            "spread_angle_deg": spread_angle_deg,
            "spread_jitter_deg": spread_jitter_deg,
            "projectile_hits": projectile_hits,
            "projectile_style": projectile_style,
            "impact_radius": get_resolved_impact_radius(projectile_style, impact_radius),
            "impact_damage_mult": impact_damage_mult,
        }

    var stats_var: Variant = slot.get("stats", {})
    var stats: Dictionary = stats_var if stats_var is Dictionary else {}
    var level: int = maxi(1, int(slot.get("level", stats.get("level", 1))))
    var style_id: String = str(stats.get("projectile_style", slot.get("style", projectile_style))).strip_edges()
    if style_id == "":
        style_id = projectile_style

    var damage: float = base_damage
    damage *= maxf(0.1, float(stats.get("damage_mult", 1.0)))
    damage += float(stats.get("flat_damage_bonus", 0.0))
    damage *= 0.82 if slot_index > 0 else 1.0

    var interval: float = attack_interval * clampf(float(stats.get("interval_mult", 1.0)), 0.35, 1.25)
    interval *= 1.0 + float(slot_index) * 0.14

    var count: int = clampi(int(stats.get("projectile_count", projectile_count)), 1, 8)
    var mode: String = str(stats.get("weapon_mode", weapon_mode))
    if count > 1 and mode == "single":
        mode = "spread"

    return {
        "weapon_id": str(slot.get("evolved_id", slot.get("id", current_weapon_id))),
        "level": level,
        "base_damage": maxf(1.0, damage),
        "attack_interval": maxf(0.10, interval),
        "weapon_mode": mode,
        "projectile_count": count,
        "spread_angle_deg": clampf(float(stats.get("spread_angle_deg", spread_angle_deg)), 0.0, 60.0),
        "spread_jitter_deg": clampf(float(stats.get("spread_jitter_deg", spread_jitter_deg)), 0.0, 20.0),
        "projectile_hits": clampi(int(stats.get("projectile_hits", projectile_hits)), 1, 12),
        "projectile_style": style_id,
        "impact_radius": clampf(float(stats.get("impact_radius", impact_radius)), 0.0, 140.0),
        "impact_damage_mult": clampf(float(stats.get("impact_damage_mult", impact_damage_mult)), 0.15, 0.95),
    }


static func get_weapon_color(style_id: String, is_crit: bool) -> Color:
    var color: Color = Color(0.72, 0.90, 1.0, 1.0)
    match style_id.to_lower():
        "mage_orb":
            color = Color(0.72, 0.62, 1.0, 1.0)
        "rogue_dart":
            color = Color(0.58, 1.0, 0.78, 1.0)
        "storm_arrow":
            color = Color(0.58, 0.88, 1.0, 1.0)
        "cleric_halo":
            color = Color(1.0, 0.94, 0.58, 1.0)
    if is_crit:
        color = color.lerp(Color(1.0, 0.86, 0.28, 1.0), 0.45)
    return color


static func get_resolved_impact_radius(style_id: String, explicit_radius: float = 0.0) -> float:
    if explicit_radius > 0.0:
        return explicit_radius

    match style_id.to_lower():
        "arcane_comet":
            return 42.0
        "holy_judgment", "vowblade", "vowstorm":
            return 38.0
        "radiant_hammer", "radiant_cataclysm":
            return 58.0
        "solar_supernova", "glacial_nova":
            return 66.0
        "astral_disc", "astral_horizon", "reliquary_orb", "zenith_reliquary":
            return 46.0
    return 0.0


static func get_orbit_config(style_id: String, evolved_weapon_ids: Array[String] = []) -> Dictionary:
    var style: String = style_id.to_lower()
    if style.find("astral") >= 0:
        return {"style_id": style_id, "radius": 66.0, "count": 2 + int(evolved_weapon_ids.has("wpn_astral_horizon")), "damage_mult": 0.46, "hit_interval": 0.32}
    if style.find("reliquary") >= 0 or style.find("zenith") >= 0:
        return {"style_id": style_id, "radius": 74.0, "count": 3 if style.find("zenith") >= 0 else 2, "damage_mult": 0.42, "hit_interval": 0.36}
    if style.find("void_chain") >= 0 or style.find("abyssal") >= 0:
        return {"style_id": style_id, "radius": 62.0, "count": 2, "damage_mult": 0.38, "hit_interval": 0.38}
    return {}


static func get_aura_config(style_id: String) -> Dictionary:
    var style: String = style_id.to_lower()
    if style.find("holy_judgment") >= 0 or style.find("seraph") >= 0 or style.find("cleric_halo") >= 0:
        return {"style_id": style_id, "radius": 88.0, "damage_mult": 0.24, "tick_interval": 0.45}
    if style.find("radiant") >= 0:
        return {"style_id": style_id, "radius": 78.0, "damage_mult": 0.22, "tick_interval": 0.5}
    if style.find("glacial") >= 0:
        return {"style_id": style_id, "radius": 82.0, "damage_mult": 0.20, "tick_interval": 0.48}
    return {}
