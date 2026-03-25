extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"
const NARRATIVE_SYSTEM_SCRIPT := preload("res://scripts/systems/narrative_system.gd")


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


func _unlock_fs2_gate() -> void:
	SaveManager.reset_meta()
	for accessory_id: String in ["acc_heart_of_mine", "acc_flame_core", "acc_zero_mark", "acc_void_eye"]:
		SaveManager.unlock_codex_entry("accessories", accessory_id, "test_unlock", "global")
	SaveManager.submit_run_result({
		"outcome": "death",
		"rooms_cleared": 8,
		"kills": 120,
		"level_reached": 7,
		"gold": 64,
		"ore": 10,
		"alignment": 0.0
	})


func _clear_active_room(world: Node) -> void:
	var spawner: Node = world.get_node_or_null("EnemySpawner")
	assert_not_null(spawner, "enemy spawner should exist for hidden-layer combat rooms")
	if spawner == null:
		return
	if spawner.has_method("stop_room_combat"):
		spawner.call("stop_room_combat")
	world.set("_kills_in_room", int(world.get("_required_kills")))
	world.call("_try_clear_room")


func test_narrative_system_route_arc_and_camp_reflection_helpers() -> void:
	var system: Node = NARRATIVE_SYSTEM_SCRIPT.new()
	assert_not_null(system, "narrative system should instantiate")
	if system == null:
		return

	add_child_autofree(system)
	await get_tree().process_frame

	system.record_choice("chapter_3", "nar_evt_whispers", "keep_the_oath", 12.0)
	system.record_choice("chapter_3", "nar_evt_whispers", "answer_the_choir", 9.0)

	var route_arc: Dictionary = system.get_route_arc_summary(72.0, "vanguard")
	assert_eq(str(route_arc.get("arc_id", "")), "redeem", "high alignment should resolve to redeem route arc")
	assert_string_contains(str(route_arc.get("style_echo", "")), "Vanguard", "route arc should include route style echo")

	var unlocked_fragments: Array[String] = ["memory_ch1_boss", "memory_ch2_boss"]
	var reflection: Dictionary = system.get_camp_reflection("chapter_3", 72.0, "vanguard", unlocked_fragments)
	assert_eq(str(reflection.get("arc_id", "")), "redeem", "camp reflection should track redeem arc")
	assert_string_contains(str(reflection.get("fragment_progress", "")), "Fragment progress:", "camp reflection should include fragment progress summary")
	assert_string_contains(str(reflection.get("recent_choice_summary", "")), "Recent vows:", "camp reflection should include recent choice summary")

	var hidden_story: Dictionary = system.get_hidden_layer_story_payload("FS1", 72.0, "vanguard", ["nar_ending_redeem"])
	assert_eq(str(hidden_story.get("arc_id", "")), "redeem", "hidden-layer story should track redeem arc")
	assert_eq(str(hidden_story.get("fragment_id", "")), "memory_fs1_redeem", "hidden-layer story should resolve linked fragment id")
	assert_true(bool(hidden_story.get("ending_ready", false)), "hidden-layer story should mark ending linkage as ready when unlocked")


func test_camp_text_and_transition_panel_include_stage5_narrative_summaries() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_3", "safe_camp", [12])
	_set_room_plan(world, 12, "chapter_3", "boss", [])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_alignment", 68.0)
	world.set("_current_route_style", "vanguard")

	var narrative_system: Node = world.get_node_or_null("NarrativeSystem")
	assert_not_null(narrative_system, "game world should expose NarrativeSystem")
	if narrative_system == null:
		return

	narrative_system.call("record_choice", "chapter_3", "nar_evt_whispers", "keep_the_oath", 12.0)
	narrative_system.call("record_choice", "chapter_3", "nar_evt_whispers", "answer_the_choir", 9.0)
	var transition_fragment_triggers: Array[Dictionary] = [{
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
	world.set("_run_fragment_triggers", transition_fragment_triggers)

	world.call("_update_camp_text")
	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Route arc:", "camp text should include route arc line")
	assert_string_contains(status_label.text, "Camp reflection:", "camp text should include camp reflection line")
	assert_string_contains(status_label.text, "Fragment progress:", "camp text should include fragment progress line")
	assert_string_contains(status_label.text, "Recent vows:", "camp text should include recent choice summary")
	assert_string_contains(status_label.text, "Camp loop:", "camp text should include archive loop guidance")
	assert_string_contains(status_label.text, "Hidden track: FS1", "camp text should include FS1 hidden layer progress")
	assert_string_contains(status_label.text, "Hidden track: FS2", "camp text should include FS2 hidden layer progress")
	assert_string_contains(status_label.text, "Hidden spec: FS1", "camp text should include FS1 hidden layer interface summary")
	assert_string_contains(status_label.text, "Hidden spec: FS2", "camp text should include FS2 hidden layer interface summary")

	world.set("_room_index", 12)
	world.set("_current_room_type", "boss")
	world.call("_begin_chapter_transition", 3)

	var transition_panel: Control = world.get_node_or_null("ChapterTransitionPanel")
	assert_not_null(transition_panel, "chapter transition panel should exist")
	if transition_panel == null:
		return

	var body_label: Label = transition_panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Body")
	assert_not_null(body_label, "transition body label should exist")
	if body_label == null:
		return

	assert_string_contains(body_label.text, "Route arc:", "transition body should include route arc summary")
	assert_string_contains(body_label.text, "Fragment progress:", "transition body should include fragment progress summary")
	assert_string_contains(body_label.text, "Camp reflection:", "transition body should include camp reflection summary")
	assert_string_contains(body_label.text, "Fragment hint:", "transition body should include reflection fragment hint")
	assert_string_contains(body_label.text, "Route echo:", "transition body should include reflection route echo")
	assert_string_contains(body_label.text, "Forward note:", "transition body should include the next-step forward note")
	assert_string_contains(body_label.text, "Hidden hook:", "transition body should include hidden route lead summary")
	assert_string_contains(body_label.text, "Hook teaser:", "transition body should include hidden route teaser")
	assert_string_contains(body_label.text, "Hook unlock:", "transition body should include hidden route unlock hint")
	assert_string_contains(body_label.text, "Hook status:", "transition body should include hidden route readiness")
	assert_string_contains(body_label.text, "Hidden track: FS1", "transition body should include FS1 hidden-layer progress")
	assert_string_contains(body_label.text, "Hidden spec: FS1", "transition body should include FS1 hidden-layer interface summary")
	assert_string_contains(body_label.text, "Hidden entry: FS1", "transition body should include FS1 hidden-layer entry hint")
	assert_string_contains(body_label.text, "Hidden reward: FS1", "transition body should include FS1 hidden-layer reward summary")
	assert_string_contains(body_label.text, "Hidden settlement: FS1", "transition body should include FS1 hidden-layer settlement summary")
	assert_string_contains(body_label.text, "Fragment recap:", "transition body should include fragment recap summary")
	assert_string_contains(body_label.text, "Grace Ledger", "transition body should include recap profile title")
	assert_string_contains(body_label.text, "Pace Hint:", "transition body should include fragment recap pace hint")
	assert_string_contains(body_label.text, "Recap Stats: triggers=1 | new=1", "transition body should include fragment recap counts")
	assert_string_contains(body_label.text, "Trigger Focus: CAMP", "transition body should include fragment recap trigger focus")
	assert_string_contains(body_label.text, "Recent vows:", "transition body should include recent choice summary")
	assert_string_contains(body_label.text, "Camp loop:", "transition body should include camp archive loop guidance")


func test_memory_altar_surfaces_fragment_recap_and_hidden_route_sections() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	var world: Node = await _instantiate_world()
	if world == null:
		return

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

	var narrative_system: Node = world.get_node_or_null("NarrativeSystem")
	assert_not_null(narrative_system, "game world should expose NarrativeSystem")
	if narrative_system == null:
		return

	narrative_system.call("record_choice", "chapter_3", "nar_evt_whispers", "keep_the_oath", 12.0)
	world.set("_alignment", 68.0)
	world.set("_current_route_style", "vanguard")
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.set("_run_fragment_triggers", [{
		"chapter_id": "chapter_3",
		"trigger_type": "camp",
		"arc_id": "redeem",
		"style": "vanguard",
		"fragment_id": "memory_ch3_transition_halo",
		"fragment_title": "Fragment XII: White Across the Threshold",
		"fragment_text": "A bell note survives the crossing.",
		"newly_unlocked": true,
		"room_index": 10
	}])

	world.call("_open_memory_altar")
	var altar_panel: Control = world.get_node_or_null("MemoryAltarPanel")
	assert_not_null(altar_panel, "memory altar panel should exist")
	if altar_panel == null:
		return

	var body_label: Label = altar_panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Body")
	assert_not_null(body_label, "memory altar body label should exist")
	if body_label == null:
		return

	assert_string_contains(body_label.text, "Archive Recap", "memory altar should open on the archive recap page")
	assert_string_contains(body_label.text, "Fragment Recap", "memory altar should surface fragment recap section")
	assert_string_contains(body_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "memory altar should surface fragment recap route echo")
	assert_string_contains(body_label.text, "Recap Stats: triggers=1 | new=1", "memory altar should surface fragment recap stats")
	assert_string_contains(body_label.text, "Review Entry: Page 1 anchors the archive recap before fragment pages.", "memory altar should explain the archive recap review entry")
	assert_string_contains(body_label.text, "Hidden Route Lead", "memory altar should surface hidden route lead section")
	assert_string_contains(body_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "memory altar should surface hidden route route-echo guidance")
	assert_string_contains(body_label.text, "Review Entry: Page 1 tracks the hidden route lead for later camp checks.", "memory altar should explain the hidden route review entry")
	assert_string_contains(body_label.text, "Hidden Layer Track", "memory altar should surface hidden layer progress section")
	assert_string_contains(body_label.text, "Hidden spec: FS1", "memory altar should surface FS1 interface summary")
	assert_string_contains(body_label.text, "Hidden entry: FS1", "memory altar should surface FS1 hidden-layer entry hint")
	assert_string_contains(body_label.text, "Hidden reward: FS1", "memory altar should surface FS1 hidden-layer reward summary")
	assert_string_contains(body_label.text, "Hidden settlement: FS1", "memory altar should surface FS1 hidden-layer settlement summary")
	assert_string_contains(body_label.text, "Review Entry: Page 1 tracks hidden-layer progress, rewards, and archive carryover.", "memory altar should explain the hidden-layer track review entry")


func test_safe_camp_can_enter_hidden_layer_and_show_settlement_archive() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 15,
		"kills": 300,
		"level_reached": 12,
		"gold": 180,
		"ore": 30,
		"alignment": 70.0,
		"route_style": "vanguard",
		"boss_flawless_chapters": ["chapter_1", "chapter_2", "chapter_3"]
	})

	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_3", "safe_camp", [12])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.call("_update_camp_text")

	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "R: Enter Time Rift", "safe camp should advertise unlocked FS1 entry")

	world.call("_try_enter_hidden_layer", "FS1")
	assert_eq(str(world.get("_active_hidden_layer_id")), "FS1", "game world should switch into FS1 when the layer is selected")
	assert_eq(int(world.get("_room_index")), 1, "hidden layer should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "combat", "FS1 should enter through a playable combat room")
	var room_plan: Dictionary = world.call("_get_room_plan", 1)
	assert_eq(str(room_plan.get("hidden_layer_id", "")), "FS1", "hidden layer entry room should carry FS1 metadata")

	world.set("_alignment", 70.0)
	world.set("_current_route_style", "vanguard")
	world.set("_hidden_layer_best_pressure_stage", 3)
	world.set("_hidden_layer_best_survival_seconds", 46.0)
	world.set("_hidden_layer_target_pressure_stage", 2)
	world.set("_hidden_layer_selected_boss_echo_id", "boss_frost_king")
	world.set("_hidden_layer_boss_echo_collection", ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"])
	world.set("_room_index", 4)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Reward preview:", "hidden settlement should show archive reward preview")
	assert_string_contains(status_label.text, "Pressure:", "hidden settlement should show gameplay pressure archive line")
	assert_string_contains(status_label.text, "Collection:", "hidden settlement should show archive collection line")
	assert_string_contains(status_label.text, "Echoes 4/4", "hidden settlement should show FS1 echo archive progress")
	assert_string_contains(status_label.text, "Mastery:", "hidden settlement should preview mastery bonus state")
	assert_string_contains(status_label.text, "ready", "hidden settlement should preview an unclaimed mastery bonus")
	assert_string_contains(status_label.text, "Frost King", "hidden settlement should surface the selected boss echo title")
	assert_string_contains(status_label.text, "Archive story:", "hidden settlement should preview hidden-layer story")
	assert_string_contains(status_label.text, "Route Echo: REDEEM | Vanguard routes favor safer pressure and disciplined pacing.", "hidden settlement should preview hidden-layer story route echo")
	assert_string_contains(status_label.text, "Ending link:", "hidden settlement should preview ending linkage")
	assert_string_contains(status_label.text, "Fragment preview:", "hidden settlement should preview hidden-layer fragment")
	assert_string_contains(status_label.text, "Fragment Text: The choir answered from below the ward, proving that vows kept in the upper halls can still echo through the fractures under time itself.", "hidden settlement should preview hidden-layer fragment text")
	assert_string_contains(status_label.text, "Review Entry: Memory Altar -> Hidden Layer Track", "hidden settlement should point players to the hidden-layer story review entry")
	assert_string_contains(status_label.text, "Archive clear and finish run", "hidden settlement should explain the archive exit flow")

	var result_payload: Dictionary = world.call("_build_hidden_layer_result_payload", "victory")
	var gameplay_payload: Dictionary = result_payload.get("hidden_layer_gameplay", {})
	assert_eq(int(gameplay_payload.get("pressure_stage", 0)), 3, "hidden-layer result payload should persist best pressure stage")
	assert_eq(str(gameplay_payload.get("boss_echo_id", "")), "boss_frost_king", "hidden-layer result payload should persist selected boss echo")
	assert_eq((gameplay_payload.get("boss_echo_collection", []) as Array).size(), 4, "hidden-layer result payload should persist collected boss echoes")
	assert_true(bool(gameplay_payload.get("collection_complete", false)), "hidden-layer result payload should mark mastery completion when all echoes are collected")
	assert_string_contains(str(gameplay_payload.get("mastery_label", "")), "ready", "hidden-layer gameplay payload should preview an unclaimed mastery bonus")
	var story_payload: Dictionary = result_payload.get("hidden_layer_story", {})
	assert_eq(str(story_payload.get("fragment_id", "")), "memory_fs1_redeem", "hidden-layer clear payload should include linked story fragment")
	var trigger_log: Array = world.get("_run_fragment_triggers")
	assert_eq(trigger_log.size(), 1, "hidden-layer clear should append one archive fragment trigger")


func test_safe_camp_can_enter_fs2_and_finish_forge_settlement_loop() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	_unlock_fs2_gate()
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_4", "safe_camp", [12])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.set("_room_active", false)
	world.set("_alignment", 68.0)
	world.set("_current_route_style", "vanguard")
	world.call("_update_camp_text")

	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Y: Enter Genesis Forge", "safe camp should advertise unlocked FS2 entry")

	world.call("_try_enter_hidden_layer", "FS2")
	assert_eq(str(world.get("_active_hidden_layer_id")), "FS2", "game world should switch into FS2 when the layer is selected")
	assert_eq(int(world.get("_room_index")), 1, "FS2 should restart at its own room 1")
	assert_eq(str(world.get("_current_room_type")), "combat", "FS2 should open with a playable forge combat room")

	var expected_rooms: Array[Dictionary] = [
		{"index": 1, "type": "combat", "trial_depth": 1, "trial_label": "Forge Trial I: Ore Tempering"},
		{"index": 2, "type": "elite", "trial_depth": 2, "trial_label": "Forge Trial II: Ember Fold"},
		{"index": 3, "type": "combat", "trial_depth": 3, "trial_label": "Forge Trial III: Frost Bind"},
		{"index": 4, "type": "elite", "trial_depth": 4, "trial_label": "Forge Trial IV: Void Sunder"},
		{"index": 5, "type": "boss", "trial_depth": 5, "trial_label": "Forge Trial V: Genesis Core"}
	]
	for row: Dictionary in expected_rooms:
		assert_eq(int(world.get("_room_index")), int(row.get("index", 0)), "FS2 should advance through the forge rooms in order")
		assert_eq(str(world.get("_current_room_type")), str(row.get("type", "")), "FS2 room type should match the forge plan")
		var room_plan: Dictionary = world.call("_get_room_plan", int(row.get("index", 0)))
		assert_eq(str(room_plan.get("hidden_layer_id", "")), "FS2", "FS2 room plan should stay tagged to the forge layer")
		assert_eq(int(room_plan.get("trial_depth", 0)), int(row.get("trial_depth", 0)), "FS2 room plan should expose the expected forge depth")
		assert_eq(str(room_plan.get("trial_label", "")), str(row.get("trial_label", "")), "FS2 room plan should expose the expected forge trial label")
		_clear_active_room(world)
		assert_false(bool(world.get("_room_active")), "clearing a forge room should deactivate it before the next trial")
		world.call("_advance_to_next_room")

	assert_eq(int(world.get("_room_index")), 6, "FS2 should advance into its settlement room after the forge boss")
	assert_eq(str(world.get("_current_room_type")), "safe_camp", "FS2 should finish in a forge settlement room")
	world.call("_update_camp_text")
	assert_string_contains(status_label.text, "Forge Settlement | Hidden settlement", "FS2 settlement should surface the forge settlement header")
	assert_string_contains(status_label.text, "Reward preview:", "FS2 settlement should surface the forge reward preview")
	assert_string_contains(status_label.text, "Trial: Forge Trial V: Genesis Core", "FS2 settlement should surface the deepest forge trial label")
	assert_string_contains(status_label.text, "Collection: Trials 5/5 - Forge Trial V: Genesis Core", "FS2 settlement should surface full forge archive progress")
	assert_string_contains(status_label.text, "Mastery: Forge Archive Mastered | Draft +1 | Merge +1 ready", "FS2 settlement should preview the forge mastery bonus state")
	assert_string_contains(status_label.text, "Archive story:", "FS2 settlement should preview hidden-layer story")
	assert_string_contains(status_label.text, "Fragment preview:", "FS2 settlement should preview hidden-layer fragment")
	assert_string_contains(status_label.text, "Archive clear and finish run", "FS2 settlement should explain the archive exit flow")

	var result_payload: Dictionary = world.call("_build_hidden_layer_result_payload", "victory")
	var reward_payload: Dictionary = result_payload.get("hidden_layer_reward_payload", {})
	var gameplay_payload: Dictionary = result_payload.get("hidden_layer_gameplay", {})
	assert_eq(int(reward_payload.get("recipe_drafts", 0)), 3, "FS2 result payload should grant three recipe drafts after a full mastered forge clear")
	assert_eq(int(reward_payload.get("relic_merges", 0)), 2, "FS2 result payload should grant two relic merges after a full mastered forge clear")
	assert_string_contains(str(result_payload.get("hidden_layer_reward_summary", "")), "Legendary recipe draft +3", "FS2 result payload should surface the forge reward summary")
	assert_eq(int(gameplay_payload.get("trial_depth", 0)), 5, "FS2 gameplay payload should persist the deepest trial depth")
	assert_eq(int(gameplay_payload.get("trial_depth_max", 0)), 5, "FS2 gameplay payload should persist the forge depth cap")
	assert_eq(str(gameplay_payload.get("deepest_trial_label", "")), "Forge Trial V: Genesis Core", "FS2 gameplay payload should persist the deepest forge label")
	assert_eq((gameplay_payload.get("trial_labels", []) as Array).size(), 5, "FS2 gameplay payload should persist the full forge trial collection")
	assert_true(bool(gameplay_payload.get("collection_complete", false)), "FS2 gameplay payload should mark the forge archive collection as complete")
	assert_string_contains(str(gameplay_payload.get("mastery_label", "")), "ready", "FS2 gameplay payload should preview the unclaimed forge mastery bonus")

	var run_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 20,
		"kills": 410,
		"level_reached": 14,
		"gold": 260,
		"ore": 52,
		"alignment": 68.0,
		"route_style": "vanguard",
		"hidden_layer_id": str(result_payload.get("hidden_layer_id", "")),
		"hidden_layer_rooms_cleared": int(result_payload.get("hidden_layer_rooms_cleared", 0)),
		"hidden_layer_kills": int(result_payload.get("hidden_layer_kills", 0)),
		"hidden_layer_reward_payload": reward_payload,
		"hidden_layer_reward_summary": str(result_payload.get("hidden_layer_reward_summary", "")),
		"hidden_layer_gameplay": gameplay_payload,
		"hidden_layer_story": result_payload.get("hidden_layer_story", {})
	})
	var hidden_record: Dictionary = run_result.get("hidden_layer_record", {})
	assert_eq(int(hidden_record.get("clears", 0)), 1, "FS2 clear should persist one hidden-layer clear in the archive record")
	assert_eq(int(hidden_record.get("recipe_drafts", 0)), 3, "FS2 archive record should persist recipe draft totals from the runtime clear")
	assert_eq(int(hidden_record.get("relic_merges", 0)), 2, "FS2 archive record should persist relic merge totals from the runtime clear")
