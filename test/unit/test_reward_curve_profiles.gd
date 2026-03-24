extends GutTest

const DROP_TABLES_CONFIG_PATH := "res://data/balance/drop_tables.json"
const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


func _load_drop_tables() -> Dictionary:
	var file := FileAccess.open(DROP_TABLES_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "drop_tables.json should be readable")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "drop_tables.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func _instantiate_world() -> Node:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return null

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return null

	add_child_autofree(world)
	await get_tree().process_frame
	return world


func _set_room_plan(world: Node, room_index: int, chapter_id: String, room_type: String) -> void:
	var room_plan_map_var: Variant = world.get("_room_plan_map")
	var room_plan_map: Dictionary = {}
	if room_plan_map_var is Dictionary:
		room_plan_map = (room_plan_map_var as Dictionary).duplicate(true)

	room_plan_map[room_index] = {
		"chapter_id": chapter_id,
		"chapter_index": int(chapter_id.trim_prefix("chapter_")),
		"room_type": room_type,
		"show_intro": false,
		"next_rooms": [],
		"previous_rooms": []
	}
	world.set("_room_plan_map", room_plan_map)


func test_drop_tables_define_chapter_reward_profiles_and_long_run_curve() -> void:
	var cfg := _load_drop_tables()
	var chapter_profiles: Dictionary = cfg.get("chapter_reward_profiles", {})
	var long_run_curve: Dictionary = cfg.get("long_run_room_curve", {})

	assert_typeof(chapter_profiles, TYPE_DICTIONARY, "chapter_reward_profiles should be Dictionary")
	assert_typeof(long_run_curve, TYPE_DICTIONARY, "long_run_room_curve should be Dictionary")

	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		var row: Dictionary = chapter_profiles.get(chapter_id, {})
		assert_false(row.is_empty(), "%s reward profile should exist" % chapter_id)
		for field_name in ["xp_mult", "gold_mult", "ore_mult", "treasure_mult"]:
			assert_gte(float(row.get(field_name, 0.0)), 0.6, "%s %s lower bound" % [chapter_id, field_name])
			assert_lte(float(row.get(field_name, 9.0)), 2.5, "%s %s upper bound" % [chapter_id, field_name])

	assert_gte(int(long_run_curve.get("room_bonus_start", 0)), 1, "room_bonus_start should be >= 1")
	assert_lte(int(long_run_curve.get("room_bonus_start", 99)), 20, "room_bonus_start should be <= 20")
	assert_gte(float(long_run_curve.get("room_bonus_per_room", -1.0)), 0.0, "room_bonus_per_room should be >= 0")
	assert_lte(float(long_run_curve.get("room_bonus_per_room", 9.0)), 0.25, "room_bonus_per_room should be <= 0.25")
	assert_gte(float(long_run_curve.get("room_bonus_cap", -1.0)), 0.0, "room_bonus_cap should be >= 0")
	assert_lte(float(long_run_curve.get("room_bonus_cap", 9.0)), 1.0, "room_bonus_cap should be <= 1")


func test_chapter_reward_curve_scales_late_chapter_xp_and_ore_upward() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 4, "chapter_1", "boss")
	_set_room_plan(world, 15, "chapter_4", "boss")

	world.set("_room_index", 4)
	var early_xp: Dictionary = world.call("_map_item_to_pickup", "xp_gem_large")
	var early_ore: Dictionary = world.call("_map_item_to_pickup", "ore_large")

	world.set("_room_index", 15)
	var late_xp: Dictionary = world.call("_map_item_to_pickup", "xp_gem_large")
	var late_ore: Dictionary = world.call("_map_item_to_pickup", "ore_large")

	assert_gt(int(late_xp.get("amount", 0)), int(early_xp.get("amount", 0)), "late chapter xp pickup should exceed early chapter")
	assert_gt(int(late_ore.get("amount", 0)), int(early_ore.get("amount", 0)), "late chapter ore pickup should exceed early chapter")


func test_long_run_curve_increases_treasure_rewards_in_late_rooms() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 6, "chapter_2", "treasure")
	_set_room_plan(world, 14, "chapter_4", "treasure")

	world.set("_room_index", 6)
	world.set("_route_gold_drop_mult", 1.0)
	world.set("_route_ore_drop_mult", 1.0)
	var early_gold: int = int(world.call("_scale_reward_amount", 24, 1.0, "gold", true))
	var early_ore: int = int(world.call("_scale_reward_amount", 3, 1.0, "ore", true))

	world.set("_room_index", 14)
	var late_gold: int = int(world.call("_scale_reward_amount", 24, 1.0, "gold", true))
	var late_ore: int = int(world.call("_scale_reward_amount", 3, 1.0, "ore", true))

	assert_gt(late_gold, early_gold, "late-run treasure gold should scale above early-run treasure gold")
	assert_gt(late_ore, early_ore, "late-run treasure ore should scale above early-run treasure ore")
