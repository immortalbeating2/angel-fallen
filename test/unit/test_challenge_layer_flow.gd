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


func _find_menu_label(menu: Control, node_name: String) -> Label:
	if menu == null:
		return null
	return menu.find_child(node_name, true, false) as Label


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


func _unlock_challenge_layer_two_gate() -> void:
	_unlock_challenge_layer_gate()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 18,
		"kills": 352,
		"level_reached": 13,
		"gold": 210,
		"ore": 40,
		"alignment": 68.0,
		"route_style": "vanguard",
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"hidden_layer_id": "FS1",
		"hidden_layer_rooms_cleared": 3,
		"hidden_layer_kills": 90,
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
			"survival_seconds": 48.0,
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
	var meta_return_profile: Dictionary = SaveManager.get_meta_return_profile()
	assert_true((meta_return_profile.get("unlocked_ids", []) as Array).has("archive_meta_return"), "CL2 should unlock after Archive Return is added to the meta-return ladder")


func _unlock_challenge_layer_three_gate() -> void:
	_unlock_challenge_layer_two_gate()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 16,
		"kills": 204,
		"level_reached": 11,
		"gold": 132,
		"ore": 24,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare",
		"challenge_layer_id": "CL2",
		"challenge_layer_title": "Challenge Layer II",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "deep_meta_cache",
		"challenge_layer_reward_title": "Deep Meta Cache",
		"challenge_layer_reward_payload": {
			"meta_bonus": 60,
			"sigils": 0,
			"insight": 0
		},
		"challenge_layer_reward_summary": "Crucible archive sealed | Deep Meta Cache | Meta +60",
		"challenge_layer_settlement_summary": "The second settlement records a deeper challenge clear for the next archive horizon.",
		"challenge_layer_rooms_cleared": 3,
		"challenge_layer_kills": 42
	})
	var cl2_record: Dictionary = SaveManager.get_challenge_layer_record("CL2")
	assert_eq(int(cl2_record.get("clears", 0)), 1, "CL3 should unlock only after CL2 archives at least one clear")


func _unlock_challenge_layer_four_gate() -> void:
	_unlock_challenge_layer_three_gate()
	SaveManager.submit_run_result({
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
	var cl3_record: Dictionary = SaveManager.get_challenge_layer_record("CL3")
	assert_eq(int(cl3_record.get("clears", 0)), 1, "CL4 should unlock only after CL3 archives at least one clear")


func _prepare_safe_camp(world: Node) -> Label:
	_set_room_plan(world, 10, "chapter_4", "safe_camp", [12])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.call("_update_camp_text")
	return world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")


func _clear_active_challenge_room(world: Node) -> void:
	var spawner: Node = world.get_node_or_null("EnemySpawner")
	assert_not_null(spawner, "enemy spawner should exist for challenge combat")
	if spawner == null:
		return
	if spawner.has_method("stop_room_combat"):
		spawner.call("stop_room_combat")
	world.set("_kills_in_room", int(world.get("_required_kills")))
	world.call("_try_clear_room")


func _reach_challenge_layer_settlement(world: Node, layer_id: String = "CL1") -> void:
	world.call("_try_enter_challenge_layer", layer_id)
	while not bool(world.call("_is_challenge_layer_settlement_room", int(world.get("_room_index")))):
		if not bool(world.get("_room_active")):
			world.call("_advance_to_next_room")
			continue
		_clear_active_challenge_room(world)
		world.call("_advance_to_next_room")


func _build_run_result_payload(outcome: String) -> Dictionary:
	return {
		"outcome": outcome,
		"rooms_cleared": 12,
		"kills": 140,
		"level_reached": 9,
		"gold": 88,
		"ore": 14,
		"alignment": 0.0,
		"difficulty_tier": 2,
		"difficulty_label": "Nightmare"
	}


func _submit_challenge_run_result(outcome: String, challenge_layer_result: Dictionary) -> Dictionary:
	var payload: Dictionary = _build_run_result_payload(outcome)
	for key_var: Variant in challenge_layer_result.keys():
		payload[str(key_var)] = challenge_layer_result.get(key_var)
	return SaveManager.submit_run_result(payload)


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


func test_safe_camp_can_enter_challenge_layer_two_and_finish_boss_settlement_loop() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_two_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return

	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Challenge Layer II:", "safe camp should surface a second challenge-layer preview header once Archive Return is unlocked")
	assert_string_contains(status_label.text, "Route frame: Entry + elite + boss + settlement", "safe camp should preview the deeper CL2 route frame before entry")
	assert_string_contains(status_label.text, "Entry hint: Complete Archive Return to unlock the second challenge layer.", "safe camp should surface the CL2 entry hint")
	assert_string_contains(status_label.text, "Entry preview: Challenge Layer II Entry", "safe camp should preview the CL2 entry room title")
	assert_string_contains(status_label.text, "Combat preview: Archive Crucible", "safe camp should preview the CL2 elite trial stage")
	assert_string_contains(status_label.text, "Settlement stage: Challenge Layer II Settlement", "safe camp should preview the CL2 settlement stage")
	assert_string_contains(status_label.text, "Reward preview: Crucible archive sealed | Meta +60 | Sigil +2 | Insight +2", "safe camp should preview the CL2 reward package before entry")
	assert_string_contains(status_label.text, "Reward choices: Deep Meta Cache | Sigil Crate | Insight Bundle", "safe camp should preview the CL2 settlement reward choices before entry")
	assert_string_contains(status_label.text, "I: Enter Challenge Layer II", "safe camp should advertise the CL2 hotkey once Archive Return is unlocked")

	world.call("_try_enter_challenge_layer", "CL2")
	assert_eq(str(world.get("_active_challenge_layer_id")), "CL2", "world should switch into challenge layer CL2")
	assert_eq(int(world.get("_room_index")), 1, "CL2 should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL2 should begin from a staging room")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer II Entry | Challenge staging", "CL2 entry room should surface the deeper staging title")
	assert_string_contains(status_label.text, "Press E -> Archive Crucible", "CL2 entry room should surface the elite-trial prompt")

	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 2, "CL2 should advance into its elite room")
	assert_eq(str(world.get("_current_room_type")), "elite", "CL2 second room should be an elite challenge room")
	var elite_plan: Dictionary = world.call("_get_room_plan", 2)
	assert_eq(str(elite_plan.get("challenge_phase", "")), "combat", "CL2 elite room should still count as the combat phase")
	assert_string_contains(status_label.text, "Archive Crucible", "CL2 elite room should surface the crucible title")
	assert_string_contains(status_label.text, "Break the elite archive wardens and expose the crown trial.", "CL2 elite room should surface the crucible objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 3, "CL2 should advance into its boss room")
	assert_eq(str(world.get("_current_room_type")), "boss", "CL2 third room should be a boss room")
	var boss_plan: Dictionary = world.call("_get_room_plan", 3)
	assert_eq(str(boss_plan.get("challenge_phase", "")), "boss", "CL2 third room should be marked as the boss phase")
	assert_string_contains(status_label.text, "Crown Trial", "CL2 boss room should surface the crown-trial title")
	assert_string_contains(status_label.text, "Defeat the crowned archive echo and unlock the deeper settlement ledger.", "CL2 boss room should surface the boss objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 4, "CL2 should advance into its settlement room")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL2 should finish in a settlement safe camp")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer II Settlement", "CL2 settlement should surface the deeper settlement title")
	assert_string_contains(status_label.text, "1) Deep Meta Cache", "CL2 settlement should list the first reinforced reward option")
	assert_string_contains(status_label.text, "2) Sigil Crate", "CL2 settlement should list the second reinforced reward option")
	assert_string_contains(status_label.text, "3) Insight Bundle", "CL2 settlement should list the third reinforced reward option")

	world.call("_try_buy_challenge_reward_slot", 2)
	assert_string_contains(status_label.text, "Bought Insight Bundle", "CL2 settlement should confirm the selected reward")
	assert_string_contains(status_label.text, "Reward preview: Crucible archive sealed | Insight Bundle | Insight +2", "CL2 settlement should preview the selected reward summary")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +0 | Sigil +0 | Insight +2", "CL2 settlement should surface the selected reward payload detail")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(challenge_layer_result.get("challenge_layer_id", "")), "CL2", "CL2 result payload should persist the deeper layer id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_phase", "")), "settlement", "CL2 result payload should end on settlement phase after a clear")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "insight_bundle", "CL2 result payload should persist the selected reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "Insight Bundle", "CL2 result payload should persist the selected reward title")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Crucible archive sealed | Insight Bundle | Insight +2", "CL2 result payload should persist the selected reward summary")
	assert_eq(int(challenge_layer_result.get("challenge_layer_rooms_cleared", 0)), 3, "CL2 result payload should record the elite-plus-boss clear count")

	var run_result: Dictionary = _submit_challenge_run_result("victory", challenge_layer_result)
	var challenge_record: Dictionary = run_result.get("challenge_layer_record", {})
	assert_eq(str(challenge_record.get("id", "")), "CL2", "CL2 clear should surface the CL2 archive record")
	assert_eq(int(challenge_record.get("clears", 0)), 1, "CL2 clear should archive one clear for the second challenge layer")
	assert_eq(int(challenge_record.get("best_rooms", 0)), 3, "CL2 clear should archive the elite-plus-boss room count")
	assert_eq(int(challenge_record.get("best_kills", 0)), 0, "CL2 clear should preserve the current forced-clear kill total used by this runtime regression")
	assert_eq(int(challenge_record.get("total_insight", 0)), 2, "CL2 clear should archive the reinforced insight payout")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Insight Bundle", "CL2 clear should archive the last selected reward title")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview safe camp label should exist after a CL2 clear")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Challenge Layer II:", "safe camp should continue surfacing the CL2 preview after a clear")
	assert_string_contains(preview_label.text, "Archive record: Clears 1 | Best Rooms 3 | Best Kills 0", "safe camp should echo the archived CL2 record after a clear")
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +0 | Insight +2", "safe camp should echo the archived CL2 ledger after a clear")
	assert_string_contains(preview_label.text, "Last archived reward: Insight Bundle", "safe camp should echo the archived CL2 reward title after a clear")


func test_safe_camp_can_enter_challenge_layer_three_and_finish_sovereign_settlement_loop() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_three_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return

	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Challenge Layer III:", "safe camp should surface a third challenge-layer preview header after a CL2 clear")
	assert_string_contains(status_label.text, "Route frame: Entry + elite + combat + boss + settlement", "safe camp should preview the CL3 route frame before entry")
	assert_string_contains(status_label.text, "Entry hint: Clear Challenge Layer II once to unlock the third challenge layer.", "safe camp should surface the CL3 entry hint")
	assert_string_contains(status_label.text, "Entry preview: Challenge Layer III Entry", "safe camp should preview the CL3 entry room title")
	assert_string_contains(status_label.text, "Combat preview: Null Gauntlet", "safe camp should preview the CL3 first combat stage")
	assert_string_contains(status_label.text, "Settlement stage: Challenge Layer III Settlement", "safe camp should preview the CL3 settlement stage")
	assert_string_contains(status_label.text, "Reward preview: Sovereign archive sealed | Meta +80 | Sigil +3 | Insight +3", "safe camp should preview the CL3 reward package before entry")
	assert_string_contains(status_label.text, "Reward choices: Sovereign Meta Cache | Sigil Matrix | Insight Reliquary", "safe camp should preview the CL3 settlement reward choices before entry")
	assert_string_contains(status_label.text, "O: Enter Challenge Layer III", "safe camp should advertise the CL3 hotkey once CL2 is cleared")

	world.call("_try_enter_challenge_layer", "CL3")
	assert_eq(str(world.get("_active_challenge_layer_id")), "CL3", "world should switch into challenge layer CL3")
	assert_eq(int(world.get("_room_index")), 1, "CL3 should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL3 should begin from a staging room")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer III Entry | Challenge staging", "CL3 entry room should surface the sovereign staging title")
	assert_string_contains(status_label.text, "Press E -> Null Gauntlet", "CL3 entry room should surface the first gauntlet prompt")

	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 2, "CL3 should advance into its elite gauntlet room")
	assert_eq(str(world.get("_current_room_type")), "elite", "CL3 second room should be an elite challenge room")
	var elite_plan: Dictionary = world.call("_get_room_plan", 2)
	assert_eq(str(elite_plan.get("challenge_phase", "")), "combat", "CL3 elite room should still count as the combat phase")
	assert_string_contains(status_label.text, "Null Gauntlet", "CL3 elite room should surface the null-gauntlet title")
	assert_string_contains(status_label.text, "Break the null wardens and expose the breach route.", "CL3 elite room should surface the first gauntlet objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 3, "CL3 should advance into its breach room")
	assert_eq(str(world.get("_current_room_type")), "combat", "CL3 third room should be a standard combat room")
	var breach_plan: Dictionary = world.call("_get_room_plan", 3)
	assert_eq(str(breach_plan.get("challenge_phase", "")), "combat", "CL3 breach room should remain part of the combat phase")
	assert_string_contains(status_label.text, "Archive Breach", "CL3 breach room should surface the breach title")
	assert_string_contains(status_label.text, "Hold the breach against the archive swarm and force the sovereign seal open.", "CL3 breach room should surface the sustained-combat objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 4, "CL3 should advance into its sovereign boss room")
	assert_eq(str(world.get("_current_room_type")), "boss", "CL3 fourth room should be a boss room")
	var boss_plan: Dictionary = world.call("_get_room_plan", 4)
	assert_eq(str(boss_plan.get("challenge_phase", "")), "boss", "CL3 fourth room should be marked as the boss phase")
	assert_string_contains(status_label.text, "Sovereign Echo", "CL3 boss room should surface the sovereign-echo title")
	assert_string_contains(status_label.text, "Defeat the sovereign archive echo and secure the final settlement ledger.", "CL3 boss room should surface the sovereign objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 5, "CL3 should advance into its settlement room")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL3 should finish in a settlement safe camp")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer III Settlement", "CL3 settlement should surface the sovereign settlement title")
	assert_string_contains(status_label.text, "1) Sovereign Meta Cache", "CL3 settlement should list the first frontier reward option")
	assert_string_contains(status_label.text, "2) Sigil Matrix", "CL3 settlement should list the second frontier reward option")
	assert_string_contains(status_label.text, "3) Insight Reliquary", "CL3 settlement should list the third frontier reward option")

	world.call("_try_buy_challenge_reward_slot", 1)
	assert_string_contains(status_label.text, "Bought Sigil Matrix", "CL3 settlement should confirm the selected reward")
	assert_string_contains(status_label.text, "Reward preview: Sovereign archive sealed | Sigil Matrix | Sigil +3", "CL3 settlement should preview the selected reward summary")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +0 | Sigil +3 | Insight +0", "CL3 settlement should surface the selected reward payload detail")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(challenge_layer_result.get("challenge_layer_id", "")), "CL3", "CL3 result payload should persist the sovereign layer id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_phase", "")), "settlement", "CL3 result payload should end on settlement phase after a clear")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "sigil_matrix", "CL3 result payload should persist the selected reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "Sigil Matrix", "CL3 result payload should persist the selected reward title")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Sovereign archive sealed | Sigil Matrix | Sigil +3", "CL3 result payload should persist the selected reward summary")
	assert_eq(int(challenge_layer_result.get("challenge_layer_rooms_cleared", 0)), 4, "CL3 result payload should record the elite-plus-combat-plus-boss clear count")

	var run_result: Dictionary = _submit_challenge_run_result("victory", challenge_layer_result)
	var challenge_record: Dictionary = run_result.get("challenge_layer_record", {})
	assert_eq(str(challenge_record.get("id", "")), "CL3", "CL3 clear should surface the CL3 archive record")
	assert_eq(int(challenge_record.get("clears", 0)), 1, "CL3 clear should archive one clear for the third challenge layer")
	assert_eq(int(challenge_record.get("best_rooms", 0)), 4, "CL3 clear should archive the deeper room count")
	assert_eq(int(challenge_record.get("best_kills", 0)), 0, "CL3 clear should preserve the current forced-clear kill total used by this runtime regression")
	assert_eq(int(challenge_record.get("total_sigils", 0)), 3, "CL3 clear should archive the frontier sigil payout")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Sigil Matrix", "CL3 clear should archive the last selected reward title")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview safe camp label should exist after a CL3 clear")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Challenge Layer III:", "safe camp should continue surfacing the CL3 preview after a clear")
	assert_string_contains(preview_label.text, "Archive record: Clears 1 | Best Rooms 4 | Best Kills 0", "safe camp should echo the archived CL3 record after a clear")
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +3 | Insight +0", "safe camp should echo the archived CL3 ledger after a clear")
	assert_string_contains(preview_label.text, "Last archived reward: Sigil Matrix", "safe camp should echo the archived CL3 reward title after a clear")


func test_safe_camp_can_enter_challenge_layer_four_and_finish_apex_settlement_loop() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_four_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return

	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Challenge Layer IV:", "safe camp should surface a fourth challenge-layer preview header after a CL3 clear")
	assert_string_contains(status_label.text, "Route frame: Entry + elite + combat + elite + boss + settlement", "safe camp should preview the CL4 route frame before entry")
	assert_string_contains(status_label.text, "Entry hint: Clear Challenge Layer III once to unlock the fourth challenge layer.", "safe camp should surface the CL4 entry hint")
	assert_string_contains(status_label.text, "Entry preview: Challenge Layer IV Entry", "safe camp should preview the CL4 entry room title")
	assert_string_contains(status_label.text, "Combat preview: Ascent Wardens", "safe camp should preview the CL4 first combat stage")
	assert_string_contains(status_label.text, "Settlement stage: Challenge Layer IV Settlement", "safe camp should preview the CL4 settlement stage")
	assert_string_contains(status_label.text, "Reward preview: Apex archive sealed | Meta +100 | Sigil +4 | Insight +4", "safe camp should preview the CL4 reward package before entry")
	assert_string_contains(status_label.text, "Reward choices: Apex Meta Cache | Sigil Constellation | Insight Throne", "safe camp should preview the CL4 settlement reward choices before entry")
	assert_string_contains(status_label.text, "P: Enter Challenge Layer IV", "safe camp should advertise the CL4 hotkey once CL3 is cleared")

	world.call("_try_enter_challenge_layer", "CL4")
	assert_eq(str(world.get("_active_challenge_layer_id")), "CL4", "world should switch into challenge layer CL4")
	assert_eq(int(world.get("_room_index")), 1, "CL4 should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL4 should begin from a staging room")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer IV Entry | Challenge staging", "CL4 entry room should surface the apex staging title")
	assert_string_contains(status_label.text, "Press E -> Ascent Wardens", "CL4 entry room should surface the first ascent prompt")

	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 2, "CL4 should advance into its first elite room")
	assert_eq(str(world.get("_current_room_type")), "elite", "CL4 second room should be an elite challenge room")
	assert_string_contains(status_label.text, "Ascent Wardens", "CL4 first elite room should surface the ascent-wardens title")
	assert_string_contains(status_label.text, "Break the ascent wardens and force the summit breach open.", "CL4 first elite room should surface the ascent objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 3, "CL4 should advance into its breach room")
	assert_eq(str(world.get("_current_room_type")), "combat", "CL4 third room should be a standard combat room")
	assert_string_contains(status_label.text, "Summit Breach", "CL4 breach room should surface the summit-breach title")
	assert_string_contains(status_label.text, "Hold the summit breach against the archive storm and reveal the throne approach.", "CL4 breach room should surface the sustained-combat objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 4, "CL4 should advance into its second elite room")
	assert_eq(str(world.get("_current_room_type")), "elite", "CL4 fourth room should be a second elite challenge room")
	assert_string_contains(status_label.text, "Throne Approach", "CL4 second elite room should surface the throne-approach title")
	assert_string_contains(status_label.text, "Shatter the throne approach and expose the apex sovereign.", "CL4 second elite room should surface the throne-approach objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 5, "CL4 should advance into its apex boss room")
	assert_eq(str(world.get("_current_room_type")), "boss", "CL4 fifth room should be a boss room")
	assert_string_contains(status_label.text, "Apex Throne", "CL4 boss room should surface the apex-throne title")
	assert_string_contains(status_label.text, "Defeat the apex sovereign and secure the final return protocol.", "CL4 boss room should surface the apex objective")
	_clear_active_challenge_room(world)
	world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 6, "CL4 should advance into its settlement room")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "CL4 should finish in a settlement safe camp")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Layer IV Settlement", "CL4 settlement should surface the apex settlement title")
	assert_string_contains(status_label.text, "1) Apex Meta Cache", "CL4 settlement should list the first apex reward option")
	assert_string_contains(status_label.text, "2) Sigil Constellation", "CL4 settlement should list the second apex reward option")
	assert_string_contains(status_label.text, "3) Insight Throne", "CL4 settlement should list the third apex reward option")

	world.call("_try_buy_challenge_reward_slot", 2)
	assert_string_contains(status_label.text, "Bought Insight Throne", "CL4 settlement should confirm the selected reward")
	assert_string_contains(status_label.text, "Reward preview: Apex archive sealed | Insight Throne | Insight +4", "CL4 settlement should preview the selected reward summary")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +0 | Sigil +0 | Insight +4", "CL4 settlement should surface the selected reward payload detail")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(challenge_layer_result.get("challenge_layer_id", "")), "CL4", "CL4 result payload should persist the apex layer id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_phase", "")), "settlement", "CL4 result payload should end on settlement phase after a clear")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "insight_throne", "CL4 result payload should persist the selected reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "Insight Throne", "CL4 result payload should persist the selected reward title")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Apex archive sealed | Insight Throne | Insight +4", "CL4 result payload should persist the selected reward summary")
	assert_eq(int(challenge_layer_result.get("challenge_layer_rooms_cleared", 0)), 5, "CL4 result payload should record the full apex progression count")

	var run_result: Dictionary = _submit_challenge_run_result("victory", challenge_layer_result)
	var challenge_record: Dictionary = run_result.get("challenge_layer_record", {})
	assert_eq(str(challenge_record.get("id", "")), "CL4", "CL4 clear should surface the CL4 archive record")
	assert_eq(int(challenge_record.get("clears", 0)), 1, "CL4 clear should archive one clear for the fourth challenge layer")
	assert_eq(int(challenge_record.get("best_rooms", 0)), 5, "CL4 clear should archive the apex room count")
	assert_eq(int(challenge_record.get("best_kills", 0)), 0, "CL4 clear should preserve the current forced-clear kill total used by this runtime regression")
	assert_eq(int(challenge_record.get("total_insight", 0)), 4, "CL4 clear should archive the apex insight payout")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Insight Throne", "CL4 clear should archive the last selected reward title")
	assert_eq(float(run_result.get("meta_return_multiplier", 1.0)), 1.6, "CL4 clear should unlock the final apex meta return milestone")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview safe camp label should exist after a CL4 clear")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Challenge Layer IV:", "safe camp should continue surfacing the CL4 preview after a clear")
	assert_string_contains(preview_label.text, "Archive record: Clears 1 | Best Rooms 5 | Best Kills 0", "safe camp should echo the archived CL4 record after a clear")
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +0 | Insight +4", "safe camp should echo the archived CL4 ledger after a clear")
	assert_string_contains(preview_label.text, "Last archived reward: Insight Throne", "safe camp should echo the archived CL4 reward title after a clear")


func test_challenge_layer_failure_path_records_attempt_without_reward() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return
	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	world.call("_try_enter_challenge_layer", "CL1")
	world.call("_advance_to_next_room")
	assert_eq(int(world.get("_room_index")), 2, "failure-path test should stop in the combat ring")
	assert_eq(str(world.get("_current_room_type")), "combat", "failure-path test should keep the challenge in combat")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "defeat")
	assert_eq(str(challenge_layer_result.get("challenge_layer_phase", "")), "combat", "defeat payload should record the combat phase")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "", "defeat payload should not claim a reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "", "defeat payload should not claim a reward title")
	assert_true((challenge_layer_result.get("challenge_layer_reward_payload", {}) as Dictionary).is_empty(), "defeat payload should not grant any challenge reward payload")
	assert_eq(str(challenge_layer_result.get("challenge_layer_settlement_summary", "")), "", "defeat payload should not claim settlement text")
	assert_string_contains(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "archived without payout", "defeat payload should surface the no-payout summary")
	assert_string_contains(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Challenge Combat Ring", "defeat payload should identify where the challenge failed")

	var result: Dictionary = _submit_challenge_run_result("defeat", challenge_layer_result)
	var challenge_record: Dictionary = result.get("challenge_layer_record", {})
	assert_eq(int(challenge_record.get("attempts", 0)), 1, "challenge record should count failed attempts")
	assert_eq(int(challenge_record.get("clears", 0)), 0, "challenge record should not count failed clears")
	assert_eq(int(challenge_record.get("total_meta_bonus", 0)), 0, "failed challenge runs should not add meta bonus to the ledger")
	assert_eq(int(challenge_record.get("total_sigils", 0)), 0, "failed challenge runs should not add sigils to the ledger")
	assert_eq(int(challenge_record.get("total_insight", 0)), 0, "failed challenge runs should not add insight to the ledger")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "", "failed challenge runs should not stamp a last reward title")

	var panel: Control = await _instantiate_run_result_panel()
	if panel == null:
		return
	panel.call("show_result", result)
	var unlock_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Unlocks")
	assert_not_null(unlock_label, "run result unlock label should exist")
	if unlock_label == null:
		return
	assert_string_contains(unlock_label.text, "Challenge Layer:", "result panel should still surface challenge archive data for failed attempts")
	assert_string_contains(unlock_label.text, "Phase: Combat", "result panel should identify the combat failure phase")
	assert_string_contains(unlock_label.text, "Challenge archive attempt archived without payout", "result panel should explain the no-payout failure summary")
	assert_string_contains(unlock_label.text, "Archive Stats: attempts=1 | clears=0", "result panel should show failed attempt archive stats")
	assert_string_contains(unlock_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +0", "result panel should keep the failed-attempt ledger at zero")
	assert_false(unlock_label.text.contains("Reward Choice:"), "result panel should not invent a reward choice for failed attempts")
	assert_false(unlock_label.text.contains("The settlement records this challenge clear for the next postgame step."), "result panel should not invent the challenge settlement summary for failed attempts")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return
	var last_run_label: Label = _find_menu_label(menu, "LastRunValue")
	assert_not_null(last_run_label, "last run label should exist")
	if last_run_label == null:
		return
	assert_string_contains(last_run_label.text, "Challenge CL1", "main menu last run summary should still surface the failed challenge layer id")
	assert_string_contains(last_run_label.text, "Phase: Combat", "main menu last run summary should show the failed challenge phase")
	assert_string_contains(last_run_label.text, "Challenge archive attempt archived without payout", "main menu last run summary should explain the no-payout failure summary")
	assert_string_contains(last_run_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +0", "main menu last run summary should keep the failed-attempt ledger at zero")
	assert_false(last_run_label.text.contains("Reward Choice:"), "main menu last run summary should not invent a reward choice for failed attempts")
	assert_false(last_run_label.text.contains("The settlement records this challenge clear for the next postgame step."), "main menu last run summary should not invent the challenge settlement summary for failed attempts")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview world status label should exist")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Archive record: Clears 0 | Best Rooms 0 | Best Kills 0", "safe camp preview should echo the failed attempt archive record")
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +0 | Insight +0", "safe camp preview should keep the failed-attempt ledger at zero")


func test_challenge_layer_sigil_bundle_branch_updates_archive_preview() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return
	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	_reach_challenge_layer_settlement(world)
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Challenge Settlement", "sigil-branch test should reach the challenge settlement room")

	world.call("_try_buy_challenge_reward_slot", 1)
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Bought Sigil Bundle", "settlement should confirm the sigil reward purchase")
	assert_string_contains(status_label.text, "Reward preview: Challenge archive sealed | Sigil Bundle | Sigil +1", "settlement should preview the selected sigil reward summary")
	assert_string_contains(status_label.text, "Selected Reward: Sigil Bundle", "settlement should surface the sigil reward title")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +0 | Sigil +1 | Insight +0", "settlement should surface the sigil reward payload detail")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "sigil_bundle", "sigil branch should persist the selected reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "Sigil Bundle", "sigil branch should persist the selected reward title")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Challenge archive sealed | Sigil Bundle | Sigil +1", "sigil branch should persist the selected reward summary")

	var result: Dictionary = _submit_challenge_run_result("victory", challenge_layer_result)
	var challenge_record: Dictionary = result.get("challenge_layer_record", {})
	assert_eq(int(challenge_record.get("total_meta_bonus", 0)), 0, "sigil branch should not add meta bonus to the archive ledger")
	assert_eq(int(challenge_record.get("total_sigils", 0)), 1, "sigil branch should add one sigil to the archive ledger")
	assert_eq(int(challenge_record.get("total_insight", 0)), 0, "sigil branch should not add insight to the archive ledger")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Sigil Bundle", "sigil branch should update the archive last reward title")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview world status label should exist")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +1 | Insight +0", "safe camp preview should echo the archived sigil ledger total")
	assert_string_contains(preview_label.text, "Last archived reward: Sigil Bundle", "safe camp preview should echo the archived sigil reward title")


func test_challenge_layer_archive_insight_branch_updates_result_ui_and_preview() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_challenge_layer_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return
	var status_label: Label = _prepare_safe_camp(world)
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	_reach_challenge_layer_settlement(world)
	world.call("_try_buy_challenge_reward_slot", 2)
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Bought Archive Insight", "settlement should confirm the insight reward purchase")
	assert_string_contains(status_label.text, "Reward preview: Challenge archive sealed | Archive Insight | Insight +1", "settlement should preview the selected insight reward summary")
	assert_string_contains(status_label.text, "Selected Reward: Archive Insight", "settlement should surface the insight reward title")
	assert_string_contains(status_label.text, "Selected Reward Detail: Meta +0 | Sigil +0 | Insight +1", "settlement should surface the insight reward payload detail")

	var challenge_layer_result: Dictionary = world.call("_build_challenge_layer_result_payload", "victory")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_id", "")), "archive_insight", "insight branch should persist the selected reward id")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_title", "")), "Archive Insight", "insight branch should persist the selected reward title")
	assert_eq(str(challenge_layer_result.get("challenge_layer_reward_summary", "")), "Challenge archive sealed | Archive Insight | Insight +1", "insight branch should persist the selected reward summary")

	var result: Dictionary = _submit_challenge_run_result("victory", challenge_layer_result)
	var challenge_record: Dictionary = result.get("challenge_layer_record", {})
	assert_eq(int(challenge_record.get("total_meta_bonus", 0)), 0, "insight branch should not add meta bonus to the archive ledger")
	assert_eq(int(challenge_record.get("total_sigils", 0)), 0, "insight branch should not add sigils to the archive ledger")
	assert_eq(int(challenge_record.get("total_insight", 0)), 1, "insight branch should add one insight to the archive ledger")
	assert_eq(str(challenge_record.get("last_reward_title", "")), "Archive Insight", "insight branch should update the archive last reward title")

	var panel: Control = await _instantiate_run_result_panel()
	if panel == null:
		return
	panel.call("show_result", result)
	var unlock_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Unlocks")
	assert_not_null(unlock_label, "run result unlock label should exist")
	if unlock_label == null:
		return
	assert_string_contains(unlock_label.text, "Reward Choice: Archive Insight", "result panel should surface the insight reward title")
	assert_string_contains(unlock_label.text, "Selected Reward Detail: Meta +0 | Sigil +0 | Insight +1", "result panel should surface the insight reward payload detail")
	assert_string_contains(unlock_label.text, "Challenge archive sealed | Archive Insight | Insight +1", "result panel should surface the insight reward summary")
	assert_string_contains(unlock_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +1", "result panel should surface the archived insight ledger total")
	assert_string_contains(unlock_label.text, "Last Reward: Archive Insight", "result panel should surface the archived insight reward title")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return
	var last_run_label: Label = _find_menu_label(menu, "LastRunValue")
	assert_not_null(last_run_label, "last run label should exist")
	if last_run_label == null:
		return
	assert_string_contains(last_run_label.text, "Reward Archive Insight", "main menu last run summary should surface the insight reward title")
	assert_string_contains(last_run_label.text, "Reward Detail: Meta +0 | Sigil +0 | Insight +1", "main menu last run summary should surface the insight reward payload detail")
	assert_string_contains(last_run_label.text, "Challenge archive sealed | Archive Insight | Insight +1", "main menu last run summary should surface the insight reward summary")
	assert_string_contains(last_run_label.text, "Reward Ledger: Meta +0 | Sigil +0 | Insight +1", "main menu last run summary should surface the archived insight ledger total")
	assert_string_contains(last_run_label.text, "Last Reward: Archive Insight", "main menu last run summary should surface the archived insight reward title")

	var preview_world: Node = await _instantiate_world()
	if preview_world == null:
		return
	var preview_label: Label = _prepare_safe_camp(preview_world)
	assert_not_null(preview_label, "preview world status label should exist")
	if preview_label == null:
		return
	assert_string_contains(preview_label.text, "Reward ledger: Meta +0 | Sigil +0 | Insight +1", "safe camp preview should echo the archived insight ledger total")
	assert_string_contains(preview_label.text, "Last archived reward: Archive Insight", "safe camp preview should echo the archived insight reward title")


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
	var last_run_label: Label = _find_menu_label(menu, "LastRunValue")
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


func test_save_manager_preserves_future_challenge_layer_records() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 14,
		"kills": 180,
		"level_reached": 10,
		"gold": 96,
		"ore": 18,
		"alignment": 0.0,
		"challenge_layer_id": "CL2",
		"challenge_layer_title": "Challenge Layer II",
		"challenge_layer_phase": "settlement",
		"challenge_layer_reward_id": "archive_insight",
		"challenge_layer_reward_title": "Archive Insight",
		"challenge_layer_reward_payload": {
			"meta_bonus": 0,
			"sigils": 0,
			"insight": 1
		},
		"challenge_layer_reward_summary": "Challenge archive sealed | Archive Insight | Insight +1",
		"challenge_layer_settlement_summary": "The second archive records a deeper challenge clear.",
		"challenge_layer_rooms_cleared": 4,
		"challenge_layer_kills": 36
	})

	var records: Dictionary = SaveManager.get_challenge_layer_records()
	assert_true(records.has("CL1"), "challenge records should keep the current CL1 baseline row")
	assert_true(records.has("CL2"), "challenge records should preserve future challenge-layer rows for CL2+")
	var cl2_record: Dictionary = SaveManager.get_challenge_layer_record("CL2")
	assert_eq(str(cl2_record.get("id", "")), "CL2", "future challenge-layer record should preserve its layer id")
	assert_eq(str(cl2_record.get("title", "")), "Challenge Layer II", "future challenge-layer record should preserve its title")
	assert_eq(int(cl2_record.get("attempts", 0)), 1, "future challenge-layer record should preserve attempts")
	assert_eq(int(cl2_record.get("clears", 0)), 1, "future challenge-layer record should preserve clears")
	assert_eq(int(cl2_record.get("best_rooms", 0)), 4, "future challenge-layer record should preserve best room count")
	assert_eq(int(cl2_record.get("best_kills", 0)), 36, "future challenge-layer record should preserve best kill count")
	assert_eq(int(cl2_record.get("total_insight", 0)), 1, "future challenge-layer record should preserve reward ledger totals")
	assert_eq(str(cl2_record.get("last_reward_title", "")), "Archive Insight", "future challenge-layer record should preserve its last reward title")
