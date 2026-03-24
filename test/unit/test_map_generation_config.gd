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
	assert_typeof(cfg.get("chapter_room_profiles", {}), TYPE_DICTIONARY, "chapter_room_profiles should be Dictionary")
	assert_typeof(cfg.get("chapter_progression_profiles", {}), TYPE_DICTIONARY, "chapter_progression_profiles should be Dictionary")
	assert_typeof(cfg.get("hidden_layers", {}), TYPE_DICTIONARY, "hidden_layers should be Dictionary")
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
	var chapter_room_profiles: Dictionary = cfg.get("chapter_room_profiles", {})
	var chapter_progression_profiles: Dictionary = cfg.get("chapter_progression_profiles", {})
	var hidden_layers: Dictionary = cfg.get("hidden_layers", {})
	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		var row: Dictionary = chapter_mult.get(chapter_id, {})
		assert_true(row.has("treasure"), "%s should define treasure multiplier" % chapter_id)
		var profile_row: Dictionary = chapter_room_profiles.get(chapter_id, {})
		for room_type in ["combat", "elite", "boss", "event", "treasure", "shop", "safe_camp"]:
			var room_profile: Dictionary = profile_row.get(room_type, {})
			assert_false(room_profile.is_empty(), "%s should define chapter_room_profiles.%s" % [chapter_id, room_type])
			assert_true(str(room_profile.get("title", "")) != "", "%s.%s should define title" % [chapter_id, room_type])
			assert_true(str(room_profile.get("objective", "")) != "", "%s.%s should define objective" % [chapter_id, room_type])
			assert_true(str(room_profile.get("route_tag", "")) != "", "%s.%s should define route_tag" % [chapter_id, room_type])
			assert_true(str(room_profile.get("status_hint", "")) != "", "%s.%s should define status_hint" % [chapter_id, room_type])
			assert_gte(float(room_profile.get("required_kills_mult", 0.0)), 0.5, "%s.%s required_kills_mult should be >= 0.5" % [chapter_id, room_type])
			assert_lte(float(room_profile.get("required_kills_mult", 99.0)), 2.5, "%s.%s required_kills_mult should be <= 2.5" % [chapter_id, room_type])
			assert_gte(float(room_profile.get("reward_mult", 0.0)), 0.5, "%s.%s reward_mult should be >= 0.5" % [chapter_id, room_type])
			assert_lte(float(room_profile.get("reward_mult", 99.0)), 2.5, "%s.%s reward_mult should be <= 2.5" % [chapter_id, room_type])

		var progression_row: Dictionary = chapter_progression_profiles.get(chapter_id, {})
		assert_false(progression_row.is_empty(), "%s should define chapter_progression_profiles row" % chapter_id)
		for field_name in ["clear_banner", "transition_intro", "transition_resolved", "event_resolved", "camp_recovery_note", "checkpoint_label"]:
			assert_true(str(progression_row.get(field_name, "")).strip_edges() != "", "%s progression field %s should be non-empty" % [chapter_id, field_name])
		assert_true(str(progression_row.get("history_recap_prefix", "")).strip_edges() != "", "%s progression field history_recap_prefix should be non-empty" % chapter_id)
		var history_recap_limit: int = int(progression_row.get("history_recap_limit", 0))
		assert_gte(history_recap_limit, 1, "%s history_recap_limit should be >= 1" % chapter_id)
		assert_lte(history_recap_limit, 8, "%s history_recap_limit should be <= 8" % chapter_id)
		var mainline_nodes: Dictionary = progression_row.get("mainline_nodes", {})
		assert_false(mainline_nodes.is_empty(), "%s mainline_nodes should be non-empty" % chapter_id)
		for room_type in ["combat", "elite", "boss", "event", "treasure", "shop", "safe_camp"]:
			assert_true(str(mainline_nodes.get(room_type, "")).strip_edges() != "", "%s mainline_nodes.%s should be non-empty" % [chapter_id, room_type])
		var pace_tags: Dictionary = progression_row.get("history_pace_tags", {})
		for room_type in ["combat", "elite", "boss", "event", "treasure", "shop", "safe_camp"]:
			assert_true(str(pace_tags.get(room_type, "")).strip_edges() != "", "%s history_pace_tags.%s should be non-empty" % [chapter_id, room_type])

	for layer_id in ["FS1", "FS2"]:
		var layer_row: Dictionary = hidden_layers.get(layer_id, {})
		assert_false(layer_row.is_empty(), "%s hidden layer profile should exist" % layer_id)
		for field_name in ["title", "theme", "unlock_rule", "entrance_hint"]:
			assert_true(str(layer_row.get(field_name, "")).strip_edges() != "", "%s.%s should be non-empty" % [layer_id, field_name])
		var map_profile: Dictionary = layer_row.get("map_profile", {})
		assert_false(map_profile.is_empty(), "%s.map_profile should exist" % layer_id)
		assert_true(str(map_profile.get("mode", "")) in ["survival", "trial_chain"], "%s.map_profile.mode should be valid" % layer_id)
		assert_true(str(map_profile.get("room_count_label", "")).strip_edges() != "", "%s.map_profile.room_count_label should be non-empty" % layer_id)
		for field_name in ["entry_room_type", "encounter_room_type", "boss_room_type", "settlement_room_type"]:
			assert_true(str(map_profile.get(field_name, "")).strip_edges() != "", "%s.map_profile.%s should be non-empty" % [layer_id, field_name])
		var combat_profile: Dictionary = layer_row.get("combat_profile", {})
		assert_false(combat_profile.is_empty(), "%s.combat_profile should exist" % layer_id)
		assert_gte(float(combat_profile.get("enemy_multiplier_base", 0.0)), 10.0, "%s combat base multiplier should be >= 10" % layer_id)
		assert_typeof(combat_profile.get("enemy_pool_tags", []), TYPE_ARRAY, "%s enemy_pool_tags should be Array" % layer_id)
		assert_typeof(combat_profile.get("boss_pool_tags", []), TYPE_ARRAY, "%s boss_pool_tags should be Array" % layer_id)
		var reward_profile: Dictionary = layer_row.get("reward_profile", {})
		assert_false(reward_profile.is_empty(), "%s.reward_profile should exist" % layer_id)
		for field_name in ["track", "summary", "repeat_motivation"]:
			assert_true(str(reward_profile.get(field_name, "")).strip_edges() != "", "%s.reward_profile.%s should be non-empty" % [layer_id, field_name])
		var settlement_profile: Dictionary = layer_row.get("settlement_profile", {})
		assert_false(settlement_profile.is_empty(), "%s.settlement_profile should exist" % layer_id)
		for field_name in ["mode", "summary"]:
			assert_true(str(settlement_profile.get(field_name, "")).strip_edges() != "", "%s.settlement_profile.%s should be non-empty" % [layer_id, field_name])

	var fs1_map_profile: Dictionary = hidden_layers.get("FS1", {}).get("map_profile", {})
	assert_eq(int(fs1_map_profile.get("room_count", 0)), -1, "FS1 should use infinite room_count contract")
	var fs2_map_profile: Dictionary = hidden_layers.get("FS2", {}).get("map_profile", {})
	assert_eq(int(fs2_map_profile.get("room_count", 0)), 5, "FS2 should use 5-room forge chain contract")
	assert_eq((fs2_map_profile.get("room_roles", []) as Array).size(), 5, "FS2 room_roles should match forge trial count")

	assert_gt(float(chapter_room_profiles.get("chapter_3", {}).get("elite", {}).get("required_kills_mult", 0.0)), float(chapter_room_profiles.get("chapter_1", {}).get("elite", {}).get("required_kills_mult", 0.0)), "chapter_3 elite pacing should be heavier than chapter_1 elite")
	assert_gt(float(chapter_room_profiles.get("chapter_4", {}).get("treasure", {}).get("reward_mult", 0.0)), float(chapter_room_profiles.get("chapter_1", {}).get("treasure", {}).get("reward_mult", 0.0)), "chapter_4 treasure reward multiplier should exceed chapter_1")

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


func test_map_generator_hidden_layer_stub_plans_expose_interface_contracts() -> void:
	var cfg := _load_map_config()
	var generator_script: Script = load("res://scripts/systems/map_generator.gd")
	assert_not_null(generator_script, "map_generator.gd should be loadable")
	if generator_script == null:
		return

	var generator: Node = generator_script.new()
	var fs1_plan: Dictionary = generator.generate_hidden_layer_stub_plan("FS1", cfg)
	var fs2_plan: Dictionary = generator.generate_hidden_layer_stub_plan("FS2", cfg)
	generator.free()

	assert_eq(str(fs1_plan.get("map_mode", "")), "survival", "FS1 stub plan should expose survival mode")
	assert_eq(int(fs1_plan.get("room_count", 0)), -1, "FS1 stub plan should preserve infinite room_count marker")
	var fs1_rooms: Array = fs1_plan.get("rooms", [])
	assert_eq(fs1_rooms.size(), 3, "FS1 stub plan should expose entry/loop/settlement interface rooms")
	assert_eq(str((fs1_rooms[1] as Dictionary).get("room_role", "")), "survival_loop", "FS1 second room should be the survival loop anchor")

	assert_eq(str(fs2_plan.get("map_mode", "")), "trial_chain", "FS2 stub plan should expose trial_chain mode")
	assert_eq(int(fs2_plan.get("room_count", 0)), 5, "FS2 stub plan should expose 5 forge trials")
	var fs2_rooms: Array = fs2_plan.get("rooms", [])
	assert_eq(fs2_rooms.size(), 5, "FS2 stub plan should build 5 chained forge rooms")
	assert_eq(str((fs2_rooms[0] as Dictionary).get("room_role", "")), "ore_tempering", "FS2 should start with the ore tempering trial")
	assert_eq(str((fs2_rooms[4] as Dictionary).get("room_type", "")), "forge_core", "FS2 final room should use the forge core boss room type")


func test_map_generator_hidden_layer_runtime_plans_are_playable() -> void:
	var cfg := _load_map_config()
	var generator_script: Script = load("res://scripts/systems/map_generator.gd")
	assert_not_null(generator_script, "map_generator.gd should be loadable")
	if generator_script == null:
		return

	var generator: Node = generator_script.new()
	var fs1_plan: Dictionary = generator.generate_hidden_layer_run_plan("FS1", cfg)
	var fs2_plan: Dictionary = generator.generate_hidden_layer_run_plan("FS2", cfg)
	generator.free()

	assert_eq(int(fs1_plan.get("start_room", 0)), 1, "FS1 runtime plan should start at room 1")
	assert_eq(int(fs1_plan.get("room_count", 0)), 4, "FS1 runtime plan should expose entry/combat/boss/settlement rooms")
	var fs1_rooms: Array = fs1_plan.get("rooms", [])
	assert_eq(fs1_rooms.size(), 4, "FS1 runtime plan should build 4 playable rooms")
	assert_eq(str((fs1_rooms[0] as Dictionary).get("room_type", "")), "combat", "FS1 should begin with a combat threshold room")
	assert_eq(int((fs1_rooms[1] as Dictionary).get("required_pressure_stage", 0)), 2, "FS1 surge room should require pressure stage 2 before clearing")
	assert_eq(float((fs1_rooms[1] as Dictionary).get("minimum_clear_seconds", 0.0)), 30.0, "FS1 surge room should require a 30 second hold before payout")
	assert_eq(((fs1_rooms[2] as Dictionary).get("boss_echo_pool", []) as Array).size(), 4, "FS1 boss room should expose the full boss echo archive pool")
	assert_eq(str((fs1_rooms[2] as Dictionary).get("room_type", "")), "boss", "FS1 should include a boss echo room")
	assert_eq(str((fs1_rooms[3] as Dictionary).get("room_type", "")), "safe_camp", "FS1 should end in a settlement room")
	assert_eq(str((fs1_rooms[3] as Dictionary).get("hidden_layer_id", "")), "FS1", "FS1 settlement should stay tagged to the hidden layer")

	assert_eq(int(fs2_plan.get("start_room", 0)), 1, "FS2 runtime plan should start at room 1")
	assert_eq(int(fs2_plan.get("room_count", 0)), 6, "FS2 runtime plan should expose 5 trials plus settlement")
	var fs2_rooms: Array = fs2_plan.get("rooms", [])
	assert_eq(fs2_rooms.size(), 6, "FS2 runtime plan should build 6 playable rooms")
	assert_eq(str((fs2_rooms[0] as Dictionary).get("room_type", "")), "combat", "FS2 should start with a forge combat trial")
	assert_eq(str((fs2_rooms[1] as Dictionary).get("room_type", "")), "elite", "FS2 should escalate into elite forge trials")
	assert_eq(int((fs2_rooms[0] as Dictionary).get("trial_depth", 0)), 1, "FS2 first trial should carry depth 1 metadata")
	assert_eq(str((fs2_rooms[0] as Dictionary).get("trial_label", "")), "Forge Trial I: Ore Tempering", "FS2 first trial should expose an archive-friendly trial label")
	assert_eq(int((fs2_rooms[4] as Dictionary).get("trial_depth", 0)), 5, "FS2 boss room should carry final trial depth metadata")
	assert_eq(str((fs2_rooms[4] as Dictionary).get("trial_label", "")), "Forge Trial V: Genesis Core", "FS2 final trial should expose an archive-friendly trial label")
	assert_eq(str((fs2_rooms[4] as Dictionary).get("room_type", "")), "boss", "FS2 should culminate in a forge boss room")
	assert_eq(str((fs2_rooms[5] as Dictionary).get("room_type", "")), "safe_camp", "FS2 should end in a forge settlement room")
	assert_eq(str((fs2_rooms[5] as Dictionary).get("hidden_layer_id", "")), "FS2", "FS2 settlement should stay tagged to the hidden layer")
