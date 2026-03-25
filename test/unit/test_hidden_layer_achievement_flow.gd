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


func test_hidden_layer_clear_and_mastery_unlock_achievements_and_main_menu_lists_them() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
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
			"pressure_stage": 3,
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_complete": true,
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		}
	})
	assert_true((fs1_result.get("new_achievements", []) as Array).has("ach_fs1_archive"), "FS1 clear should unlock archive achievement")
	assert_true((fs1_result.get("new_achievements", []) as Array).has("ach_fs1_mastery"), "FS1 mastery should unlock mastery achievement")

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
			"trial_labels": [
				"Forge Trial I: Ore Tempering",
				"Forge Trial II: Ember Fold",
				"Forge Trial III: Frost Bind",
				"Forge Trial IV: Void Sunder",
				"Forge Trial V: Genesis Core"
			],
			"collection_complete": true,
			"mastery_label": "Forge Archive Mastered | Draft +1 | Merge +1 claimed"
		}
	})
	assert_true((fs2_result.get("new_achievements", []) as Array).has("ach_fs2_archive"), "FS2 clear should unlock archive achievement")
	assert_true((fs2_result.get("new_achievements", []) as Array).has("ach_fs2_mastery"), "FS2 mastery should unlock mastery achievement")

	var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
	assert_true(unlocked.has("ach_fs1_archive"), "FS1 archive achievement should persist")
	assert_true(unlocked.has("ach_fs1_mastery"), "FS1 mastery achievement should persist")
	assert_true(unlocked.has("ach_fs2_archive"), "FS2 archive achievement should persist")
	assert_true(unlocked.has("ach_fs2_mastery"), "FS2 mastery achievement should persist")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(last_run_label, "last run label should exist")
	if achievement_label == null or last_run_label == null:
		return

	assert_string_contains(achievement_label.text, "[x] Rift Archivist", "achievement list should show unlocked FS1 archive achievement")
	assert_string_contains(achievement_label.text, "[x] Echo Sovereign", "achievement list should show unlocked FS1 mastery achievement")
	assert_string_contains(achievement_label.text, "[x] Forge Archivist", "achievement list should show unlocked FS2 archive achievement")
	assert_string_contains(achievement_label.text, "[x] Genesis Perfected", "achievement list should show unlocked FS2 mastery achievement")
	assert_string_contains(achievement_label.text, "Progress: 11/20", "achievement list should show achievement completion progress")
	assert_string_contains(achievement_label.text, "Category Progress:", "achievement list should expose grouped progress summary")
	assert_string_contains(achievement_label.text, "- Run 7/8", "achievement list should summarize run achievement progress")
	assert_string_contains(achievement_label.text, "- Hidden Layer 4/5", "achievement list should summarize hidden-layer achievement progress")
	assert_string_contains(achievement_label.text, "- Difficulty 0/3", "achievement list should summarize difficulty achievement progress")
	assert_string_contains(achievement_label.text, "- Challenge Layer 0/4", "achievement list should summarize challenge-layer achievement progress")
	assert_string_contains(achievement_label.text, "Recent Group Breakdown:", "achievement list should summarize recent unlock groups")
	assert_string_contains(achievement_label.text, "- Run 2", "achievement list should count run unlocks inside the recent window")
	assert_string_contains(achievement_label.text, "- Hidden Layer 3", "achievement list should count hidden-layer unlocks inside the recent window")
	assert_string_contains(achievement_label.text, "- Difficulty 0", "achievement list should show zero recent difficulty unlocks when none are present")
	assert_string_contains(achievement_label.text, "- Challenge Layer 0", "achievement list should show zero recent challenge-layer unlocks when none are present")
	assert_string_contains(achievement_label.text, "Recent Unlocks (last 5):", "achievement list should expose recent achievement unlocks")
	assert_string_contains(achievement_label.text, "[Run] First Light", "recent achievement unlocks should label run-milestone achievements")
	assert_string_contains(achievement_label.text, "[Hidden Layer] Forge Archivist", "recent achievement unlocks should label hidden-layer archive achievements")
	assert_string_contains(achievement_label.text, "[Hidden Layer] Genesis Perfected", "recent achievement unlocks should label hidden-layer mastery achievements")
	assert_string_contains(achievement_label.text, "Endings Progress: 2/3", "achievement list should summarize ending completion progress")
	assert_string_contains(achievement_label.text, "Recent Endings:\n- Ending: BALANCE | Run #3 |", "achievement list should show recent ending unlocks newest first with timeline metadata")
	assert_string_contains(achievement_label.text, "\n- Ending: REDEEM | Run #2 |", "achievement list should show the older ending with timeline metadata")
	assert_string_contains(achievement_label.text, "Fragment progress: 0 / 39", "achievement list should summarize memory fragment progress even when none are unlocked")
	assert_string_contains(achievement_label.text, "Recent Fragments (last 5):\n-", "achievement list should expose an empty recent fragment section when no fragments are unlocked")
	assert_string_contains(last_run_label.text, "NewAch 2", "last run summary should surface new achievement burst count")


func test_difficulty_clear_progression_unlocks_achievements_and_main_menu_lists_them() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 6,
		"kills": 80,
		"level_reached": 6,
		"gold": 24,
		"ore": 4,
		"alignment": 0.0
	})
	SaveManager.update_runtime_settings({"difficulty_tier": 1})

	var hard_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 9,
		"kills": 120,
		"level_reached": 8,
		"gold": 48,
		"ore": 10,
		"alignment": 0.0,
		"difficulty_tier": 1
	})
	assert_true((hard_result.get("new_achievements", []) as Array).has("ach_hard_clear"), "Hard clear should unlock the Hard difficulty achievement")

	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 360,
		"level_reached": 13,
		"gold": 220,
		"ore": 44,
		"alignment": 72.0,
		"route_style": "vanguard",
		"difficulty_tier": 1,
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
			"pressure_stage": 3,
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_complete": true,
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		}
	})
	SaveManager.update_runtime_settings({"difficulty_tier": 2})

	var nightmare_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 19,
		"kills": 420,
		"level_reached": 14,
		"gold": 280,
		"ore": 56,
		"alignment": 0.0,
		"route_style": "neutral",
		"difficulty_tier": 2,
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
			"trial_labels": [
				"Forge Trial I: Ore Tempering",
				"Forge Trial II: Ember Fold",
				"Forge Trial III: Frost Bind",
				"Forge Trial IV: Void Sunder",
				"Forge Trial V: Genesis Core"
			],
			"collection_complete": true,
			"mastery_label": "Forge Archive Mastered | Draft +1 | Merge +1 claimed"
		}
	})
	assert_true((nightmare_result.get("new_achievements", []) as Array).has("ach_nightmare_clear"), "Nightmare clear should unlock the Nightmare clear achievement")
	assert_true((nightmare_result.get("new_achievements", []) as Array).has("ach_nightmare_hidden"), "Nightmare hidden-layer clear should unlock the hidden Nightmare achievement")

	var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
	assert_true(unlocked.has("ach_hard_clear"), "Hard clear achievement should persist")
	assert_true(unlocked.has("ach_nightmare_clear"), "Nightmare clear achievement should persist")
	assert_true(unlocked.has("ach_nightmare_hidden"), "Nightmare hidden clear achievement should persist")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(last_run_label, "last run label should exist")
	if achievement_label == null or last_run_label == null:
		return

	assert_string_contains(achievement_label.text, "[x] Steel Baptism", "achievement list should show unlocked Hard clear achievement")
	assert_string_contains(achievement_label.text, "[x] Nightmare Victor", "achievement list should show unlocked Nightmare clear achievement")
	assert_string_contains(achievement_label.text, "[x] Abyss Crowned", "achievement list should show unlocked Nightmare hidden clear achievement")
	assert_string_contains(achievement_label.text, "Progress: 14/20", "achievement list should update completion progress after difficulty clears")
	assert_string_contains(achievement_label.text, "Category Progress:", "achievement list should expose grouped progress summary after difficulty clears")
	assert_string_contains(achievement_label.text, "- Run 7/8", "achievement list should keep run achievement progress after difficulty clears")
	assert_string_contains(achievement_label.text, "- Hidden Layer 4/5", "achievement list should keep hidden-layer achievement progress after difficulty clears")
	assert_string_contains(achievement_label.text, "- Difficulty 3/3", "achievement list should summarize difficulty achievement progress after clears")
	assert_string_contains(achievement_label.text, "- Challenge Layer 0/4", "achievement list should keep challenge-layer achievement progress at zero before challenge clears")
	assert_string_contains(achievement_label.text, "Recent Group Breakdown:", "achievement list should summarize recent unlock groups after difficulty clears")
	assert_string_contains(achievement_label.text, "- Run 0", "achievement list should show zero recent run unlocks when the recent window is full of later groups")
	assert_string_contains(achievement_label.text, "- Hidden Layer 3", "achievement list should keep hidden-layer entries inside the recent window")
	assert_string_contains(achievement_label.text, "- Difficulty 2", "achievement list should count recent difficulty unlocks inside the recent window")
	assert_string_contains(achievement_label.text, "- Challenge Layer 0", "achievement list should show zero recent challenge-layer unlocks before any challenge clear milestone")
	assert_string_contains(achievement_label.text, "Recent Unlocks (last 5):", "achievement list should expose recent unlock history after difficulty clears")
	assert_string_contains(achievement_label.text, "[Difficulty] Nightmare Victor", "recent achievement unlocks should label the Nightmare clear milestone")
	assert_string_contains(achievement_label.text, "[Difficulty] Abyss Crowned", "recent achievement unlocks should label the hidden Nightmare milestone")
	assert_string_contains(achievement_label.text, "[Hidden Layer] Rift Archivist", "recent achievement unlocks should keep older hidden-layer entries when they remain inside the last-five window")
	assert_string_contains(achievement_label.text, "Endings Progress: 2/3", "achievement list should summarize ending completion progress after the unlocked endings persist")
	assert_string_contains(achievement_label.text, "Recent Endings:\n- Ending: REDEEM | Run #4 |", "achievement list should show recent ending unlocks newest first for the current profile with timeline metadata")
	assert_string_contains(achievement_label.text, "\n- Ending: BALANCE | Run #2 |", "achievement list should show the prior ending with timeline metadata for the current profile")
	assert_string_contains(achievement_label.text, "Fragment progress: 0 / 39", "achievement list should summarize memory fragment progress when the run did not unlock any fragments")
	assert_string_contains(achievement_label.text, "Recent Fragments (last 5):\n-", "achievement list should show an empty recent fragment section when no fragments were unlocked")
	assert_string_contains(last_run_label.text, "NewAch 4", "last run summary should surface the full Nightmare hidden-layer burst count")


func test_archive_return_and_challenge_layer_clears_expand_achievement_groups() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
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
			"pressure_stage": 3,
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"],
			"collection_complete": true,
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
			"trial_labels": [
				"Forge Trial I: Ore Tempering",
				"Forge Trial II: Ember Fold",
				"Forge Trial III: Frost Bind",
				"Forge Trial IV: Void Sunder",
				"Forge Trial V: Genesis Core"
			],
			"collection_complete": true,
			"mastery_label": "Forge Archive Mastered | Draft +1 | Merge +1 claimed"
		}
	})
	var archive_return_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 19,
		"kills": 300,
		"level_reached": 13,
		"gold": 230,
		"ore": 46,
		"alignment": 72.0,
		"route_style": "vanguard",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 80,
		"hidden_layer_reward_payload": {
			"track": "time_fragments",
			"time_fragments": 3,
			"rewind_charges": 1,
			"collection_bonus_awarded": false,
			"collection_bonus_label": "Rewind +1 | Time Fragments +2",
			"summary": "Time Fragments +3 | Rewind +1 | Rift archive sealed"
		},
		"hidden_layer_reward_summary": "Time Fragments +3 | Rewind +1 | Rift archive sealed",
		"hidden_layer_gameplay": {
			"pressure_stage": 2,
			"boss_echo_collection": ["boss_rock_colossus", "boss_flame_lord"],
			"collection_complete": false,
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 ready"
		}
	})
	assert_true((archive_return_result.get("new_achievements", []) as Array).has("ach_archive_return"), "repeating hidden-layer clears after sealing both archives should unlock the Archive Return achievement")

	var cl1_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 12,
		"kills": 140,
		"level_reached": 9,
		"gold": 88,
		"ore": 14,
		"alignment": 0.0,
		"challenge_layer_id": "CL1",
		"challenge_layer_title": "Challenge Layer",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "meta_cache",
		"challenge_layer_reward_title": "Meta Cache",
		"challenge_layer_reward_payload": {
			"meta_bonus": 40,
			"sigils": 0,
			"insight": 0
		},
		"challenge_layer_reward_summary": "Challenge archive sealed | Meta Cache | Meta +40",
		"challenge_layer_settlement_summary": "The settlement records this challenge clear for the next postgame step.",
		"challenge_layer_rooms_cleared": 2,
		"challenge_layer_kills": 24
	})
	assert_true((cl1_result.get("new_achievements", []) as Array).has("ach_cl1_clear"), "first CL1 clear should unlock the first challenge-layer achievement")

	var cl2_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 15,
		"kills": 188,
		"level_reached": 10,
		"gold": 112,
		"ore": 22,
		"alignment": 0.0,
		"challenge_layer_id": "CL2",
		"challenge_layer_title": "Challenge Layer II",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "insight_bundle",
		"challenge_layer_reward_title": "Insight Bundle",
		"challenge_layer_reward_payload": {
			"meta_bonus": 0,
			"sigils": 0,
			"insight": 2
		},
		"challenge_layer_reward_summary": "Crucible archive sealed | Insight Bundle | Insight +2",
		"challenge_layer_settlement_summary": "The second settlement records a deeper challenge clear for the next archive horizon.",
		"challenge_layer_rooms_cleared": 3,
		"challenge_layer_kills": 36
	})
	assert_true((cl2_result.get("new_achievements", []) as Array).has("ach_cl2_clear"), "first CL2 clear should unlock the second challenge-layer achievement")

	var cl3_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 224,
		"level_reached": 12,
		"gold": 136,
		"ore": 28,
		"alignment": 0.0,
		"challenge_layer_id": "CL3",
		"challenge_layer_title": "Challenge Layer III",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "sigil_matrix",
		"challenge_layer_reward_title": "Sigil Matrix",
		"challenge_layer_reward_payload": {
			"meta_bonus": 0,
			"sigils": 3,
			"insight": 0
		},
		"challenge_layer_reward_summary": "Sovereign archive sealed | Sigil Matrix | Sigil +3",
		"challenge_layer_settlement_summary": "The third settlement records a sovereign challenge clear for the final archive frontier.",
		"challenge_layer_rooms_cleared": 4,
		"challenge_layer_kills": 42
	})
	assert_true((cl3_result.get("new_achievements", []) as Array).has("ach_cl3_clear"), "first CL3 clear should unlock the third challenge-layer achievement")

	var cl4_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 22,
		"kills": 248,
		"level_reached": 14,
		"gold": 162,
		"ore": 32,
		"alignment": 0.0,
		"challenge_layer_id": "CL4",
		"challenge_layer_title": "Challenge Layer IV",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "insight_throne",
		"challenge_layer_reward_title": "Insight Throne",
		"challenge_layer_reward_payload": {
			"meta_bonus": 0,
			"sigils": 0,
			"insight": 4
		},
		"challenge_layer_reward_summary": "Apex archive sealed | Insight Throne | Insight +4",
		"challenge_layer_settlement_summary": "The fourth settlement records the apex challenge clear for the final return frontier.",
		"challenge_layer_rooms_cleared": 5,
		"challenge_layer_kills": 48
	})
	assert_true((cl4_result.get("new_achievements", []) as Array).has("ach_cl4_clear"), "first CL4 clear should unlock the fourth challenge-layer achievement")

	var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
	assert_true(unlocked.has("ach_archive_return"), "Archive Return achievement should persist")
	assert_true(unlocked.has("ach_cl1_clear"), "CL1 clear achievement should persist")
	assert_true(unlocked.has("ach_cl2_clear"), "CL2 clear achievement should persist")
	assert_true(unlocked.has("ach_cl3_clear"), "CL3 clear achievement should persist")
	assert_true(unlocked.has("ach_cl4_clear"), "CL4 clear achievement should persist")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(last_run_label, "last run label should exist")
	if achievement_label == null or last_run_label == null:
		return

	assert_string_contains(achievement_label.text, "[x] Archive Echo", "achievement list should show the hidden-layer repeat achievement")
	assert_string_contains(achievement_label.text, "[x] Archive Initiate", "achievement list should show the first challenge-layer achievement")
	assert_string_contains(achievement_label.text, "[x] Crown Archivist", "achievement list should show the second challenge-layer achievement")
	assert_string_contains(achievement_label.text, "[x] Sovereign Curator", "achievement list should show the third challenge-layer achievement")
	assert_string_contains(achievement_label.text, "[x] Apex Archivist", "achievement list should show the fourth challenge-layer achievement")
	assert_string_contains(achievement_label.text, "Progress: 16/20", "achievement list should include the expanded Stage 6 achievement total")
	assert_string_contains(achievement_label.text, "- Hidden Layer 5/5", "achievement list should show the expanded hidden-layer achievement group")
	assert_string_contains(achievement_label.text, "- Challenge Layer 4/4", "achievement list should show the expanded challenge-layer achievement group")
	assert_string_contains(achievement_label.text, "- Challenge Layer 4", "recent achievement group breakdown should count the recent challenge-layer unlocks")
	assert_string_contains(achievement_label.text, "[Hidden Layer] Archive Echo", "recent achievement unlocks should label the hidden-layer repeat milestone")
	assert_string_contains(achievement_label.text, "[Challenge Layer] Archive Initiate", "recent achievement unlocks should label the first challenge-layer milestone")
	assert_string_contains(achievement_label.text, "[Challenge Layer] Crown Archivist", "recent achievement unlocks should label the second challenge-layer milestone")
	assert_string_contains(achievement_label.text, "[Challenge Layer] Sovereign Curator", "recent achievement unlocks should label the third challenge-layer milestone")
	assert_string_contains(achievement_label.text, "[Challenge Layer] Apex Archivist", "recent achievement unlocks should label the fourth challenge-layer milestone")
	assert_string_contains(last_run_label.text, "NewAch 1", "last run summary should surface the final challenge-layer achievement burst count")


func test_recent_endings_follow_actual_unlock_order_in_achievement_list_and_review_archive() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 7,
		"kills": 96,
		"level_reached": 7,
		"gold": 30,
		"ore": 6,
		"alignment": 0.0
	})
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 8,
		"kills": 118,
		"level_reached": 8,
		"gold": 36,
		"ore": 8,
		"alignment": -72.0
	})
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 9,
		"kills": 132,
		"level_reached": 9,
		"gold": 44,
		"ore": 10,
		"alignment": 72.0
	})

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	menu.call("_refresh_ending_review")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var ending_review_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/EndingReviewValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(ending_review_label, "ending review label should exist")
	if achievement_label == null or ending_review_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Endings:\n- Ending: REDEEM | Run #4 |", "recent endings should list the newest unlocked ending first using actual unlock order and timeline metadata")
	assert_string_contains(achievement_label.text, "\n- Ending: FALL | Run #3 |", "recent endings should include the second-most-recent ending with timeline metadata")
	assert_string_contains(achievement_label.text, "\n- Ending: BALANCE | Run #2 |", "recent endings should include the earliest ending in the recent block with timeline metadata")
	assert_string_contains(ending_review_label.text, "Ending Archive (1/3)\nEnding: BALANCE", "ending review should start from the earliest unlocked ending in archive order")
	menu.call("_on_review_ending_button_pressed")
	assert_string_contains(ending_review_label.text, "Ending Archive (2/3)\nEnding: FALL", "ending review should advance following the actual unlock sequence")
	menu.call("_on_review_ending_button_pressed")
	assert_string_contains(ending_review_label.text, "Ending Archive (3/3)\nEnding: REDEEM", "ending review should keep the newest unlock last in the forward archive cycle")


func test_recent_fragments_follow_explicit_unlock_metadata_in_achievement_list_and_review_archive() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["unlocked_fragments"] = ["memory_fs1_redeem", "memory_ch1_boss", "memory_camp_oracle"]
	meta["fragment_meta"] = {
		"memory_ch1_boss": {
			"fragment_id": "memory_ch1_boss",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"memory_camp_oracle": {
			"fragment_id": "memory_camp_oracle",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"memory_fs1_redeem": {
			"fragment_id": "memory_fs1_redeem",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	menu.call("_refresh_fragment_review")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var fragment_review_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/FragmentReviewValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(fragment_review_label, "fragment review label should exist")
	if achievement_label == null or fragment_review_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Fragments (last 5):\n- Fragment XXXV: Choir Beneath the Rift | Run #3 | 2026-03-20T10:00:00\n- Fragment XXXIII: Quiet Beneath Embers | Run #2 | 2026-03-20T09:00:00\n- Fragment I: Chapel Ash | Run #1 | 2026-03-20T08:00:00", "recent fragments should list newest unlocks first using explicit fragment metadata and timeline suffixes")
	assert_string_contains(fragment_review_label.text, "Memory Archive (1/3)\nFragment I: Chapel Ash", "fragment review should start from the earliest unlocked fragment in archive order")
	assert_string_contains(fragment_review_label.text, "Unlocked: Run #1 | 2026-03-20T08:00:00", "fragment review should expose unlock timeline metadata for the current archive entry")
	menu.call("_on_review_fragment_button_pressed")
	assert_string_contains(fragment_review_label.text, "Memory Archive (2/3)\nFragment XXXIII: Quiet Beneath Embers", "fragment review should advance using the explicit fragment unlock order")
	assert_string_contains(fragment_review_label.text, "Unlocked: Run #2 | 2026-03-20T09:00:00", "fragment review should update timeline metadata when cycling forward")
	menu.call("_on_review_fragment_button_pressed")
	assert_string_contains(fragment_review_label.text, "Memory Archive (3/3)\nFragment XXXV: Choir Beneath the Rift", "fragment review should keep the newest fragment last in the forward archive cycle")
	assert_string_contains(fragment_review_label.text, "Unlocked: Run #3 | 2026-03-20T10:00:00", "fragment review should keep the newest fragment timeline metadata aligned with the archive cursor")


func test_recent_fragments_show_run_index_and_timestamp_metadata() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["unlocked_fragments"] = ["memory_fs1_redeem", "memory_ch1_boss", "memory_camp_oracle"]
	meta["fragment_meta"] = {
		"memory_ch1_boss": {
			"fragment_id": "memory_ch1_boss",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"memory_camp_oracle": {
			"fragment_id": "memory_camp_oracle",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"memory_fs1_redeem": {
			"fragment_id": "memory_fs1_redeem",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	if achievement_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Fragments (last 5):\n- Fragment XXXV: Choir Beneath the Rift | Run #3 | 2026-03-20T10:00:00\n- Fragment XXXIII: Quiet Beneath Embers | Run #2 | 2026-03-20T09:00:00\n- Fragment I: Chapel Ash | Run #1 | 2026-03-20T08:00:00", "recent fragments should show newest-first timeline metadata in the achievement list")
	assert_string_contains(achievement_label.text, "[x] Fragment I: Chapel Ash | Run #1 | 2026-03-20T08:00:00", "unlocked fragment rows should expose the earliest fragment timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Fragment XXXIII: Quiet Beneath Embers | Run #2 | 2026-03-20T09:00:00", "unlocked fragment rows should expose mid-sequence fragment timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Fragment XXXV: Choir Beneath the Rift | Run #3 | 2026-03-20T10:00:00", "unlocked fragment rows should expose the newest fragment timeline metadata")


func test_recent_endings_follow_explicit_unlock_metadata_in_achievement_list_and_review_archive() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["unlocked_endings"] = ["nar_ending_redeem", "nar_ending_balance", "nar_ending_fall"]
	meta["ending_meta"] = {
		"nar_ending_balance": {
			"ending_id": "nar_ending_balance",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"nar_ending_fall": {
			"ending_id": "nar_ending_fall",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"nar_ending_redeem": {
			"ending_id": "nar_ending_redeem",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	menu.call("_refresh_ending_review")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	var ending_review_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/EndingReviewValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	assert_not_null(ending_review_label, "ending review label should exist")
	if achievement_label == null or ending_review_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Endings:\n- Ending: REDEEM | Run #3 | 2026-03-20T10:00:00\n- Ending: FALL | Run #2 | 2026-03-20T09:00:00\n- Ending: BALANCE | Run #1 | 2026-03-20T08:00:00", "recent endings should use explicit ending metadata for newest-first ordering")
	assert_string_contains(ending_review_label.text, "Ending Archive (1/3)\nEnding: BALANCE", "ending review should start from the earliest unlocked ending from metadata order")
	assert_string_contains(ending_review_label.text, "Unlocked: Run #1 | 2026-03-20T08:00:00", "ending review should expose unlock timeline metadata for the current archive entry")
	menu.call("_on_review_ending_button_pressed")
	assert_string_contains(ending_review_label.text, "Ending Archive (2/3)\nEnding: FALL", "ending review should advance using the explicit ending unlock order")
	assert_string_contains(ending_review_label.text, "Unlocked: Run #2 | 2026-03-20T09:00:00", "ending review should update timeline metadata when cycling forward")
	menu.call("_on_review_ending_button_pressed")
	assert_string_contains(ending_review_label.text, "Ending Archive (3/3)\nEnding: REDEEM", "ending review should keep the newest ending last in the forward archive cycle")
	assert_string_contains(ending_review_label.text, "Unlocked: Run #3 | 2026-03-20T10:00:00", "ending review should keep the newest ending timeline metadata aligned with the archive cursor")


func test_recent_achievement_unlocks_show_run_index_and_timestamp_metadata() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["unlocked_achievements"] = ["ach_nightmare_hidden", "ach_first_clear", "ach_fs1_archive"]
	meta["achievement_meta"] = {
		"ach_first_clear": {
			"achievement_id": "ach_first_clear",
			"condition": "clear_floor_1",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"ach_fs1_archive": {
			"achievement_id": "ach_fs1_archive",
			"condition": "hidden_layer_clear_fs1",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"ach_nightmare_hidden": {
			"achievement_id": "ach_nightmare_hidden",
			"condition": "difficulty_hidden_clear_nightmare",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	if achievement_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Unlocks (last 5):\n- [Difficulty] Abyss Crowned | Run #3 | 2026-03-20T10:00:00\n- [Hidden Layer] Rift Archivist | Run #2 | 2026-03-20T09:00:00\n- [Run] First Light | Run #1 | 2026-03-20T08:00:00", "recent achievement unlocks should expose explicit run and timestamp metadata in newest-first order")
	assert_string_contains(achievement_label.text, "[x] First Light | Run #1 | 2026-03-20T08:00:00", "unlocked achievement rows should expose the earliest achievement timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Rift Archivist | Run #2 | 2026-03-20T09:00:00", "unlocked achievement rows should expose hidden-layer achievement timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Abyss Crowned | Run #3 | 2026-03-20T10:00:00", "unlocked achievement rows should expose the newest achievement timeline metadata")


func test_recent_endings_show_run_index_and_timestamp_metadata() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var meta: Dictionary = SaveManager.get_meta_data()
	meta["unlocked_endings"] = ["nar_ending_redeem", "nar_ending_balance", "nar_ending_fall"]
	meta["ending_meta"] = {
		"nar_ending_balance": {
			"ending_id": "nar_ending_balance",
			"discovered_at": "2026-03-20T08:00:00",
			"run_index": 1
		},
		"nar_ending_fall": {
			"ending_id": "nar_ending_fall",
			"discovered_at": "2026-03-20T09:00:00",
			"run_index": 2
		},
		"nar_ending_redeem": {
			"ending_id": "nar_ending_redeem",
			"discovered_at": "2026-03-20T10:00:00",
			"run_index": 3
		}
	}
	SaveManager.set("_meta", meta)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	menu.call("_refresh_achievement_list")
	var achievement_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/AchievementListValue")
	assert_not_null(achievement_label, "achievement list label should exist")
	if achievement_label == null:
		return

	assert_string_contains(achievement_label.text, "Recent Endings:\n- Ending: REDEEM | Run #3 | 2026-03-20T10:00:00\n- Ending: FALL | Run #2 | 2026-03-20T09:00:00\n- Ending: BALANCE | Run #1 | 2026-03-20T08:00:00", "recent endings should expose explicit run and timestamp metadata in newest-first order")
	assert_string_contains(achievement_label.text, "[x] Redeem | Run #3 | 2026-03-20T10:00:00", "redeem ending row should expose the newest ending timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Fall | Run #2 | 2026-03-20T09:00:00", "fall ending row should expose the middle ending timeline metadata")
	assert_string_contains(achievement_label.text, "[x] Balance | Run #1 | 2026-03-20T08:00:00", "balance ending row should expose the earliest ending timeline metadata")


func test_last_run_summary_surfaces_fragment_recap_title_and_counts() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 15,
		"kills": 250,
		"level_reached": 11,
		"gold": 120,
		"ore": 20,
		"alignment": 68.0,
		"route_style": "vanguard",
		"fragment_triggers": [{
			"chapter_id": "chapter_3",
			"trigger_type": "camp",
			"arc_id": "redeem",
			"style": "vanguard",
			"fragment_id": "memory_ch3_transition_halo",
			"fragment_title": "Fragment XII: White Across the Threshold",
			"fragment_text": "A bell note survives the crossing.",
			"newly_unlocked": true,
			"room_index": 10
		}]
	})
	var meta: Dictionary = SaveManager.get_meta_data()
	var last_run: Dictionary = SaveManager.get_last_run()
	last_run["hidden_layer_story"] = {
		"layer_id": "FS1",
		"arc_id": "redeem",
		"style": "vanguard",
		"style_echo": "Vanguard routes favor safer pressure and disciplined pacing.",
		"title": "Time Rift: Choir Refrain",
		"body": "Grace survives the fracture by returning as rhythm: a choir hidden below the ward, answering every vow you carried into the broken hours.",
		"archive_echo": "The undercrypt remembers which promises held when time itself started to split.",
		"ending_id": "nar_ending_redeem",
		"ending_link": "nar_ending_redeem",
		"ending_ready": true,
		"fragment_id": "memory_fs1_redeem",
		"fragment_title": "Fragment XXXV: Choir Beneath the Rift",
		"fragment_text": "The choir answered from below the ward, proving that vows kept in the upper halls can still echo through the fractures under time itself.",
		"fragment_newly_unlocked": true
	}
	last_run["hidden_layer_statuses"] = {
		"FS1": {
			"title": "Time Rift",
			"unlocked": true,
			"progress_label": "Flawless Boss Route 3/3",
			"detail": "Clear chapter bosses 1-3 in one victorious run without losing HP.",
			"entry_hint": "When the chapter_3 boss falls flawlessly, the camp altar can refract into the rift.",
			"reward_summary": "Time Fragments crystallize into one Rewind charge for the archive.",
			"settlement_summary": "Archive survival time, fragments, and one Rewind charge before returning.",
			"record_label": "Clears 1 | Best Rooms 3 | Time Fragments 5 | Rewind 2",
			"story_label": "Time Rift: Choir Refrain | Fragment XXXV: Choir Beneath the Rift | REDEEM",
			"gameplay_label": "Pressure 3 | Hold 46.0s | Echo Frost King",
			"collection_label": "Echoes 4/4 | Rock Colossus, Flame Lord, Frost King, Void Lord",
			"mastery_label": "Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed"
		},
		"FS2": {
			"title": "Genesis Forge",
			"unlocked": false,
			"progress_label": "Boss Relics 0/4"
		}
	}
	last_run["new_hidden_layers"] = []
	last_run["hidden_layer_id"] = "FS1"
	last_run["hidden_layer_reward_summary"] = "Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2"
	last_run["hidden_layer_gameplay"] = {
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
	last_run["hidden_layer_record"] = {
		"attempts": 1,
		"clears": 1,
		"best_rooms_cleared": 3
	}
	last_run["challenge_layer_id"] = "CL1"
	last_run["challenge_layer_title"] = "Challenge Layer"
	last_run["challenge_layer_phase"] = "settlement"
	last_run["challenge_layer_reward_title"] = "Meta Cache"
	last_run["challenge_layer_reward_summary"] = "Challenge archive sealed | Meta Cache | Meta +40"
	last_run["challenge_layer_record"] = {
		"attempts": 2,
		"clears": 1,
		"best_rooms": 2
	}
	last_run["narrative_choices"] = [
		{
			"chapter_id": "chapter_1",
			"segment_id": "camp_intro",
			"choice_id": "choose_mercy",
			"alignment_delta": 8.0
		},
		{
			"chapter_id": "chapter_2",
			"segment_id": "route_split",
			"choice_id": "take_oath",
			"alignment_delta": 12.0
		}
	]
	last_run["chapter_route_styles"] = {
		"chapter_1": "vanguard",
		"chapter_2": "raider",
		"chapter_3": "vanguard",
		"chapter_4": "neutral"
	}
	last_run["route_style_timeline"] = [
		{
			"room_index": 4,
			"chapter_id": "chapter_1",
			"style_id": "vanguard",
			"selected_slot": 0
		},
		{
			"room_index": 9,
			"chapter_id": "chapter_2",
			"style_id": "raider",
			"selected_slot": 2
		}
	]
	last_run["chapter_effect_timeline"] = [
		{
			"room_index": 3,
			"chapter_id": "chapter_1",
			"icon": "[+]",
			"title": "Shrine of Grace",
			"duration_rooms": 2,
			"desc": "Blessed relic prices fall.",
			"score": 1.0
		},
		{
			"room_index": 8,
			"chapter_id": "chapter_2",
			"icon": "[-]",
			"title": "Ashen Tax",
			"duration_rooms": 1,
			"desc": "Forge tolls rise for one room.",
			"score": -1.0
		},
		{
			"room_index": 12,
			"chapter_id": "chapter_3",
			"icon": "[~]",
			"title": "Echo Balance",
			"duration_rooms": 2,
			"desc": "Neutral echoes stabilize memory drift.",
			"score": 0.0
		}
	]
	last_run["new_achievements"] = [
		"ach_first_clear",
		"ach_fs1_archive",
		"ach_nightmare_hidden"
	]
	last_run["new_codex_unlocks"] = [
		{
			"category": "archives",
			"entry_id": "fs1_echo_archive",
			"source": "hidden_layer_clear"
		},
		{
			"category": "archives",
			"entry_id": "fs2_trial_mastery",
			"source": "hidden_layer_mastery"
		},
		{
			"category": "archives",
			"entry_id": "nightmare_hidden_archive",
			"source": "difficulty_hidden_clear"
		}
	]
	last_run["new_difficulty_unlocks"] = [
		{
			"tier": 2,
			"label": "Nightmare"
		}
	]
	last_run["new_meta_return_unlocks"] = [
		{
			"label": "Echo Dividend",
			"bonus_text": "Meta +15%"
		}
	]
	last_run["meta_return_summary"] = "Return x1.25"
	last_run["meta_return_next_hint"] = "Next milestone: clear one hidden layer without taking damage."
	last_run["fragment_triggers"] = [
		{
			"chapter_id": "chapter_3",
			"trigger_type": "camp",
			"fragment_id": "memory_ch3_transition_halo",
			"fragment_title": "Fragment XII: White Across the Threshold",
			"newly_unlocked": true
		},
		{
			"chapter_id": "chapter_fs1",
			"trigger_type": "hidden_layer",
			"fragment_id": "memory_fs1_redeem",
			"fragment_title": "Fragment XXXV: Choir Beneath the Rift",
			"newly_unlocked": false
		}
	]
	meta["last_run"] = last_run
	SaveManager.set("_meta", meta)
	SaveManager.set("_last_run", last_run)

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return

	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	var ending_review_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/EndingReviewValue")
	assert_not_null(last_run_label, "last run label should exist")
	assert_not_null(ending_review_label, "ending review label should exist")
	if last_run_label == null or ending_review_label == null:
		return

	assert_string_contains(last_run_label.text, "FragRecap Grace Ledger 1/1", "last run summary should surface fragment recap title and trigger/new counts")
	assert_string_contains(last_run_label.text, "Recap Stats: triggers=1 | new=1", "last run summary should surface fragment recap stats block")
	assert_string_contains(last_run_label.text, "Recap: Redeem triggers resolve as a ledger of rescued vows, revealing how camp choices soften later endings.", "last run summary should surface fragment recap summary text")
	assert_string_contains(last_run_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "last run summary should surface fragment recap route echo")
	assert_string_contains(last_run_label.text, "Pace: Chapter transitions and camp reflections are the fastest way to complete the choir-side fragment chain.", "last run summary should surface fragment recap pace guidance")
	assert_string_contains(last_run_label.text, "Trigger Focus: CAMP", "last run summary should surface fragment recap trigger focus")
	assert_string_contains(last_run_label.text, "Review Entry: Memory Altar -> Archive Recap", "last run summary should point players to the fragment recap review entry")
	assert_string_contains(last_run_label.text, "Hidden Route: FS1 -> Choir Undercrypt [READY]", "last run summary should surface the hidden route lead")
	assert_string_contains(last_run_label.text, "Hidden Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "last run summary should surface the hidden route echo")
	assert_string_contains(last_run_label.text, "Hidden Review Entry: Memory Altar -> Hidden Route Lead", "last run summary should point players to the hidden route review entry")
	assert_string_contains(last_run_label.text, "Epilogue Branch: Choir Restored [FIRST]", "last run summary should surface the active epilogue branch title and mode")
	assert_string_contains(last_run_label.text, "Branch Echo: Vanguard routes favor safer pressure and disciplined pacing.", "last run summary should surface the epilogue branch route echo")
	assert_string_contains(last_run_label.text, "Archive Hook: The altar now archives choir-side threads that point toward a sealed path beneath the first ward.", "last run summary should surface the epilogue archive hook")
	assert_string_contains(last_run_label.text, "Branch Review Entry: Ending Archive -> Current Ending", "last run summary should point players to the epilogue branch review entry")
	assert_string_contains(last_run_label.text, "Ending Payoff: Grace Restored", "last run summary should surface the active ending payoff title")
	assert_string_contains(last_run_label.text, "Payoff Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "last run summary should surface the ending payoff route echo")
	assert_string_contains(last_run_label.text, "Legacy: The camp survives because you chose to carry everyone through the last threshold, not just yourself.", "last run summary should surface the ending payoff legacy")
	assert_string_contains(last_run_label.text, "Fragment Hook: Redeem endings complete the choir-side fragment chain and strengthen shrine/survivor memory routes.", "last run summary should surface the ending payoff fragment hook")
	assert_string_contains(last_run_label.text, "Payoff Review Entry: Ending Archive -> Current Ending", "last run summary should point players to the ending payoff review entry")
	assert_string_contains(last_run_label.text, "Epilogue: At dawn, the camp bells ring again. Survivors whisper your true name and the first altar rekindles.", "last run summary should surface the active ending epilogue text")
	assert_string_contains(last_run_label.text, "Epilogue Review Entry: Ending Archive -> Current Ending", "last run summary should point players to the epilogue review entry")
	assert_string_contains(last_run_label.text, "Epilogue Chain:", "last run summary should surface the latest ending epilogue chain")
	assert_string_contains(last_run_label.text, "- At first light the choir returns to the camp in broken harmony, answering the vows you carried through the final gate.", "last run summary should list the first epilogue chain beat")
	assert_string_contains(last_run_label.text, "- The survivors rebuild the first ward with your fragments laid into the stone, turning memory into shelter.", "last run summary should list the middle epilogue chain beat")
	assert_string_contains(last_run_label.text, "Chain Review Entry: Ending Archive -> Current Ending", "last run summary should point players to the epilogue chain review entry")
	assert_string_contains(last_run_label.text, "Hidden Story: FS1 -> Time Rift: Choir Refrain [REDEEM]", "last run summary should surface the hidden-layer story title and arc")
	assert_string_contains(last_run_label.text, "Story Body: Grace survives the fracture by returning as rhythm: a choir hidden below the ward, answering every vow you carried into the broken hours.", "last run summary should surface the hidden-layer story body")
	assert_string_contains(last_run_label.text, "Story Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "last run summary should surface the hidden-layer story route echo")
	assert_string_contains(last_run_label.text, "Story Archive Echo: The undercrypt remembers which promises held when time itself started to split.", "last run summary should surface the hidden-layer archive echo")
	assert_string_contains(last_run_label.text, "Story Ending Link: REDEEM [READY]", "last run summary should surface the hidden-layer story ending link")
	assert_string_contains(last_run_label.text, "Story Fragment Archive: Fragment XXXV: Choir Beneath the Rift [NEW]", "last run summary should surface the hidden-layer story fragment archive row")
	assert_string_contains(last_run_label.text, "Story Fragment Text: The choir answered from below the ward, proving that vows kept in the upper halls can still echo through the fractures under time itself.", "last run summary should surface the hidden-layer story fragment text")
	assert_string_contains(last_run_label.text, "Story Review Entry: Memory Altar -> Hidden Layer Track", "last run summary should point players to the hidden-layer story review entry")
	assert_string_contains(last_run_label.text, "Hidden Layers:", "last run summary should surface hidden-layer status tracking")
	assert_string_contains(last_run_label.text, "FS1 -> Time Rift [UNLOCKED]", "last run summary should surface the FS1 hidden-layer status row")
	assert_string_contains(last_run_label.text, "Entry: When the chapter_3 boss falls flawlessly, the camp altar can refract into the rift.", "last run summary should surface the hidden-layer entry hint")
	assert_string_contains(last_run_label.text, "Reward: Time Fragments crystallize into one Rewind charge for the archive.", "last run summary should surface the hidden-layer reward summary")
	assert_string_contains(last_run_label.text, "Settlement: Archive survival time, fragments, and one Rewind charge before returning.", "last run summary should surface the hidden-layer settlement summary")
	assert_string_contains(last_run_label.text, "Review Entry: Memory Altar -> Hidden Layer Track", "last run summary should point players to the hidden-layer track review entry")
	assert_string_contains(last_run_label.text, "Hidden Clear: FS1 completion archived", "last run summary should surface the active hidden-layer clear archive header")
	assert_string_contains(last_run_label.text, "Reward Cache: Time Fragments +5 | Rewind +2 | Rift archive sealed | Mastery Rewind +1 | Time Fragments +2", "last run summary should surface the active hidden-layer reward cache summary")
	assert_string_contains(last_run_label.text, "Pressure: Rift Surge 3/3 | Hold 46.0s | Echo Frost King", "last run summary should surface the active hidden-layer pressure summary")
	assert_string_contains(last_run_label.text, "Collection: Echoes 4/4 | Rock Colossus, Flame Lord, Frost King, Void Lord", "last run summary should surface the active hidden-layer echo collection summary")
	assert_string_contains(last_run_label.text, "Mastery: Echo Archive Mastered | Rewind +1 | Time Fragments +2 claimed", "last run summary should surface the active hidden-layer mastery summary")
	assert_string_contains(last_run_label.text, "Archive Stats: attempts=1 | clears=1 | best_rooms=3", "last run summary should surface the active hidden-layer archive stats")
	assert_string_contains(last_run_label.text, "Challenge Layer:", "last run summary should mirror the active challenge-layer archive header")
	assert_string_contains(last_run_label.text, "CL1 -> Challenge Layer", "last run summary should mirror the active challenge-layer title")
	assert_string_contains(last_run_label.text, "Phase: Settlement", "last run summary should mirror the active challenge-layer phase")
	assert_string_contains(last_run_label.text, "Reward Choice: Meta Cache", "last run summary should mirror the active challenge-layer reward choice")
	assert_string_contains(last_run_label.text, "Difficulty tuning: Haz x1.00 | G x1.00 | O x1.00 | T x1.00", "last run summary should mirror the active challenge-layer difficulty tuning")
	assert_string_contains(last_run_label.text, "Challenge archive sealed | Meta Cache | Meta +40", "last run summary should mirror the active challenge-layer reward summary")
	assert_string_contains(last_run_label.text, "Archive Stats: attempts=2 | clears=1 | best_rooms=2 | best_kills=0", "last run summary should mirror the active challenge-layer archive stats")
	assert_string_contains(last_run_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +0", "last run summary should mirror the active challenge-layer reward ledger")
	assert_string_contains(last_run_label.text, "Fragments:\nUnlocked: Fragment XII: White Across the Threshold [chapter_3/camp]\nEchoed: Fragment XXXV: Choir Beneath the Rift [chapter_fs1/hidden_layer]", "last run summary should mirror the run-result fragment trigger block")
	assert_string_contains(last_run_label.text, "Burst Unlocks:\nAchievement: First Light\nAchievement: Rift Archivist\nAchievement: Abyss Crowned\nCodex: [Archives] Time Rift Archive (Hidden Layer Clear)\nCodex: [Archives] Genesis Forge Mastery (Hidden Layer Mastery)\nCodex: [Archives] Nightmare Hidden Archive (Nightmare Hidden Clear)\nDifficulty: Nightmare unlocked\nMeta Return: Echo Dividend (Meta +15%)", "last run summary should mirror the burst unlock rows from the run result panel")
	assert_string_contains(last_run_label.text, "Meta Return:\nReturn x1.25\nNext milestone: clear one hidden layer without taking damage.", "last run summary should mirror the meta return summary and next hint block")
	assert_string_contains(last_run_label.text, "Narrative Choices:\n- chapter_1 / camp_intro -> choose_mercy (+8)\n- chapter_2 / route_split -> take_oath (+12)", "last run summary should surface narrative choice history")
	assert_string_contains(last_run_label.text, "Route Style Evolution:\n  CH1:VANGUARD | CH2:RAIDER | CH3:VANGUARD | CH4:NEUTRAL\nLocks:\n- R4 chapter_1 -> VANGUARD (slot 1)\n- R9 chapter_2 -> RAIDER (slot 3)", "last run summary should surface route style evolution and lock timeline")
	assert_string_contains(last_run_label.text, "[ALL] Chapter Effect Timeline: Full Replay\nSegments -> BOON:1  CURSE:1  MIXED:1\n- R3 chapter_1 [+] Shrine of Grace (2R) | Blessed relic prices fall.\n- R8 chapter_2 [-] Ashen Tax (1R) | Forge tolls rise for one room.\n- R12 chapter_3 [~] Echo Balance (2R) | Neutral echoes stabilize memory drift.", "last run summary should surface chapter effect timeline history")
	assert_string_contains(ending_review_label.text, "Epilogue Branch: Choir Restored [FIRST]", "ending review should surface the latest run epilogue branch title and mode")
	assert_string_contains(ending_review_label.text, "Branch Echo: Vanguard routes favor safer pressure and disciplined pacing.", "ending review should surface the epilogue branch route echo")
	assert_string_contains(ending_review_label.text, "Archive Hook: The altar now archives choir-side threads that point toward a sealed path beneath the first ward.", "ending review should surface the epilogue archive hook")
	assert_string_contains(ending_review_label.text, "Review Entry: Ending Archive -> Current Ending", "ending review should point players to the active branch review entry")
	assert_string_contains(ending_review_label.text, "Ending Payoff: Grace Restored", "ending review should surface the latest run ending payoff title")
	assert_string_contains(ending_review_label.text, "Payoff Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "ending review should surface the ending payoff route echo")
	assert_string_contains(ending_review_label.text, "Legacy: The camp survives because you chose to carry everyone through the last threshold, not just yourself.", "ending review should surface the ending payoff legacy")
	assert_string_contains(ending_review_label.text, "Fragment Hook: Redeem endings complete the choir-side fragment chain and strengthen shrine/survivor memory routes.", "ending review should surface the ending payoff fragment hook")
	assert_string_contains(ending_review_label.text, "Payoff Review Entry: Ending Archive -> Current Ending", "ending review should point players to the active payoff review entry")
	assert_string_contains(ending_review_label.text, "Epilogue: At dawn, the camp bells ring again. Survivors whisper your true name and the first altar rekindles.", "ending review should surface the latest run ending epilogue text")
	assert_string_contains(ending_review_label.text, "Epilogue Review Entry: Ending Archive -> Current Ending", "ending review should point players to the active epilogue review entry")
	assert_string_contains(ending_review_label.text, "Epilogue Chain:", "ending review should surface the latest run epilogue chain")
	assert_string_contains(ending_review_label.text, "- At first light the choir returns to the camp in broken harmony, answering the vows you carried through the final gate.", "ending review should list the first epilogue chain beat")
	assert_string_contains(ending_review_label.text, "- When the embers dim, the reliquary still glows - proof that grace survived the run because someone chose to keep it costly.", "ending review should list the final epilogue chain beat")
	assert_string_contains(ending_review_label.text, "Chain Review Entry: Ending Archive -> Current Ending", "ending review should point players to the active epilogue chain review entry")
