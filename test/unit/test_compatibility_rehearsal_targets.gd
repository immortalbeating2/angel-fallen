extends GutTest

const CONFIG_PATH := "res://data/balance/compatibility_rehearsal_targets.json"
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


func test_compatibility_rehearsal_config_has_required_sections() -> void:
	var cfg: Dictionary = _load_json_dict(CONFIG_PATH)
	assert_true(str(cfg.get("channel", "")).length() > 0, "channel should be non-empty")

	var profiles: Array = cfg.get("profiles", [])
	assert_typeof(profiles, TYPE_ARRAY, "profiles should be array")
	assert_gte(profiles.size(), 2, "profiles should include cross-platform entries")

	var profile_ids: Array[String] = []
	for profile_var: Variant in profiles:
		assert_typeof(profile_var, TYPE_DICTIONARY, "profile row should be object")
		if not (profile_var is Dictionary):
			continue
		var profile: Dictionary = profile_var
		var profile_id: String = str(profile.get("id", ""))
		profile_ids.append(profile_id)
		assert_true(not profile_id.is_empty(), "profile.id should be non-empty")
		assert_true(str(profile.get("platform_marker", "")).length() > 0, "profile.platform_marker should be non-empty")
		assert_true(str(profile.get("resolution", "")).find("x") >= 0, "profile.resolution should be WxH")
		assert_true(["keyboard_mouse", "gamepad"].has(str(profile.get("input_mode", ""))), "profile.input_mode should be valid")
		assert_true(["forward_plus", "mobile", "compatibility"].has(str(profile.get("renderer", ""))), "profile.renderer should be valid")

		var scenes: Array = profile.get("required_scenes", [])
		assert_typeof(scenes, TYPE_ARRAY, "profile.required_scenes should be array")
		assert_gte(scenes.size(), 1, "profile.required_scenes should be non-empty")
		for scene_var: Variant in scenes:
			var scene_path: String = str(scene_var)
			assert_true(scene_path.begins_with("res://"), "required scene should be res:// path")

	assert_has(profile_ids, "win10_1080p_keyboard", "should include windows keyboard profile")
	assert_has(profile_ids, "ubuntu22_1080p_keyboard", "should include ubuntu keyboard profile")

	var required_actions: Array = cfg.get("required_actions", [])
	assert_typeof(required_actions, TYPE_ARRAY, "required_actions should be array")
	assert_gte(required_actions.size(), 5, "required_actions should include core gameplay actions")
	for action_var: Variant in required_actions:
		var action: String = str(action_var)
		assert_true(InputMap.has_action(action), "InputMap should contain action '%s'" % action)

	var thresholds: Dictionary = cfg.get("thresholds", {})
	assert_typeof(thresholds, TYPE_DICTIONARY, "thresholds should be object")
	assert_gte(float(thresholds.get("min_profile_pass_rate", 0.0)), 0.5, "min_profile_pass_rate should be >= 0.5")
	assert_gte(int(thresholds.get("max_profile_failures", -1)), 0, "max_profile_failures should be >= 0")
	assert_gte(int(thresholds.get("max_missing_actions", -1)), 0, "max_missing_actions should be >= 0")

	var blockers: Dictionary = cfg.get("publish_blockers", {})
	assert_typeof(blockers, TYPE_DICTIONARY, "publish_blockers should be object")
	for key: String in [
		"require_release_gate_json",
		"require_release_gate_markdown",
		"require_zero_profile_failures"
	]:
		assert_typeof(blockers.get(key), TYPE_BOOL, "publish_blockers.%s should be bool" % key)


func test_compatibility_rehearsal_platform_markers_exist_in_ci_workflow() -> void:
	var cfg: Dictionary = _load_json_dict(CONFIG_PATH)
	var profiles: Array = cfg.get("profiles", [])

	var workflow_file := FileAccess.open(CI_WORKFLOW_PATH, FileAccess.READ)
	assert_not_null(workflow_file, "%s should be readable" % CI_WORKFLOW_PATH)
	if workflow_file == null:
		return
	var workflow_text: String = workflow_file.get_as_text()

	for profile_var: Variant in profiles:
		if not (profile_var is Dictionary):
			continue
		var marker: String = str((profile_var as Dictionary).get("platform_marker", ""))
		if marker.is_empty():
			continue
		assert_true(workflow_text.find(marker) >= 0, "CI workflow should contain marker '%s'" % marker)
