extends GutTest

const ENEMY_SCENE_PATH: String = "res://scenes/game/enemy.tscn"
const ENEMY_SPAWNER_SCRIPT := preload("res://scripts/systems/enemy_spawner.gd")


class MockPlayer:
	extends CharacterBody2D

	var damage_taken: float = 0.0
	var last_knockback: Vector2 = Vector2.ZERO

	func apply_damage(amount: float) -> void:
		damage_taken += amount

	func apply_knockback(force: Vector2) -> void:
		last_knockback = force


func _spawn_enemy_node() -> CharacterBody2D:
	var scene: PackedScene = load(ENEMY_SCENE_PATH)
	assert_not_null(scene, "Enemy scene should load")
	if scene == null:
		return null

	var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
	assert_not_null(enemy, "Enemy instance should be CharacterBody2D")
	if enemy == null:
		return null

	add_child_autofree(enemy)
	await get_tree().process_frame
	return enemy


func _clear_active_enemies() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if ObjectPool != null and node.get_parent() == ObjectPool:
			continue
		if ObjectPool != null:
			ObjectPool.release("enemy_basic", node)
		else:
			node.queue_free()


func _collect_support_enemy_ids() -> Array[String]:
	var ids: Array[String] = []
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == null or not is_instance_valid(node):
			continue
		if node.has_method("is_pool_active") and not bool(node.is_pool_active()):
			continue
		var enemy_id: String = str(node.get("enemy_id"))
		if enemy_id == "" or enemy_id.begins_with("boss_"):
			continue
		ids.append(enemy_id)
	return ids


func _set_boss_phase_by_hp(boss: CharacterBody2D, hp_ratio: float) -> void:
	var health: Node = boss.get_node_or_null("HealthComponent")
	if health == null:
		return
	var max_hp: float = float(health.get("max_hp"))
	health.set("current_hp", clampf(max_hp * hp_ratio, 1.0, max_hp))
	boss.call("_update_phase_by_hp")


func _contains_keyword(ids: Array[String], keyword: String) -> bool:
	for enemy_id: String in ids:
		if enemy_id.find(keyword) >= 0:
			return true
	return false


func test_boss_phases_config_has_required_mainline_thresholds() -> void:
	var raw_text: String = FileAccess.get_file_as_string("res://data/balance/boss_phases.json")
	assert_ne(raw_text, "", "boss_phases.json should be readable")
	if raw_text == "":
		return

	var parsed: Variant = JSON.parse_string(raw_text)
	assert_true(parsed is Dictionary, "boss_phases.json should parse as Dictionary")
	if not (parsed is Dictionary):
		return

	var bosses_var: Variant = (parsed as Dictionary).get("bosses", {})
	assert_true(bosses_var is Dictionary, "bosses should exist")
	if not (bosses_var is Dictionary):
		return

	var bosses: Dictionary = bosses_var
	var required: Dictionary = {
		"enemy_rock_colossus": 3,
		"enemy_flame_lord": 3,
		"enemy_frost_king": 3,
		"enemy_void_lord": 4,
	}

	for boss_id: String in required.keys():
		assert_true(bosses.has(boss_id), "bosses should include %s" % boss_id)
		var thresholds_var: Variant = bosses.get(boss_id, [])
		assert_true(thresholds_var is Array, "%s thresholds should be array" % boss_id)
		if not (thresholds_var is Array):
			continue
		var thresholds: Array = thresholds_var
		assert_gte(thresholds.size(), int(required.get(boss_id, 2)), "%s thresholds should match mainline minimum" % boss_id)


func test_frost_and_void_phase_skills_apply_distinct_forces() -> void:
	var enemy: CharacterBody2D = await _spawn_enemy_node()
	if enemy == null:
		return

	var player := MockPlayer.new()
	add_child_autofree(player)
	player.add_to_group("player")
	player.global_position = Vector2(120.0, 0.0)
	await get_tree().process_frame

	enemy.global_position = Vector2.ZERO
	enemy.touch_damage = 20.0
	enemy.apply_spawn_profile({
		"tier": "boss",
		"archetype": "boss",
		"enemy_id": "boss_frost_king",
		"scale": Vector2(2.0, 2.0)
	})
	enemy.set("_phase_index", 2)
	enemy.set("_player", player)
	enemy.call("_cast_frost_king_shardburst")

	assert_gt(player.damage_taken, 0.0, "frost shardburst should damage player")
	assert_gt(player.last_knockback.length(), 0.0, "frost shardburst should knock player away")
	assert_gt(player.last_knockback.x, 0.0, "frost shardburst should push player away from boss")
	var frost_knockback: Vector2 = player.last_knockback

	player.damage_taken = 0.0
	player.last_knockback = Vector2.ZERO
	player.global_position = Vector2(120.0, 0.0)

	enemy.apply_spawn_profile({
		"tier": "boss",
		"archetype": "boss",
		"enemy_id": "boss_void_lord",
		"scale": Vector2(2.0, 2.0)
	})
	enemy.set("_phase_index", 3)
	enemy.set("_player", player)
	enemy.call("_cast_void_lord_gravity_well")

	assert_gt(player.damage_taken, 0.0, "void gravity well should damage player")
	assert_gt(player.last_knockback.length(), 0.0, "void gravity well should apply pull force")
	assert_lt(player.last_knockback.x, 0.0, "void gravity well should pull player toward boss")
	assert_ne(frost_knockback.sign(), player.last_knockback.sign(), "frost and void boss skills should push in opposite directions")


func test_phase_transition_pressure_has_distinct_frost_and_void_vectors() -> void:
	var enemy: CharacterBody2D = await _spawn_enemy_node()
	if enemy == null:
		return

	var player := MockPlayer.new()
	add_child_autofree(player)
	player.add_to_group("player")
	player.global_position = Vector2(128.0, 0.0)
	await get_tree().process_frame

	enemy.global_position = Vector2.ZERO
	enemy.touch_damage = 18.0
	enemy.apply_spawn_profile({
		"tier": "boss",
		"archetype": "boss",
		"enemy_id": "boss_frost_king",
		"scale": Vector2(2.0, 2.0)
	})
	enemy.set("_player", player)
	_set_boss_phase_by_hp(enemy, 0.62)

	assert_gt(player.damage_taken, 0.0, "frost phase shift should deal burst damage")
	assert_gt(player.last_knockback.length(), 0.0, "frost phase shift should push player")
	assert_gt(player.last_knockback.x, 0.0, "frost phase shift should push away from boss")
	var frost_shift_damage: float = player.damage_taken

	player.damage_taken = 0.0
	player.last_knockback = Vector2.ZERO
	player.global_position = Vector2(128.0, 0.0)

	enemy.apply_spawn_profile({
		"tier": "boss",
		"archetype": "boss",
		"enemy_id": "boss_void_lord",
		"scale": Vector2(2.0, 2.0)
	})
	enemy.set("_player", player)
	_set_boss_phase_by_hp(enemy, 0.22)

	assert_gt(player.damage_taken, frost_shift_damage * 0.7, "void phase shift should deal meaningful burst damage")
	assert_gt(player.last_knockback.length(), 0.0, "void phase shift should apply pull")
	assert_lt(player.last_knockback.x, 0.0, "void phase shift should pull player toward boss")


func test_boss_spawner_triggers_phase_support_waves_for_frost_and_void() -> void:
	_clear_active_enemies()
	await get_tree().process_frame

	var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new()
	spawner.enemy_scene = load(ENEMY_SCENE_PATH)
	spawner.max_alive = 64
	add_child_autofree(spawner)

	var player := CharacterBody2D.new()
	add_child_autofree(player)
	player.add_to_group("player")
	player.global_position = Vector2.ZERO
	await get_tree().process_frame

	spawner.start_room_combat(12, "boss", "boss_frost_king", {})
	spawner.call("_process", 0.2)
	var frost_boss: CharacterBody2D = spawner.call("_find_active_boss_node") as CharacterBody2D
	assert_not_null(frost_boss, "frost boss should spawn in boss combat mode")
	if frost_boss == null:
		return

	_set_boss_phase_by_hp(frost_boss, 0.35)
	assert_eq(int(frost_boss.call("get_phase_index")), 2, "frost boss should enter phase 2 after hp drop")
	var frost_alive_before: int = int(spawner.get_alive_count())
	spawner.call("_process_boss_support")
	var frost_alive_after: int = int(spawner.get_alive_count())
	assert_gt(frost_alive_after, frost_alive_before, "frost boss phase transition should summon support enemies")

	var frost_support_ids: Array[String] = _collect_support_enemy_ids()
	assert_true(_contains_keyword(frost_support_ids, "frost") or _contains_keyword(frost_support_ids, "ice") or _contains_keyword(frost_support_ids, "blizzard"), "frost support wave should use chapter_3 enemy roster")
	assert_true(frost_support_ids.has("miniboss_frost_warden"), "frost phase 2 support should include miniboss escort")

	var frost_alive_snapshot: int = int(spawner.get_alive_count())
	spawner.call("_process_boss_support")
	assert_eq(int(spawner.get_alive_count()), frost_alive_snapshot, "same frost phase should not spawn duplicate support wave")

	spawner.stop_room_combat()
	_clear_active_enemies()
	await get_tree().process_frame

	spawner.start_room_combat(15, "boss", "boss_void_lord", {})
	spawner.call("_process", 0.2)
	var void_boss: CharacterBody2D = spawner.call("_find_active_boss_node") as CharacterBody2D
	assert_not_null(void_boss, "void boss should spawn in boss combat mode")
	if void_boss == null:
		return

	_set_boss_phase_by_hp(void_boss, 0.2)
	assert_eq(int(void_boss.call("get_phase_index")), 3, "void boss should enter phase 3 after hp drop")
	var void_alive_before: int = int(spawner.get_alive_count())
	spawner.call("_process_boss_support")
	var void_alive_after: int = int(spawner.get_alive_count())
	assert_gt(void_alive_after, void_alive_before, "void boss late phase should summon support enemies")

	var void_support_ids: Array[String] = _collect_support_enemy_ids()
	assert_true(_contains_keyword(void_support_ids, "void") or _contains_keyword(void_support_ids, "rift") or _contains_keyword(void_support_ids, "abyss"), "void support wave should use chapter_4 enemy roster")
	assert_true(void_support_ids.has("miniboss_void_harbinger"), "void late phase support should include miniboss escort")
