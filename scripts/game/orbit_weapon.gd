extends Node2D

var owner_body: CharacterBody2D
var weapon: Node
var radius: float = 64.0
var orbit_count: int = 2
var damage_mult: float = 0.46
var hit_interval: float = 0.34
var style_id: String = "astral_disc"

var _angle: float = 0.0
var _visuals: Array[Polygon2D] = []
var _enemy_hit_timers: Dictionary = {}


func setup(new_owner: CharacterBody2D, new_weapon: Node, config: Dictionary) -> void:
	owner_body = new_owner
	weapon = new_weapon
	radius = clampf(float(config.get("radius", radius)), 36.0, 130.0)
	orbit_count = clampi(int(config.get("count", orbit_count)), 1, 6)
	damage_mult = clampf(float(config.get("damage_mult", damage_mult)), 0.18, 0.75)
	hit_interval = clampf(float(config.get("hit_interval", hit_interval)), 0.18, 0.8)
	style_id = str(config.get("style_id", style_id))
	_rebuild_visuals()


func _process(delta: float) -> void:
	if owner_body == null or weapon == null:
		return
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return

	_angle += delta * _get_orbit_speed()
	_update_hit_timers(delta)
	_update_visuals()
	_apply_orbit_hits()


func _rebuild_visuals() -> void:
	for visual: Polygon2D in _visuals:
		if is_instance_valid(visual):
			visual.queue_free()
	_visuals.clear()

	for i in range(orbit_count):
		var visual: Polygon2D = Polygon2D.new()
		visual.color = _get_style_color()
		visual.polygon = PackedVector2Array([-10, -4, 8, -6, 14, 0, 8, 6, -10, 4])
		visual.z_index = 7
		add_child(visual)
		_visuals.append(visual)


func _update_visuals() -> void:
	for i in range(_visuals.size()):
		var visual: Polygon2D = _visuals[i]
		if not is_instance_valid(visual):
			continue
		var angle: float = _angle + TAU * float(i) / float(maxi(1, _visuals.size()))
		visual.position = Vector2.RIGHT.rotated(angle) * radius
		visual.rotation = angle + PI * 0.5


func _apply_orbit_hits() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if not (node is Node2D):
			continue

		var enemy: Node2D = node
		if _enemy_hit_timers.has(enemy.get_instance_id()):
			continue
		for visual: Polygon2D in _visuals:
			if not is_instance_valid(visual):
				continue
			var hit_position: Vector2 = global_position + visual.position
			if hit_position.distance_to(enemy.global_position) > 18.0:
				continue
			_apply_damage(enemy, hit_position)
			_enemy_hit_timers[enemy.get_instance_id()] = hit_interval
			break


func _apply_damage(enemy: Node2D, hit_position: Vector2) -> void:
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

	var amount: float = DamageSystem.calculate_damage(owner_body, enemy, base_damage * damage_mult, int(DamageSystem.DamageType.PHYSICAL), bonus_pct, 0.0, 1.0, 1.0)
	var push: Vector2 = (enemy.global_position - hit_position).normalized()
	if push == Vector2.ZERO:
		push = Vector2.RIGHT
	if enemy.has_method("apply_damage"):
		enemy.apply_damage(amount, owner_body, int(DamageSystem.DamageType.PHYSICAL), false, push * 82.0)


func _update_hit_timers(delta: float) -> void:
	var retained: Dictionary = {}
	for key: Variant in _enemy_hit_timers.keys():
		var remaining: float = float(_enemy_hit_timers[key]) - delta
		if remaining > 0.0:
			retained[key] = remaining
	_enemy_hit_timers = retained


func _get_orbit_speed() -> float:
	if style_id.find("reliquary") >= 0 or style_id.find("zenith") >= 0:
		return 2.9
	if style_id.find("void") >= 0 or style_id.find("abyssal") >= 0:
		return 2.35
	return 3.35


func _get_style_color() -> Color:
	if style_id.find("void") >= 0 or style_id.find("abyssal") >= 0:
		return Color(0.74, 0.52, 1.0, 0.9)
	if style_id.find("reliquary") >= 0 or style_id.find("zenith") >= 0:
		return Color(0.64, 0.95, 1.0, 0.92)
	return Color(0.58, 0.92, 1.0, 0.9)
