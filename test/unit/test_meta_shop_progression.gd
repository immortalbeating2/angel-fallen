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


func _find_menu_button(menu: Control, node_name: String) -> Button:
	if menu == null:
		return null
	return menu.find_child(node_name, true, false) as Button


func _grant_meta_currency(amount: int) -> void:
	SaveManager._meta["meta_currency"] = amount
	SaveManager.save_meta()


func test_meta_shop_progression_caps_purchase_levels_by_meta_return_milestones() -> void:
	if SaveManager == null:
		pending("SaveManager singleton not available")
		return

	SaveManager.reset_meta()
	_grant_meta_currency(9999)

	assert_eq(int(SaveManager.get_meta_upgrade_level_cap("meta_max_hp")), 3, "base meta shop cap should start at level 3")
	assert_string_contains(str(SaveManager.get_meta_upgrade_progression_summary().get("summary", "")), "Upgrade Cap 3/6", "meta shop summary should start at 3/6")

	for _i in range(3):
		var purchase_result: Dictionary = SaveManager.purchase_upgrade("meta_max_hp")
		assert_true(bool(purchase_result.get("ok", false)), "meta_max_hp should purchase successfully up to the base cap")

	var locked_result: Dictionary = SaveManager.purchase_upgrade("meta_max_hp")
	assert_false(bool(locked_result.get("ok", false)), "fourth purchase should be blocked before Hard Return")
	assert_eq(str(locked_result.get("reason", "")), "meta_return_locked", "purchase should report meta return gating")
	assert_string_contains(str(locked_result.get("next_hint", "")), "Unlock Hard Return for Lv.4", "purchase should hint the next cap milestone")

	var menu: Control = await _instantiate_main_menu()
	if menu == null:
		return
	var upgrade_button: Button = _find_menu_button(menu, "Upgrade1Button")
	var shop_message_label: Label = _find_menu_label(menu, "ShopMessageValue")
	assert_not_null(upgrade_button, "upgrade button should exist")
	assert_not_null(shop_message_label, "shop message label should exist")
	if upgrade_button == null or shop_message_label == null:
		return
	assert_string_contains(upgrade_button.text, "Unlock Hard Return for Lv.4", "meta shop button should surface the next cap requirement")
	assert_string_contains(shop_message_label.text, "Upgrade Cap 3/6", "meta shop message should surface the current upgrade cap")

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
		"alignment": 0.0,
		"difficulty_tier": 1
	})

	assert_eq(int(SaveManager.get_meta_upgrade_level_cap("meta_max_hp")), 4, "Hard Return should raise the shop cap to level 4")
	assert_string_contains(str(SaveManager.get_meta_upgrade_next_hint("meta_max_hp")), "Unlock Nightmare Return for Lv.5", "next shop hint should advance to Nightmare Return")
	assert_true(bool(SaveManager.purchase_upgrade("meta_max_hp").get("ok", false)), "level 4 purchase should unlock after Hard Return")

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
	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 10,
		"kills": 100,
		"level_reached": 8,
		"gold": 50,
		"ore": 10,
		"alignment": 0.0,
		"difficulty_tier": 2
	})

	assert_eq(int(SaveManager.get_meta_upgrade_level_cap("meta_max_hp")), 5, "Nightmare Return should raise the shop cap to level 5")
	assert_true(bool(SaveManager.purchase_upgrade("meta_max_hp").get("ok", false)), "level 5 purchase should unlock after Nightmare Return")
	var locked_six: Dictionary = SaveManager.purchase_upgrade("meta_max_hp")
	assert_eq(str(locked_six.get("reason", "")), "meta_return_locked", "level 6 should still be gated before Nightmare Hidden Return")
	assert_string_contains(str(locked_six.get("next_hint", "")), "Unlock Nightmare Hidden Return for Lv.6", "shop should point at the final cap unlock")

	SaveManager.submit_run_result({
		"outcome": "victory",
		"rooms_cleared": 20,
		"kills": 410,
		"level_reached": 14,
		"gold": 260,
		"ore": 52,
		"alignment": 0.0,
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

	assert_eq(int(SaveManager.get_meta_upgrade_level_cap("meta_max_hp")), 6, "Nightmare Hidden Return should raise the shop cap to level 6")
	assert_true(bool(SaveManager.purchase_upgrade("meta_max_hp").get("ok", false)), "level 6 purchase should unlock after Nightmare Hidden Return")
	var final_result: Dictionary = SaveManager.purchase_upgrade("meta_max_hp")
	assert_eq(str(final_result.get("reason", "")), "max_level", "purchases beyond the config max should still stop at max level")
	assert_string_contains(str(SaveManager.get_meta_upgrade_progression_summary().get("summary", "")), "Upgrade Cap 6/6", "final progression summary should show a fully unlocked meta shop")

	menu.call("_refresh_meta_text")
	assert_string_contains(shop_message_label.text, "Upgrade Cap 6/6", "meta shop message should surface the fully unlocked cap")
	assert_string_contains(shop_message_label.text, "All meta shop levels unlocked", "meta shop message should report when the cap ladder is complete")
