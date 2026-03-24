extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"
const RUN_RESULT_PANEL_SCENE_PATH := "res://scenes/ui/run_result_panel.tscn"


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


func _instantiate_run_result_panel() -> Control:
	var scene: PackedScene = load(RUN_RESULT_PANEL_SCENE_PATH)
	assert_not_null(scene, "run_result_panel scene should load")
	if scene == null:
		return null

	var panel: Control = scene.instantiate() as Control
	assert_not_null(panel, "run_result_panel scene should instantiate")
	if panel == null:
		return null

	add_child_autofree(panel)
	await get_tree().process_frame
	return panel


func _set_room_plan(world: Node, room_index: int, chapter_id: String, room_type: String, next_rooms: Array = []) -> void:
	var room_plan_map_var: Variant = world.get("_room_plan_map")
	var room_plan_map: Dictionary = {}
	if room_plan_map_var is Dictionary:
		room_plan_map = (room_plan_map_var as Dictionary).duplicate(true)

	room_plan_map[room_index] = {
		"chapter_id": chapter_id,
		"chapter_index": int(chapter_id.trim_prefix("chapter_")),
		"room_type": room_type,
		"show_intro": false,
		"next_rooms": next_rooms,
		"previous_rooms": []
	}
	world.set("_room_plan_map", room_plan_map)


func test_save_manager_persists_stage5_payoff_fields_on_victory() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 15,
		"kills": 320,
		"level_reached": 12,
		"gold": 210,
		"ore": 42,
		"alignment": 74.0,
		"route_style": "vanguard",
		"boss_flawless_chapters": ["chapter_1", "chapter_2", "chapter_3"],
		"fragment_triggers": [{
			"chapter_id": "chapter_3",
			"trigger_type": "camp",
			"arc_id": "redeem",
			"style": "vanguard",
			"fragment_id": "memory_camp_oracle",
			"fragment_title": "Fragment XXXIII: Quiet Beneath Embers",
			"fragment_text": "When the altar dimmed...",
			"newly_unlocked": true,
			"room_index": 10
		}]
	})

	assert_eq(str(result.get("ending_id", "")), "nar_ending_redeem", "high alignment victory should resolve to redeem ending")
	assert_eq(str(result.get("route_style", "")), "vanguard", "last run should persist resolved route_style")
	var payoff: Dictionary = result.get("ending_payoff", {})
	assert_false(payoff.is_empty(), "ending payoff should be persisted")
	assert_eq(str(payoff.get("arc_id", "")), "redeem", "ending payoff should include resolved route arc")
	assert_eq(str(payoff.get("style", "")), "vanguard", "ending payoff should include route style")
	var chain: Array = result.get("ending_epilogue_chain", [])
	assert_gte(chain.size(), 3, "ending epilogue chain should be persisted")
	var epilogue_branch: Dictionary = result.get("epilogue_branch", {})
	assert_false(epilogue_branch.is_empty(), "epilogue branch should be persisted")
	assert_eq(str(epilogue_branch.get("branch_key", "")), "first_unlock", "first ending clear should persist first unlock branch")
	var fragment_recap: Dictionary = result.get("fragment_recap", {})
	assert_false(fragment_recap.is_empty(), "fragment recap should be persisted")
	assert_eq(int(fragment_recap.get("trigger_count", 0)), 1, "fragment recap should summarize trigger count")
	var hidden_layer_hook: Dictionary = result.get("hidden_layer_hook", {})
	assert_false(hidden_layer_hook.is_empty(), "hidden layer hook should be persisted")
	assert_eq(str(hidden_layer_hook.get("target_layer", "")), "FS1", "redeem victory should point at FS1")
	assert_eq(result.get("boss_flawless_chapters", []), ["chapter_1", "chapter_2", "chapter_3"], "boss flawless chapter log should be persisted")
	var hidden_layer_statuses: Dictionary = result.get("hidden_layer_statuses", {})
	assert_false(hidden_layer_statuses.is_empty(), "hidden layer statuses should be persisted")
	var fs1_status: Dictionary = hidden_layer_statuses.get("FS1", {})
	assert_true(bool(fs1_status.get("unlocked", false)), "FS1 should unlock after flawless boss route")
	assert_eq(str(fs1_status.get("progress_label", "")), "Flawless Boss Route 3/3", "FS1 status should show completed unlock progress")
	assert_eq(str(fs1_status.get("map_mode", "")), "survival", "FS1 should expose hidden layer map mode")
	assert_string_contains(str(fs1_status.get("entry_hint", "")), "camp altar", "FS1 should expose entry hint from map config")
	assert_string_contains(str(fs1_status.get("reward_summary", "")), "Rewind charge", "FS1 should expose reward summary from map config")
	assert_true((result.get("new_hidden_layers", []) as Array).has("FS1"), "victory should report newly unlocked FS1")
	var triggers: Array = result.get("fragment_triggers", [])
	assert_eq(triggers.size(), 1, "fragment trigger log should be persisted")


func test_save_manager_tracks_fs2_unlock_from_boss_relic_collection() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	for accessory_id: String in ["acc_heart_of_mine", "acc_flame_core", "acc_zero_mark", "acc_void_eye"]:
		SaveManager.unlock_codex_entry("accessories", accessory_id, "test_unlock", "global")

	var result: Dictionary = SaveManager.submit_run_result({
		"outcome": "death",
		"rooms_cleared": 8,
		"kills": 120,
		"level_reached": 7,
		"gold": 64,
		"ore": 10,
		"alignment": 0.0
	})

	var hidden_layer_statuses: Dictionary = result.get("hidden_layer_statuses", {})
	var fs2_status: Dictionary = hidden_layer_statuses.get("FS2", {})
	assert_true(bool(fs2_status.get("unlocked", false)), "FS2 should unlock after all boss relic accessories are collected")
	assert_eq(str(fs2_status.get("progress_label", "")), "Boss Relics 4/4", "FS2 should report full boss relic progress")
	assert_eq(str(fs2_status.get("room_count_label", "")), "5 fixed forge trials", "FS2 should expose forge room-count contract")
	assert_string_contains(str(fs2_status.get("reward_summary", "")), "legendary weapon recipes", "FS2 should expose forge reward summary")
	assert_true((result.get("new_hidden_layers", []) as Array).has("FS2"), "run result should report newly unlocked FS2")


func test_save_manager_persists_runtime_difficulty_and_scales_meta_reward() -> void:
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
	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	var result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0
	})

	assert_eq(int(result.get("difficulty_tier", -1)), 2, "run result should persist selected difficulty tier")
	assert_eq(str(result.get("difficulty_label", "")), "Nightmare", "run result should persist selected difficulty label")
	assert_string_contains(str(result.get("difficulty_summary", "")), "Haz x1.22", "run result should persist difficulty risk summary")
	assert_string_contains(str(result.get("difficulty_summary", "")), "T x1.28", "run result should persist difficulty reward summary")
	assert_eq(float(result.get("meta_return_multiplier", 1.0)), 1.25, "nightmare clear progression should expose stacked meta return multiplier after the run")
	assert_string_contains(str(result.get("meta_return_summary", "")), "Return x1.25", "run result should persist post-run meta return summary")
	var new_difficulty_unlocks: Array = result.get("new_difficulty_unlocks", [])
	assert_eq(new_difficulty_unlocks.size(), 0, "runs after the ladder is fully unlocked should not report redundant difficulty unlocks")
	assert_eq(int(result.get("meta_reward", 0)), 307, "meta reward should use the pre-unlock meta return state for the unlocking run")


func test_save_manager_archives_hidden_layer_completion_rewards() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var result: Dictionary = SaveManager.submit_run_result({
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
		},
		"hidden_layer_story": {
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
	})

	assert_eq(str(result.get("hidden_layer_id", "")), "FS1", "hidden layer id should be persisted on clear")
	assert_string_contains(str(result.get("hidden_layer_reward_summary", "")), "Time Fragments +5", "hidden layer reward summary should be persisted")
	var hidden_layer_story: Dictionary = result.get("hidden_layer_story", {})
	assert_eq(str(hidden_layer_story.get("title", "")), "Time Rift: Choir Refrain", "hidden layer story payload should persist")
	assert_eq(str(hidden_layer_story.get("fragment_id", "")), "memory_fs1_redeem", "hidden layer story should persist linked fragment id")
	var hidden_layer_gameplay: Dictionary = result.get("hidden_layer_gameplay", {})
	assert_eq(int(hidden_layer_gameplay.get("pressure_stage", 0)), 3, "hidden layer gameplay payload should persist pressure stage")
	assert_eq((hidden_layer_gameplay.get("boss_echo_collection", []) as Array).size(), 4, "hidden layer gameplay payload should persist boss echo collection")
	var hidden_layer_record: Dictionary = result.get("hidden_layer_record", {})
	assert_eq(int(hidden_layer_record.get("clears", 0)), 1, "FS1 clear should increment hidden layer clears")
	var hidden_layer_statuses: Dictionary = result.get("hidden_layer_statuses", {})
	var fs1_status: Dictionary = hidden_layer_statuses.get("FS1", {})
	assert_true(bool(fs1_status.get("completed", false)), "FS1 status should mark the layer as completed after a clear")
	assert_string_contains(str(fs1_status.get("record_label", "")), "Rewind 2", "FS1 status should expose hidden-layer archive record summary")
	assert_string_contains(str(fs1_status.get("story_label", "")), "Time Rift: Choir Refrain", "FS1 status should expose hidden-layer story archive summary")
	assert_string_contains(str(fs1_status.get("gameplay_label", "")), "Frost King", "FS1 status should expose gameplay archive summary")
	assert_string_contains(str(fs1_status.get("collection_label", "")), "Echoes 4/4", "FS1 status should expose persistent echo archive collection progress")
	assert_string_contains(str(fs1_status.get("mastery_label", "")), "claimed", "FS1 status should expose mastery bonus claim state")


func test_game_world_fragment_pacing_and_run_result_panel_show_stage5_details() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_3", "safe_camp", [11])
	_set_room_plan(world, 11, "chapter_3", "event", [12])
	_set_room_plan(world, 12, "chapter_3", "boss", [])
	world.set("_alignment", 72.0)
	world.set("_current_route_style", "vanguard")

	var narrative_system: Node = world.get_node_or_null("NarrativeSystem")
	assert_not_null(narrative_system, "NarrativeSystem should exist in game world")
	if narrative_system == null:
		return

	narrative_system.call("record_choice", "chapter_3", "nar_evt_whispers", "keep_the_oath", 12.0)
	narrative_system.call("record_choice", "chapter_3", "nar_evt_whispers", "answer_the_choir", 9.0)

	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.call("_enter_safe_camp_room")

	var trigger_log: Array = world.get("_run_fragment_triggers")
	assert_gte(trigger_log.size(), 1, "camp pacing should add a fragment trigger entry")
	var latest_line: String = str(world.call("_get_latest_fragment_trigger_line"))
	assert_string_contains(latest_line, "Memory", "latest fragment trigger line should be human-readable")

	world.set("_room_index", 11)
	world.set("_current_room_type", "event")
	world.call("_on_event_closed")
	trigger_log = world.get("_run_fragment_triggers")
	assert_gte(trigger_log.size(), 2, "event pacing should append a fragment trigger entry")

	world.set("_room_index", 12)
	world.set("_current_room_type", "boss")
	world.call("_on_transition_closed")
	trigger_log = world.get("_run_fragment_triggers")
	assert_gte(trigger_log.size(), 3, "transition pacing should append a fragment trigger entry")

	var run_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 15,
		"kills": 290,
		"level_reached": 11,
		"gold": 180,
		"ore": 36,
		"alignment": float(world.get("_alignment")),
		"route_style": str(world.call("_resolve_run_route_style_for_payoff")),
		"fragment_triggers": trigger_log,
		"narrative_choices": narrative_system.call("get_run_choices"),
		"chapter_effect_timeline": [],
		"chapter_route_styles": {},
		"route_style_timeline": []
	})

	var panel: Control = await _instantiate_run_result_panel()
	if panel == null:
		return
	panel.call("show_result", run_result)

	var ending_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/EndingStory")
	var unlock_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Unlocks")
	assert_not_null(ending_label, "EndingStory label should exist")
	assert_not_null(unlock_label, "Unlocks label should exist")
	if ending_label == null or unlock_label == null:
		return

	assert_string_contains(ending_label.text, "Payoff:", "run result panel should render ending payoff summary")
	assert_string_contains(ending_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "run result panel should render ending payoff route echo")
	assert_string_contains(ending_label.text, "Review Entry: Ending Archive -> Current Ending", "run result panel should point players to the ending payoff review entry")
	assert_string_contains(ending_label.text, "Epilogue: At dawn, the camp bells ring again. Survivors whisper your true name and the first altar rekindles.", "run result panel should render the active ending epilogue text")
	assert_string_contains(ending_label.text, "Epilogue Review Entry: Ending Archive -> Current Ending", "run result panel should point players to the epilogue review entry")
	assert_string_contains(ending_label.text, "Epilogue Chain:", "run result panel should render epilogue chain")
	assert_string_contains(ending_label.text, "- At first light the choir returns to the camp in broken harmony, answering the vows you carried through the final gate.", "run result panel should render the first epilogue chain beat")
	assert_string_contains(ending_label.text, "Chain Review Entry: Ending Archive -> Current Ending", "run result panel should point players to the epilogue chain review entry")
	assert_string_contains(ending_label.text, "Epilogue Branch:", "run result panel should render epilogue branch summary")
	assert_string_contains(ending_label.text, "Branch Echo: Vanguard routes favor safer pressure and disciplined pacing.", "run result panel should render epilogue branch route echo")
	assert_string_contains(ending_label.text, "Review Entry: Ending Archive -> Current Ending", "run result panel should point players to the epilogue branch review entry")
	assert_string_contains(unlock_label.text, "Fragments:", "run result panel should render fragment trigger list")
	assert_string_contains(unlock_label.text, "Fragment Recap:", "run result panel should render fragment recap block")
	assert_string_contains(unlock_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "run result panel should render fragment recap route echo")
	assert_string_contains(unlock_label.text, "Review Entry: Memory Altar -> Archive Recap", "run result panel should point players to the archive recap review entry")
	assert_string_contains(unlock_label.text, "Hidden Route:", "run result panel should render hidden route hook block")
	assert_string_contains(unlock_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "run result panel should render hidden route route-echo guidance")
	assert_string_contains(unlock_label.text, "Review Entry: Memory Altar -> Hidden Route Lead", "run result panel should point players to the hidden route review entry")
	assert_string_contains(unlock_label.text, "Hidden Layers:", "run result panel should render hidden layer status block")
	assert_string_contains(unlock_label.text, "FS1 -> Time Rift", "run result panel should render FS1 status row")
	assert_string_contains(unlock_label.text, "Entry:", "run result panel should render hidden layer entry hint")
	assert_string_contains(unlock_label.text, "Reward:", "run result panel should render hidden layer reward summary")
	assert_string_contains(unlock_label.text, "Settlement:", "run result panel should render hidden layer settlement summary")
	assert_string_contains(unlock_label.text, "Record:", "run result panel should render hidden layer archive record summary")
	assert_string_contains(unlock_label.text, "Review Entry: Memory Altar -> Hidden Layer Track", "run result panel should point players to the hidden-layer track review entry")


func test_run_result_panel_renders_hidden_layer_story_archive_details() -> void:
	var panel: Control = await _instantiate_run_result_panel()
	if panel == null:
		return

	panel.call("show_result", {
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 360,
		"level_reached": 13,
		"meta_reward": 120,
		"difficulty_label": "Nightmare",
		"difficulty_summary": "Haz x1.22 | G x1.16 | O x1.22 | T x1.28",
		"meta_return_summary": "Return x1.30",
		"meta_return_next_hint": "Next Return: clear any hidden layer on Nightmare",
		"new_difficulty_unlocks": [
			{"tier": 2, "label": "Nightmare"}
		],
		"new_meta_return_unlocks": [
			{"id": "nightmare_meta_return", "label": "Nightmare Return", "bonus_text": "+15% Meta"}
		],
		"new_achievements": ["ach_fs1_archive", "ach_fs1_mastery", "ach_nightmare_clear", "ach_nightmare_hidden"],
		"new_codex_unlocks": [
			{"category": "archives", "entry_id": "fs1_echo_archive", "source": "hidden_layer_clear", "chapter_id": "global"},
			{"category": "archives", "entry_id": "fs1_echo_mastery", "source": "hidden_layer_mastery", "chapter_id": "global"},
			{"category": "archives", "entry_id": "nightmare_clear_archive", "source": "difficulty_clear", "chapter_id": "global"},
			{"category": "archives", "entry_id": "nightmare_hidden_archive", "source": "difficulty_hidden_clear", "chapter_id": "global"}
		],
		"hidden_layer_id": "FS1",
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
		},
		"hidden_layer_story": {
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
		},
		"hidden_layer_record": {
			"attempts": 1,
			"clears": 1,
			"best_rooms_cleared": 3
		},
		"hidden_layer_statuses": {
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
		},
		"new_hidden_layers": []
	})

	var unlock_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Unlocks")
	var summary_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Summary")
	assert_not_null(unlock_label, "Unlocks label should exist")
	assert_not_null(summary_label, "Summary label should exist")
	if unlock_label == null or summary_label == null:
		return

	assert_string_contains(summary_label.text, "Diff Nightmare", "run result summary should surface difficulty label")
	assert_string_contains(summary_label.text, "Haz x1.22", "run result summary should surface difficulty risk summary")
	assert_string_contains(summary_label.text, "T x1.28", "run result summary should surface difficulty reward summary")
	assert_string_contains(summary_label.text, "Return x1.30", "run result summary should surface meta return summary")
	assert_string_contains(unlock_label.text, "Story:", "run result panel should render hidden-layer story title")
	assert_string_contains(unlock_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "run result panel should render hidden-layer story route echo")
	assert_string_contains(unlock_label.text, "Ending Link:", "run result panel should render hidden-layer ending linkage")
	assert_string_contains(unlock_label.text, "Archive Echo:", "run result panel should render hidden-layer archive echo")
	assert_string_contains(unlock_label.text, "Fragment Archive:", "run result panel should render hidden-layer fragment archive summary")
	assert_string_contains(unlock_label.text, "Fragment Text: The choir answered from below the ward, proving that vows kept in the upper halls can still echo through the fractures under time itself.", "run result panel should render hidden-layer fragment text")
	assert_string_contains(unlock_label.text, "Review Entry: Memory Altar -> Hidden Layer Track", "run result panel should point players to the hidden-layer story review entry")
	assert_string_contains(unlock_label.text, "Archive:", "run result panel should render persistent hidden-layer archive linkage")
	assert_string_contains(unlock_label.text, "Pressure:", "run result panel should render hidden-layer gameplay pressure summary")
	assert_string_contains(unlock_label.text, "Gameplay:", "run result panel should render persistent gameplay archive summary")
	assert_string_contains(unlock_label.text, "Collection:", "run result panel should render hidden-layer collection archive summary")
	assert_string_contains(unlock_label.text, "Mastery:", "run result panel should render hidden-layer mastery archive summary")
	assert_string_contains(unlock_label.text, "Burst Unlocks:", "run result panel should render unlock burst summary block")
	assert_string_contains(unlock_label.text, "Difficulty: Nightmare unlocked", "run result panel should render difficulty unlock bursts with readable labels")
	assert_string_contains(unlock_label.text, "Meta Return: Nightmare Return (+15% Meta)", "run result panel should render meta return unlock bursts")
	assert_string_contains(unlock_label.text, "Meta Return:\nReturn x1.30", "run result panel should surface current meta return summary block")
	assert_string_contains(unlock_label.text, "Achievement: Rift Archivist", "run result panel should resolve achievement ids to titles")
	assert_string_contains(unlock_label.text, "Achievement: Nightmare Victor", "run result panel should resolve difficulty achievement ids to titles")
	assert_string_contains(unlock_label.text, "Codex: [Archives] Time Rift Archive", "run result panel should render codex archive burst title")
	assert_string_contains(unlock_label.text, "Codex: [Archives] Time Rift Mastery", "run result panel should render codex mastery burst title")
	assert_string_contains(unlock_label.text, "Codex: [Archives] Nightmare Archive", "run result panel should render difficulty archive burst title")
	assert_string_contains(unlock_label.text, "Codex: [Archives] Nightmare Hidden Archive", "run result panel should render nightmare hidden archive burst title")
