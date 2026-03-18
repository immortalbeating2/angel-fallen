class_name DamageSystem
extends RefCounted

enum DamageType {
    PHYSICAL,
    HOLY,
    FIRE,
    ICE,
    VOID
}


static func calculate_damage(
    source: Node,
    target: Node,
    weapon_damage: float,
    damage_type: int,
    bonus_pct: float,
    penetration: float,
    crit_multiplier: float = 1.0,
    knockback_mult: float = 1.0
) -> float:
    var armor_value: float = _get_target_armor(target)
    var final_armor: float = clampf(armor_value, 0.0, 0.75)
    var base: float = weapon_damage * (1.0 + maxf(bonus_pct, 0.0))

    var reduced_multiplier: float = 1.0
    if damage_type == int(DamageType.HOLY):
        reduced_multiplier = 1.0 - final_armor * (1.0 - clampf(penetration, 0.0, 1.0))
    else:
        reduced_multiplier = 1.0 - final_armor

    var damage_value: float = maxf(base * reduced_multiplier * maxf(1.0, crit_multiplier), 1.0)
    EventBus.damage_dealt.emit(source, target, damage_value, int(damage_type))
    return damage_value


static func _get_target_armor(target: Node) -> float:
    if target == null:
        return 0.0

    var stats_component: Node = target.get_node_or_null("StatsComponent")
    if stats_component == null:
        return 0.0

    if stats_component.has_method("get_armor_capped"):
        return stats_component.get_armor_capped()
    if stats_component.get("armor") != null:
        return float(stats_component.armor)
    return 0.0
