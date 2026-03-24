extends GutTest

const RUNTIME_SETTINGS_PANEL_SCENE_PATH := "res://scenes/ui/runtime_settings_panel.tscn"
const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


func _instantiate_settings_panel() -> Control:
	var scene: PackedScene = load(RUNTIME_SETTINGS_PANEL_SCENE_PATH)
	assert_not_null(scene, "runtime_settings_panel scene should load")
	if scene == null:
		return null

	var panel: Control = scene.instantiate() as Control
	assert_not_null(panel, "runtime_settings_panel scene should instantiate")
	if panel == null:
		return null

	add_child_autofree(panel)
	await get_tree().process_frame
	return panel


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


func test_runtime_settings_panel_and_game_world_apply_difficulty_tier() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	assert_eq(int(SaveManager.get_runtime_settings().get("difficulty_tier", -1)), 0, "locked difficulty should clamp to normal before progression unlocks")
	assert_eq(int(SaveManager.get_max_unlocked_difficulty_tier()), 0, "only Normal should be available on a fresh save")

	var panel: Control = await _instantiate_settings_panel()
	if panel == null:
		return

	var difficulty_slider: HSlider = panel.get_node_or_null("DifficultyRow/Slider")
	var difficulty_value: Label = panel.get_node_or_null("DifficultyRow/Value")
	var difficulty_hint: Label = panel.get_node_or_null("DifficultyHint")
	assert_not_null(difficulty_slider, "difficulty slider should exist in settings panel")
	assert_not_null(difficulty_value, "difficulty value label should exist in settings panel")
	assert_not_null(difficulty_hint, "difficulty hint label should exist in settings panel")
	if difficulty_slider == null or difficulty_value == null or difficulty_hint == null:
		return

	assert_eq(int(difficulty_slider.max_value), 0, "fresh saves should only allow the Normal difficulty tier")
	assert_eq(int(difficulty_slider.value), 0, "settings panel should clamp locked difficulty tiers to Normal")
	assert_string_contains(difficulty_value.text, "Normal", "settings panel should show the active difficulty label")
	assert_string_contains(difficulty_hint.text, "Unlock Hard", "settings panel should explain how to unlock Hard")

	var hard_unlock_result: Dictionary = SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 6,
		"kills": 80,
		"level_reached": 6,
		"gold": 24,
		"ore": 4,
		"alignment": 0.0
	})
	var hard_unlocks: Array = hard_unlock_result.get("new_difficulty_unlocks", [])
	assert_eq(hard_unlocks.size(), 1, "first clear should unlock Hard")
	assert_eq(str((hard_unlocks[0] as Dictionary).get("label", "")), "Hard", "first clear should report Hard as the new difficulty unlock")
	assert_eq(int(SaveManager.get_max_unlocked_difficulty_tier()), 1, "first clear should unlock Hard difficulty")
	panel.call("sync_from_save")
	assert_eq(int(difficulty_slider.max_value), 1, "settings panel should expand to Hard after the first clear")
	assert_string_contains(difficulty_hint.text, "Unlock Nightmare", "settings panel should explain how to unlock Nightmare")

	panel.call("_on_difficulty_slider_value_changed", 1.0)
	assert_eq(int(SaveManager.get_runtime_settings().get("difficulty_tier", -1)), 1, "difficulty slider should persist updated tier")
	assert_string_contains(str(difficulty_value.text), "Hard", "difficulty label should refresh after slider commit")

	var nightmare_unlock_result: Dictionary = SaveManager.submit_run_result({
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
	var nightmare_unlocks: Array = nightmare_unlock_result.get("new_difficulty_unlocks", [])
	assert_eq(nightmare_unlocks.size(), 1, "hidden-layer mastery should unlock Nightmare")
	assert_eq(str((nightmare_unlocks[0] as Dictionary).get("label", "")), "Nightmare", "hidden-layer mastery should report Nightmare as the new difficulty unlock")
	assert_eq(int(SaveManager.get_max_unlocked_difficulty_tier()), 2, "hidden-layer mastery should unlock Nightmare difficulty")
	panel.call("sync_from_save")
	assert_eq(int(difficulty_slider.max_value), 2, "settings panel should expand to Nightmare after mastery")
	assert_string_contains(difficulty_hint.text, "All difficulty tiers unlocked", "settings panel should confirm the difficulty ladder is fully open")

	SaveManager.update_runtime_settings({"difficulty_tier": 2})
	var world: Node = await _instantiate_world()
	if world == null:
		return

	assert_eq(int(world.get("_difficulty_tier")), 2, "game world should adopt persisted difficulty tier on ready")
	assert_eq(str(world.get("_difficulty_label")), "Nightmare", "game world should resolve persisted difficulty label")
	assert_string_contains(str(world.call("get_room_status_text")), "Difficulty: Nightmare", "game world room status should surface difficulty label")
	assert_string_contains(str(world.call("_get_difficulty_risk_reward_line")), "Haz x1.22", "game world should expose difficulty hazard summary")
	assert_string_contains(str(world.call("_get_difficulty_risk_reward_line")), "T x1.28", "game world should expose difficulty treasure reward summary")
	assert_gt(float(world.call("_get_hazard_intensity")), 1.0, "difficulty tier should scale hazard intensity")
	assert_eq(int(world.call("_scale_reward_amount", 20, 1.0, "gold")), 22, "difficulty tier should scale gold rewards on top of chapter reward curve")
	assert_eq(int(world.call("_scale_reward_amount", 40, 1.0, "gold", true)), 56, "difficulty tier should scale treasure rewards on top of the treasure curve")

	var spawner: Node = world.get_node_or_null("EnemySpawner")
	assert_not_null(spawner, "game world should include enemy spawner")
	if spawner == null:
		return

	assert_gt(float(spawner.get("_runtime_spawn_rate_mult")), 1.0, "difficulty tier should scale spawn multiplier")
	assert_gt(float(spawner.get("_runtime_enemy_hp_mult")), 1.0, "difficulty tier should scale enemy hp multiplier")
	assert_gt(float(spawner.get("_runtime_enemy_damage_mult")), 1.0, "difficulty tier should scale enemy damage multiplier")
