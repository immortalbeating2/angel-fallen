extends GutTest

const NARRATIVE_CONFIG_PATH := "res://data/balance/narrative_content.json"
const NARRATIVE_INDEX_PATH := "res://data/balance/narrative_index.json"


func _load_narrative_config() -> Dictionary:
	var file := FileAccess.open(NARRATIVE_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "narrative_content.json should be readable")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "narrative_content.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func _load_narrative_index() -> Dictionary:
	var file := FileAccess.open(NARRATIVE_INDEX_PATH, FileAccess.READ)
	assert_not_null(file, "narrative_index.json should be readable")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "narrative_index.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func test_narrative_route_styles_have_expected_profiles() -> void:
	var cfg := _load_narrative_config()
	var route_styles: Dictionary = cfg.get("route_styles", {})
	assert_typeof(route_styles, TYPE_DICTIONARY, "route_styles should be Dictionary")

	for style_id in ["neutral", "vanguard", "raider"]:
		assert_true(route_styles.has(style_id), "route_styles should include %s" % style_id)
		var row: Dictionary = route_styles.get(style_id, {})
		assert_typeof(row, TYPE_DICTIONARY, "%s route style should be Dictionary" % style_id)

		assert_gte(float(row.get("event_weight_mult", 0.0)), 0.5, "%s event_weight_mult lower bound" % style_id)
		assert_lte(float(row.get("event_weight_mult", 99.0)), 1.8, "%s event_weight_mult upper bound" % style_id)
		assert_gte(float(row.get("hazard_mult", 0.0)), 0.6, "%s hazard_mult lower bound" % style_id)
		assert_lte(float(row.get("hazard_mult", 99.0)), 1.5, "%s hazard_mult upper bound" % style_id)
		assert_gte(float(row.get("gold_drop_mult", 0.0)), 0.5, "%s gold_drop_mult lower bound" % style_id)
		assert_lte(float(row.get("gold_drop_mult", 99.0)), 2.0, "%s gold_drop_mult upper bound" % style_id)
		assert_gte(float(row.get("ore_drop_mult", 0.0)), 0.5, "%s ore_drop_mult lower bound" % style_id)
		assert_lte(float(row.get("ore_drop_mult", 99.0)), 2.0, "%s ore_drop_mult upper bound" % style_id)

		assert_true(row.has("theme_tint"), "%s should define theme_tint" % style_id)
		assert_typeof(row.get("theme_tint", ""), TYPE_STRING, "%s theme_tint should be string" % style_id)
		assert_true(str(row.get("theme_tint", "")).length() > 0, "%s theme_tint should not be empty" % style_id)

		assert_gte(float(row.get("theme_blend", -1.0)), 0.0, "%s theme_blend lower bound" % style_id)
		assert_lte(float(row.get("theme_blend", 99.0)), 0.5, "%s theme_blend upper bound" % style_id)

		assert_gte(float(row.get("boss_hp_mult", 0.0)), 0.7, "%s boss_hp_mult lower bound" % style_id)
		assert_lte(float(row.get("boss_hp_mult", 99.0)), 1.4, "%s boss_hp_mult upper bound" % style_id)
		assert_gte(float(row.get("boss_damage_mult", 0.0)), 0.7, "%s boss_damage_mult lower bound" % style_id)
		assert_lte(float(row.get("boss_damage_mult", 99.0)), 1.5, "%s boss_damage_mult upper bound" % style_id)
		assert_gte(float(row.get("boss_speed_mult", 0.0)), 0.7, "%s boss_speed_mult lower bound" % style_id)
		assert_lte(float(row.get("boss_speed_mult", 99.0)), 1.5, "%s boss_speed_mult upper bound" % style_id)
		assert_gte(float(row.get("boss_scale_mult", 0.0)), 0.85, "%s boss_scale_mult lower bound" % style_id)
		assert_lte(float(row.get("boss_scale_mult", 99.0)), 1.25, "%s boss_scale_mult upper bound" % style_id)

		assert_true(row.has("boss_color"), "%s should define boss_color" % style_id)
		assert_typeof(row.get("boss_color", ""), TYPE_STRING, "%s boss_color should be string" % style_id)
		assert_true(str(row.get("boss_color", "")).length() > 0, "%s boss_color should not be empty" % style_id)


func test_chapter_events_define_route_weight_bias_keys() -> void:
	var cfg := _load_narrative_config()
	var chapter_events: Dictionary = cfg.get("chapter_events", {})
	assert_typeof(chapter_events, TYPE_DICTIONARY, "chapter_events should be Dictionary")

	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		assert_true(chapter_events.has(chapter_id), "%s should exist in chapter_events" % chapter_id)
		var rows: Array = chapter_events.get(chapter_id, [])
		assert_typeof(rows, TYPE_ARRAY, "%s chapter events should be an Array" % chapter_id)
		assert_gt(rows.size(), 0, "%s chapter events should not be empty" % chapter_id)

		for i in range(rows.size()):
			var row_var: Variant = rows[i]
			assert_typeof(row_var, TYPE_DICTIONARY, "%s[%d] should be Dictionary" % [chapter_id, i])
			if not (row_var is Dictionary):
				continue
			var row: Dictionary = row_var
			for route_key in ["weight_if_route_vanguard", "weight_if_route_raider"]:
				assert_true(row.has(route_key), "%s[%d] should include %s" % [chapter_id, i, route_key])
				var weight_value: float = float(row.get(route_key, -1.0))
				assert_gt(weight_value, 0.0, "%s[%d].%s should be > 0" % [chapter_id, i, route_key])
				assert_lte(weight_value, 3.0, "%s[%d].%s should be <= 3.0" % [chapter_id, i, route_key])


func test_route_arc_profiles_exist_for_all_alignment_outcomes() -> void:
	var cfg := _load_narrative_config()
	var rows: Dictionary = cfg.get("route_arc_profiles", {})
	assert_typeof(rows, TYPE_DICTIONARY, "route_arc_profiles should be Dictionary")

	for arc_id in ["balance", "redeem", "fall"]:
		assert_true(rows.has(arc_id), "route_arc_profiles should include %s" % arc_id)
		var row: Dictionary = rows.get(arc_id, {})
		assert_false(row.is_empty(), "%s route arc profile should not be empty" % arc_id)
		for field_name in ["title", "summary", "camp_focus", "fragment_hint"]:
			assert_true(str(row.get(field_name, "")).strip_edges() != "", "%s.%s should be non-empty" % [arc_id, field_name])


func test_camp_reflections_cover_all_mainline_chapters_and_route_arcs() -> void:
	var cfg := _load_narrative_config()
	var rows: Dictionary = cfg.get("camp_reflections", {})
	assert_typeof(rows, TYPE_DICTIONARY, "camp_reflections should be Dictionary")

	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		assert_true(rows.has(chapter_id), "camp_reflections should include %s" % chapter_id)
		var chapter_row: Dictionary = rows.get(chapter_id, {})
		assert_false(chapter_row.is_empty(), "%s camp reflection row should not be empty" % chapter_id)
		for arc_id in ["balance", "redeem", "fall"]:
			var row: Dictionary = chapter_row.get(arc_id, {})
			assert_false(row.is_empty(), "%s.%s camp reflection should not be empty" % [chapter_id, arc_id])
			for field_name in ["title", "body", "fragment_hint"]:
				assert_true(str(row.get(field_name, "")).strip_edges() != "", "%s.%s.%s should be non-empty" % [chapter_id, arc_id, field_name])


func test_ending_payoff_profiles_and_epilogue_chains_cover_all_endings() -> void:
	var cfg := _load_narrative_config()
	var payoff_rows: Dictionary = cfg.get("ending_payoff_profiles", {})
	var epilogue_rows: Dictionary = cfg.get("epilogue_chains", {})
	assert_typeof(payoff_rows, TYPE_DICTIONARY, "ending_payoff_profiles should be Dictionary")
	assert_typeof(epilogue_rows, TYPE_DICTIONARY, "epilogue_chains should be Dictionary")

	for ending_id in ["nar_ending_redeem", "nar_ending_fall", "nar_ending_balance"]:
		var payoff: Dictionary = payoff_rows.get(ending_id, {})
		assert_false(payoff.is_empty(), "%s payoff profile should not be empty" % ending_id)
		for field_name in ["title", "summary", "legacy", "fragment_hook"]:
			assert_true(str(payoff.get(field_name, "")).strip_edges() != "", "%s.%s should be non-empty" % [ending_id, field_name])

		var chain: Array = epilogue_rows.get(ending_id, [])
		assert_typeof(chain, TYPE_ARRAY, "%s epilogue chain should be Array" % ending_id)
		assert_gte(chain.size(), 3, "%s epilogue chain should contain at least 3 steps" % ending_id)
		for i in range(chain.size()):
			assert_true(str(chain[i]).strip_edges() != "", "%s epilogue chain step %d should be non-empty" % [ending_id, i])


func test_fragment_trigger_profiles_cover_all_mainline_chapters_and_trigger_types() -> void:
	var cfg := _load_narrative_config()
	var trigger_rows: Dictionary = cfg.get("fragment_trigger_profiles", {})
	assert_typeof(trigger_rows, TYPE_DICTIONARY, "fragment_trigger_profiles should be Dictionary")

	for chapter_id in ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]:
		var chapter_row: Dictionary = trigger_rows.get(chapter_id, {})
		assert_false(chapter_row.is_empty(), "%s trigger profile row should not be empty" % chapter_id)
		for trigger_type in ["camp", "event", "transition"]:
			var trigger_row: Dictionary = chapter_row.get(trigger_type, {})
			assert_false(trigger_row.is_empty(), "%s.%s trigger profile should not be empty" % [chapter_id, trigger_type])
			for arc_id in ["balance", "redeem", "fall"]:
				assert_true(str(trigger_row.get(arc_id, "")).strip_edges() != "", "%s.%s.%s trigger should be non-empty" % [chapter_id, trigger_type, arc_id])


func test_stage5_batch3_profiles_cover_all_endings_and_route_arcs() -> void:
	var cfg := _load_narrative_config()
	var epilogue_branch_rows: Dictionary = cfg.get("epilogue_branch_profiles", {})
	var fragment_recap_rows: Dictionary = cfg.get("fragment_recap_profiles", {})
	var hidden_hook_rows: Dictionary = cfg.get("hidden_layer_hooks", {})
	assert_typeof(epilogue_branch_rows, TYPE_DICTIONARY, "epilogue_branch_profiles should be Dictionary")
	assert_typeof(fragment_recap_rows, TYPE_DICTIONARY, "fragment_recap_profiles should be Dictionary")
	assert_typeof(hidden_hook_rows, TYPE_DICTIONARY, "hidden_layer_hooks should be Dictionary")

	for ending_id in ["nar_ending_redeem", "nar_ending_fall", "nar_ending_balance"]:
		var branch_row: Dictionary = epilogue_branch_rows.get(ending_id, {})
		assert_false(branch_row.is_empty(), "%s epilogue branch profile should not be empty" % ending_id)
		for branch_key in ["first_unlock", "repeat_unlock"]:
			var branch_entry: Dictionary = branch_row.get(branch_key, {})
			assert_false(branch_entry.is_empty(), "%s.%s should not be empty" % [ending_id, branch_key])
			for field_name in ["title", "body"]:
				assert_true(str(branch_entry.get(field_name, "")).strip_edges() != "", "%s.%s.%s should be non-empty" % [ending_id, branch_key, field_name])
		assert_true(str(branch_row.get("archive_hook", "")).strip_edges() != "", "%s.archive_hook should be non-empty" % ending_id)

	for arc_id in ["balance", "redeem", "fall"]:
		var recap_row: Dictionary = fragment_recap_rows.get(arc_id, {})
		assert_false(recap_row.is_empty(), "%s fragment recap profile should not be empty" % arc_id)
		for field_name in ["title", "summary", "pace_hint"]:
			assert_true(str(recap_row.get(field_name, "")).strip_edges() != "", "%s.%s should be non-empty" % [arc_id, field_name])

		var hook_row: Dictionary = hidden_hook_rows.get(arc_id, {})
		assert_false(hook_row.is_empty(), "%s hidden layer hook should not be empty" % arc_id)
		assert_true(str(hook_row.get("target_layer", "")).strip_edges() in ["FS1", "FS2"], "%s.target_layer should target a hidden stratum" % arc_id)
		for field_name in ["title", "teaser", "unlock_hint"]:
			assert_true(str(hook_row.get(field_name, "")).strip_edges() != "", "%s.%s should be non-empty" % [arc_id, field_name])


func test_hidden_layer_story_profiles_cover_layers_arcs_and_fragment_index_totals() -> void:
	var cfg := _load_narrative_config()
	var index_cfg := _load_narrative_index()
	var memory_fragments: Dictionary = cfg.get("memory_fragments", {})
	var hidden_story_rows: Dictionary = cfg.get("hidden_layer_story_profiles", {})
	assert_typeof(memory_fragments, TYPE_DICTIONARY, "memory_fragments should be Dictionary")
	assert_typeof(hidden_story_rows, TYPE_DICTIONARY, "hidden_layer_story_profiles should be Dictionary")

	for layer_id in ["FS1", "FS2"]:
		var layer_row: Dictionary = hidden_story_rows.get(layer_id, {})
		assert_false(layer_row.is_empty(), "%s hidden-layer story row should not be empty" % layer_id)
		for arc_id in ["balance", "redeem", "fall"]:
			var story_row: Dictionary = layer_row.get(arc_id, {})
			assert_false(story_row.is_empty(), "%s.%s story row should not be empty" % [layer_id, arc_id])
			for field_name in ["title", "body", "archive_echo", "ending_link", "fragment_id"]:
				assert_true(str(story_row.get(field_name, "")).strip_edges() != "", "%s.%s.%s should be non-empty" % [layer_id, arc_id, field_name])
			assert_true(str(story_row.get("ending_link", "")) in ["nar_ending_balance", "nar_ending_redeem", "nar_ending_fall"], "%s.%s should target a main ending" % [layer_id, arc_id])
			assert_true(memory_fragments.has(str(story_row.get("fragment_id", ""))), "%s.%s fragment id should exist in memory_fragments" % [layer_id, arc_id])

	var index_fragments: Dictionary = index_cfg.get("memory_fragments", {})
	assert_eq(int(index_fragments.get("total", 0)), memory_fragments.size(), "narrative_index fragment total should match memory_fragments count")
