extends GutTest

const HUD_SCENE_PATH := "res://scenes/ui/hud.tscn"


func _instantiate_hud() -> CanvasLayer:
	var scene: PackedScene = load(HUD_SCENE_PATH)
	assert_not_null(scene, "hud scene should load")
	if scene == null:
		return null

	var hud: CanvasLayer = scene.instantiate() as CanvasLayer
	assert_not_null(hud, "hud scene should instantiate")
	if hud == null:
		return null

	add_child_autofree(hud)
	await get_tree().process_frame
	return hud


func test_hud_codex_toast_uses_archive_entry_titles() -> void:
	var hud: CanvasLayer = await _instantiate_hud()
	if hud == null:
		return

	hud.call("_on_codex_unlocked", "archives", "fs1_echo_archive")
	hud.call("_on_codex_unlocked", "archives", "nightmare_hidden_archive")
	var queue: Array = hud.get("_toast_queue")
	assert_eq(queue.size(), 2, "hud should queue codex toasts for archive entries")
	if queue.size() < 2:
		return

	var first_toast: Dictionary = queue[0]
	var second_toast: Dictionary = queue[1]
	assert_string_contains(str(first_toast.get("text", "")), "Time Rift Archive", "hud toast should show archive codex title instead of raw id")
	assert_string_contains(str(second_toast.get("text", "")), "Nightmare Hidden Archive", "hud toast should show difficulty archive titles instead of raw ids")


func test_hud_difficulty_toast_uses_readable_labels() -> void:
	var hud: CanvasLayer = await _instantiate_hud()
	if hud == null:
		return

	hud.call("_on_difficulty_unlocked", 2, "Nightmare")
	var queue: Array = hud.get("_toast_queue")
	assert_eq(queue.size(), 1, "hud should queue one difficulty toast")
	if queue.is_empty():
		return

	var toast_row: Dictionary = queue[0]
	assert_string_contains(str(toast_row.get("text", "")), "Difficulty Unlocked: Nightmare", "hud toast should surface the readable difficulty label")


func test_hud_meta_return_toast_uses_readable_labels() -> void:
	var hud: CanvasLayer = await _instantiate_hud()
	if hud == null:
		return

	hud.call("_on_meta_return_unlocked", "nightmare_meta_return", "Nightmare Return", "+15% Meta")
	var queue: Array = hud.get("_toast_queue")
	assert_eq(queue.size(), 1, "hud should queue one meta return toast")
	if queue.is_empty():
		return

	var toast_row: Dictionary = queue[0]
	assert_string_contains(str(toast_row.get("text", "")), "Meta Return Unlocked: Nightmare Return (+15% Meta)", "hud toast should surface readable meta return milestone text")
