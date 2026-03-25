extends GutTest

const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"


func _instantiate_main_menu() -> Control:
	var scene: PackedScene = load(MAIN_MENU_SCENE_PATH)
	assert_not_null(scene, "main_menu scene should load")
	if scene == null:
		return null

	var menu: Control = scene.instantiate() as Control
	assert_not_null(menu, "main_menu scene should instantiate")
	if menu == null:
		return null

	add_child_autofree(menu)
	await get_tree().process_frame
	return menu


func _find_menu_label(menu: Control, node_name: String) -> Label:
	if menu == null:
		return null
	return menu.find_child(node_name, true, false) as Label


func test_hidden_layer_archives_unlock_codex_entries_and_main_menu_shows_archive_category() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	var fs1_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 360,
		"level_reached": 13,
		"gold": 220,
		"ore": 44,
		"alignment": 72.0,
		"route_style": "vanguard",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 84,
		"hidden_layer_reward_payload": {
			"track": "time_fragments",
			"time_fragments": 5,
			"rewind_charges": 2,
			"collection_bonus_awarded": true,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2"
		},
		"hidden_layer_reward_summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2",
		"hidden_layer_gameplay": {
			"pressure_label": "Rift Surge",
			"pressure_stage": 3,
			"required_pressure_stage": 2,
			"survival_seconds": 46.0,
			"minimum_clear_seconds": 30.0,
			"boss_echo_id": "boss_frost_king",
			"boss_echo_title": "Frost King",
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_count": 4,
			"collection_required": 4,
			"collection_complete": true,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		}
	})
	var fs1_difficulty_unlocks: Array = fs1_result.get("new_difficulty_unlocks", [])
	assert_eq(fs1_difficulty_unlocks.size(), 2, "the first mastery clear should unlock both Hard and Nightmare")
	assert_eq(str((fs1_difficulty_unlocks[0] as Dictionary).get("label", "")), "Hard", "first difficulty unlock should be Hard")
	assert_eq(str((fs1_difficulty_unlocks[1] as Dictionary).get("label", "")), "Nightmare", "second difficulty unlock should be Nightmare")
	assert_eq((fs1_result.get("new_codex_unlocks", []) as Array).size(), 2, "the first mastery clear should still only surface hidden-layer codex unlocks")
	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	var fs2_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 20,
		"kills": 410,
		"level_reached": 14,
		"gold": 260,
		"ore": 52,
		"alignment": 0.0,
		"route_style": "neutral",
		"hidden_layer_id": "FS2",
		"hidden_layer_rooms_cleared": 5,
		"hidden_layer_kills": 112,
		"hidden_layer_reward_payload": {
			"track": "legendary_forge",
			"recipe_drafts": 3,
			"relic_merges": 2,
			"collection_bonus_awarded": true,
			"collection_bonus_label": "Draft +1 | Merge +1",
			"summary": "Legendary recipe draft +3 | Relic merge archive +2 | Depth 5/5 | Archive 5/5 | Mastery Draft +1 | Merge +1"
		},
		"hidden_layer_reward_summary": "Legendary recipe draft +3 | Relic merge archive +2 | Depth 5/5 | Archive 5/5 | Mastery Draft +1 | Merge +1",
		"hidden_layer_gameplay": {
			"trial_depth": 5,
			"trial_depth_max": 5,
			"trial_label": "Forge Trial V: Genesis Core",
			"deepest_trial_label": "Forge Trial V: Genesis Core",
			"trial_labels": [
				"Forge Trial I: Ore Tempering",
				"Forge Trial II: Ember Fold",
				"Forge Trial III: Frost Bind",
				"Forge Trial IV: Void Sunder",
				"Forge Trial V: Genesis Core"
			],
			"collection_count": 5,
			"collection_required": 5,
			"collection_complete": true,
			"collection_bonus_label": "Draft +1 | Merge +1",
			"mastery_label": "Forge Archive Mastered | Draft +1 | Merge +1 claimed"
		}
	})

	var fs1_codex_unlocks: Array = fs1_result.get("new_codex_unlocks", [])
	var fs2_codex_unlocks: Array = fs2_result.get("new_codex_unlocks", [])
	assert_eq(fs1_codex_unlocks.size(), 2, "FS1 mastery clear should surface two codex unlocks in the run result")
	assert_eq(fs2_codex_unlocks.size(), 5, "Nightmare hidden-layer clear should surface hidden-layer and difficulty archive codex unlocks")

	var codex: Dictionary = SaveManager.get_codex()
	var archives: Array = codex.get("archives", [])
	assert_true(archives.has("fs1_echo_archive"), "FS1 clear should unlock archive codex entry")
	assert_true(archives.has("fs1_echo_mastery"), "FS1 mastery should unlock mastery codex entry")
	assert_true(archives.has("fs2_trial_archive"), "FS2 clear should unlock archive codex entry")
	assert_true(archives.has("fs2_trial_mastery"), "FS2 mastery should unlock mastery codex entry")
	assert_true(archives.has("hard_clear_archive"), "Nightmare clears should also unlock the Hard difficulty archive")
	assert_true(archives.has("nightmare_clear_archive"), "Nightmare clear should unlock the Nightmare archive")
	assert_true(archives.has("nightmare_hidden_archive"), "Nightmare hidden-layer clear should unlock the hidden Nightmare archive")

	var recent_unlocks: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(8)
	var recent_sources: Array[String] = []
	for row: Dictionary in recent_unlocks:
		recent_sources.append(str(row.get("source", "")))
	assert_true(recent_sources.has("hidden_layer_clear"), "recent codex unlocks should include hidden-layer clear source")
	assert_true(recent_sources.has("hidden_layer_mastery"), "recent codex unlocks should include hidden-layer mastery source")
	assert_true(recent_sources.has("difficulty_clear"), "recent codex unlocks should include difficulty clear source")
	assert_true(recent_sources.has("difficulty_hidden_clear"), "recent codex unlocks should include difficulty hidden clear source")

	var recent_before_menu: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(5)
	var recent_before_keys: Array[String] = []
	for row: Dictionary in recent_before_menu:
		recent_before_keys.append("%s:%s:%s" % [
			str(row.get("category", "")),
			str(row.get("entry_id", "")),
			str(row.get("source", ""))
		])

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	var recent_after_menu: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(5)
	var recent_after_keys: Array[String] = []
	for row: Dictionary in recent_after_menu:
		recent_after_keys.append("%s:%s:%s" % [
			str(row.get("category", "")),
			str(row.get("entry_id", "")),
			str(row.get("source", ""))
		])
	assert_eq(recent_after_keys, recent_before_keys, "opening the main menu should not mutate recent codex unlock ordering")

	var catalog: Array = menu.call("_build_codex_catalog", "archives")
	assert_eq(catalog.size(), 13, "archive codex catalog should expose hidden-layer, meta-return, and challenge archive entries")

	menu.set("_codex_category_index", 5)
	menu.call("_refresh_codex_overlay")

	var title_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexTitle")
	var content_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexContent")
	var detail_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexDetail")
	var stats_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsValue")
	assert_not_null(title_label, "codex title label should exist")
	assert_not_null(content_label, "codex content label should exist")
	assert_not_null(detail_label, "codex detail label should exist")
	assert_not_null(stats_label, "codex stats label should exist")
	if title_label == null or content_label == null or detail_label == null or stats_label == null:
		return

	assert_string_contains(title_label.text, "Archives", "codex title should switch to the archive category")
	assert_string_contains(content_label.text, "Time Rift Archive", "archive catalog should list the FS1 archive entry")
	assert_string_contains(content_label.text, "Genesis Forge Mastery", "archive catalog should list the FS2 mastery entry")
	assert_string_contains(content_label.text, "Archive Return Protocol", "archive catalog should list the archive-return entry")
	assert_string_contains(content_label.text, "Apex Return Protocol", "archive catalog should list the apex-return entry")
	assert_string_contains(content_label.text, "Challenge Layer Archive", "archive catalog should list the CL1 archive entry")
	assert_string_contains(content_label.text, "Crown Trial Archive", "archive catalog should list the CL2 archive entry")
	assert_string_contains(content_label.text, "Sovereign Echo Archive", "archive catalog should list the CL3 archive entry")
	assert_string_contains(content_label.text, "Apex Throne Archive", "archive catalog should list the CL4 archive entry")
	assert_string_contains(content_label.text, "Nightmare Hidden Archive", "archive catalog should list the Nightmare hidden archive entry")
	assert_string_contains(detail_label.text, "Layer: Time Rift", "archive detail should resolve the hidden-layer title")
	assert_string_contains(detail_label.text, "Collection:", "archive detail should surface collection progress")
	assert_string_contains(detail_label.text, "Mastery:", "archive detail should surface mastery state")
	assert_string_contains(stats_label.text, "Archives", "codex stats panel should count the archive category")
	assert_string_contains(stats_label.text, "Source Breakdown:", "codex stats panel should expose source breakdown summary")
	assert_string_contains(stats_label.text, "- Hidden Layer Clear 2", "source breakdown should count hidden-layer clear unlocks")
	assert_string_contains(stats_label.text, "- Hidden Layer Mastery 2", "source breakdown should count hidden-layer mastery unlocks")
	assert_string_contains(stats_label.text, "- Difficulty Clear 2", "source breakdown should count difficulty clear unlocks")
	assert_string_contains(stats_label.text, "- Nightmare Hidden Clear 1", "source breakdown should count hidden Nightmare unlocks")
	assert_string_contains(stats_label.text, "Recent Category Breakdown:", "codex stats panel should expose recent category distribution")
	assert_string_contains(stats_label.text, "- Archives 5", "recent category breakdown should count archive-heavy recent unlocks")
	assert_string_contains(stats_label.text, "Recent Chapter Breakdown:", "codex stats panel should expose recent chapter distribution")
	assert_string_contains(stats_label.text, "- Global 5", "recent chapter breakdown should count the archive-heavy recent window as global entries")
	assert_string_contains(stats_label.text, "Recent Source Breakdown:", "codex stats panel should expose recent source distribution")
	assert_string_contains(stats_label.text, "- Hidden Layer Clear 1", "recent source breakdown should count recent hidden-layer clear entries")
	assert_string_contains(stats_label.text, "- Hidden Layer Mastery 1", "recent source breakdown should count recent hidden-layer mastery entries")
	assert_string_contains(stats_label.text, "- Difficulty Clear 2", "recent source breakdown should count recent difficulty clear entries")
	assert_string_contains(stats_label.text, "- Nightmare Hidden Clear 1", "recent source breakdown should count recent hidden Nightmare entries")
	assert_string_contains(stats_label.text, "Visible Recent Window: 5/5", "codex stats panel should summarize the unfiltered recent window size")
	assert_string_contains(stats_label.text, "Hidden Layer Clear", "recent unlocks should prettify hidden-layer clear source")
	assert_string_contains(stats_label.text, "Hidden Layer Mastery", "recent unlocks should prettify hidden-layer mastery source")
	assert_string_contains(stats_label.text, "Difficulty Clear", "recent unlocks should prettify difficulty clear source")

	menu.set("_codex_stats_source_filter_index", 7)
	menu.call("_refresh_codex_stats_panel")
	assert_string_contains(stats_label.text, "Visible Recent Window: 1/5", "filtered codex stats should summarize the reduced recent window size")
	assert_string_contains(stats_label.text, "- Archives 1", "filtered recent category breakdown should follow the visible recent window")
	assert_string_contains(stats_label.text, "- Global 1", "filtered recent chapter breakdown should follow the visible recent window")
	assert_string_contains(stats_label.text, "- Nightmare Hidden Clear 1", "filtered recent source breakdown should follow the visible recent window")
	assert_string_contains(stats_label.text, "Nightmare Hidden Clear", "source-filtered codex stats should prettify the hidden Nightmare source")

	var nightmare_hidden_index: int = -1
	for index: int in range(catalog.size()):
		var row: Variant = catalog[index]
		if row is Dictionary and str((row as Dictionary).get("id", "")) == "nightmare_hidden_archive":
			nightmare_hidden_index = index
			break
	assert_gt(nightmare_hidden_index, -1, "nightmare hidden archive entry should exist in the archive catalog")
	if nightmare_hidden_index < 0:
		return
	menu.set("_codex_entry_index", nightmare_hidden_index)
	menu.call("_refresh_codex_overlay")
	assert_string_contains(detail_label.text, "Tier: Nightmare", "difficulty archive detail should show Nightmare tier")
	assert_string_contains(detail_label.text, "Hidden Clears: 1", "difficulty hidden archive detail should surface hidden clear count")
	assert_string_contains(detail_label.text, "Risk Profile: Haz x1.22", "difficulty archive detail should surface the risk profile")

	var last_run_label: Label = _find_menu_label(menu, "LastRunValue")
	assert_not_null(last_run_label, "last run label should exist")
	if last_run_label == null:
		return
	assert_string_contains(last_run_label.text, "Diff Nightmare", "last run summary should surface persisted difficulty label")
	assert_string_contains(last_run_label.text, "NewCodex 5", "last run summary should surface the combined difficulty and archive codex burst count")
	assert_string_contains(last_run_label.text, "NewDiff 0", "last run summary should show no new difficulty unlocks once the ladder is complete")
	assert_string_contains(last_run_label.text, "Haz x1.22", "last run summary should surface difficulty risk summary")


func test_archive_return_and_challenge_layers_unlock_codex_entries_and_show_archive_details() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 360,
		"level_reached": 13,
		"gold": 220,
		"ore": 44,
		"alignment": 72.0,
		"route_style": "vanguard",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 84,
		"hidden_layer_reward_payload": {
			"track": "time_fragments",
			"time_fragments": 5,
			"rewind_charges": 2,
			"collection_bonus_awarded": true,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2"
		},
		"hidden_layer_reward_summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2",
		"hidden_layer_gameplay": {
			"pressure_label": "Rift Surge",
			"pressure_stage": 3,
			"required_pressure_stage": 2,
			"survival_seconds": 46.0,
			"minimum_clear_seconds": 30.0,
			"boss_echo_id": "boss_frost_king",
			"boss_echo_title": "Frost King",
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_count": 4,
			"collection_required": 4,
			"collection_complete": true,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		}
	})
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 20,
		"kills": 410,
		"level_reached": 14,
		"gold": 260,
		"ore": 52,
		"alignment": 0.0,
		"route_style": "neutral",
		"hidden_layer_id": "FS2",
		"hidden_layer_rooms_cleared": 5,
		"hidden_layer_kills": 112,
		"hidden_layer_reward_payload": {
			"track": "legendary_forge",
			"recipe_drafts": 3,
			"relic_merges": 2,
			"collection_bonus_awarded": true,
			"collection_bonus_label": "Draft +1 | Merge +1",
			"summary": "Legendary recipe draft +3 | Relic merge archive +2 | Depth 5/5 | Archive 5/5 | Mastery Draft +1 | Merge +1"
		},
		"hidden_layer_reward_summary": "Legendary recipe draft +3 | Relic merge archive +2 | Depth 5/5 | Archive 5/5 | Mastery Draft +1 | Merge +1",
		"hidden_layer_gameplay": {
			"trial_depth": 5,
			"trial_depth_max": 5,
			"trial_label": "Forge Trial V: Genesis Core",
			"deepest_trial_label": "Forge Trial V: Genesis Core",
			"trial_labels": [
				"Forge Trial I: Ore Tempering",
				"Forge Trial II: Ember Fold",
				"Forge Trial III: Frost Bind",
				"Forge Trial IV: Void Sunder",
				"Forge Trial V: Genesis Core"
			],
			"collection_count": 5,
			"collection_required": 5,
			"collection_complete": true,
			"collection_bonus_label": "Draft +1 | Merge +1",
			"mastery_label": "Forge Archive Mastered | Draft +1 | Merge +1 claimed"
		}
	})
	var archive_return_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 19,
		"kills": 372,
		"level_reached": 13,
		"gold": 236,
		"ore": 47,
		"alignment": 68.0,
		"route_style": "vanguard",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 88,
		"hidden_layer_reward_payload": {
			"track": "time_fragments",
			"time_fragments": 5,
			"rewind_charges": 2,
			"collection_bonus_awarded": false,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed"
		},
		"hidden_layer_reward_summary": "Time Fragments +5 | Rewind +2 | Rift archive sealed",
		"hidden_layer_gameplay": {
			"pressure_label": "Rift Surge",
			"pressure_stage": 2,
			"required_pressure_stage": 2,
			"survival_seconds": 42.0,
			"minimum_clear_seconds": 30.0,
			"boss_echo_id": "boss_frost_king",
			"boss_echo_title": "Frost King",
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_count": 4,
			"collection_required": 4,
			"collection_complete": true,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		}
	})
	var archive_return_unlocks: Array = archive_return_result.get("new_codex_unlocks", [])
	assert_true(archive_return_unlocks.any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "archive_return_protocol"), "archive return repeat clear should unlock the archive-return codex entry")

	var cl1_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 12,
		"kills": 140,
		"level_reached": 9,
		"gold": 88,
		"ore": 14,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL1",
		"challenge_layer_title": "Challenge Layer",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "meta_cache",
		"challenge_layer_reward_title": "Meta Cache",
		"challenge_layer_reward_payload": {"meta_bonus": 40, "sigils": 0, "insight": 0},
		"challenge_layer_reward_summary": "Challenge archive sealed | Meta Cache | Meta +40",
		"challenge_layer_settlement_summary": "The settlement records this challenge clear for the next postgame step.",
		"challenge_layer_rooms_cleared": 2,
		"challenge_layer_kills": 24
	})
	assert_true((cl1_result.get("new_codex_unlocks", []) as Array).any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "cl1_challenge_archive"), "CL1 clear should unlock the first challenge archive entry")

	var cl2_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 16,
		"kills": 196,
		"level_reached": 11,
		"gold": 118,
		"ore": 20,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL2",
		"challenge_layer_title": "Challenge Layer II",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "insight_bundle",
		"challenge_layer_reward_title": "Insight Bundle",
		"challenge_layer_reward_payload": {"meta_bonus": 0, "sigils": 0, "insight": 2},
		"challenge_layer_reward_summary": "Crucible archive sealed | Insight Bundle | Insight +2",
		"challenge_layer_settlement_summary": "The second settlement records a deeper challenge clear for the next archive horizon.",
		"challenge_layer_rooms_cleared": 3,
		"challenge_layer_kills": 0
	})
	assert_true((cl2_result.get("new_codex_unlocks", []) as Array).any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "cl2_crown_archive"), "CL2 clear should unlock the crown-trial archive entry")

	var cl3_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 224,
		"level_reached": 12,
		"gold": 136,
		"ore": 28,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL3",
		"challenge_layer_title": "Challenge Layer III",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "sigil_matrix",
		"challenge_layer_reward_title": "Sigil Matrix",
		"challenge_layer_reward_payload": {"meta_bonus": 0, "sigils": 3, "insight": 0},
		"challenge_layer_reward_summary": "Sovereign archive sealed | Sigil Matrix | Sigil +3",
		"challenge_layer_settlement_summary": "The third settlement records a sovereign challenge clear for the final archive frontier.",
		"challenge_layer_rooms_cleared": 4,
		"challenge_layer_kills": 0
	})
	assert_true((cl3_result.get("new_codex_unlocks", []) as Array).any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "cl3_sovereign_archive"), "CL3 clear should unlock the sovereign archive entry")

	var cl4_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 22,
		"kills": 248,
		"level_reached": 14,
		"gold": 162,
		"ore": 32,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL4",
		"challenge_layer_title": "Challenge Layer IV",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "insight_throne",
		"challenge_layer_reward_title": "Insight Throne",
		"challenge_layer_reward_payload": {"meta_bonus": 0, "sigils": 0, "insight": 4},
		"challenge_layer_reward_summary": "Apex archive sealed | Insight Throne | Insight +4",
		"challenge_layer_settlement_summary": "The fourth settlement records the apex challenge clear for the final return frontier.",
		"challenge_layer_rooms_cleared": 5,
		"challenge_layer_kills": 0
	})
	assert_true((cl4_result.get("new_codex_unlocks", []) as Array).any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "cl4_apex_archive"), "CL4 clear should unlock the apex archive entry")
	assert_true((cl4_result.get("new_codex_unlocks", []) as Array).any(func(row: Variant) -> bool: return row is Dictionary and str((row as Dictionary).get("entry_id", "")) == "apex_return_protocol"), "CL4 clear should unlock the apex-return codex entry")

	var archives: Array = SaveManager.get_codex().get("archives", [])
	assert_true(archives.has("archive_return_protocol"), "codex should persist the archive-return entry")
	assert_true(archives.has("apex_return_protocol"), "codex should persist the apex-return entry")
	assert_true(archives.has("cl1_challenge_archive"), "codex should persist the CL1 archive entry")
	assert_true(archives.has("cl2_crown_archive"), "codex should persist the CL2 archive entry")
	assert_true(archives.has("cl3_sovereign_archive"), "codex should persist the CL3 archive entry")
	assert_true(archives.has("cl4_apex_archive"), "codex should persist the CL4 archive entry")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.set("_codex_category_index", 5)
	menu.call("_refresh_codex_overlay")
	var content_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexContent")
	var detail_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexDetail")
	var stats_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsValue")
	assert_not_null(content_label, "codex content label should exist")
	assert_not_null(detail_label, "codex detail label should exist")
	assert_not_null(stats_label, "codex stats label should exist")
	if content_label == null or detail_label == null or stats_label == null:
		return

	assert_string_contains(content_label.text, "Archive Return Protocol", "archive catalog should list the archive-return entry after unlock")
	assert_string_contains(content_label.text, "Apex Return Protocol", "archive catalog should list the apex-return entry after unlock")
	assert_string_contains(content_label.text, "Challenge Layer Archive", "archive catalog should list the CL1 archive entry after unlock")
	assert_string_contains(content_label.text, "Crown Trial Archive", "archive catalog should list the CL2 archive entry after unlock")
	assert_string_contains(content_label.text, "Sovereign Echo Archive", "archive catalog should list the CL3 archive entry after unlock")
	assert_string_contains(content_label.text, "Apex Throne Archive", "archive catalog should list the CL4 archive entry after unlock")
	assert_string_contains(stats_label.text, "Challenge Layer Clear", "codex stats should prettify the challenge-layer clear source")

	var archive_catalog: Array = menu.call("_build_codex_catalog", "archives")
	var apex_return_index: int = -1
	var cl2_index: int = -1
	var cl3_index: int = -1
	var cl4_index: int = -1
	for index: int in range(archive_catalog.size()):
		var row: Variant = archive_catalog[index]
		if not (row is Dictionary):
			continue
		var entry_id: String = str((row as Dictionary).get("id", ""))
		if entry_id == "apex_return_protocol":
			apex_return_index = index
		elif entry_id == "cl2_crown_archive":
			cl2_index = index
		elif entry_id == "cl3_sovereign_archive":
			cl3_index = index
		elif entry_id == "cl4_apex_archive":
			cl4_index = index
	assert_gt(apex_return_index, -1, "apex-return codex row should exist in the archive catalog")
	assert_gt(cl2_index, -1, "CL2 codex row should exist in the archive catalog")
	assert_gt(cl3_index, -1, "CL3 codex row should exist in the archive catalog")
	assert_gt(cl4_index, -1, "CL4 codex row should exist in the archive catalog")

	menu.set("_codex_entry_index", apex_return_index)
	menu.call("_refresh_codex_overlay")
	assert_string_contains(detail_label.text, "Meta Return: Apex Return Protocol", "apex-return codex detail should surface its title")
	assert_string_contains(detail_label.text, "Status: Unlocked", "apex-return codex detail should surface unlocked state")
	assert_string_contains(detail_label.text, "Current Return: Return x1.45", "apex-return codex detail should surface the unlocked meta-return summary for the current codex-only unlock path")

	menu.set("_codex_entry_index", cl2_index)
	menu.call("_refresh_codex_overlay")
	assert_string_contains(detail_label.text, "Layer: Challenge Layer II", "CL2 codex detail should surface the challenge-layer title")
	assert_string_contains(detail_label.text, "Clears: 1", "CL2 codex detail should surface clear count")
	assert_string_contains(detail_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +2", "CL2 codex detail should surface the archived challenge reward ledger")
	assert_string_contains(detail_label.text, "Last Reward: Insight Bundle", "CL2 codex detail should surface the archived challenge reward title")

	menu.set("_codex_entry_index", cl3_index)
	menu.call("_refresh_codex_overlay")
	assert_string_contains(detail_label.text, "Layer: Challenge Layer III", "CL3 codex detail should surface the challenge-layer title")
	assert_string_contains(detail_label.text, "Clears: 1", "CL3 codex detail should surface clear count")
	assert_string_contains(detail_label.text, "Reward Ledger: Meta +0 | Sigil +3 | Insight +0", "CL3 codex detail should surface the archived challenge reward ledger")
	assert_string_contains(detail_label.text, "Last Reward: Sigil Matrix", "CL3 codex detail should surface the archived challenge reward title")

	menu.set("_codex_entry_index", cl4_index)
	menu.call("_refresh_codex_overlay")
	assert_string_contains(detail_label.text, "Layer: Challenge Layer IV", "CL4 codex detail should surface the challenge-layer title")
	assert_string_contains(detail_label.text, "Clears: 1", "CL4 codex detail should surface clear count")
	assert_string_contains(detail_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +4", "CL4 codex detail should surface the archived challenge reward ledger")
	assert_string_contains(detail_label.text, "Last Reward: Insight Throne", "CL4 codex detail should surface the archived challenge reward title")


func test_codex_recent_unlocks_show_run_index_and_timestamp_metadata() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["codex"] = {
		"archives": ["nightmare_hidden_archive", "fs1_echo_archive", "fs2_trial_mastery"]
	}
	meta["codex_meta"] = {
		"archives:fs1_echo_archive": {
			"category": "archives",
			"entry_id": "fs1_echo_archive",
			"source": "hidden_layer_clear",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"archives:fs2_trial_mastery": {
			"category": "archives",
			"entry_id": "fs2_trial_mastery",
			"source": "hidden_layer_mastery",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"archives:nightmare_hidden_archive": {
			"category": "archives",
			"entry_id": "nightmare_hidden_archive",
			"source": "difficulty_hidden_clear",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.set("_codex_category_index", 5)
	menu.call("_refresh_codex_overlay")
	var content_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexContent")
	var stats_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsValue")
	assert_not_null(content_label, "codex content label should exist")
	assert_not_null(stats_label, "codex stats label should exist")
	if content_label == null or stats_label == null:
		return

	assert_string_contains(content_label.text, "> [x] Time Rift Archive | Run #1 | 2026-03-20T08:00:00", "selected codex row should expose timeline metadata without changing catalog order")
	assert_string_contains(content_label.text, "  [x] Genesis Forge Mastery | Run #2 | 2026-03-20T09:00:00", "non-selected unlocked codex row should expose middle archive timeline metadata")
	assert_string_contains(content_label.text, "  [x] Nightmare Hidden Archive | Run #3 | 2026-03-20T10:00:00", "non-selected unlocked codex row should expose newest archive timeline metadata")
	assert_string_contains(stats_label.text, "Recent Unlocks (last 5):\nFilters -> Source: All Sources | Chapter: All Chapters\nVisible Recent Window: 3/5\n- [Archives] Nightmare Hidden Archive | Nightmare Hidden Clear | Global | Run #3 | 2026-03-20T10:00:00\n- [Archives] Genesis Forge Mastery | Hidden Layer Mastery | Global | Run #2 | 2026-03-20T09:00:00\n- [Archives] Time Rift Archive | Hidden Layer Clear | Global | Run #1 | 2026-03-20T08:00:00", "codex recent unlocks should expose newest-first run and timestamp metadata in the stats panel")


func test_codex_detail_shows_unified_unlock_timeline_metadata() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["codex"] = {
		"archives": ["nightmare_hidden_archive", "fs1_echo_archive", "fs2_trial_mastery"]
	}
	meta["codex_meta"] = {
		"archives:fs1_echo_archive": {
			"category": "archives",
			"entry_id": "fs1_echo_archive",
			"source": "hidden_layer_clear",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"archives:fs2_trial_mastery": {
			"category": "archives",
			"entry_id": "fs2_trial_mastery",
			"source": "hidden_layer_mastery",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"archives:nightmare_hidden_archive": {
			"category": "archives",
			"entry_id": "nightmare_hidden_archive",
			"source": "difficulty_hidden_clear",
			"chapter_id": "global",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.set("_codex_category_index", 5)
	var archive_catalog: Array = menu.call("_build_codex_catalog", "archives")
	var nightmare_index: int = -1
	for index: int in range(archive_catalog.size()):
		var row: Variant = archive_catalog[index]
		if row is Dictionary and str((row as Dictionary).get("id", "")) == "nightmare_hidden_archive":
			nightmare_index = index
			break
	assert_gt(nightmare_index, -1, "nightmare archive entry should exist in the codex catalog")
	if nightmare_index < 0:
		return

	menu.set("_codex_entry_index", nightmare_index)
	menu.call("_refresh_codex_overlay")
	var detail_label: Label = menu.get_node_or_null("CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexDetail")
	assert_not_null(detail_label, "codex detail label should exist")
	if detail_label == null:
		return

	assert_string_contains(detail_label.text, "Unlocked: Run #3 | 2026-03-20T10:00:00", "codex detail should expose unified unlock timeline metadata for the selected entry")
