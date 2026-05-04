extends Node2D

var source: Node
var radius: float = 64.0
var duration: float = 2.8
var tick_interval: float = 0.35
var damage: float = 5.0
var damage_type: int = 0
var knockback_force: float = 34.0
var style_id: String = "solar"

var _life_remaining: float = 0.0
var _tick_timer: float = 0.0
var _ring: Line2D


func setup(config: Dictionary) -> void:
	source = config.get("source", null) as Node
	radius = clampf(float(config.get("radius", radius)), 32.0, 140.0)
	duration = clampf(float(config.get("duration", duration)), 0.6, 6.0)
	tick_interval = clampf(float(config.get("tick_interval", tick_interval)), 0.18, 1.0)
	damage = maxf(1.0, float(config.get("damage", damage)))
	damage_type = int(config.get("damage_type", damage_type))
	knockback_force = clampf(float(config.get("knockback_force", knockback_force)), 0.0, 140.0)
	style_id = str(config.get("style_id", style_id))
	_life_remaining = duration
	_tick_timer = 0.02
	_rebuild_visual()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_life_remaining -= delta
	if _life_remaining <= 0.0:
		queue_free()
		return

	_tick_timer = maxf(0.0, _tick_timer - delta)
	if _ring != null:
		_ring.rotation += delta * 0.35
		_ring.modulate.a = clampf(_life_remaining / duration, 0.0, 1.0)
	if _tick_timer <= 0.0:
		_tick_timer = tick_interval
		_apply_zone_tick()


func _rebuild_visual() -> void:
	_ring = Line2D.new()
	_ring.width = 3.0
	_ring.default_color = _get_style_color()
	_ring.z_index = 3
	_ring.points = _build_ring_points(radius, 40)
	add_child(_ring)

	var fill: Polygon2D = Polygon2D.new()
	fill.color = Color(_ring.default_color.r, _ring.default_color.g, _ring.default_color.b, 0.11)
	fill.polygon = _build_ring_points(radius * 0.96, 40)
	fill.z_index = 2
	add_child(fill)


func _apply_zone_tick() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if not (node is Node2D):
			continue
		var enemy: Node2D = node
		var distance: float = global_position.distance_to(enemy.global_position)
		if distance > radius:
			continue

		var falloff: float = clampf(1.0 - distance / radius, 0.5, 1.0)
		var push: Vector2 = (enemy.global_position - global_position).normalized()
		if push == Vector2.ZERO:
			push = Vector2.RIGHT
		if enemy.has_method("apply_damage"):
			enemy.apply_damage(damage * falloff, source, damage_type, false, push * knockback_force)


func _build_ring_points(ring_radius: float, segments: int) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var safe_segments: int = maxi(12, segments)
	for i in range(safe_segments + 1):
		var angle: float = TAU * float(i) / float(safe_segments)
		points.append(Vector2.RIGHT.rotated(angle) * ring_radius)
	return points


func _get_style_color() -> Color:
	if style_id.find("glacial") >= 0 or style_id.find("frost") >= 0:
		return Color(0.48, 0.88, 1.0, 0.58)
	if style_id.find("void") >= 0 or style_id.find("zenith") >= 0:
		return Color(0.78, 0.58, 1.0, 0.58)
	return Color(1.0, 0.58, 0.25, 0.58)
