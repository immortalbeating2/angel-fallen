extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"
const META_SAVE_PATH := "user://meta_save.json"

var _meta_save_exists_before: bool = false
var _meta_save_text_before: String = ""


func before_each() -> void:
	_snapshot_meta_save()
	if SaveManager != null and SaveManager.has_method("reset_meta"):
		SaveManager.reset_meta()
		SaveManager.set_selected_character_id("char_knight")


func after_each() -> void:
	_restore_meta_save()


func _snapshot_meta_save() -> void:
	_meta_save_exists_before = FileAccess.file_exists(META_SAVE_PATH)
	_meta_save_text_before = ""
	if _meta_save_exists_before:
		_meta_save_text_before = FileAccess.get_file_as_string(META_SAVE_PATH)


func _restore_meta_save() -> void:
	if _meta_save_exists_before:
		var file := FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_meta_save_text_before)
	else:
		if FileAccess.file_exists(META_SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(META_SAVE_PATH))

	if SaveManager != null and SaveManager.has_method("load_meta"):
		SaveManager.load_meta()


func _spawn_game_world() -> Node:
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

	var spawner: Node = world.get_node_or_null("EnemySpawner")
	if spawner != null and spawner.has_method("stop_room_combat"):
		spawner.stop_room_combat()

	if bool(world.get("_chapter_intro_pending")) and world.has_method("_on_intro_closed"):
		world.call("_on_intro_closed")
		await get_tree().process_frame
		if spawner != null and spawner.has_method("stop_room_combat"):
			spawner.stop_room_combat()

	return world


func test_character_select_to_room_progress_and_run_persist() -> void:
	if SaveManager != null and SaveManager.has_method("set_selected_character_id"):
		SaveManager.set_selected_character_id("char_knight")

	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	assert_not_null(weapon, "Player should have AutoWeapon")
	if weapon == null:
		return
	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_cross", "Selected knight profile should apply at run start")

	var start_room: int = int(world.get("_room_index"))
	world.set("_room_active", true)
	world.set("_current_room_type", "combat")
	world.call("_try_clear_room")

	var next_candidates: Array = world.get("_pending_next_rooms")
	assert_gte(next_candidates.size(), 1, "Cleared room should prepare at least one next-room candidate")

	world.call("_advance_to_next_room")
	await get_tree().process_frame
	assert_ne(int(world.get("_room_index")), start_room, "Room progression should advance to next room")

	var total_runs_before: int = int(SaveManager.get_meta_data().get("total_runs", 0))
	world.call("_finish_run", "retreat")
	await get_tree().process_frame

	var total_runs_after: int = int(SaveManager.get_meta_data().get("total_runs", 0))
	assert_eq(total_runs_after, total_runs_before + 1, "Run settlement should increase total_runs by 1")

	var last_run: Dictionary = SaveManager.get_last_run()
	assert_eq(str(last_run.get("outcome", "")), "retreat", "Run result should persist outcome")
	assert_eq(int(last_run.get("rooms_cleared", -1)), int(world.get("_run_rooms_cleared")), "Run result should persist cleared-room count")


func test_level_up_path_can_trigger_and_apply_weapon_evolution() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	var level_system: Node = world.get_node_or_null("LevelUpSystem")
	assert_not_null(weapon, "AutoWeapon should exist")
	assert_not_null(level_system, "LevelUpSystem should exist")
	if weapon == null or level_system == null:
		return

	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_cross", "Knight run should start with holy_cross weapon id")

	level_system.call("_mark_passive_progress", "precision")
	level_system.call("_mark_passive_progress", "precision")

	var evo_options_var: Variant = level_system.call("_collect_available_evolution_options")
	var evo_options: Array = []
	if evo_options_var is Array:
		evo_options = evo_options_var
	assert_false(evo_options.is_empty(), "Passive progress should expose at least one evolution option")

	var picked_option: Dictionary = {}
	for row_var: Variant in evo_options:
		if not (row_var is Dictionary):
			continue
		var row: Dictionary = row_var
		var recipe_var: Variant = row.get("recipe", {})
		if recipe_var is Dictionary:
			var recipe: Dictionary = recipe_var
			if str(recipe.get("result_weapon_id", "")) == "wpn_holy_judgment":
				picked_option = row
				break

	assert_false(picked_option.is_empty(), "holy_judgment evolution option should be available for holy_cross + precision Lv2")
	if picked_option.is_empty():
		return

	level_system.call("_apply_evolution_option", picked_option)
	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_judgment", "Evolution should update current weapon id")
	assert_true(weapon.has_method("has_evolved_to") and bool(weapon.call("has_evolved_to", "wpn_holy_judgment")), "Evolution should be tracked in evolved id set")


func test_shop_purchase_updates_resource_and_stat_feedback() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var stats: Node = player.get_node_or_null("StatsComponent")
	assert_not_null(stats, "StatsComponent should exist")
	if stats == null:
		return

	world.set("_room_index", 3)
	world.call("_enter_shop_room")

	var base_damage_bonus: float = float(stats.get("damage_bonus_pct"))
	world.set("_gold", 120)
	var offers_seed: Array = world.get("_shop_offers")
	assert_false(offers_seed.is_empty(), "Shop room should generate offers")
	if offers_seed.is_empty() or not (offers_seed[0] is Dictionary):
		return

	var forced_offer: Dictionary = offers_seed[0]
	forced_offer["id"] = "pas_might"
	forced_offer["category"] = "passive"
	forced_offer["quality"] = "common"
	forced_offer["price"] = 40
	forced_offer["title"] = "Might Sigil"
	forced_offer["desc"] = "+15% damage"
	forced_offer["sold"] = false
	offers_seed[0] = forced_offer
	world.set("_shop_offers", offers_seed)
	world.call("_update_shop_text")
	world.call("_try_buy_shop_slot", 0)

	assert_eq(int(world.get("_gold")), 80, "Shop purchase should deduct gold by slot price")

	var offers: Array = world.get("_shop_offers")
	assert_gte(offers.size(), 1, "Shop offer list should remain valid after purchase")
	if offers.is_empty() or not (offers[0] is Dictionary):
		return

	var bought: Dictionary = offers[0]
	assert_true(bool(bought.get("sold", false)), "Bought slot should be marked as sold")
	assert_true(is_equal_approx(float(stats.get("damage_bonus_pct")), base_damage_bonus + 0.15), "Shop effect should apply passive bonus to player stats")
	assert_true(str(world.get("_shop_message")).find("Bought") >= 0, "Shop message should reflect successful purchase")


func test_shop_purchase_can_apply_new_cycle_passive_effect() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var stats: Node = player.get_node_or_null("StatsComponent")
	var weapon: Node = player.get_node_or_null("AutoWeapon")
	assert_not_null(stats, "StatsComponent should exist")
	assert_not_null(weapon, "AutoWeapon should exist")
	if stats == null or weapon == null:
		return

	world.set("_room_index", 4)
	world.call("_enter_shop_room")

	var base_move_speed: float = float(stats.get("base_move_speed"))
	var base_attack_interval: float = float(weapon.get("attack_interval"))

	world.set("_gold", 140)
	var offers_seed: Array = world.get("_shop_offers")
	assert_false(offers_seed.is_empty(), "Shop room should generate offers")
	if offers_seed.is_empty() or not (offers_seed[0] is Dictionary):
		return

	var forced_offer: Dictionary = offers_seed[0]
	forced_offer["id"] = "pas_momentum"
	forced_offer["category"] = "passive"
	forced_offer["quality"] = "common"
	forced_offer["price"] = 44
	forced_offer["title"] = "Momentum Circuit"
	forced_offer["desc"] = "+14 move speed and faster weapon cycle"
	forced_offer["sold"] = false
	offers_seed[0] = forced_offer
	world.set("_shop_offers", offers_seed)
	world.call("_update_shop_text")
	world.call("_try_buy_shop_slot", 0)

	assert_eq(int(world.get("_gold")), 96, "Shop purchase should deduct forced offer price")
	assert_true(float(stats.get("base_move_speed")) > base_move_speed, "pas_momentum should increase base_move_speed")
	assert_true(float(weapon.get("attack_interval")) < base_attack_interval, "pas_momentum should reduce attack_interval")
