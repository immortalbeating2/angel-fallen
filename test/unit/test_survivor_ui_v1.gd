extends GutTest

const HUD_SCENE_PATH: String = "res://scenes/ui/hud.tscn"
const LEVEL_UP_PANEL_SCENE_PATH: String = "res://scenes/ui/level_up_panel.tscn"


func _instantiate_scene(scene_path: String) -> Node:
	var scene: PackedScene = load(scene_path)
	assert_not_null(scene, "%s should load" % scene_path)
	if scene == null:
		return null

	var node: Node = scene.instantiate()
	assert_not_null(node, "%s should instantiate" % scene_path)
	if node == null:
		return null

	add_child_autofree(node)
	await get_tree().process_frame
	return node


func test_hud_exposes_treasure_chest_hint_entry() -> void:
	var hud: Node = await _instantiate_scene(HUD_SCENE_PATH)
	if hud == null:
		return

	assert_true(hud.has_method("show_treasure_chest_hint"), "HUD should expose treasure hint show entry for GameWorld")
	assert_true(hud.has_method("hide_treasure_chest_hint"), "HUD should expose treasure hint hide entry for GameWorld")

	hud.call("show_treasure_chest_hint")
	var label: Label = hud.get_node_or_null("TreasureHintLayer/TreasureHintPanel/MarginContainer/TreasureHintLabel") as Label
	assert_not_null(label, "treasure hint label should exist")
	if label == null:
		return
	assert_true(label.visible, "treasure hint label should be visible after show")
	assert_string_contains(label.text, "进化圣箱", "treasure hint should use survivor evolution chest wording")

	hud.call("hide_treasure_chest_hint")
	assert_false(label.visible, "treasure hint label should hide when requested")


func test_hud_exposes_boss_health_entry() -> void:
	var hud: Node = await _instantiate_scene(HUD_SCENE_PATH)
	if hud == null:
		return

	assert_true(hud.has_method("show_boss_health"), "HUD should expose boss health show entry for GameWorld")
	assert_true(hud.has_method("update_boss_health"), "HUD should expose boss health update entry for GameWorld")
	assert_true(hud.has_method("hide_boss_health"), "HUD should expose boss health hide entry for GameWorld")

	hud.call("show_boss_health", "Void Lord", 200.0)
	hud.call("update_boss_health", 75.0, 200.0)
	var panel: CanvasItem = hud.get_node_or_null("BossHealthLayer/BossHealthPanel") as CanvasItem
	var name_label: Label = hud.get_node_or_null("BossHealthLayer/BossHealthPanel/MarginContainer/VBoxContainer/BossNameLabel") as Label
	var bar: ProgressBar = hud.get_node_or_null("BossHealthLayer/BossHealthPanel/MarginContainer/VBoxContainer/BossHealthBar") as ProgressBar
	assert_not_null(panel, "boss health panel should exist")
	assert_not_null(name_label, "boss name label should exist")
	assert_not_null(bar, "boss health bar should exist")
	if panel == null or name_label == null or bar == null:
		return

	assert_true(panel.visible, "boss health panel should be visible after show")
	assert_string_contains(name_label.text, "Void Lord", "boss health should show boss name")
	assert_eq(int(bar.max_value), 200, "boss health max should be configurable")
	assert_eq(int(bar.value), 75, "boss health value should update")

	hud.call("hide_boss_health")
	assert_false(panel.visible, "boss health panel should hide when requested")


func test_level_up_panel_marks_dark_pact_rewards() -> void:
	var panel: Node = await _instantiate_scene(LEVEL_UP_PANEL_SCENE_PATH)
	if panel == null:
		return

	var options: Array[Dictionary] = [
		{"id": "pact_void_edge", "title": "Void Edge", "desc": "Power for a price", "tags": ["dark_pact"]},
		{"id": "wpn_holy_cross", "title": "Holy Cross", "desc": "Reliable strike"},
		{"id": "pas_armor", "title": "Armor", "desc": "Take less damage"}
	]
	panel.call("show_options", options, 4)

	var title_label: Label = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Title") as Label
	var first_button: Button = panel.get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Option1") as Button
	assert_not_null(title_label, "level up panel title should exist")
	assert_not_null(first_button, "first reward button should exist")
	if title_label == null or first_button == null:
		return

	assert_string_contains(title_label.text, "黑暗契约", "reward overlay should surface dark pact presentation marker")
	assert_string_contains(first_button.text, "PACT", "dark pact option should carry compact PACT marker")
