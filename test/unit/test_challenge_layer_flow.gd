extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"
const RUN_RESULT_PANEL_SCENE_PATH := "res://scenes/ui/run_result_panel.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu/main_menu.tscn"


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


func _unlock_challenge_layer_gate() -> void:
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
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0
	})
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
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0
	})
	SaveManager.submit_run_result({
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
	var meta_return_profile: Dictionary = SaveManager.get_meta_return_profile()
	assert_true((meta_return_profile.get("unlocked_ids", []) as Array).has("nightmare_hidden_meta_return"), "challenge layer gate should require the full meta return chain")


func test_safe_camp_can_enter_challenge_layer_and_finish_at_settlement() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_gate()
	SaveManager.submit_run_result({
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
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_4", "safe_camp", [12])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.call("_update_camp_text")

	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Challenge Layer:", "safe camp should surface a challenge-layer preview header once the meta-return chain is complete")
	assert_string_contains(status_label.text, "Route frame: Entry + combat + settlement", "safe camp should preview the challenge route frame before entry")
	assert_string_contains(status_label.text, "Checkpoint preview: Challenge Gate", "safe camp should preview the challenge entry checkpoint")
	assert_string_contains(status_label.text, "Entry hint: Clear the full difficulty/meta-return chain to stabilize the first challenge layer.", "safe camp should surface the challenge entry hint summary")
	assert_string_contains(status_label.text, "Entry preview: Challenge Layer Entry", "safe camp should preview the challenge entry room title")
	assert_string_contains(status_label.text, "Objective: Step into the challenge archive route and confirm the first checkpoint.", "safe camp should preview the challenge entry objective")
	assert_string_contains(status_label.text, "Entry staging: Press E to enter the first challenge combat ring.", "safe camp should preview the first staging action inside the challenge layer")
	assert_string_contains(status_label.text, "Reward preview: Challenge archive sealed | Meta +40 | Sigil +1", "safe camp should preview the challenge reward package before entry")
	assert_string_contains(status_label.text, "Settlement preview: Archive the challenge clear and prepare the next late-game route.", "safe camp should preview the challenge settlement destination")
	assert_string_contains(status_label.text, "Reward choices: Meta Cache | Sigil Bundle | Archive Insight", "safe camp should preview the three settlement reward choices before entry")
	assert_string_contains(status_label.text, "1) Meta Cache - Meta +40", "safe camp should preview the first reward detail before entry")
	assert_string_contains(status_label.text, "2) Sigil Bundle - Sigil +1", "safe camp should preview the second reward detail before entry")
	assert_string_contains(status_label.text, "3) Archive Insight - Insight +1", "safe camp should preview the third reward detail before entry")
	assert_string_contains(status_label.text, "Difficulty tuning: Haz x1.22 | G x1.16 | O x1.22 | T x1.28", "safe camp should preview the challenge difficulty tuning before entry")
	assert_string_contains(status_label.text, "Archive exit: T: Memory Altar | E: Archive clear and finish run", "safe camp should preview the settlement archive exit actions before entry")
	assert_string_contains(status_label.text, "Combat preview: Challenge Combat Ring", "safe camp should preview the challenge combat stage title before entry")
	assert_string_contains(status_label.text, "Combat objective: Defeat the archive guardians and stabilize the settlement route.", "safe camp should preview the challenge combat objective before entry")
	assert_string_contains(status_label.text, "Combat checkpoint: Challenge Ring", "safe camp should preview the challenge combat checkpoint before entry")
	assert_string_contains(status_label.text, "Combat clear banner: Challenge ring stabilized.", "safe camp should preview the combat clear banner before entry")
	assert_string_contains(status_label.text, "Settlement stage: Challenge Settlement", "safe camp should preview the settlement stage title before entry")
	assert_string_contains(status_label.text, "Settlement objective: Archive the challenge clear and claim the first settlement reward.", "safe camp should preview the settlement objective before entry")
	assert_string_contains(status_label.text, "Settlement checkpoint: Challenge Archive", "safe camp should preview the settlement checkpoint before entry")
	assert_string_contains(status_label.text, "Settlement staging: Press E to archive the challenge and finish the run.", "safe camp should preview the settlement staging action before entry")
	assert_string_contains(status_label.text, "Archive record: Clears 1 | Best Rooms 2 | Best Kills 24", "safe camp should preview the current archived challenge record before entry")
	assert_string_contains(status_label.text, "Reward ledger: Meta +40 | Sigil +0 | Insight +0", "safe camp should preview accumulated reward totals before entry")
	assert_string_contains(status_label.text, "Last archived reward: Meta Cache", "safe camp should preview the last archived challenge reward before entry")
	assert_string_contains(status_label.text, "U: Enter Challenge Layer", "safe camp should advertise challenge-layer entry once the meta-return chain is complete")

	world.call("_try_enter_challenge_layer", "CL1")
	assert_eq(str(world.get("_active_challenge_layer_id")), "CL1", "world should switch into challenge layer CL1")
	assert_eq(int(world.get("_room_index")), 1, "challenge layer should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "challenge layer entry room should be a non-combat staging room in the minimal loop")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer Entry | Challenge staging", "entry room should surface the challenge staging title")
	assert_string_contains(status_label.text, "Objective: Step into the challenge archive route and confirm the first checkpoint.", "entry room should keep the entry objective visible after entering")
	assert_string_contains(status_label.text, "Press E to enter the first challenge combat ring.", "entry room should surface the staging action hint")
	assert_string_contains(status_label.text, "Reward preview: Challenge archive sealed | Meta +40 | Sigil +1", "entry room should keep the reward preview visible")
	assert_string_contains(status_label.text, "Difficulty tuning: Haz x1.22 | G x1.16 | O x1.22 | T x1.28", "entry room should surface the challenge difficulty tuning")
	assert_string_contains(status_label.text, "Press E -> Challenge Combat Ring", "entry room should surface the combat-ring prompt")
	var entry_plan: Dictionary = world.call("_get_room_plan", 1)
	assert_eq(str(entry_plan.get("challenge_layer_id", "")), "CL1", "challenge layer entry room should carry CL1 metadata")
	assert_eq(str(entry_plan.get("challenge_phase", "")), "entry", "first challenge room should be marked as the entry phase")

	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 2, "challenge layer should advance into its combat room")
	assert_eq(str(world.get("_current_room_type")), "combat", "challenge middle room should now be a combat room")
	var combat_plan: Dictionary = world.call("_get_room_plan", 2)
	assert_eq(str(combat_plan.get("challenge_phase", "")), "combat", "second challenge room should be marked as the combat phase")
	assert_true(bool(world.get("_room_active")), "challenge combat room should be active")
	assert_string_contains(status_label.text, "Challenge Combat Ring", "combat room should surface the challenge combat title")
	assert_string_contains(status_label.text, "Defeat the archive guardians and stabilize the settlement route.", "combat room should surface the challenge combat objective")
	assert_string_contains(status_label.text, "A minimal combat proof before deeper challenge rooms arrive.", "combat room should surface the challenge combat status hint")
	assert_string_contains(status_label.text, "Difficulty tuning: Haz x1.22 | G x1.16 | O x1.22 | T x1.28", "combat room should surface the challenge difficulty tuning")

	var spawner: Node = world.get_node_or_null("EnemySpawner")
	assert_not_null(spawner, "enemy spawner should exist for challenge combat")
	if spawner == null:
		return
	if spawner.has_method("stop_room_combat"):
		spawner.call("stop_room_combat")
	world.set("_kills_in_room", int(world.get("_required_kills")))
	world.call("_try_clear_room")
	assert_false(bool(world.get("_room_active")), "challenge combat room should become inactive after clear")

	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 3, "challenge layer should advance into its settlement room")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "challenge settlement should remain a safe-camp style room")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Settlement", "challenge settlement should surface dedicated settlement text")
	assert_string_contains(status_label.text, "Reward preview:", "challenge settlement should preview its payout")
	assert_string_contains(status_label.text, "1) Meta Cache", "challenge settlement should list the first reward-shop option")
	assert_string_contains(status_label.text, "Archive clear and finish run", "challenge settlement should explain the finish action")

	world.call("_try_buy_challenge_reward_slot", 0)
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Bought Meta Cache", "buying the first challenge reward should update the settlement message")
	assert_string_contains(status_label.text, "Selected Reward: Meta Cache", "settlement should surface the chosen reward title")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +40 | Sigil +0 | Insight +0", "settlement should surface the chosen reward payload detail")

	var result_payload: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(result_payload.get("challenge_layer_id", "")), "CL1", "challenge result payload should persist the active layer id")
	assert_eq(str(result_payload.get("challenge_layer_title", "")), "Challenge Layer", "challenge result payload should expose the layer title")
	assert_eq(str(result_payload.get("challenge_layer_phase", "")), "settlement", "challenge result payload should record that the layer ended in settlement")
	assert_eq(int(result_payload.get("challenge_layer_rooms_cleared", 0)), 2, "challenge result payload should count the entry plus combat progression into settlement")
	assert_eq(str(result_payload.get("challenge_layer_reward_id", "")), "meta_cache", "challenge result payload should persist the selected reward id")
	assert_eq(str(result_payload.get("challenge_layer_reward_title", "")), "Meta Cache", "challenge result payload should persist the selected reward title")
	var challenge_reward_payload: Dictionary = result_payload.get("challenge_layer_reward_payload", {})
	assert_eq(int(challenge_reward_payload.get("meta_bonus", 0)), 40, "meta cache reward should expose its meta bonus")
	assert_string_contains(str(result_payload.get("challenge_layer_reward_summary", "")), "Challenge archive sealed", "challenge result payload should expose reward summary text")
	assert_string_contains(str(result_payload.get("challenge_layer_reward_summary", "")), "Meta Cache", "challenge result payload should include the chosen reward title")


func test_save_manager_and_result_ui_persist_challenge_layer_summary() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 12,
		"kills": 140,
		"level_reached": 9,
		"gold": 88,
		"ore": 14,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"difficulty_summary": "Haz x1.22 | G x1.16 | O x1.22 | T x1.28",
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

	assert_eq(str(result.get("challenge_layer_id", "")), "CL1", "last run should persist the cleared challenge layer id")
	assert_eq(str(result.get("challenge_layer_reward_id", "")), "meta_cache", "last run should persist the selected challenge reward id")
	assert_eq(str(result.get("challenge_layer_reward_title", "")), "Meta Cache", "last run should persist the selected challenge reward title")
	assert_string_contains(str(result.get("challenge_layer_reward_summary", "")), "Meta Cache", "last run should persist the chosen challenge reward summary")
	assert_eq(str(result.get("challenge_layer_settlement_summary", "")), "The settlement records this challenge clear for the next postgame step.", "last run should persist the challenge settlement summary")
	var challenge_record: Dictionary = result.get("challenge_layer_record", {})
	assert_eq(int(challenge_record.get("clears", 0)), 1, "challenge record should count victorious clears")
	assert_eq(int(challenge_record.get("total_meta_bonus", 0)), 40, "challenge record should accumulate reward-shop meta bonus")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Meta Cache", "challenge record should remember the last selected reward")

	var panel: Control = await _instantiate_run_result_panel()
	if panel == null:
		return
	panel.call("show_result", result)
	var unlock_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Unlocks")
	assert_not_null(unlock_label, "run result unlock label should exist")
	if unlock_label == null:
		return
	assert_string_contains(unlock_label.text, "Challenge Layer:", "result panel should surface a dedicated challenge-layer block")
	assert_string_contains(unlock_label.text, "Challenge archive sealed", "result panel should include challenge reward summary")
	assert_string_contains(unlock_label.text, "Reward Choice: Meta Cache", "result panel should surface the selected challenge reward title")
	assert_string_contains(unlock_label.text, "Selected Reward Detail: Meta +40 | Sigil +0 | Insight +0", "result panel should surface the selected reward payload detail")
	assert_string_contains(unlock_label.text, "Settlement: The settlement records this challenge clear for the next postgame step.", "result panel should surface the settlement summary")
	assert_string_contains(unlock_label.text, "Reward Ledger: Meta +40 | Sigil +0 | Insight +0", "result panel should surface challenge reward ledger totals")
	assert_string_contains(unlock_label.text, "Last Reward: Meta Cache", "result panel should surface the last archived challenge reward title")
	assert_string_contains(unlock_label.text, "Run Stats: rooms=2 | kills=24", "result panel should surface this run challenge clear stats")
	assert_string_contains(unlock_label.text, "best_kills=24", "result panel should surface challenge archive best kills")
	assert_string_contains(unlock_label.text, "Difficulty tuning: Haz x1.22 | G x1.16 | O x1.22 | T x1.28", "result panel should surface challenge difficulty tuning")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return
	var last_run_label: Label = menu.get_node_or_null("CenterContainer/VBoxContainer/LastRunValue")
	assert_not_null(last_run_label, "last run label should exist")
	if last_run_label == null:
		return
	assert_string_contains(last_run_label.text, "Challenge CL1", "main menu last run summary should surface the challenge layer id")
	assert_string_contains(last_run_label.text, "Reward Meta Cache", "main menu last run summary should surface the selected challenge reward")
	assert_string_contains(last_run_label.text, "Reward Detail: Meta +40 | Sigil +0 | Insight +0", "main menu last run summary should surface the selected reward payload detail")
	assert_string_contains(last_run_label.text, "Settlement: The settlement records this challenge clear for the next postgame step.", "main menu last run summary should surface the settlement summary")
	assert_string_contains(last_run_label.text, "Reward Ledger: Meta +40 | Sigil +0 | Insight +0", "main menu last run summary should surface challenge reward ledger totals")
	assert_string_contains(last_run_label.text, "Last Reward: Meta Cache", "main menu last run summary should surface the last archived challenge reward title")
	assert_string_contains(last_run_label.text, "Run Stats: rooms=2 | kills=24", "main menu last run summary should surface this run challenge clear stats")
	assert_string_contains(last_run_label.text, "best_kills=24", "main menu last run summary should surface challenge archive best kills")
	assert_string_contains(last_run_label.text, "Difficulty tuning: Haz x1.22 | G x1.16 | O x1.22 | T x1.28", "main menu last run summary should surface challenge difficulty tuning")
