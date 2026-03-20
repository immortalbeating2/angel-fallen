extends GutTest

const MAP_CONFIG_PATH := "res://data/balance/map_generation.json"


func _load_map_config() -> Dictionary:
	var file := FileAccess.open(MAP_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "map_generation.json should be readable")
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "map_generation.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func test_map_generation_schema_has_required_sections() -> void:
	var cfg := _load_map_config()

	assert_eq(int(cfg.get("room_count", 0)), 15, "room_count should stay at MVP 15 rooms")
	assert_eq(int(cfg.get("layout_cols", 0)), 5, "layout_cols should keep 3x5 minimap layout")
	assert_typeof(cfg.get("chapter_order", []), TYPE_ARRAY, "chapter_order should be Array")
	assert_typeof(cfg.get("chapters", {}), TYPE_DICTIONARY, "chapters should be Dictionary")
	assert_typeof(cfg.get("base_room_weights", {}), TYPE_DICTIONARY, "base_room_weights should be Dictionary")
	assert_typeof(cfg.get("chapter_room_weight_mult", {}), TYPE_DICTIONARY, "chapter_room_weight_mult should be Dictionary")
	assert_typeof(cfg.get("constraints", {}), TYPE_DICTIONARY, "constraints should be Dictionary")
	var base_weights: Dictionary = cfg.get("base_room_weights", {})
	assert_true(base_weights.has("treasure"), "base_room_weights should define treasure weight")
	assert_gte(float(base_weights.get("treasure", 0.0)), 0.0, "treasure weight must be >= 0")
	var constraints: Dictionary = cfg.get("constraints", {})
	assert_true(constraints.has("max_treasure_per_chapter"), "constraints should define max_treasure_per_chapter")
	assert_gte(int(constraints.get("max_treasure_per_chapter", -1)), 0, "max_treasure_per_chapter should be >= 0")
	assert_typeof(constraints.get("max_room_type_per_chapter", {}), TYPE_DICTIONARY, "constraints.max_room_type_per_chapter should be Dictionary")
	assert_typeof(constraints.get("min_room_type_per_chapter", {}), TYPE_DICTIONARY, "constraints.min_room_type_per_chapter should be Dictionary")
	var room_type_caps: Dictionary = constraints.get("max_room_type_per_chapter", {})
	var room_type_mins: Dictionary = constraints.get("min_room_type_per_chapter", {})
	for room_type in ["event", "shop", "elite", "treasure"]:
		assert_true(room_type_caps.has(room_type), "max_room_type_per_chapter should define '%s'" % room_type)
		assert_gte(int(room_type_caps.get(room_type, -1)), 0, "max_room_type_per_chapter.%s should be >= 0" % room_type)
		assert_true(room_type_mins.has(room_type), "min_room_type_per_chapter should define '%s'" % room_type)
		assert_gte(int(room_type_mins.get(room_type, -1)), 0, "min_room_type_per_chapter.%s should be >= 0" % room_type)
		assert_lte(int(room_type_mins.get(room_type, 0)), int(room_type_caps.get(room_type, 0)), "min_room_type_per_chapter.%s should not exceed max" % room_type)
	var chapter_mult: Dictionary = cfg.get("chapter_room_weight_mult", {})
	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		var row: Dictionary = chapter_mult.get(chapter_id, {})
		assert_true(row.has("treasure"), "%s should define treasure multiplier" % chapter_id)

	var treasure_challenge: Dictionary = cfg.get("treasure_challenge", {})
	assert_typeof(treasure_challenge, TYPE_DICTIONARY, "treasure_challenge should be Dictionary")
	assert_false(treasure_challenge.is_empty(), "treasure_challenge should not be empty")
	assert_typeof(treasure_challenge.get("enabled", null), TYPE_BOOL, "treasure_challenge.enabled should be bool")
	assert_true(treasure_challenge.has("combat_mode"), "treasure_challenge should define combat_mode")
	assert_true(["elite", "normal"].has(str(treasure_challenge.get("combat_mode", ""))), "treasure_challenge.combat_mode should be elite or normal")
	assert_gte(int(treasure_challenge.get("required_kills_base", 0)), 1, "treasure_challenge.required_kills_base should be >= 1")
	assert_gte(int(treasure_challenge.get("required_kills_per_room", -1)), 0, "treasure_challenge.required_kills_per_room should be >= 0")
	assert_gte(int(treasure_challenge.get("gold_reward_base", 0)), 1, "treasure_challenge.gold_reward_base should be >= 1")
	assert_gte(int(treasure_challenge.get("gold_reward_per_room", -1)), 0, "treasure_challenge.gold_reward_per_room should be >= 0")
	assert_gte(int(treasure_challenge.get("ore_reward_base", 0)), 1, "treasure_challenge.ore_reward_base should be >= 1")
	assert_gte(int(treasure_challenge.get("ore_reward_step_rooms", 0)), 1, "treasure_challenge.ore_reward_step_rooms should be >= 1")
	for key in ["accessory_chance_base", "accessory_chance_vanguard", "accessory_chance_raider"]:
		var chance: float = float(treasure_challenge.get(key, -1.0))
		assert_gte(chance, 0.0, "treasure_challenge.%s should be >= 0" % key)
		assert_lte(chance, 1.0, "treasure_challenge.%s should be <= 1" % key)


func test_map_generation_chapters_cover_full_room_range() -> void:
	var cfg := _load_map_config()
	var room_count: int = int(cfg.get("room_count", 0))
	var chapter_order: Array = cfg.get("chapter_order", [])
	var chapters: Dictionary = cfg.get("chapters", {})

	var expected_start := 1
	for chapter_id in chapter_order:
		var row: Dictionary = chapters.get(str(chapter_id), {})
		assert_false(row.is_empty(), "chapter row should exist for %s" % chapter_id)

		var start_room: int = int(row.get("start_room", -1))
		var end_room: int = int(row.get("end_room", -1))
		var intro_room: int = int(row.get("intro_room", -1))
		var boss_room: int = int(row.get("boss_room", -1))

		assert_eq(start_room, expected_start, "%s should continue previous chapter range" % chapter_id)
		assert_gte(end_room, start_room, "%s should have valid range" % chapter_id)
		assert_gte(intro_room, start_room, "%s intro_room lower bound" % chapter_id)
		assert_lte(intro_room, end_room, "%s intro_room upper bound" % chapter_id)
		assert_gte(boss_room, start_room, "%s boss_room lower bound" % chapter_id)
		assert_lte(boss_room, end_room, "%s boss_room upper bound" % chapter_id)
		expected_start = end_room + 1

	assert_eq(expected_start - 1, room_count, "chapter ranges should end at room_count")


func test_map_generator_outputs_room_plan_invariants() -> void:
	var cfg := _load_map_config()
	var generator_script: Script = load("res://scripts/systems/map_generator.gd")
	assert_not_null(generator_script, "map_generator.gd should be loadable")
	if generator_script == null:
		return

	var generator: Node = generator_script.new()
	var plan: Dictionary = generator.generate_run_plan(cfg)
	generator.free()

	var room_count: int = int(plan.get("room_count", 0))
	var rooms: Array = plan.get("rooms", [])
	var map_bounds: Dictionary = plan.get("map_bounds", {})
	var chapter_caps: Dictionary = {}
	var constraints: Dictionary = cfg.get("constraints", {})
	var max_treasure_per_chapter: int = int(constraints.get("max_treasure_per_chapter", 999))
	var max_room_type_per_chapter: Dictionary = constraints.get("max_room_type_per_chapter", {})
	var min_room_type_per_chapter: Dictionary = constraints.get("min_room_type_per_chapter", {})
	assert_eq(room_count, int(cfg.get("room_count", 0)), "generated room_count should follow config")
	assert_eq(rooms.size(), room_count, "rooms array size should equal room_count")
	assert_typeof(map_bounds, TYPE_DICTIONARY, "plan should include map_bounds")
	assert_false(map_bounds.is_empty(), "map_bounds should not be empty")

	var min_x: int = int(map_bounds.get("min_x", 0))
	var max_x: int = int(map_bounds.get("max_x", 0))
	var min_y: int = int(map_bounds.get("min_y", 0))
	var max_y: int = int(map_bounds.get("max_y", 0))
	var bounds_cols: int = int(map_bounds.get("cols", 0))
	var bounds_rows: int = int(map_bounds.get("rows", 0))
	assert_gte(bounds_cols, 1, "map_bounds.cols should be >= 1")
	assert_gte(bounds_rows, 1, "map_bounds.rows should be >= 1")
	assert_eq(bounds_cols, max_x - min_x + 1, "map_bounds.cols should match x span")
	assert_eq(bounds_rows, max_y - min_y + 1, "map_bounds.rows should match y span")

	var valid_room_types := {
		"combat": true,
		"elite": true,
		"event": true,
		"shop": true,
		"treasure": true,
		"safe_camp": true,
		"boss": true
	}

	var boss_count := 0
	var room_map: Dictionary = {}
	var coord_seen: Dictionary = {}
	for i in range(rooms.size()):
		var row: Dictionary = rooms[i]
		var idx: int = int(row.get("index", -1))
		var room_type: String = str(row.get("room_type", ""))
		var chapter_id: String = str(row.get("chapter_id", ""))
		var map_x: int = int(row.get("map_x", 0))
		var map_y: int = int(row.get("map_y", 0))
		assert_eq(idx, i + 1, "room index should be sequential")
		assert_true(valid_room_types.has(room_type), "room type should be valid")
		assert_gte(map_x, min_x, "room map_x should be within bounds")
		assert_lte(map_x, max_x, "room map_x should be within bounds")
		assert_gte(map_y, min_y, "room map_y should be within bounds")
		assert_lte(map_y, max_y, "room map_y should be within bounds")
		var coord_key := "%d:%d" % [map_x, map_y]
		assert_false(coord_seen.has(coord_key), "room coordinates should be unique (%s)" % coord_key)
		coord_seen[coord_key] = true
		room_map[idx] = row
		if room_type == "boss":
			boss_count += 1
			assert_true(str(row.get("boss_id", "")).begins_with("boss_"), "boss room should provide boss_id")
		var chapter_type_caps: Dictionary = chapter_caps.get(chapter_id, {})
		chapter_type_caps[room_type] = int(chapter_type_caps.get(room_type, 0)) + 1
		chapter_caps[chapter_id] = chapter_type_caps

	assert_eq(str((rooms[0] as Dictionary).get("room_type", "")), "combat", "first room should always be combat")
	assert_gte(boss_count, 4, "MVP run plan should contain at least 4 boss rooms")
	for chapter_id in chapter_caps.keys():
		var chapter_type_caps: Dictionary = chapter_caps.get(chapter_id, {})
		assert_lte(int(chapter_type_caps.get("treasure", 0)), max_treasure_per_chapter, "%s treasure rooms should respect max_treasure_per_chapter" % chapter_id)
		for room_type in ["event", "shop", "elite", "treasure"]:
			var min_value: int = int(min_room_type_per_chapter.get(room_type, 0))
			var cap_value: int = int(max_room_type_per_chapter.get(room_type, room_count))
			assert_gte(int(chapter_type_caps.get(room_type, 0)), min_value, "%s %s rooms should respect min_room_type_per_chapter" % [chapter_id, room_type])
			assert_lte(int(chapter_type_caps.get(room_type, 0)), cap_value, "%s %s rooms should respect max_room_type_per_chapter" % [chapter_id, room_type])

	var chapter_1_start: Dictionary = room_map.get(1, {})
	var chapter_1_next: Array = chapter_1_start.get("next_rooms", [])
	assert_typeof(chapter_1_next, TYPE_ARRAY, "chapter_1 start should include next_rooms")
	assert_gte(chapter_1_next.size(), 2, "chapter_1 start should provide at least two branch options")
