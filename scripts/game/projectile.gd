extends Area2D

const GROUND_HAZARD_SCRIPT: Script = preload("res://scripts/game/ground_hazard_zone.gd")

@export var speed: float = 680.0
@export var max_lifetime: float = 1.2
@export var hit_radius: float = 12.0
@export var impact_radius: float = 0.0
@export var impact_damage_mult: float = 0.42

@onready var _trail: Line2D = $Trail
@onready var _shape: Polygon2D = $Polygon2D

var _direction: Vector2 = Vector2.RIGHT
var _source: Node
var _weapon_damage: float = 10.0
var _damage_type: int = 0
var _bonus_pct: float = 0.0
var _penetration: float = 0.0
var _crit_multiplier: float = 1.0
var _is_crit: bool = false
var _knockback_force: float = 90.0
var _remaining_hits: int = 1
var _hit_enemy_ids: Dictionary = {}
var _style_id: String = "default"
var _life_remaining: float = 0.0
var _active: bool = false
var _impact_radius_runtime: float = 0.0
var _impact_damage_mult_runtime: float = 0.42


func setup(
    source: Node,
    direction: Vector2,
    weapon_damage: float,
    damage_type: int,
    bonus_pct: float,
    penetration: float,
    crit_multiplier: float,
    is_crit: bool,
    knockback_force: float,
    max_hits: int = 1,
    style_id: String = "default",
    splash_radius: float = 0.0,
    splash_damage_mult: float = 0.42
) -> void:
    _active = true
    _source = source
    _direction = direction.normalized()
    _weapon_damage = weapon_damage
    _damage_type = damage_type
    _bonus_pct = bonus_pct
    _penetration = penetration
    _crit_multiplier = maxf(1.0, crit_multiplier)
    _is_crit = is_crit
    _knockback_force = maxf(0.0, knockback_force)
    _remaining_hits = max(1, max_hits)
    _style_id = style_id
    _impact_radius_runtime = clampf(splash_radius, 0.0, 140.0)
    _impact_damage_mult_runtime = clampf(splash_damage_mult, 0.15, 0.85)
    _hit_enemy_ids.clear()
    _life_remaining = max_lifetime
    _apply_visual_style(_style_id, _is_crit)


func _process(delta: float) -> void:
    if not _active:
        return
    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    global_position += _direction * speed * delta
    rotation = _direction.angle()

    _life_remaining -= delta
    if _life_remaining <= 0.0:
        _recycle()
        return

    var enemy: Node2D = _find_colliding_enemy()
    if enemy == null:
        return

    var damage_value: float = _calculate_hit_damage(enemy)
    _apply_projectile_damage(enemy, damage_value, _direction * _knockback_force, _is_crit)
    if AudioManager != null and AudioManager.has_method("play_weapon_impact_cue"):
        AudioManager.play_weapon_impact_cue(_style_id, _is_crit)
    _spawn_hit_spark(enemy.global_position, _is_crit)
    _apply_impact_splash(enemy, enemy.global_position, damage_value)
    _spawn_ground_zone(enemy.global_position, damage_value)

    _hit_enemy_ids[enemy.get_instance_id()] = true
    _remaining_hits -= 1
    if _remaining_hits <= 0:
        _recycle()


func _find_colliding_enemy() -> Node2D:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if not (node is Node2D):
            continue

        var enemy: Node2D = node
        if _hit_enemy_ids.has(enemy.get_instance_id()):
            continue
        # 这里用轻量距离检测替代物理碰撞回调，方便对象池投射物在无额外碰撞配置时也能稳定工作。
        if global_position.distance_to(enemy.global_position) <= hit_radius:
            return enemy

    return null


func _calculate_hit_damage(enemy: Node) -> float:
    # 命中时才实时结算最终伤害，确保暴击、穿透和来源属性都按发射瞬间快照参与计算。
    return DamageSystem.calculate_damage(
        _source,
        enemy,
        _weapon_damage,
        _damage_type,
        _bonus_pct,
        _penetration,
        _crit_multiplier if _is_crit else 1.0,
        1.0
    )


func _apply_projectile_damage(enemy: Node2D, amount: float, knockback: Vector2, is_crit: bool) -> void:
    if enemy == null:
        return
    if enemy.has_method("apply_damage"):
        enemy.apply_damage(
            amount,
            _source,
            _damage_type,
            is_crit,
            knockback
        )


func _apply_impact_splash(primary_enemy: Node2D, hit_position: Vector2, primary_damage: float) -> void:
    if _impact_radius_runtime <= 0.0:
        return

    var splash_damage: float = maxf(1.0, primary_damage * _impact_damage_mult_runtime)
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if not (node is Node2D):
            continue

        var enemy: Node2D = node
        if enemy == primary_enemy:
            continue
        if _hit_enemy_ids.has(enemy.get_instance_id()):
            continue
        var distance: float = enemy.global_position.distance_to(hit_position)
        if distance > _impact_radius_runtime:
            continue

        var away: Vector2 = (enemy.global_position - hit_position).normalized()
        if away == Vector2.ZERO:
            away = _direction
        var falloff: float = clampf(1.0 - distance / _impact_radius_runtime, 0.35, 1.0)
        _apply_projectile_damage(
            enemy,
            splash_damage * falloff,
            away * (_knockback_force * 0.58),
            false
        )
        _hit_enemy_ids[enemy.get_instance_id()] = true

    _spawn_impact_ring(hit_position)


func _recycle() -> void:
    _active = false
    if ObjectPool != null:
        ObjectPool.release("projectile_basic", self)
        return
    queue_free()


func _spawn_hit_spark(hit_position: Vector2, is_crit: bool) -> void:
    var parent_scene: Node = get_tree().current_scene
    if parent_scene == null:
        parent_scene = get_tree().root

    var spark: Node2D = Node2D.new()
    spark.global_position = hit_position
    parent_scene.add_child(spark)

    var color: Color = Color(1.0, 0.78, 0.28, 0.95) if is_crit else Color(0.82, 0.95, 1.0, 0.82)
    for i in range(4):
        var ray: Line2D = Line2D.new()
        ray.width = 3.0 if is_crit else 2.0
        ray.default_color = color
        var angle: float = float(i) * TAU / 4.0 + randf_range(-0.28, 0.28)
        ray.points = PackedVector2Array([Vector2.ZERO, Vector2.RIGHT.rotated(angle) * (18.0 if is_crit else 13.0)])
        spark.add_child(ray)

    var tween: Tween = spark.create_tween()
    tween.tween_property(spark, "modulate:a", 0.0, 0.16)
    tween.tween_callback(spark.queue_free)


func _spawn_impact_ring(hit_position: Vector2) -> void:
    var parent_scene: Node = get_tree().current_scene
    if parent_scene == null:
        parent_scene = get_tree().root

    var ring: Line2D = Line2D.new()
    ring.global_position = hit_position
    ring.width = 2.5
    ring.default_color = _get_style_color(_style_id, _is_crit, 0.62)
    ring.z_index = 6
    ring.points = _build_ring_points(maxf(12.0, _impact_radius_runtime * 0.42), 18)
    parent_scene.add_child(ring)

    var tween: Tween = ring.create_tween()
    tween.tween_property(ring, "scale", Vector2.ONE * 1.55, 0.18)
    tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.18)
    tween.tween_callback(ring.queue_free)


func _spawn_ground_zone(hit_position: Vector2, primary_damage: float) -> void:
    var config: Dictionary = _get_ground_zone_config(primary_damage)
    if config.is_empty():
        return

    var parent_scene: Node = get_tree().current_scene
    if parent_scene == null:
        parent_scene = get_tree().root

    var zone: Node2D = GROUND_HAZARD_SCRIPT.new() as Node2D
    if zone == null:
        return
    zone.name = "GroundHazardZone"
    zone.global_position = hit_position
    parent_scene.add_child(zone)
    if zone.has_method("setup"):
        zone.setup(config)


func _get_ground_zone_config(primary_damage: float) -> Dictionary:
    var style: String = _style_id.to_lower()
    var radius: float = 0.0
    var duration: float = 0.0
    var tick_mult: float = 0.0
    if style.find("solar_supernova") >= 0:
        radius = 78.0
        duration = 2.8
        tick_mult = 0.28
    elif style.find("glacial_nova") >= 0:
        radius = 72.0
        duration = 3.2
        tick_mult = 0.23
    elif style.find("radiant_cataclysm") >= 0:
        radius = 86.0
        duration = 2.4
        tick_mult = 0.32
    elif style.find("zenith_reliquary") >= 0:
        radius = 74.0
        duration = 2.9
        tick_mult = 0.25

    if radius <= 0.0:
        return {}
    return {
        "source": _source,
        "radius": radius,
        "duration": duration,
        "tick_interval": 0.35,
        "damage": maxf(1.0, primary_damage * tick_mult),
        "damage_type": _damage_type,
        "knockback_force": 38.0,
        "style_id": _style_id
    }


func _build_ring_points(radius: float, segments: int) -> PackedVector2Array:
    var points: PackedVector2Array = PackedVector2Array()
    var safe_segments: int = maxi(8, segments)
    for i in range(safe_segments + 1):
        var angle: float = TAU * float(i) / float(safe_segments)
        points.append(Vector2.RIGHT.rotated(angle) * radius)
    return points


func on_pool_acquired() -> void:
    _active = false
    _remaining_hits = 1
    _hit_enemy_ids.clear()
    _style_id = "default"
    _life_remaining = max_lifetime
    _impact_radius_runtime = impact_radius
    _impact_damage_mult_runtime = impact_damage_mult


func on_pool_released() -> void:
    _active = false
    _remaining_hits = 1
    _hit_enemy_ids.clear()
    _style_id = "default"
    _source = null
    _impact_radius_runtime = impact_radius
    _impact_damage_mult_runtime = impact_damage_mult


func _apply_visual_style(style_id: String, is_crit: bool) -> void:
    if _shape == null:
        return

    # 投射物外观直接由武器风格 id 决定，暴击只额外做一次高亮混色，不改底层几何模板。
    var color: Color = _get_style_color(style_id, is_crit)
    var polygon: PackedVector2Array = PackedVector2Array([-6, -3, 8, 0, -6, 3])

    match style_id.to_lower():
        "knight_lance":
            polygon = PackedVector2Array([-8, -2, 11, 0, -8, 2])
        "mage_orb":
            polygon = PackedVector2Array([-4, -4, 0, -7, 4, -4, 7, 0, 4, 4, 0, 7, -4, 4, -7, 0])
        "rogue_dart":
            polygon = PackedVector2Array([-7, -1.5, 10, 0, -7, 1.5])

    _shape.color = color
    _shape.polygon = polygon
    if _trail != null:
        _trail.default_color = Color(color.r, color.g, color.b, 0.42)
        _trail.width = 5.5 if is_crit else 4.0


func _get_style_color(style_id: String, is_crit: bool, alpha: float = 1.0) -> Color:
    var color: Color = Color(1.0, 0.93, 0.44, alpha)
    match style_id.to_lower():
        "knight_lance", "holy_judgment", "seraph_lance", "vowblade", "vowstorm":
            color = Color(0.70, 0.88, 1.0, alpha)
        "mage_orb", "arcane_comet", "glacial_nova":
            color = Color(0.64, 0.56, 1.0, alpha)
        "rogue_dart", "shadow_tempest":
            color = Color(0.55, 1.0, 0.78, alpha)
        "radiant_hammer", "radiant_cataclysm", "solar_supernova":
            color = Color(1.0, 0.72, 0.32, alpha)
        "void_chain", "abyssal_chain", "nether_shard", "nether_maelstrom":
            color = Color(0.74, 0.52, 1.0, alpha)
        "astral_disc", "astral_horizon", "reliquary_orb", "zenith_reliquary":
            color = Color(0.58, 0.92, 1.0, alpha)
    if is_crit:
        color = color.lerp(Color(1.0, 0.95, 0.55, alpha), 0.45)
    return color
