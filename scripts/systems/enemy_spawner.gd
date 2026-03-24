extends Node2D

@export var enemy_scene: PackedScene
@export var floor_index: int = 1
@export var max_alive: int = 24

var _room_active: bool = false
var _room_time: float = 0.0
var _spawn_timer: float = 0.0
var _spawn_count: int = 0
var _combat_mode: String = "normal"
var _boss_spawned: bool = false
var _boss_id: String = ""
var _boss_style_profile: Dictionary = {}
var _active_boss: CharacterBody2D
var _boss_support_phase_marks: Dictionary = {}
var _last_boss_support_snapshot: Dictionary = {}
var _runtime_spawn_rate_mult: float = 1.0
var _runtime_enemy_hp_mult: float = 1.0
var _runtime_enemy_damage_mult: float = 1.0
var _elite_wave_interval: int = 8
var _enemy_type_weights: Dictionary = {
    "normal": 46.0,
    "fast": 24.0,
    "tank": 18.0,
    "ranged": 12.0
}
var _chapter_archetype_map: Dictionary = {
    "chapter_1": {
        "normal": "enemy_shadowling",
        "fast": "enemy_stalker",
        "tank": "enemy_brute",
        "ranged": "enemy_hexcaster"
    },
    "chapter_2": {
        "normal": "enemy_emberling",
        "fast": "enemy_scorch_runner",
        "tank": "enemy_burn_guard",
        "ranged": "enemy_flame_channeler"
    },
    "chapter_3": {
        "normal": "enemy_frostling",
        "fast": "enemy_glacier_runner",
        "tank": "enemy_ice_guard",
        "ranged": "enemy_blizzard_mage"
    },
    "chapter_4": {
        "normal": "enemy_voidling",
        "fast": "enemy_rift_runner",
        "tank": "enemy_abyss_guard",
        "ranged": "enemy_void_priest"
    }
}


func _ready() -> void:
    if enemy_scene != null and ObjectPool != null:
        ObjectPool.register_scene("enemy_basic", enemy_scene, maxi(12, max_alive + 8))


func _process(delta: float) -> void:
    if not _room_active:
        return

    _room_time += delta

    if _combat_mode == "boss":
        if not _boss_spawned:
            _boss_spawned = _spawn_boss()
        _process_boss_support()
        return

    _spawn_timer -= delta

    if _spawn_timer <= 0.0:
        _spawn_timer = _get_spawn_interval()
        _spawn_enemy()


func start_room_combat(new_floor_index: int, combat_mode: String = "normal", boss_id: String = "", boss_style_profile: Dictionary = {}) -> void:
    floor_index = maxi(1, new_floor_index)
    _room_time = 0.0
    _spawn_timer = 0.15
    _spawn_count = 0
    _room_active = true
    _combat_mode = combat_mode
    _boss_spawned = false
    _boss_id = boss_id
    _boss_style_profile = boss_style_profile.duplicate(true)
    _active_boss = null
    _boss_support_phase_marks.clear()
    _last_boss_support_snapshot.clear()
    _load_spawn_profile_config()


func stop_room_combat() -> void:
    _room_active = false
    _combat_mode = "normal"
    _boss_spawned = false
    _boss_id = ""
    _boss_style_profile = {}
    _active_boss = null
    _boss_support_phase_marks.clear()
    _last_boss_support_snapshot.clear()


func get_room_time() -> float:
    return _room_time


func get_alive_count() -> int:
    var total: int = 0
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if node == null or not is_instance_valid(node):
            continue
        if ObjectPool != null and node.get_parent() == ObjectPool:
            continue
        if node.has_method("is_pool_active") and not bool(node.is_pool_active()):
            continue
        total += 1
    return total


func set_runtime_modifiers(spawn_rate_mult: float, enemy_hp_mult: float, enemy_damage_mult: float) -> void:
    _runtime_spawn_rate_mult = clampf(spawn_rate_mult, 0.55, 1.8)
    _runtime_enemy_hp_mult = clampf(enemy_hp_mult, 0.55, 1.8)
    _runtime_enemy_damage_mult = clampf(enemy_damage_mult, 0.55, 1.8)


func _spawn_enemy() -> void:
    if enemy_scene == null:
        return
    var alive_limit: int = max_alive
    if _combat_mode == "elite":
        alive_limit = mini(max_alive, maxi(6, int(round(float(max_alive) * 0.55))))

    if get_alive_count() >= alive_limit:
        return

    var enemy: CharacterBody2D = _acquire_enemy_instance()
    if enemy == null:
        return

    var archetype: String = _pick_enemy_archetype()
    var is_elite_wave: bool = _combat_mode == "elite" or (_elite_wave_interval > 0 and _spawn_count > 0 and _spawn_count % _elite_wave_interval == 0)
    var chapter_id: String = _get_chapter_id_for_floor(floor_index)
    var enemy_id: String = _build_enemy_id(archetype, is_elite_wave, chapter_id)
    var profile: Dictionary = _build_archetype_profile(archetype, is_elite_wave)
    var tier: String = str(profile.get("tier", "normal"))
    enemy.enemy_id = enemy_id

    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    var center: Vector2 = global_position
    if player != null:
        center = player.global_position

    var angle: float = randf() * TAU
    var distance: float = randf_range(320.0, 460.0)
    enemy.global_position = center + Vector2.RIGHT.rotated(angle) * distance

    var pressure: Dictionary = _get_room_pressure_values()
    var floor_mult: float = _get_floor_multiplier()
    var hp_mult: float = floor_mult * float(pressure.get("hp_mult", 1.0)) * _runtime_enemy_hp_mult * float(profile.get("hp_mult", 1.0))
    var damage_mult: float = floor_mult * float(pressure.get("damage_mult", 1.0)) * _runtime_enemy_damage_mult * float(profile.get("damage_mult", 1.0))
    var speed_mult: float = float(profile.get("speed_mult", 1.0))
    var attack_interval_mult: float = float(profile.get("attack_interval_mult", 1.0))

    var health_component: Node = enemy.get_node_or_null("HealthComponent")
    if health_component != null and health_component.get("max_hp") != null:
        health_component.max_hp *= hp_mult
        health_component.current_hp = health_component.max_hp

    if enemy.get("touch_damage") != null:
        enemy.touch_damage *= damage_mult
    if enemy.get("move_speed") != null:
        enemy.move_speed *= speed_mult
    if enemy.get("attack_interval") != null:
        enemy.attack_interval = maxf(0.2, float(enemy.attack_interval) * attack_interval_mult)

    if enemy.has_method("apply_spawn_profile"):
        enemy.apply_spawn_profile({
            "tier": tier,
            "archetype": archetype,
            "enemy_id": enemy_id,
            "base_color": profile.get("base_color", Color(0.83, 0.37, 0.37, 1.0)),
            "scale": profile.get("scale", Vector2.ONE),
            "ranged": bool(profile.get("ranged", false)),
            "preferred_range": float(profile.get("preferred_range", 170.0)),
            "ranged_attack_range": float(profile.get("ranged_attack_range", 255.0)),
            "ranged_attack_interval": float(profile.get("ranged_attack_interval", 1.25)),
            "ranged_damage_mult": float(profile.get("ranged_damage_mult", 0.8))
        })

    _spawn_count += 1


func _spawn_boss() -> bool:
    if enemy_scene == null:
        return false
    if get_alive_count() > 0:
        return true

    var boss: CharacterBody2D = _acquire_enemy_instance()
    if boss == null:
        return false

    var boss_name: String = _boss_id
    if boss_name == "":
        boss_name = "boss_unknown"
    if boss.get("enemy_id") != null:
        boss.enemy_id = boss_name

    var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
    if player != null:
        boss.global_position = player.global_position + Vector2(randf_range(-220.0, 220.0), -260.0)
    else:
        boss.global_position = global_position

    var health_mult: float = (10.0 + float(floor_index) * 1.7) * _runtime_enemy_hp_mult
    var damage_mult: float = (1.8 + float(floor_index) * 0.08) * _runtime_enemy_damage_mult
    var speed_mult: float = 1.0
    var scale_mult: float = 1.0
    var boss_color: Color = Color(0.95, 0.45, 0.2, 1.0)

    if not _boss_style_profile.is_empty():
        health_mult *= clampf(float(_boss_style_profile.get("hp_mult", 1.0)), 0.7, 1.4)
        damage_mult *= clampf(float(_boss_style_profile.get("damage_mult", 1.0)), 0.7, 1.5)
        speed_mult = clampf(float(_boss_style_profile.get("speed_mult", 1.0)), 0.7, 1.5)
        scale_mult = clampf(float(_boss_style_profile.get("scale_mult", 1.0)), 0.85, 1.25)
        boss_color = Color.from_string(str(_boss_style_profile.get("color", "#f2733a")), boss_color)

    var health_component: Node = boss.get_node_or_null("HealthComponent")
    if health_component != null and health_component.get("max_hp") != null:
        health_component.max_hp *= health_mult
        health_component.current_hp = health_component.max_hp

    if boss.get("touch_damage") != null:
        boss.touch_damage *= damage_mult
    if boss.get("move_speed") != null:
        boss.move_speed *= 0.76 * speed_mult

    var visual: Polygon2D = boss.get_node_or_null("Polygon2D") as Polygon2D
    if visual != null:
        visual.color = boss_color
    boss.scale = Vector2(1.9, 1.9) * scale_mult
    if boss.has_method("set_visual_scale_base"):
        boss.set_visual_scale_base(boss.scale)
    if boss.has_method("apply_spawn_profile"):
        boss.apply_spawn_profile({
            "tier": "boss",
            "archetype": "boss",
            "enemy_id": boss_name,
            "base_color": boss_color,
            "scale": boss.scale
        })
    _active_boss = boss
    _boss_support_phase_marks.clear()
    return true


func _process_boss_support() -> void:
    if _boss_id == "":
        return
    if not _should_spawn_support_for_boss(_boss_id):
        return

    if _active_boss == null or not is_instance_valid(_active_boss):
        _active_boss = _find_active_boss_node()
    if _active_boss == null:
        return

    var phase_index: int = 0
    if _active_boss.has_method("get_phase_index"):
        phase_index = int(_active_boss.get_phase_index())
    else:
        phase_index = int(_active_boss.get("_phase_index"))
    if phase_index <= 0:
        return
    if bool(_boss_support_phase_marks.get(phase_index, false)):
        return

    var support_alive: int = _get_boss_support_alive_count()
    if support_alive >= _get_boss_support_alive_limit(_boss_id):
        return

    var support_result: Dictionary = _spawn_boss_support_wave(_boss_id, phase_index)
    var spawned: int = int(support_result.get("spawned_count", 0))
    if spawned > 0:
        _boss_support_phase_marks[phase_index] = true
        _last_boss_support_snapshot = support_result.duplicate(true)
        _last_boss_support_snapshot["phase_index"] = phase_index
        _last_boss_support_snapshot["boss_id"] = _boss_id

        var includes_miniboss: bool = bool(support_result.get("includes_miniboss", false))
        if _active_boss != null and is_instance_valid(_active_boss) and _active_boss.has_method("play_boss_support_stage_cue"):
            _active_boss.play_boss_support_stage_cue(phase_index, includes_miniboss)

        if AudioManager != null and AudioManager.has_method("play_boss_support_cue"):
            AudioManager.play_boss_support_cue(_boss_id, phase_index, spawned, includes_miniboss)


func _should_spawn_support_for_boss(boss_name: String) -> bool:
    return boss_name == "boss_frost_king" or boss_name == "boss_void_lord"


func _find_active_boss_node() -> CharacterBody2D:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if node == null or not is_instance_valid(node):
            continue
        if node.has_method("is_pool_active") and not bool(node.is_pool_active()):
            continue
        var node_id: String = str(node.get("enemy_id"))
        if node_id == _boss_id:
            return node as CharacterBody2D
    return null


func _get_boss_support_alive_count() -> int:
    var total: int = 0
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if node == null or not is_instance_valid(node):
            continue
        if ObjectPool != null and node.get_parent() == ObjectPool:
            continue
        if node.has_method("is_pool_active") and not bool(node.is_pool_active()):
            continue
        var node_id: String = str(node.get("enemy_id"))
        if node_id == "" or node_id.begins_with("boss_"):
            continue
        total += 1
    return total


func _get_boss_support_alive_limit(boss_name: String) -> int:
    if boss_name == "boss_void_lord":
        return 9
    if boss_name == "boss_frost_king":
        return 7
    return 5


func _spawn_boss_support_wave(boss_name: String, phase_index: int) -> Dictionary:
    var support_patterns: Dictionary = {
        "boss_frost_king": [
            ["normal", "ranged"],
            ["fast", "tank", "ranged"],
            ["fast", "tank", "ranged"]
        ],
        "boss_void_lord": [
            ["fast", "ranged"],
            ["normal", "tank", "ranged"],
            ["normal", "fast", "tank", "ranged"],
            ["normal", "fast", "tank", "ranged"]
        ]
    }

    var patterns_var: Variant = support_patterns.get(boss_name, [])
    if not (patterns_var is Array):
        return {"spawned_count": 0, "includes_miniboss": false, "chapter_id": "", "curve": {}}

    var patterns: Array = patterns_var
    var wave_index: int = mini(phase_index - 1, patterns.size() - 1)
    if wave_index < 0 or wave_index >= patterns.size():
        return {"spawned_count": 0, "includes_miniboss": false, "chapter_id": "", "curve": {}}

    var wave_var: Variant = patterns[wave_index]
    if not (wave_var is Array):
        return {"spawned_count": 0, "includes_miniboss": false, "chapter_id": "", "curve": {}}

    var chapter_id: String = _resolve_boss_support_chapter(boss_name)
    var curve: Dictionary = _build_boss_support_curve(chapter_id, phase_index, false)
    var spawned: int = 0
    var includes_miniboss: bool = false
    var wave: Array = wave_var
    for i in range(wave.size()):
        var archetype: String = str(wave[i])
        var use_elite: bool = phase_index >= 2 and i >= wave.size() - 1
        var use_miniboss: bool = _should_use_miniboss_support(boss_name, archetype, phase_index, i, wave.size())
        if use_miniboss:
            includes_miniboss = true
        if _spawn_boss_support_enemy(chapter_id, archetype, use_elite, phase_index, boss_name, use_miniboss):
            spawned += 1
    return {
        "spawned_count": spawned,
        "includes_miniboss": includes_miniboss,
        "chapter_id": chapter_id,
        "curve": curve,
    }


func _resolve_boss_support_chapter(boss_name: String) -> String:
    if boss_name == "boss_frost_king":
        return "chapter_3"
    if boss_name == "boss_void_lord":
        return "chapter_4"
    return _get_chapter_id_for_floor(floor_index)


func _should_use_miniboss_support(boss_name: String, archetype: String, phase_index: int, slot_index: int, wave_size: int) -> bool:
    if phase_index < 2:
        return false
    if archetype != "tank":
        return false
    if boss_name == "boss_frost_king":
        return slot_index >= wave_size - 2
    if boss_name == "boss_void_lord":
        return phase_index >= 3 and slot_index >= wave_size - 2
    return false


func _resolve_miniboss_support_id(boss_name: String) -> String:
    if boss_name == "boss_frost_king":
        return "miniboss_frost_warden"
    if boss_name == "boss_void_lord":
        return "miniboss_void_harbinger"
    return "miniboss_support"


func _build_boss_support_curve(chapter_id: String, phase_index: int, is_miniboss: bool) -> Dictionary:
    var chapter_curve: Dictionary = {
        "chapter_1": {"hp": 0.95, "damage": 0.94, "speed": 0.98, "attack": 1.02},
        "chapter_2": {"hp": 1.00, "damage": 1.00, "speed": 1.02, "attack": 1.00},
        "chapter_3": {"hp": 1.12, "damage": 1.08, "speed": 1.06, "attack": 0.96},
        "chapter_4": {"hp": 1.22, "damage": 1.16, "speed": 1.10, "attack": 0.92},
    }
    var chapter_row: Dictionary = chapter_curve.get(chapter_id, chapter_curve.get("chapter_2", {}))
    var phase_step: float = clampf(float(phase_index), 0.0, 4.0)

    var hp_mult: float = float(chapter_row.get("hp", 1.0)) * (1.0 + 0.18 * phase_step)
    var damage_mult: float = float(chapter_row.get("damage", 1.0)) * (1.0 + 0.12 * phase_step)
    var speed_mult: float = float(chapter_row.get("speed", 1.0)) * (1.0 + 0.06 * phase_step)
    var attack_interval_mult: float = float(chapter_row.get("attack", 1.0)) * (1.0 - 0.05 * phase_step)

    if is_miniboss:
        hp_mult *= 1.42
        damage_mult *= 1.28
        speed_mult *= 1.09
        attack_interval_mult *= 0.88

    hp_mult = clampf(hp_mult, 0.8, 4.2)
    damage_mult = clampf(damage_mult, 0.8, 3.4)
    speed_mult = clampf(speed_mult, 0.82, 1.85)
    attack_interval_mult = clampf(attack_interval_mult, 0.35, 1.25)

    return {
        "chapter_id": chapter_id,
        "phase_index": phase_index,
        "is_miniboss": is_miniboss,
        "hp_mult": hp_mult,
        "damage_mult": damage_mult,
        "speed_mult": speed_mult,
        "attack_interval_mult": attack_interval_mult,
    }


func get_boss_support_curve_snapshot(boss_name: String, phase_index: int, includes_miniboss: bool = false) -> Dictionary:
    var chapter_id: String = _resolve_boss_support_chapter(boss_name)
    return _build_boss_support_curve(chapter_id, phase_index, includes_miniboss)


func get_last_boss_support_snapshot() -> Dictionary:
    return _last_boss_support_snapshot.duplicate(true)


func _spawn_boss_support_enemy(chapter_id: String, archetype: String, is_elite: bool, phase_index: int, boss_name: String, is_miniboss: bool = false) -> bool:
    if get_alive_count() >= max_alive + 8:
        return false

    var enemy: CharacterBody2D = _acquire_enemy_instance()
    if enemy == null:
        return false

    var enemy_id: String = _build_enemy_id(archetype, is_elite, chapter_id)
    if is_miniboss:
        enemy_id = _resolve_miniboss_support_id(boss_name)
    var profile: Dictionary = _build_archetype_profile(archetype, is_elite)
    var tier: String = str(profile.get("tier", "normal"))
    if is_miniboss:
        tier = "elite"

    var center: Vector2 = global_position
    if _active_boss != null and is_instance_valid(_active_boss):
        center = _active_boss.global_position
    var angle: float = randf() * TAU
    var distance: float = randf_range(140.0, 220.0)
    enemy.global_position = center + Vector2.RIGHT.rotated(angle) * distance

    var support_curve: Dictionary = _build_boss_support_curve(chapter_id, phase_index, is_miniboss)
    var support_hp_mult: float = float(support_curve.get("hp_mult", 1.0)) * _runtime_enemy_hp_mult
    var support_damage_mult: float = float(support_curve.get("damage_mult", 1.0)) * _runtime_enemy_damage_mult
    var support_speed_mult: float = float(support_curve.get("speed_mult", 1.0))
    var support_attack_interval_mult: float = float(support_curve.get("attack_interval_mult", 1.0))

    var health_component: Node = enemy.get_node_or_null("HealthComponent")
    if health_component != null and health_component.get("max_hp") != null:
        health_component.max_hp *= support_hp_mult * float(profile.get("hp_mult", 1.0))
        health_component.current_hp = health_component.max_hp

    if enemy.get("touch_damage") != null:
        enemy.touch_damage *= support_damage_mult * float(profile.get("damage_mult", 1.0))
    if enemy.get("move_speed") != null:
        enemy.move_speed *= support_speed_mult * float(profile.get("speed_mult", 1.0))
    if enemy.get("attack_interval") != null:
        enemy.attack_interval = maxf(
            0.18,
            float(enemy.attack_interval)
            * float(profile.get("attack_interval_mult", 1.0))
            * support_attack_interval_mult
        )

    if is_miniboss:
        var support_scale: Vector2 = profile.get("scale", Vector2.ONE)
        profile["scale"] = support_scale * 1.32
        var boss_tint: Color = profile.get("base_color", Color(0.83, 0.37, 0.37, 1.0))
        if boss_name == "boss_frost_king":
            boss_tint = boss_tint.lightened(0.24)
        elif boss_name == "boss_void_lord":
            boss_tint = boss_tint.darkened(0.12)
        profile["base_color"] = boss_tint

    if enemy.has_method("apply_spawn_profile"):
        enemy.apply_spawn_profile({
            "tier": tier,
            "archetype": archetype,
            "enemy_id": enemy_id,
            "base_color": profile.get("base_color", Color(0.83, 0.37, 0.37, 1.0)),
            "scale": profile.get("scale", Vector2.ONE),
            "ranged": bool(profile.get("ranged", false)),
            "preferred_range": float(profile.get("preferred_range", 170.0)),
            "ranged_attack_range": float(profile.get("ranged_attack_range", 255.0)),
            "ranged_attack_interval": float(profile.get("ranged_attack_interval", 1.25)),
            "ranged_damage_mult": float(profile.get("ranged_damage_mult", 0.8))
        })

    return true


func _pick_enemy_archetype() -> String:
    var total: float = 0.0
    for value: Variant in _enemy_type_weights.values():
        total += maxf(0.0, float(value))
    if total <= 0.0:
        return "normal"

    var roll: float = randf() * total
    var cumulative: float = 0.0
    for key: Variant in _enemy_type_weights.keys():
        var weight: float = maxf(0.0, float(_enemy_type_weights.get(key, 0.0)))
        cumulative += weight
        if roll <= cumulative:
            return str(key)
    return "normal"


func _build_enemy_id(archetype: String, is_elite: bool, chapter_id: String) -> String:
    var chapter_row_var: Variant = _chapter_archetype_map.get(chapter_id, _chapter_archetype_map.get("chapter_1", {}))
    var chapter_row: Dictionary = {}
    if chapter_row_var is Dictionary:
        chapter_row = chapter_row_var
    var base_name: String = str(chapter_row.get(archetype, chapter_row.get("normal", "enemy_shadowling")))
    if base_name == "":
        base_name = "enemy_shadowling"
    if is_elite:
        return "elite_%s" % base_name.trim_prefix("enemy_")
    return base_name


func _build_archetype_profile(archetype: String, is_elite: bool) -> Dictionary:
    var profile: Dictionary = {
        "tier": "normal",
        "hp_mult": 1.0,
        "damage_mult": 1.0,
        "speed_mult": 1.0,
        "attack_interval_mult": 1.0,
        "base_color": Color(0.83, 0.37, 0.37, 1.0),
        "scale": Vector2.ONE,
        "ranged": false,
        "preferred_range": 170.0,
        "ranged_attack_range": 255.0,
        "ranged_attack_interval": 1.3,
        "ranged_damage_mult": 0.85
    }

    match archetype:
        "fast":
            profile["hp_mult"] = 0.78
            profile["damage_mult"] = 0.9
            profile["speed_mult"] = 1.45
            profile["attack_interval_mult"] = 0.86
            profile["base_color"] = Color(0.78, 0.52, 0.96, 1.0)
            profile["scale"] = Vector2(0.92, 0.92)
        "tank":
            profile["hp_mult"] = 1.85
            profile["damage_mult"] = 1.22
            profile["speed_mult"] = 0.72
            profile["attack_interval_mult"] = 1.18
            profile["base_color"] = Color(0.55, 0.78, 0.72, 1.0)
            profile["scale"] = Vector2(1.22, 1.22)
        "ranged":
            profile["hp_mult"] = 0.92
            profile["damage_mult"] = 0.95
            profile["speed_mult"] = 0.88
            profile["attack_interval_mult"] = 1.02
            profile["base_color"] = Color(0.92, 0.62, 0.38, 1.0)
            profile["ranged"] = true
            profile["preferred_range"] = 205.0
            profile["ranged_attack_range"] = 290.0
            profile["ranged_attack_interval"] = 1.15
            profile["ranged_damage_mult"] = 0.72

    if is_elite:
        profile["tier"] = "elite"
        profile["hp_mult"] = float(profile.get("hp_mult", 1.0)) * 2.1
        profile["damage_mult"] = float(profile.get("damage_mult", 1.0)) * 1.45
        profile["speed_mult"] = float(profile.get("speed_mult", 1.0)) * 1.08
        profile["base_color"] = Color(0.98, 0.84, 0.3, 1.0)
        var base_scale: Vector2 = profile.get("scale", Vector2.ONE)
        profile["scale"] = base_scale * 1.25

    return profile


func _load_spawn_profile_config() -> void:
    var scaling: Dictionary = ConfigManager.get_config("enemy_scaling", {})

    var interval: int = int(scaling.get("elite_wave_interval", 8))
    _elite_wave_interval = maxi(3, interval)

    var config_weights_var: Variant = scaling.get("enemy_type_weights", {})
    var config_weights: Dictionary = {}
    if config_weights_var is Dictionary:
        config_weights = config_weights_var

    var required_types: Array[String] = ["normal", "fast", "tank", "ranged"]
    for enemy_type: String in required_types:
        var raw_weight: float = float(config_weights.get(enemy_type, _enemy_type_weights.get(enemy_type, 0.0)))
        _enemy_type_weights[enemy_type] = maxf(0.0, raw_weight)

    var chapter_map_var: Variant = scaling.get("chapter_archetype_map", {})
    if chapter_map_var is Dictionary:
        for chapter_id: String in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
            var chapter_row_var: Variant = (chapter_map_var as Dictionary).get(chapter_id, {})
            if not (chapter_row_var is Dictionary):
                continue
            var chapter_row: Dictionary = chapter_row_var
            if not _chapter_archetype_map.has(chapter_id):
                _chapter_archetype_map[chapter_id] = {}
            var target_row: Dictionary = _chapter_archetype_map[chapter_id]
            for enemy_type: String in required_types:
                var enemy_id: String = str(chapter_row.get(enemy_type, target_row.get(enemy_type, "enemy_shadowling"))).strip_edges()
                if enemy_id != "":
                    target_row[enemy_type] = enemy_id


func _get_chapter_id_for_floor(target_floor: int) -> String:
    var safe_floor: int = maxi(1, target_floor)
    if safe_floor <= 4:
        return "chapter_1"
    if safe_floor <= 8:
        return "chapter_2"
    if safe_floor <= 12:
        return "chapter_3"
    return "chapter_4"


func _acquire_enemy_instance() -> CharacterBody2D:
    var enemy: CharacterBody2D
    if ObjectPool != null:
        enemy = ObjectPool.acquire("enemy_basic", self) as CharacterBody2D
    if enemy == null and enemy_scene != null:
        enemy = enemy_scene.instantiate() as CharacterBody2D
        if enemy != null:
            add_child(enemy)
    return enemy


func _get_spawn_interval() -> float:
    var floor_ratio: float = 1.0 + float(floor_index - 1) * 0.09
    var time_ratio: float = 1.0
    if _room_time > 120.0:
        time_ratio = 1.8
    elif _room_time > 60.0:
        time_ratio = 1.5
    elif _room_time > 30.0:
        time_ratio = 1.25

    var interval: float = 1.3 / (floor_ratio * time_ratio * _runtime_spawn_rate_mult)
    if _combat_mode == "elite":
        interval *= 1.18
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
