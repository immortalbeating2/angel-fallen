extends Node2D

var owner_body: CharacterBody2D
var weapon: Node
var radius: float = 86.0
var damage_mult: float = 0.24
var tick_interval: float = 0.45
var style_id: String = "holy_aura"

var _tick_timer: float = 0.0
var _ring: Line2D


func setup(new_owner: CharacterBody2D, new_weapon: Node, config: Dictionary) -> void:
	owner_body = new_owner
	weapon = new_weapon
	radius = clampf(float(config.get("radius", radius)), 48.0, 150.0)
	damage_mult = clampf(float(config.get("damage_mult", damage_mult)), 0.12, 0.45)
	tick_interval = clampf(float(config.get("tick_interval", tick_interval)), 0.28, 0.9)
	style_id = str(config.get("style_id", style_id))
	_rebuild_ring()


func _process(delta: float) -> void:
	if owner_body == null or weapon == null:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_tick_timer = maxf(0.0, _tick_timer - delta)
	if _ring != null:
		_ring.rotation += delta * 0.55
		_ring.modulate.a = 0.34 + 0.12 * sin(Time.get_ticks_msec() / 180.0)
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_aura_tick()


func _rebuild_ring() -> void:
	if _ring != null and is_instance_valid(_ring):
		_ring.queue_free()

	_ring = Line2D.new()
	_ring.width = 2.5
	_ring.default_color = _get_style_color()
	_ring.z_index = 4
	_ring.points = _build_ring_points(radius, 48)
	add_child(_ring)


func _apply_aura_tick() -> void:
	var base_damage: float = 8.0
	var bonus_pct: float = 0.0
	if weapon != null:
		if weapon.get("base_damage") != null:
			base_damage = float(weapon.get("base_damage"))
		if weapon.get("external_damage_bonus_pct") != null:
			bonus_pct += float(weapon.get("external_damage_bonus_pct"))
	var stats: Node = owner_body.get_node_or_null("StatsComponent") if owner_body != null else null
	if stats != null and stats.get("damage_bonus_pct") != null:
		bonus_pct += float(stats.get("damage_bonus_pct"))

	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if not (node is Node2D):
			continue
		var enemy: Node2D = node
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue

		var falloff: float = clampf(1.0 - distance / radius, 0.55, 1.0)
		var amount: float = DamageSystem.calculate_damage(owner_body, enemy, base_damage * damage_mult * falloff, int(DamageSystem.DamageType.HOLY), bonus_pct, 0.0, 1.0, 1.0)
		var push: Vector2 = (enemy.global_position - global_position).normalized()
		if push == Vector2.ZERO:
			push = Vector2.RIGHT
		if enemy.has_method("apply_damage"):
			enemy.apply_damage(amount, owner_body, int(DamageSystem.DamageType.HOLY), false, push * 42.0)


func _build_ring_points(ring_radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_segments: int = maxi(12, segments)
	for i in range(safe_segments + 1):
		var angle: float = TAU * float(i) / float(safe_segments)
		points.append(Vector2.RIGHT.rotated(angle) * ring_radius)
	return points


func _get_style_color() -> Color:
	if style_id.find("void") >= 0:
		return Color(0.74, 0.52, 1.0, 0.38)
	if style_id.find("frost") >= 0 or style_id.find("glacial") >= 0:
		return Color(0.58, 0.9, 1.0, 0.36)
	return Color(1.0, 0.92, 0.54, 0.36)
