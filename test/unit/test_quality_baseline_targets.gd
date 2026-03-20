extends GutTest

const QUALITY_BASELINE_CONFIG_PATH := "res://data/balance/quality_baseline_targets.json"


func _load_json_dict(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, "%s should be readable" % path)
	if file == null:
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "%s should parse as Dictionary" % path)
	if parsed is Dictionary:
		return parsed
	return {}


func test_quality_baseline_config_has_required_sections() -> void:
	var cfg: Dictionary = _load_json_dict(QUALITY_BASELINE_CONFIG_PATH)
	var scenarios: Dictionary = cfg.get("scenarios", {})
	var targets: Dictionary = cfg.get("targets", {})
	var compatibility: Dictionary = cfg.get("compatibility_matrix", {})

	assert_typeof(scenarios, TYPE_DICTIONARY, "scenarios should be a Dictionary")
	assert_typeof(targets, TYPE_DICTIONARY, "targets should be a Dictionary")
	assert_typeof(compatibility, TYPE_DICTIONARY, "compatibility_matrix should be a Dictionary")

	var required_scenarios := [
		"menu_idle",
		"game_world_idle",
		"game_world_elite_pressure_medium",
		"game_world_elite_pressure_high",
		"game_world_elite_pressure_extreme",
		"game_world_boss_pressure_endurance"
	]
	for scenario_id: String in required_scenarios:
		assert_true(scenarios.has(scenario_id), "scenarios should contain %s" % scenario_id)
		var row: Dictionary = scenarios.get(scenario_id, {})
		assert_typeof(row, TYPE_DICTIONARY, "%s scenario should be object" % scenario_id)
		assert_true(str(row.get("scene", "")).begins_with("res://"), "%s scene should be res:// path" % scenario_id)
		assert_gte(int(row.get("sample_frames", 0)), 60, "%s sample_frames should be >= 60" % scenario_id)

	assert_eq(str((scenarios.get("game_world_elite_pressure_medium", {}) as Dictionary).get("setup", "")), "elite_pressure_medium", "medium elite scenario setup should match")
	assert_eq(str((scenarios.get("game_world_elite_pressure_high", {}) as Dictionary).get("setup", "")), "elite_pressure_high", "high elite scenario setup should match")
	assert_eq(str((scenarios.get("game_world_elite_pressure_extreme", {}) as Dictionary).get("setup", "")), "elite_pressure_extreme", "extreme elite scenario setup should match")
	assert_eq(str((scenarios.get("game_world_boss_pressure_endurance", {}) as Dictionary).get("setup", "")), "boss_pressure_endurance", "boss endurance scenario setup should match")

	var frame_time: Dictionary = targets.get("frame_time_ms", {})
	var memory: Dictionary = targets.get("memory_mb", {})
	var node_pressure: Dictionary = targets.get("node_pressure", {})
	var alert_grading: Dictionary = targets.get("alert_grading", {})
	assert_typeof(frame_time, TYPE_DICTIONARY, "targets.frame_time_ms should be object")
	assert_typeof(memory, TYPE_DICTIONARY, "targets.memory_mb should be object")
	assert_typeof(node_pressure, TYPE_DICTIONARY, "targets.node_pressure should be object")
	assert_typeof(alert_grading, TYPE_DICTIONARY, "targets.alert_grading should be object")

	for scenario_id: String in required_scenarios:
		assert_true(frame_time.has(scenario_id), "frame_time_ms should include %s" % scenario_id)
		assert_true(memory.has(scenario_id), "memory_mb should include %s" % scenario_id)

	assert_gte(int(node_pressure.get("enemy_peak_warning", 0)), 50, "enemy_peak_warning should be >= 50")
	assert_gte(int(node_pressure.get("projectile_peak_warning", 0)), 20, "projectile_peak_warning should be >= 20")
	assert_gte(float(alert_grading.get("frame_time_ratio_warning", 0.0)), 1.0, "frame_time_ratio_warning should be >= 1.0")
	assert_gte(float(alert_grading.get("frame_time_ratio_critical", 0.0)), float(alert_grading.get("frame_time_ratio_warning", 1.0)), "frame_time critical ratio should be >= warning ratio")
	assert_gte(float(alert_grading.get("memory_ratio_critical", 0.0)), float(alert_grading.get("memory_ratio_warning", 1.0)), "memory critical ratio should be >= warning ratio")
	assert_gte(float(alert_grading.get("node_pressure_ratio_critical", 0.0)), float(alert_grading.get("node_pressure_ratio_warning", 1.0)), "node pressure critical ratio should be >= warning ratio")


func test_quality_baseline_required_actions_exist_in_input_map() -> void:
	var cfg: Dictionary = _load_json_dict(QUALITY_BASELINE_CONFIG_PATH)
	var compatibility: Dictionary = cfg.get("compatibility_matrix", {})
	var actions: Array = compatibility.get("required_actions", [])
	assert_typeof(actions, TYPE_ARRAY, "required_actions should be an Array")
	assert_gte(actions.size(), 5, "required_actions should include core gameplay inputs")

	for action_var: Variant in actions:
		var action: String = str(action_var)
		assert_true(InputMap.has_action(action), "InputMap should contain action '%s'" % action)
