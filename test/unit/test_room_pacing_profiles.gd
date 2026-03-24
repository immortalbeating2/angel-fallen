extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


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


func test_route_briefs_and_required_kills_follow_chapter_room_profiles() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 9, "chapter_3", "combat", [10])
	_set_room_plan(world, 10, "chapter_3", "elite", [])
	_set_room_plan(world, 11, "chapter_4", "treasure", [])

	assert_eq(world.call("_format_room_route_brief", 9), "R9-FROST-CMB", "chapter_3 combat route brief should use frost pacing tag")
	assert_eq(world.call("_format_room_route_brief", 10), "R10-FROST-ELT", "chapter_3 elite route brief should use frost elite tag")

	var base_combat_kills: int = 10 + 9 * 3
	var scaled_combat_kills: int = int(world.call("_get_room_required_kills", 9, base_combat_kills))
	assert_gt(scaled_combat_kills, base_combat_kills, "chapter_3 combat profile should increase required kills")

	var treasure_reward_mult: float = float(world.call("_get_room_reward_mult", 11))
	assert_gt(treasure_reward_mult, 1.0, "late chapter treasure profile should boost rewards")


func test_room_entry_text_uses_chapter_room_profile_labels() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 10, "chapter_3", "safe_camp", [12])
	_set_room_plan(world, 12, "chapter_3", "boss", [])
	world.set("_room_index", 10)
	world.set("_current_room_type", "safe_camp")
	world.call("_enter_safe_camp_room")

	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	assert_string_contains(status_label.text, "Aurora Camp", "safe camp text should use chapter-specific title")
	assert_string_contains(status_label.text, "Warm the party before the throne road", "safe camp text should include chapter-specific objective")
	assert_string_contains(status_label.text, "FROST-BOSS", "safe camp route hint should use chapter-specific route tag")
	assert_string_contains(status_label.text, "Aurora camp complete. Next push enters chapter_4 collapse pressure.", "safe camp text should include chapter progression recovery note")

	_set_room_plan(world, 12, "chapter_3", "boss", [])
	world.set("_room_index", 12)
	world.set("_current_room_type", "boss")
	world.call("_enter_boss_room")

	assert_string_contains(status_label.text, "Aurora Throne", "boss room should use chapter-specific title")
	assert_string_contains(status_label.text, "Unseat the Frost King", "boss room should use chapter-specific objective")
	assert_string_contains(status_label.text, "Reflection pulses punish greedy movement.", "boss room should include chapter-specific pacing hint")


func test_chapter_progression_texts_drive_clear_transition_and_event_messages() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 13, "chapter_4", "combat", [14])
	_set_room_plan(world, 14, "chapter_4", "event", [15])
	_set_room_plan(world, 15, "chapter_4", "boss", [])

	var status_label: Label = world.get_node_or_null("HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue")
	assert_not_null(status_label, "room status label should exist")
	if status_label == null:
		return

	world.set("_room_index", 13)
	world.set("_current_room_type", "combat")
	var transition_effects: Array[Dictionary] = [
		{
			"title": "Shrine of Grace",
			"remaining_rooms": 2,
			"effects": {"damage_bonus_pct": 0.12, "hazard_intensity_mult": 0.85}
		},
		{
			"title": "Ashen Tax",
			"remaining_rooms": 1,
			"effects": {"enemy_damage_mult": 1.15, "hazard_intensity_mult": 1.2}
		}
	]
	world.set("_active_chapter_effects", transition_effects)
	world.call("_ensure_room_history", 13, "combat")
	world.call("_try_clear_room")
	assert_string_contains(status_label.text, "Void lane secured.", "clear message should use chapter progression clear_banner")
	assert_string_contains(status_label.text, "Corruption climbs with every delay.", "clear message should include room pacing status hint")
	assert_string_contains(status_label.text, "Checkpoint: VOID-CHECK", "clear message should include chapter checkpoint label")
	assert_string_contains(status_label.text, "Mainline: Breach the void line", "clear message should expose chapter mainline node")
	assert_string_contains(status_label.text, "Void memory trace:", "clear message should include chapter history recap prefix")

	world.call("_begin_chapter_transition", 4)
	assert_string_contains(status_label.text, "Void front breached.", "transition intro should use chapter progression intro text")
	var transition_panel: Control = world.get_node_or_null("ChapterTransitionPanel")
	assert_not_null(transition_panel, "chapter transition panel should exist")
	if transition_panel == null:
		return
	var body_label: Label = transition_panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Body")
	assert_not_null(body_label, "transition body label should exist")
	if body_label == null:
		return
	assert_string_contains(body_label.text, "Checkpoint: VOID-CHECK", "transition body should include chapter checkpoint label")
	assert_string_contains(body_label.text, "Mainline: Breach the void line", "transition body should include chapter mainline node")
	assert_string_contains(body_label.text, "Void memory trace:", "transition body should include chapter history recap")
	assert_string_contains(body_label.text, "Chapter hazards ahead: void_rift, void_corruption", "transition body should preview chapter hazard forecast")
	assert_string_contains(body_label.text, "Active chapter effects: [+] Shrine of Grace(2), [-] Ashen Tax(1)", "transition body should preview active chapter effects")
	assert_string_contains(body_label.text, "Next route: Press E -> R14-VOID-EVT", "transition body should preview the next route hint")

	world.call("_on_transition_closed")
	assert_string_contains(status_label.text, "Void chapter resolved. Final route locked.", "transition close should use chapter progression resolved text")
	assert_string_contains(status_label.text, "Checkpoint: VOID-CHECK", "transition close should keep chapter checkpoint label")
	assert_string_contains(status_label.text, "Mainline: Breach the void line", "transition close should keep chapter mainline node")
	assert_string_contains(status_label.text, "Void memory trace:", "transition close should include chapter history recap")

	world.set("_room_index", 14)
	world.set("_current_room_type", "event")
	world.call("_on_event_closed")
	assert_string_contains(status_label.text, "Threshold echo sealed. Final route pressure is set.", "event close should use chapter progression event text")
	assert_string_contains(status_label.text, "Mainline: Seal the threshold echo", "event close should expose event mainline node")
	assert_string_contains(status_label.text, "Void memory trace:", "event close should include chapter history recap")


func test_room_history_records_progression_pace_tags_and_clear_metadata() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	_set_room_plan(world, 9, "chapter_3", "elite", [10])
	world.set("_room_index", 9)
	world.set("_current_room_type", "elite")
	world.call("_ensure_room_history", 9, "elite")

	var room_history_var: Variant = world.get("_room_history")
	assert_typeof(room_history_var, TYPE_DICTIONARY, "_room_history should be a Dictionary")
	if not (room_history_var is Dictionary):
		return

	var room_history: Dictionary = room_history_var
	var row_var: Variant = room_history.get(9, {})
	assert_typeof(row_var, TYPE_DICTIONARY, "room 9 history row should exist")
	if not (row_var is Dictionary):
		return

	var row: Dictionary = row_var
	assert_eq(str(row.get("chapter_id", "")), "chapter_3", "history row should store chapter_id")
	assert_eq(str(row.get("route_tag", "")), "FROST-ELT", "history row should store chapter-specific route tag")
	assert_eq(str(row.get("pace_tag", "")), "frost_hunt", "history row should store chapter progression pace tag")
	assert_eq(str(row.get("checkpoint", "")), "FROST-CHECK", "history row should store chapter checkpoint label")
	assert_false(bool(row.get("completed", true)), "new history row should start as incomplete")

	world.call("_mark_room_completed", 9)
	room_history = world.get("_room_history")
	row = room_history.get(9, {})
	assert_true(bool(row.get("completed", false)), "history row should be marked completed")
	assert_eq(str(row.get("clear_banner", "")), "Whiteout lane secured.", "history row should store chapter clear banner")
	assert_string_contains(str(row.get("clear_hint", "")), "Blizzard pressure rewards decisive clears.", "history row should store room pacing clear hint")
	assert_eq(str(row.get("mainline_node", "")), "Shatter the frozen hunt", "history row should store chapter mainline node")


func test_history_recap_limit_uses_recent_completed_rooms() -> void:
	var world: Node = await _instantiate_world()
	if world == null:
		return

	for room_id in [21, 22, 23, 24, 25, 26]:
		_set_room_plan(world, room_id, "chapter_4", "combat", [])
		world.call("_ensure_room_history", room_id, "combat")
		world.call("_mark_room_completed", room_id)

	var recap_limit: int = int(world.call("_get_chapter_history_recap_limit", 26))
	assert_eq(recap_limit, 5, "chapter_4 history recap should keep the configured limit")

	var recap_text: String = str(world.call("_build_chapter_history_recap", 26))
	assert_string_contains(recap_text, "Void memory trace:", "history recap should use chapter-specific prefix")
	assert_eq(recap_text.find("R21 "), -1, "history recap should trim entries older than limit")
	assert_true(recap_text.find("R22 ") >= 0, "history recap should keep the oldest entry within limit")
	assert_true(recap_text.find("R26 ") >= 0, "history recap should include latest completed room")
