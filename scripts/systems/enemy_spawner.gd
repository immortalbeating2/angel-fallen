extends Node2D

@export var enemy_scene: PackedScene
@export var floor_index: int = 1
@export var max_alive: int = 24

var _room_active: bool = false
var _room_time: float = 0.0
var _spawn_timer: float = 0.0
var _combat_mode: String = "normal"
var _boss_spawned: bool = false
var _boss_id: String = ""


func _process(delta: float) -> void:
    if not _room_active:
        return

    _room_time += delta

    if _combat_mode == "boss":
        if not _boss_spawned:
            _boss_spawned = _spawn_boss()
        return

    _spawn_timer -= delta

    if _spawn_timer <= 0.0:
        _spawn_timer = _get_spawn_interval()
        _spawn_enemy()


func start_room_combat(new_floor_index: int, combat_mode: String = "normal", boss_id: String = "") -> void:
    floor_index = maxi(1, new_floor_index)
    _room_time = 0.0
    _spawn_timer = 0.15
    _room_active = true
    _combat_mode = combat_mode
    _boss_spawned = false
    _boss_id = boss_id


func stop_room_combat() -> void:
    _room_active = false
    _combat_mode = "normal"
    _boss_spawned = false
    _boss_id = ""


func get_room_time() -> float:
    return _room_time


func get_alive_count() -> int:
    return get_tree().get_nodes_in_group("enemy").size()


func _spawn_enemy() -> void:
    if enemy_scene == null:
        return
    if get_alive_count() >= max_alive:
        return

    var enemy: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
    if enemy == null:
        return

    add_child(enemy)

    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    var center: Vector2 = global_position
    if player != null:
        center = player.global_position

    var angle: float = randf() * TAU
    var distance: float = randf_range(320.0, 460.0)
    enemy.global_position = center + Vector2.RIGHT.rotated(angle) * distance

    var pressure: Dictionary = _get_room_pressure_values()
    var floor_mult: float = _get_floor_multiplier()
    var hp_mult: float = floor_mult * float(pressure.get("hp_mult", 1.0))
    var damage_mult: float = floor_mult * float(pressure.get("damage_mult", 1.0))

    var health_component: Node = enemy.get_node_or_null("HealthComponent")
    if health_component != null and health_component.get("max_hp") != null:
        health_component.max_hp *= hp_mult
        health_component.current_hp = health_component.max_hp

    if enemy.get("touch_damage") != null:
        enemy.touch_damage *= damage_mult


func _spawn_boss() -> bool:
    if enemy_scene == null:
        return false
    if get_alive_count() > 0:
        return true

    var boss: CharacterBody2D = enemy_scene.instantiate() as CharacterBody2D
    if boss == null:
        return false

    add_child(boss)

    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    if player != null:
        boss.global_position = player.global_position + Vector2(randf_range(-220.0, 220.0), -260.0)
    else:
        boss.global_position = global_position

    var boss_name: String = _boss_id
    if boss_name == "":
        boss_name = "boss_unknown"
    if boss.get("enemy_id") != null:
        boss.enemy_id = boss_name

    var health_mult: float = 10.0 + float(floor_index) * 1.7
    var damage_mult: float = 1.8 + float(floor_index) * 0.08

    var health_component: Node = boss.get_node_or_null("HealthComponent")
    if health_component != null and health_component.get("max_hp") != null:
        health_component.max_hp *= health_mult
        health_component.current_hp = health_component.max_hp

    if boss.get("touch_damage") != null:
        boss.touch_damage *= damage_mult
    if boss.get("move_speed") != null:
        boss.move_speed *= 0.76

    var visual: Polygon2D = boss.get_node_or_null("Polygon2D") as Polygon2D
    if visual != null:
        visual.color = Color(0.95, 0.45, 0.2, 1.0)
    boss.scale = Vector2(1.9, 1.9)
    if boss.has_method("set_visual_scale_base"):
        boss.set_visual_scale_base(boss.scale)
    return true


func _get_spawn_interval() -> float:
    var floor_ratio: float = 1.0 + float(floor_index - 1) * 0.09
    var time_ratio: float = 1.0
    if _room_time > 120.0:
        time_ratio = 1.8
    elif _room_time > 60.0:
        time_ratio = 1.5
    elif _room_time > 30.0:
        time_ratio = 1.25

    var interval: float = 1.3 / (floor_ratio * time_ratio)
    return clampf(interval, 0.2, 1.3)


func _get_floor_multiplier() -> float:
    var scaling: Dictionary = ConfigManager.get_config("enemy_scaling", {})
    var multipliers: Dictionary = scaling.get("floor_multipliers", {})
    return float(multipliers.get(str(floor_index), 1.0))


func _get_room_pressure_values() -> Dictionary:
    var scaling: Dictionary = ConfigManager.get_config("enemy_scaling", {})
    var brackets: Array = scaling.get("room_time_brackets", [])
    for item: Variant in brackets:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        if _room_time <= float(row.get("max_seconds", 9999.0)):
            return row
    return {"hp_mult": 1.0, "damage_mult": 1.0}
