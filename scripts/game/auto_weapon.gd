extends Node

@export var base_damage: float = 12.0
@export var attack_interval: float = 0.45
@export var attack_range: float = 220.0
@export var projectile_scene: PackedScene

var _cooldown: float = 0.0
var _owner_body: CharacterBody2D
var _stats_component: Node


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

    _fire_projectile(target, bonus_pct, crit_chance, crit_multiplier, knockback_force)

    _cooldown = attack_interval


func _fire_projectile(target: Node2D, bonus_pct: float, crit_chance: float, crit_multiplier: float, knockback_force: float) -> void:
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

    var direction: Vector2 = (target.global_position - _owner_body.global_position).normalized()
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
            knockback_force
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
