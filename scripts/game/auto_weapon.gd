extends Node

const ORBIT_WEAPON_SCRIPT: Script = preload("res://scripts/game/orbit_weapon.gd")
const AURA_WEAPON_SCRIPT: Script = preload("res://scripts/game/aura_weapon.gd")
const RUNTIME_PROFILE_RESOLVER_SCRIPT: Script = preload("res://scripts/systems/weapon_runtime_profile_resolver.gd")

@export var base_damage: float = 12.0
@export var attack_interval: float = 0.45
@export var attack_range: float = 220.0
@export var projectile_scene: PackedScene
@export var external_damage_bonus_pct: float = 0.0
@export var weapon_mode: String = "single"
@export var projectile_count: int = 1
@export var spread_angle_deg: float = 12.0
@export var spread_jitter_deg: float = 0.0
@export var projectile_hits: int = 1
@export var projectile_style: String = "default"
@export var current_weapon_id: String = "wpn_magic_missile"
@export var impact_radius: float = 0.0
@export var impact_damage_mult: float = 0.42

var _cooldown: float = 0.0
var _owner_body: CharacterBody2D
var _stats_component: Node
var _weapon_pivot: Node2D
var _weapon_visual: Polygon2D
var _muzzle_flash: Polygon2D
var _orbit_weapon: Node2D
var _aura_weapon: Node2D
var _loadout: Node
var _slot_cooldowns: Dictionary = {}
var _last_effect_signature: String = ""
var _evolved_weapon_ids: Array[String] = []


func _ready() -> void:
    _owner_body = get_parent() as CharacterBody2D
    if _owner_body == null:
        _owner_body = owner as CharacterBody2D
    if _owner_body != null:
        _stats_component = _owner_body.get_node_or_null("StatsComponent")
        _weapon_pivot = _owner_body.get_node_or_null("WeaponPivot") as Node2D
        if _weapon_pivot != null:
            _weapon_visual = _weapon_pivot.get_node_or_null("WeaponVisual") as Polygon2D
            _muzzle_flash = _weapon_pivot.get_node_or_null("MuzzleFlash") as Polygon2D
    if projectile_scene == null:
        projectile_scene = load("res://scenes/game/projectile.tscn")
    if projectile_scene != null and ObjectPool != null:
        ObjectPool.register_scene("projectile_basic", projectile_scene, 24)
    var world: Node = _owner_body.get_parent() if _owner_body != null else null
    if world != null:
        _loadout = world.get_node_or_null("WeaponLoadout")


func _process(delta: float) -> void:
    if _owner_body == null:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return
    _refresh_survivor_effect_layers()

    var bonus_pct: float = 0.0
    if _stats_component != null and _stats_component.get("damage_bonus_pct") != null:
        bonus_pct = _stats_component.damage_bonus_pct
    bonus_pct += external_damage_bonus_pct

    var crit_chance: float = 0.05
    var crit_multiplier: float = 1.5
    var knockback_force: float = 135.0
    if _stats_component != null:
        if _stats_component.get("crit_chance") != null:
            crit_chance = _stats_component.crit_chance
        if _stats_component.get("crit_multiplier") != null:
            crit_multiplier = _stats_component.crit_multiplier
        if _stats_component.get("knockback_power") != null:
            knockback_force = maxf(125.0, _stats_component.knockback_power)

    if _process_loadout_weapons(delta, bonus_pct, crit_chance, crit_multiplier, knockback_force):
        return

    _cooldown = maxf(0.0, _cooldown - delta)
    if _cooldown > 0.0:
        return

    var target: Node2D = _find_nearest_enemy()
    if target == null:
        return

    _fire_pattern(target, bonus_pct, crit_chance, crit_multiplier, knockback_force)

    _cooldown = attack_interval


func _process_loadout_weapons(delta: float, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> bool:
    var slots: Array = _get_runtime_weapon_slots()
    if slots.is_empty():
        return false

    for i in range(slots.size()):
        if not (slots[i] is Dictionary):
            continue
        var slot: Dictionary = slots[i]
        var weapon_id: String = str(slot.get("id", "")).strip_edges()
        if weapon_id == "":
            continue

        var key: String = "%d:%s" % [i, weapon_id]
        _slot_cooldowns[key] = maxf(0.0, float(_slot_cooldowns.get(key, 0.0)) - delta)
        if float(_slot_cooldowns.get(key, 0.0)) > 0.0:
            continue

        var target: Node2D = _find_nearest_enemy()
        if target == null:
            continue

        var profile: Dictionary = _build_slot_runtime_profile(slot, i)
        _fire_pattern_with_profile(target, profile, bonus_pct, crit_chance, crit_multiplier, knockback_force)
        _slot_cooldowns[key] = float(profile.get("attack_interval", attack_interval))

    return true


func _get_runtime_weapon_slots() -> Array:
    if _loadout == null or not is_instance_valid(_loadout):
        if _owner_body != null and _owner_body.get_parent() != null:
            _loadout = _owner_body.get_parent().get_node_or_null("WeaponLoadout")
    if _loadout == null or not _loadout.has_method("get_snapshot"):
        return []

    var snapshot: Dictionary = _loadout.get_snapshot()
    var slots_var: Variant = snapshot.get("weapon_slots", [])
    if not (slots_var is Array):
        return []
    return slots_var


func get_runtime_weapon_slot_profiles() -> Array[Dictionary]:
    var profiles: Array[Dictionary] = []
    var slots: Array = _get_runtime_weapon_slots()
    for i in range(slots.size()):
        if slots[i] is Dictionary:
            profiles.append(_build_slot_runtime_profile(slots[i], i))
    return profiles


func _build_slot_runtime_profile(slot: Dictionary, slot_index: int) -> Dictionary:
    return RUNTIME_PROFILE_RESOLVER_SCRIPT.build_slot_profile(slot, slot_index, _get_base_runtime_profile_defaults())


func _get_base_runtime_profile_defaults() -> Dictionary:
    return {
        "current_weapon_id": current_weapon_id,
        "base_damage": base_damage,
        "attack_interval": attack_interval,
        "weapon_mode": weapon_mode,
        "projectile_count": projectile_count,
        "spread_angle_deg": spread_angle_deg,
        "spread_jitter_deg": spread_jitter_deg,
        "projectile_hits": projectile_hits,
        "projectile_style": projectile_style,
        "impact_radius": impact_radius,
        "impact_damage_mult": impact_damage_mult,
    }


func _fire_pattern(target: Node2D, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
    var base_direction: Vector2 = (target.global_position - _owner_body.global_position).normalized()
    var normalized_mode: String = weapon_mode.strip_edges().to_lower()
    if normalized_mode == "spread":
        var count: int = clampi(projectile_count, 1, 7)
        if count <= 1:
            _spawn_projectile(base_direction, bonus_pct, crit_chance, crit_multiplier, knockback_force)
            return

        for i in range(count):
            var ratio: float = 0.0
            if count > 1:
                ratio = float(i) / float(count - 1)
            var normalized: float = ratio * 2.0 - 1.0
            var angle_offset: float = deg_to_rad(spread_angle_deg) * normalized
            if spread_jitter_deg > 0.0:
                angle_offset += deg_to_rad(randf_range(-spread_jitter_deg, spread_jitter_deg))
            _spawn_projectile(base_direction.rotated(angle_offset), bonus_pct, crit_chance, crit_multiplier, knockback_force)
        return

    _spawn_projectile(base_direction, bonus_pct, crit_chance, crit_multiplier, knockback_force)


func _fire_pattern_with_profile(target: Node2D, profile: Dictionary, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
    var base_direction: Vector2 = (target.global_position - _owner_body.global_position).normalized()
    var normalized_mode: String = str(profile.get("weapon_mode", "single")).strip_edges().to_lower()
    var count: int = clampi(int(profile.get("projectile_count", 1)), 1, 8)
    if normalized_mode == "spread" and count > 1:
        for i in range(count):
            var ratio: float = float(i) / float(maxi(1, count - 1))
            var normalized: float = ratio * 2.0 - 1.0
            var angle_offset: float = deg_to_rad(float(profile.get("spread_angle_deg", 12.0))) * normalized
            var jitter: float = float(profile.get("spread_jitter_deg", 0.0))
            if jitter > 0.0:
                angle_offset += deg_to_rad(randf_range(-jitter, jitter))
            _spawn_projectile_with_profile(base_direction.rotated(angle_offset), profile, bonus_pct, crit_chance, crit_multiplier, knockback_force)
        return

    _spawn_projectile_with_profile(base_direction, profile, bonus_pct, crit_chance, crit_multiplier, knockback_force)


func _spawn_projectile(direction: Vector2, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
    _spawn_projectile_with_profile(direction, {
        "base_damage": base_damage,
        "projectile_hits": projectile_hits,
        "projectile_style": projectile_style,
        "impact_radius": _get_resolved_impact_radius(),
        "impact_damage_mult": impact_damage_mult,
    }, bonus_pct, crit_chance, crit_multiplier, knockback_force)


func _spawn_projectile_with_profile(direction: Vector2, profile: Dictionary, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
    if projectile_scene == null:
        return

    var parent_scene: Node = _owner_body.get_parent() if _owner_body != null else null
    if parent_scene == null:
        parent_scene = get_tree().current_scene
    if parent_scene == null:
        parent_scene = get_tree().root

    var projectile: Area2D
    if ObjectPool != null:
        projectile = ObjectPool.acquire("projectile_basic", parent_scene) as Area2D
    if projectile == null:
        projectile = projectile_scene.instantiate() as Area2D
    if projectile == null:
        return

    projectile.global_position = _owner_body.global_position + direction * 16.0

    var is_crit: bool = randf() < clampf(crit_chance, 0.0, 0.95)
    var style_id: String = str(profile.get("projectile_style", projectile_style))
    if projectile.has_method("setup"):
        projectile.setup(
            _owner_body,
            direction,
            float(profile.get("base_damage", base_damage)),
            int(DamageSystem.DamageType.PHYSICAL),
            bonus_pct,
            0.0,
            crit_multiplier,
            is_crit,
            knockback_force,
            int(profile.get("projectile_hits", projectile_hits)),
            style_id,
            float(profile.get("impact_radius", _get_resolved_impact_radius())),
            float(profile.get("impact_damage_mult", impact_damage_mult))
        )

    if projectile.get_parent() == null:
        parent_scene.add_child(projectile)

    _play_weapon_feedback(direction, is_crit, style_id)


func _play_weapon_feedback(direction: Vector2, is_crit: bool, style_id: String = "") -> void:
    if _weapon_pivot == null:
        return
    if style_id == "":
        style_id = projectile_style

    _weapon_pivot.rotation = direction.angle()
    if _weapon_visual != null:
        _weapon_visual.visible = true
        _weapon_visual.color = _get_weapon_color(style_id, is_crit)
        _weapon_visual.scale = Vector2(1.14, 1.14)

    if _muzzle_flash != null:
        _muzzle_flash.visible = true
        _muzzle_flash.modulate = Color(1, 1, 1, 1)
        _muzzle_flash.scale = Vector2(1.0, 1.0) * (1.25 if is_crit else 1.0)

    var tween: Tween = create_tween()
    if _weapon_visual != null:
        tween.tween_property(_weapon_visual, "scale", Vector2.ONE, 0.08)
    if _muzzle_flash != null:
        tween.parallel().tween_property(_muzzle_flash, "modulate:a", 0.0, 0.10)
        tween.parallel().tween_property(_muzzle_flash, "scale", Vector2(0.55, 0.55), 0.10)
        tween.tween_callback(func() -> void:
            if _muzzle_flash != null:
                _muzzle_flash.visible = false
                _muzzle_flash.modulate = Color(1, 1, 1, 1)
        )


func _get_weapon_color(style_id: String, is_crit: bool) -> Color:
    return RUNTIME_PROFILE_RESOLVER_SCRIPT.get_weapon_color(style_id, is_crit)


func _get_resolved_impact_radius() -> float:
    return RUNTIME_PROFILE_RESOLVER_SCRIPT.get_resolved_impact_radius(projectile_style, impact_radius)


func _refresh_survivor_effect_layers() -> void:
    if _owner_body == null:
        return

    var signature: String = "%s|%s|%.2f|%d" % [current_weapon_id, projectile_style, base_damage, projectile_hits]
    if signature == _last_effect_signature:
        return
    _last_effect_signature = signature

    var orbit_config: Dictionary = _get_orbit_config()
    if orbit_config.is_empty():
        _remove_effect_node("_orbit_weapon")
    else:
        if _orbit_weapon == null or not is_instance_valid(_orbit_weapon):
            _orbit_weapon = ORBIT_WEAPON_SCRIPT.new() as Node2D
            if _orbit_weapon == null:
                return
            _orbit_weapon.name = "OrbitWeapon"
            _owner_body.add_child(_orbit_weapon)
        if _orbit_weapon.has_method("setup"):
            _orbit_weapon.setup(_owner_body, self, orbit_config)

    var aura_config: Dictionary = _get_aura_config()
    if aura_config.is_empty():
        _remove_effect_node("_aura_weapon")
    else:
        if _aura_weapon == null or not is_instance_valid(_aura_weapon):
            _aura_weapon = AURA_WEAPON_SCRIPT.new() as Node2D
            if _aura_weapon == null:
                return
            _aura_weapon.name = "AuraWeapon"
            _owner_body.add_child(_aura_weapon)
        if _aura_weapon.has_method("setup"):
            _aura_weapon.setup(_owner_body, self, aura_config)


func _remove_effect_node(property_name: String) -> void:
    var node: Node = _orbit_weapon if property_name == "_orbit_weapon" else _aura_weapon
    if node != null and is_instance_valid(node):
        node.queue_free()
    if property_name == "_orbit_weapon":
        _orbit_weapon = null
    else:
        _aura_weapon = null


func _get_orbit_config() -> Dictionary:
    return RUNTIME_PROFILE_RESOLVER_SCRIPT.get_orbit_config(projectile_style, _evolved_weapon_ids)


func _get_aura_config() -> Dictionary:
    return RUNTIME_PROFILE_RESOLVER_SCRIPT.get_aura_config(projectile_style)


func _find_nearest_enemy() -> Node2D:
    var nearest: Node2D
    var nearest_distance: float = attack_range

    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if not (node is Node2D):
            continue
        var enemy: Node2D = node
        var distance: float = _owner_body.global_position.distance_to(enemy.global_position)
        if distance <= nearest_distance:
            nearest_distance = distance
            nearest = enemy

    return nearest


func reset_weapon_state(weapon_id: String = "wpn_magic_missile") -> void:
    current_weapon_id = weapon_id.strip_edges()
    if current_weapon_id == "":
        current_weapon_id = "wpn_magic_missile"
    _evolved_weapon_ids.clear()
    _last_effect_signature = ""


func apply_weapon_level_profile(profile: Dictionary) -> void:
    if profile.is_empty():
        return

    if profile.has("flat_damage_bonus"):
        base_damage = maxf(1.0, base_damage + float(profile.get("flat_damage_bonus", 0.0)))
    if profile.has("damage_mult"):
        base_damage = maxf(1.0, base_damage * maxf(0.1, float(profile.get("damage_mult", 1.0))))
    if profile.has("interval_mult"):
        attack_interval = maxf(0.08, attack_interval * clampf(float(profile.get("interval_mult", 1.0)), 0.35, 1.25))
    if profile.has("weapon_mode"):
        weapon_mode = str(profile.get("weapon_mode", weapon_mode))
    if profile.has("projectile_count"):
        projectile_count = clampi(int(profile.get("projectile_count", projectile_count)), 1, 8)
    if profile.has("spread_angle_deg"):
        spread_angle_deg = clampf(float(profile.get("spread_angle_deg", spread_angle_deg)), 0.0, 60.0)
    if profile.has("spread_jitter_deg"):
        spread_jitter_deg = clampf(float(profile.get("spread_jitter_deg", spread_jitter_deg)), 0.0, 20.0)
    if profile.has("projectile_hits"):
        projectile_hits = clampi(int(profile.get("projectile_hits", projectile_hits)), 1, 12)
    if profile.has("projectile_style"):
        projectile_style = str(profile.get("projectile_style", projectile_style))
    if profile.has("impact_radius"):
        impact_radius = clampf(float(profile.get("impact_radius", impact_radius)), 0.0, 140.0)
    if profile.has("impact_damage_mult"):
        impact_damage_mult = clampf(float(profile.get("impact_damage_mult", impact_damage_mult)), 0.15, 0.95)

    _last_effect_signature = ""


func has_evolved_to(result_weapon_id: String) -> bool:
    return _evolved_weapon_ids.has(result_weapon_id)


func apply_evolution_profile(recipe: Dictionary) -> bool:
    var result_weapon_id: String = str(recipe.get("result_weapon_id", "")).strip_edges()
    if result_weapon_id == "":
        return false
    if _evolved_weapon_ids.has(result_weapon_id):
        return false

    var profile_var: Variant = recipe.get("evolution_profile", {})
    var profile: Dictionary = {}
    if profile_var is Dictionary:
        profile = profile_var

    var damage_mult: float = maxf(0.5, float(profile.get("damage_mult", 1.25)))
    var flat_damage_bonus: float = float(profile.get("flat_damage_bonus", 0.0))
    var interval_mult: float = clampf(float(profile.get("interval_mult", 0.9)), 0.35, 1.25)

    base_damage = maxf(1.0, base_damage * damage_mult + flat_damage_bonus)
    attack_interval = maxf(0.08, attack_interval * interval_mult)

    if profile.has("weapon_mode"):
        weapon_mode = str(profile.get("weapon_mode", weapon_mode))
    if profile.has("projectile_count"):
        projectile_count = clampi(int(profile.get("projectile_count", projectile_count)), 1, 8)
    if profile.has("spread_angle_deg"):
        spread_angle_deg = clampf(float(profile.get("spread_angle_deg", spread_angle_deg)), 0.0, 60.0)
    if profile.has("spread_jitter_deg"):
        spread_jitter_deg = clampf(float(profile.get("spread_jitter_deg", spread_jitter_deg)), 0.0, 20.0)
    if profile.has("projectile_hits"):
        projectile_hits = clampi(int(profile.get("projectile_hits", projectile_hits)), 1, 12)
    if profile.has("projectile_style"):
        projectile_style = str(profile.get("projectile_style", projectile_style))
    if profile.has("impact_radius"):
        impact_radius = clampf(float(profile.get("impact_radius", impact_radius)), 0.0, 120.0)
    if profile.has("impact_damage_mult"):
        impact_damage_mult = clampf(float(profile.get("impact_damage_mult", impact_damage_mult)), 0.15, 0.85)

    current_weapon_id = result_weapon_id
    _evolved_weapon_ids.append(result_weapon_id)
    return true
