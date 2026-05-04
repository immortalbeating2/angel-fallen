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


func test_player_lethal_damage_finishes_run_as_death() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	assert_true(player.is_in_group("player"), "Player must be in player group before taking damage")
	player.call("apply_damage", 9999.0)
	await get_tree().process_frame

	var run_result_panel: Node = world.get_node_or_null("RunResultPanel")
	assert_not_null(run_result_panel, "Run result panel should exist")
	if run_result_panel == null:
		return
	assert_true(bool(run_result_panel.get("visible")), "Lethal player damage should show run result panel")

	var last_run: Dictionary = SaveManager.get_last_run()
	assert_eq(str(last_run.get("outcome", "")), "death", "Lethal player damage should persist death outcome")


func test_player_input_moves_runtime_player_body() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: CharacterBody2D = world.get_node_or_null("Player") as CharacterBody2D
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	await get_tree().physics_frame
	await get_tree().physics_frame
	Input.action_release("move_right")

	assert_gt(player.global_position.x, start_x, "Pressed move_right should move the runtime player body")


func test_treasure_path_can_trigger_and_apply_weapon_evolution() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	var level_system: Node = world.get_node_or_null("LevelUpSystem")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(weapon, "AutoWeapon should exist")
	assert_not_null(level_system, "LevelUpSystem should exist")
	assert_not_null(loadout, "WeaponLoadout should exist")
	if weapon == null or level_system == null or loadout == null:
		return

	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_cross", "Knight run should start with holy_cross weapon id")

	for _i in range(7):
		loadout.call("add_or_level_weapon", "wpn_holy_cross")
	level_system.call("_mark_passive_progress", "precision")
	level_system.call("_mark_passive_progress", "precision")

	var evo_options_var: Variant = level_system.call("get_available_treasure_evolutions", "treasure_chest")
	var evo_options: Array = []
	if evo_options_var is Array:
		evo_options = evo_options_var
	assert_false(evo_options.is_empty(), "满级武器 + 被动进度应暴露宝箱进化候选")

	var picked_recipe: Dictionary = {}
	for row_var: Variant in evo_options:
		if not (row_var is Dictionary):
			continue
		var recipe: Dictionary = row_var
		if str(recipe.get("result_weapon_id", "")) == "wpn_holy_judgment":
			picked_recipe = recipe
			break

	assert_false(picked_recipe.is_empty(), "holy_judgment treasure evolution should be available for full holy_cross + precision Lv2")
	if picked_recipe.is_empty():
		return

	level_system.call("apply_evolution_recipe", picked_recipe)
	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_judgment", "Evolution should update current weapon id")
	assert_true(weapon.has_method("has_evolved_to") and bool(weapon.call("has_evolved_to", "wpn_holy_judgment")), "Evolution should be tracked in evolved id set")


func test_runtime_chest_pickup_opens_treasure_and_applies_evolution() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	var level_system: Node = world.get_node_or_null("LevelUpSystem")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(weapon, "AutoWeapon should exist")
	assert_not_null(level_system, "LevelUpSystem should exist")
	assert_not_null(loadout, "WeaponLoadout should exist")
	if weapon == null or level_system == null or loadout == null:
		return

	for _i in range(7):
		loadout.call("add_or_level_weapon", "wpn_holy_cross")
	level_system.call("_mark_passive_progress", "precision")
	level_system.call("_mark_passive_progress", "precision")

	var rewards: Array = world.call("_open_runtime_treasure_chest", 40, "chest_rare")
	assert_false(rewards.is_empty(), "Runtime treasure chest should return rewards")
	assert_eq(str(rewards[0].get("type", "")), "evolution", "Eligible treasure chest should prioritize evolution")
	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_judgment", "Runtime treasure chest should apply evolution recipe")
	assert_true(bool(loadout.get("weapon_slots")[0].get("evolved", false)), "Runtime treasure evolution should mark loadout slot evolved")


func test_runtime_chest_can_evolve_secondary_loadout_weapon() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(weapon, "AutoWeapon should exist")
	assert_not_null(loadout, "WeaponLoadout should exist")
	if weapon == null or loadout == null:
		return

	loadout.call("add_or_level_weapon", "wpn_radiant_hammer")
	for _i in range(7):
		loadout.call("add_or_level_weapon", "wpn_radiant_hammer")
	for _i in range(3):
		loadout.call("add_or_level_passive", "pas_armor")

	var rewards: Array = world.call("_open_runtime_treasure_chest", 40, "chest_rare")
	assert_false(rewards.is_empty(), "Secondary full weapon treasure chest should return rewards")
	assert_eq(str(rewards[0].get("type", "")), "evolution", "Secondary full weapon should be eligible for treasure evolution")
	assert_eq(str(rewards[0].get("id", "")), "wpn_radiant_cataclysm", "Treasure chest should evolve the eligible secondary weapon")
	assert_eq(str(weapon.get("current_weapon_id")), "wpn_holy_cross", "Secondary evolution should not overwrite the character starting weapon executor")
	assert_true(bool(loadout.call("has_weapon_evolved", "wpn_radiant_hammer", "wpn_radiant_cataclysm")), "Secondary loadout slot should record evolved result")

	var profiles_var: Variant = weapon.call("get_runtime_weapon_slot_profiles")
	var profiles: Array = profiles_var if profiles_var is Array else []
	var found_cataclysm: bool = false
	for row_var: Variant in profiles:
		if row_var is Dictionary and str((row_var as Dictionary).get("projectile_style", "")) == "radiant_cataclysm":
			found_cataclysm = true
			break
	assert_true(found_cataclysm, "Secondary evolved weapon should update runtime projectile profile")


func test_multi_weapon_loadout_exposes_independent_runtime_profiles() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(weapon, "AutoWeapon should exist")
	assert_not_null(loadout, "WeaponLoadout should exist")
	if weapon == null or loadout == null:
		return

	loadout.call("add_or_level_weapon", "wpn_radiant_hammer")
	var profiles_var: Variant = weapon.call("get_runtime_weapon_slot_profiles")
	var profiles: Array = profiles_var if profiles_var is Array else []
	assert_gte(profiles.size(), 2, "AutoWeapon should expose one runtime profile per weapon slot")

	var found_radiant: bool = false
	for row_var: Variant in profiles:
		if row_var is Dictionary and str((row_var as Dictionary).get("weapon_id", "")) == "wpn_radiant_hammer":
			found_radiant = true
			assert_eq(str((row_var as Dictionary).get("projectile_style", "")), "radiant_hammer", "Secondary weapon should keep its own projectile style")
	assert_true(found_radiant, "Secondary weapon should have an independent runtime profile")

	var target: Node2D = Node2D.new()
	target.name = "RuntimeProfileTarget"
	target.add_to_group("enemy")
	target.global_position = (player as Node2D).global_position + Vector2.RIGHT * 180.0
	world.add_child(target)

	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING, "Game world should be in PLAYING state before auto weapon runtime fire check")
	assert_not_null(weapon.call("_find_nearest_enemy"), "Runtime target should be discoverable by AutoWeapon")
	assert_not_null(weapon.get("projectile_scene"), "AutoWeapon should have a projectile scene before runtime fire check")
	await get_tree().process_frame

	var found_radiant_projectile: bool = false
	var observed_styles: Array[String] = []
	for child: Node in world.get_children():
		var script: Script = child.get_script() as Script
		if script == null or script.resource_path != "res://scripts/game/projectile.gd":
			continue
		var style_id: String = str(child.get("_style_id"))
		observed_styles.append(style_id)
		if style_id == "radiant_hammer":
			found_radiant_projectile = true
			break
	assert_true(found_radiant_projectile, "Secondary weapon should fire a projectile with its own runtime style; observed=%s" % [", ".join(observed_styles)])


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


func test_shop_purchase_can_apply_d13_weapon_effect() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	assert_not_null(weapon, "AutoWeapon should exist")
	if weapon == null:
		return

	world.set("_room_index", 5)
	world.call("_enter_shop_room")

	var base_damage: float = float(weapon.get("base_damage"))
	var base_style: String = str(weapon.get("projectile_style"))
	world.set("_gold", 180)
	var offers_seed: Array = world.get("_shop_offers")
	assert_false(offers_seed.is_empty(), "Shop room should generate offers")
	if offers_seed.is_empty() or not (offers_seed[0] is Dictionary):
		return

	var forced_offer: Dictionary = offers_seed[0]
	forced_offer["id"] = "wpn_radiant_hammer"
	forced_offer["category"] = "weapon"
	forced_offer["quality"] = "rare"
	forced_offer["price"] = 62
	forced_offer["title"] = "Radiant Hammer"
	forced_offer["desc"] = "+6.8 damage and +2 projectile hits"
	forced_offer["sold"] = false
	offers_seed[0] = forced_offer
	world.set("_shop_offers", offers_seed)
	world.call("_update_shop_text")
	world.call("_try_buy_shop_slot", 0)

	assert_eq(int(world.get("_gold")), 118, "Shop purchase should deduct forced D13 weapon price")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(loadout, "WeaponLoadout should exist")
	assert_eq(int(loadout.call("get_weapon_level", "wpn_radiant_hammer")), 1, "wpn_radiant_hammer should enter loadout as a new weapon")
	assert_eq(str(weapon.get("projectile_style")), base_style, "New non-primary weapon should not overwrite the character starting weapon executor")
	assert_true(is_equal_approx(float(weapon.get("base_damage")), base_damage), "New non-primary weapon should not directly mutate AutoWeapon damage")


func test_shop_purchase_can_apply_d18_weapon_effect() -> void:
	var world: Node = await _spawn_game_world()
	if world == null:
		return

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player node should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	assert_not_null(weapon, "AutoWeapon should exist")
	if weapon == null:
		return

	world.set("_room_index", 6)
	world.call("_enter_shop_room")

	var base_damage: float = float(weapon.get("base_damage"))
	var base_hits: int = int(weapon.get("projectile_hits"))
	var base_style: String = str(weapon.get("projectile_style"))
	world.set("_gold", 190)
	var offers_seed: Array = world.get("_shop_offers")
	assert_false(offers_seed.is_empty(), "Shop room should generate offers")
	if offers_seed.is_empty() or not (offers_seed[0] is Dictionary):
		return

	var forced_offer: Dictionary = offers_seed[0]
	forced_offer["id"] = "wpn_vowblade"
	forced_offer["category"] = "weapon"
	forced_offer["quality"] = "rare"
	forced_offer["price"] = 64
	forced_offer["title"] = "Vowblade"
	forced_offer["desc"] = "+6.2 damage, focused strike, +1 hit"
	forced_offer["sold"] = false
	offers_seed[0] = forced_offer
	world.set("_shop_offers", offers_seed)
	world.call("_update_shop_text")
	world.call("_try_buy_shop_slot", 0)

	assert_eq(int(world.get("_gold")), 126, "Shop purchase should deduct forced D18 weapon price")
	var loadout: Node = world.get_node_or_null("WeaponLoadout")
	assert_not_null(loadout, "WeaponLoadout should exist")
	assert_eq(int(loadout.call("get_weapon_level", "wpn_vowblade")), 1, "wpn_vowblade should enter loadout as a new weapon")
	assert_eq(str(weapon.get("projectile_style")), base_style, "New non-primary weapon should not overwrite the character starting weapon executor")
	assert_true(is_equal_approx(float(weapon.get("base_damage")), base_damage), "New non-primary weapon should not directly mutate AutoWeapon damage")
	assert_eq(int(weapon.get("projectile_hits")), base_hits, "New non-primary weapon should not directly mutate primary projectile hits")
