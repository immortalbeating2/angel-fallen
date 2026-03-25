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


func test_difficulty_meta_return_progression_unlocks_and_surfaces_across_ui() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var normal_unlock: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 6,
		"kills": 80,
		"level_reached": 6,
		"gold": 24,
		"ore": 4,
		"alignment": 0.0
	})
	assert_eq((normal_unlock.get("new_meta_return_unlocks", []) as Array).size(), 0, "normal clears should not unlock meta return milestones")

	SaveManager.update_runtime_settings({"difficulty_tier": 1})
	var hard_clear: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0
	})
	var hard_returns: Array = hard_clear.get("new_meta_return_unlocks", [])
	assert_eq(hard_returns.size(), 1, "first Hard clear should unlock one meta return milestone")
	assert_eq(str((hard_returns[0] as Dictionary).get("label", "")), "Hard Return", "Hard clear should unlock the Hard meta return milestone")
	assert_eq(float(hard_clear.get("meta_return_multiplier", 1.0)), 1.1, "Hard return milestone should raise the permanent meta return multiplier")
	assert_string_contains(str(hard_clear.get("meta_return_summary", "")), "Return x1.10", "Hard clear should persist meta return summary")
	assert_string_contains(str(hard_clear.get("meta_return_next_hint", "")), "Nightmare run", "Hard clear should point at the Nightmare return milestone")
	assert_eq(int(hard_clear.get("meta_reward", 0)), 271, "the unlocking Hard clear should still use the pre-unlock return multiplier")

	var nightmare_unlock: Dictionary = SaveManager.submit_run_result({
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
	var nightmare_unlock_rows: Array = nightmare_unlock.get("new_difficulty_unlocks", [])
	assert_eq(nightmare_unlock_rows.size(), 1, "hidden-layer mastery should unlock Nightmare difficulty")
	assert_eq(str((nightmare_unlock_rows[0] as Dictionary).get("label", "")), "Nightmare", "hidden-layer mastery should report Nightmare unlock")

	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	var nightmare_clear: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0
	})
	var nightmare_returns: Array = nightmare_clear.get("new_meta_return_unlocks", [])
	assert_eq(nightmare_returns.size(), 1, "first Nightmare clear should unlock one meta return milestone")
	assert_eq(str((nightmare_returns[0] as Dictionary).get("label", "")), "Nightmare Return", "Nightmare clear should unlock Nightmare Return")
	assert_eq(float(nightmare_clear.get("meta_return_multiplier", 1.0)), 1.25, "Nightmare return should raise the permanent multiplier to x1.25")
	assert_string_contains(str(nightmare_clear.get("meta_return_summary", "")), "Return x1.25", "Nightmare clear should persist updated meta return summary")

	var nightmare_hidden: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 20,
		"kills": 410,
		"level_reached": 14,
		"gold": 260,
		"ore": 52,
		"alignment": 0.0,
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
	var hidden_returns: Array = nightmare_hidden.get("new_meta_return_unlocks", [])
	assert_eq(hidden_returns.size(), 1, "first Nightmare hidden clear should unlock the Nightmare Hidden Return milestone")
	assert_eq(str((hidden_returns[0] as Dictionary).get("label", "")), "Nightmare Hidden Return", "Nightmare hidden clear should unlock Nightmare Hidden Return")
	assert_eq(float(nightmare_hidden.get("meta_return_multiplier", 1.0)), 1.4, "Nightmare Hidden Return should raise the permanent multiplier to x1.40")
	assert_string_contains(str(nightmare_hidden.get("meta_return_summary", "")), "Return x1.40", "Nightmare hidden clear should persist the updated meta return summary")
	assert_string_contains(str(nightmare_hidden.get("meta_return_next_hint", "")), "clear any hidden layer again after sealing both archives", "first dual-archive clear should point at the hidden-layer repeat meta return milestone")

	var archive_repeat: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 19,
		"kills": 372,
		"level_reached": 13,
		"gold": 210,
		"ore": 40,
		"alignment": 68.0,
		"route_style": "vanguard",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 92,
		"hidden_layer_reward_payload": {
			"track": "time_fragments",
			"time_fragments": 4,
			"rewind_charges": 1,
			"collection_bonus_awarded": false,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"summary": "Time Fragments +4 | Rewind +1 | Rift archive sealed"
		},
		"hidden_layer_reward_summary": "Time Fragments +4 | Rewind +1 | Rift archive sealed",
		"hidden_layer_gameplay": {
			"pressure_label": "Rift Surge",
			"pressure_stage": 2,
			"required_pressure_stage": 2,
			"survival_seconds": 33.0,
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
	var archive_returns: Array = archive_repeat.get("new_meta_return_unlocks", [])
	assert_eq(archive_returns.size(), 1, "re-clearing a hidden archive after sealing both layers should unlock one extra meta return milestone")
	assert_eq(str((archive_returns[0] as Dictionary).get("label", "")), "Archive Return", "hidden-layer repeat clear should unlock Archive Return")
	assert_eq(float(archive_repeat.get("meta_return_multiplier", 1.0)), 1.5, "Archive Return should raise the permanent multiplier to x1.50")
	assert_string_contains(str(archive_repeat.get("meta_return_summary", "")), "Return x1.50", "repeat hidden clear should persist the post-archive meta return summary")
	assert_string_contains(str(archive_repeat.get("meta_return_next_hint", "")), "Challenge Layer IV", "archive return should now point at the final apex meta return rung")

	var apex_clear: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 24,
		"kills": 266,
		"level_reached": 15,
		"gold": 180,
		"ore": 34,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL4",
		"challenge_layer_title": "Challenge Layer IV",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "apex_meta_cache",
		"challenge_layer_reward_title": "Apex Meta Cache",
		"challenge_layer_reward_payload": {
			"meta_bonus": 100,
			"sigils": 0,
			"insight": 0
		},
		"challenge_layer_reward_summary": "Apex archive sealed | Apex Meta Cache | Meta +100",
		"challenge_layer_settlement_summary": "The fourth settlement records the apex challenge clear for the final return frontier.",
		"challenge_layer_rooms_cleared": 5,
		"challenge_layer_kills": 0
	})
	var apex_returns: Array = apex_clear.get("new_meta_return_unlocks", [])
	assert_eq(apex_returns.size(), 1, "CL4 clear should unlock the final apex meta return milestone")
	assert_eq(str((apex_returns[0] as Dictionary).get("label", "")), "Apex Return", "CL4 clear should unlock Apex Return")
	assert_eq(float(apex_clear.get("meta_return_multiplier", 1.0)), 1.6, "Apex Return should raise the permanent multiplier to x1.60")
	assert_string_contains(str(apex_clear.get("meta_return_summary", "")), "Return x1.60", "CL4 clear should persist the final meta return summary")
	assert_string_contains(str(apex_clear.get("meta_return_next_hint", "")), "All meta returns unlocked", "Apex Return should complete the full meta return ladder")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	var shop_message_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/ShopMessageValue")
	assert_not_null(last_run_label, "last run label should exist")
	assert_not_null(shop_message_label, "shop message label should exist")
	if last_run_label == null or shop_message_label == null:
		return

	assert_string_contains(last_run_label.text, "NewReturn 1", "last run summary should surface new meta return unlock count")
	assert_string_contains(last_run_label.text, "Return x1.60", "last run summary should surface the permanent meta return multiplier")
	assert_string_contains(shop_message_label.text, "Return x1.60", "meta shop hint should surface the current meta return multiplier")
	assert_string_contains(shop_message_label.text, "Upgrade Cap 6/6", "meta shop hint should surface the fully unlocked upgrade cap")
	assert_string_contains(shop_message_label.text, "All meta returns unlocked", "meta shop hint should surface the final meta return state")
