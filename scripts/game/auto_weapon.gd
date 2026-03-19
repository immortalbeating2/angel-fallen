extends Node

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

var _cooldown: float = 0.0
var _owner_body: CharacterBody2D
var _stats_component: Node
var _evolved_weapon_ids: Array[String] = []


func _ready() -> void:
    _owner_body = owner as CharacterBody2D
    if _owner_body != null:
        _stats_component = _owner_body.get_node_or_null("StatsComponent")
    if projectile_scene == null:
        projectile_scene = load("res://scenes/game/projectile.tscn")
    if projectile_scene != null and ObjectPool != null:
        ObjectPool.register_scene("projectile_basic", projectile_scene, 24)


func _process(delta: float) -> void:
    if _owner_body == null:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    _cooldown = maxf(0.0, _cooldown - delta)
    if _cooldown > 0.0:
        return

    var target: Node2D = _find_nearest_enemy()
    if target == null:
        return

    var bonus_pct: float = 0.0
    if _stats_component != null and _stats_component.get("damage_bonus_pct") != null:
        bonus_pct = _stats_component.damage_bonus_pct
    bonus_pct += external_damage_bonus_pct

    var crit_chance: float = 0.05
    var crit_multiplier: float = 1.5
    var knockback_force: float = 90.0
    if _stats_component != null:
        if _stats_component.get("crit_chance") != null:
            crit_chance = _stats_component.crit_chance
        if _stats_component.get("crit_multiplier") != null:
            crit_multiplier = _stats_component.crit_multiplier
        if _stats_component.get("knockback_power") != null:
            knockback_force = _stats_component.knockback_power

    _fire_pattern(target, bonus_pct, crit_chance, crit_multiplier, knockback_force)

    _cooldown = attack_interval


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


func _spawn_projectile(direction: Vector2, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
    if projectile_scene == null:
        return

    var parent_scene: Node = get_tree().current_scene
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
    if projectile.has_method("setup"):
        projectile.setup(
            _owner_body,
            direction,
            base_damage,
            int(DamageSystem.DamageType.PHYSICAL),
            bonus_pct,
            0.0,
            crit_multiplier,
            is_crit,
            knockback_force,
            projectile_hits,
            projectile_style
        )

    if projectile.get_parent() == null:
        parent_scene.add_child(projectile)


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

    current_weapon_id = result_weapon_id
    _evolved_weapon_ids.append(result_weapon_id)
    return true
