extends GutTest

const RELEASE_GATE_CONFIG_PATH := "res://data/balance/release_gate_targets.json"
const CI_WORKFLOW_PATH := "res://.github/workflows/ci.yml"


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


func test_release_gate_config_has_required_sections() -> void:
	var cfg: Dictionary = _load_json_dict(RELEASE_GATE_CONFIG_PATH)
	assert_true(str(cfg.get("channel", "")).length() > 0, "channel should be non-empty")

	var limits: Dictionary = cfg.get("baseline_alert_limits", {})
	assert_typeof(limits, TYPE_DICTIONARY, "baseline_alert_limits should be object")
	assert_gte(int(limits.get("max_total", -1)), 0, "max_total should be >= 0")
	assert_gte(int(limits.get("max_critical", -1)), 0, "max_critical should be >= 0")
	assert_gte(int(limits.get("max_warning", -1)), 0, "max_warning should be >= 0")

	var scenario_req: Dictionary = cfg.get("scenario_requirements", {})
	assert_typeof(scenario_req, TYPE_DICTIONARY, "scenario_requirements should be object")
	var must_include: Array = scenario_req.get("must_include", [])
	assert_typeof(must_include, TYPE_ARRAY, "must_include should be array")
	assert_gte(must_include.size(), 6, "must_include should contain core baseline scenarios")

	var expected_scenarios := [
		"menu_idle",
		"game_world_idle",
		"game_world_elite_pressure_medium",
		"game_world_elite_pressure_high",
		"game_world_elite_pressure_extreme",
		"game_world_boss_pressure_endurance"
	]
	for scenario_id: String in expected_scenarios:
		assert_has(must_include, scenario_id, "must_include should contain %s" % scenario_id)

	var compatibility_req: Dictionary = cfg.get("compatibility_requirements", {})
	assert_typeof(compatibility_req, TYPE_DICTIONARY, "compatibility_requirements should be object")
	var required_actions: Array = compatibility_req.get("required_actions_with_events", [])
	assert_typeof(required_actions, TYPE_ARRAY, "required_actions_with_events should be array")
	assert_gte(required_actions.size(), 5, "required_actions_with_events should include core gameplay actions")
	for action_var: Variant in required_actions:
		var action: String = str(action_var)
		assert_true(InputMap.has_action(action), "InputMap should contain action '%s'" % action)

	var required_markers: Array = compatibility_req.get("required_platform_markers", [])
	assert_typeof(required_markers, TYPE_ARRAY, "required_platform_markers should be array")
	assert_gte(required_markers.size(), 2, "required_platform_markers should include CI matrix markers")

	var blockers: Dictionary = cfg.get("publish_blockers", {})
	assert_typeof(blockers, TYPE_DICTIONARY, "publish_blockers should be object")
	for key: String in [
		"require_baseline_json",
		"require_baseline_markdown",
		"require_zero_critical_alerts",
		"require_zero_warning_alerts"
	]:
		assert_typeof(blockers.get(key), TYPE_BOOL, "publish_blockers.%s should be bool" % key)


func test_release_gate_platform_markers_exist_in_ci_workflow() -> void:
	var cfg: Dictionary = _load_json_dict(RELEASE_GATE_CONFIG_PATH)
	var compatibility_req: Dictionary = cfg.get("compatibility_requirements", {})
	var required_markers: Array = compatibility_req.get("required_platform_markers", [])

	var workflow_file := FileAccess.open(CI_WORKFLOW_PATH, FileAccess.READ)
	assert_not_null(workflow_file, "%s should be readable" % CI_WORKFLOW_PATH)
	if workflow_file == null:
		return
	var workflow_text: String = workflow_file.get_as_text()

	for marker_var: Variant in required_markers:
		var marker: String = str(marker_var)
		assert_true(workflow_text.find(marker) >= 0, "CI workflow should contain marker '%s'" % marker)
