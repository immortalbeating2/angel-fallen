extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


func _set_room_plan(world: Node, room_index: int, chapter_id: String, room_type: String) -> void:
	var room_plan_map_var: Variant = world.get("_room_plan_map")
	var room_plan_map: Dictionary = {}
	if room_plan_map_var is Dictionary:
		room_plan_map = (room_plan_map_var as Dictionary).duplicate(true)

	room_plan_map[room_index] = {
		"chapter_id": chapter_id,
		"chapter_index": int(chapter_id.trim_prefix("chapter_")),
		"room_type": room_type,
		"show_intro": false,
		"next_rooms": [],
		"previous_rooms": []
	}
	world.set("_room_plan_map", room_plan_map)


func _find_room_index_for_chapter(world: Node, chapter_id: String) -> int:
	var room_plan_map_var: Variant = world.get("_room_plan_map")
	if not (room_plan_map_var is Dictionary):
		return -1

	var room_plan_map: Dictionary = room_plan_map_var
	for key_var: Variant in room_plan_map.keys():
		var room_data_var: Variant = room_plan_map.get(key_var, {})
		if not (room_data_var is Dictionary):
			continue

		var room_data: Dictionary = room_data_var
		if str(room_data.get("chapter_id", "")) == chapter_id:
			return int(key_var)

	return -1


func test_game_world_exposes_tilemap_visual_layers() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var ground: Node = world.get_node_or_null("GroundTileMap")
	var ground_detail: Node = world.get_node_or_null("GroundDetailTileMap")
	var doors: Node = world.get_node_or_null("DoorTileMap")
	var hazard: Node = world.get_node_or_null("HazardTileMap")
	var ambient_fx: Node = world.get_node_or_null("AmbientFxTileMap")
	assert_not_null(ground, "GroundTileMap should exist")
	assert_not_null(ground_detail, "GroundDetailTileMap should exist")
	assert_not_null(doors, "DoorTileMap should exist")
	assert_not_null(hazard, "HazardTileMap should exist")
	assert_not_null(ambient_fx, "AmbientFxTileMap should exist")

	if ground is TileMap:
		var ground_tileset: TileSet = (ground as TileMap).tile_set
		assert_not_null(ground_tileset, "GroundTileMap should load a TileSet resource")
		if ground_tileset != null:
			assert_true(ground_tileset.resource_path.begins_with("res://resources/tilesets/"), "GroundTileMap should use tileset assets from resources/tilesets")
	if ground_detail is TileMap:
		var ground_detail_tileset: TileSet = (ground_detail as TileMap).tile_set
		assert_not_null(ground_detail_tileset, "GroundDetailTileMap should load a TileSet resource")
		if ground_detail_tileset != null:
			assert_true(ground_detail_tileset.resource_path.begins_with("res://resources/tilesets/"), "GroundDetailTileMap should use tileset assets from resources/tilesets")
	if doors is TileMap:
		var door_tileset: TileSet = (doors as TileMap).tile_set
		assert_not_null(door_tileset, "DoorTileMap should load a TileSet resource")
		if door_tileset != null:
			assert_true(door_tileset.resource_path.begins_with("res://resources/tilesets/"), "DoorTileMap should use tileset assets from resources/tilesets")
	if hazard is TileMap:
		var hazard_tileset: TileSet = (hazard as TileMap).tile_set
		assert_not_null(hazard_tileset, "HazardTileMap should load a TileSet resource")
		if hazard_tileset != null:
			assert_true(hazard_tileset.resource_path.begins_with("res://resources/tilesets/"), "HazardTileMap should use tileset assets from resources/tilesets")
	if ambient_fx is TileMap:
		var ambient_fx_tileset: TileSet = (ambient_fx as TileMap).tile_set
		assert_not_null(ambient_fx_tileset, "AmbientFxTileMap should load a TileSet resource")
		if ambient_fx_tileset != null:
			assert_true(ambient_fx_tileset.resource_path.begins_with("res://resources/tilesets/"), "AmbientFxTileMap should use tileset assets from resources/tilesets")


func test_hazard_tilemap_reacts_to_hazard_state() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var hazard: Node = world.get_node_or_null("HazardTileMap")
	assert_true(hazard is TileMap, "HazardTileMap node should be TileMap")
	if not (hazard is TileMap):
		return

	var hazard_tilemap: TileMap = hazard as TileMap
	world.set("_active_hazards", ["lava_pool", "void_rift"])
	world.call("_render_hazard_tiles")
	assert_gte(hazard_tilemap.get_used_cells(0).size(), 1, "HazardTileMap should paint cells when hazards are active")

	world.set("_room_active", true)
	world.set("_current_room_type", "combat")
	world.call("_update_environment_visuals", 0.25)
	var alpha_active: float = hazard_tilemap.modulate.a
	assert_gt(alpha_active, 0.0, "HazardTileMap alpha should increase in active hazard combat rooms")

	world.set("_room_active", false)
	world.call("_update_environment_visuals", 0.25)
	assert_lt(hazard_tilemap.modulate.a, alpha_active, "HazardTileMap alpha should fade when room is inactive")


func test_hazard_tilemap_animates_tile_variants_over_time() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var hazard_node: Node = world.get_node_or_null("HazardTileMap")
	assert_true(hazard_node is TileMap, "HazardTileMap should be TileMap")
	if not (hazard_node is TileMap):
		return

	var hazard_tilemap: TileMap = hazard_node as TileMap
	world.set("_active_hazards", ["void_rift"])
	world.set("_room_active", true)
	world.set("_current_room_type", "combat")
	world.call("_render_hazard_tiles")

	var used_cells: Array[Vector2i] = hazard_tilemap.get_used_cells(0)
	assert_gte(used_cells.size(), 1, "HazardTileMap should have cells to animate")
	if used_cells.is_empty():
		return

	var probe: Vector2i = used_cells[0]
	var before: Vector2i = hazard_tilemap.get_cell_atlas_coords(0, probe)
	world.call("_update_hazard_tile_animation", 0.26)
	var after: Vector2i = hazard_tilemap.get_cell_atlas_coords(0, probe)
	assert_ne(after, before, "Hazard tile atlas coords should advance after animation tick")


func test_tilemap_uses_chapter_specific_detail_door_hazard_and_ambient_tilesets() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var doors_node: Node = world.get_node_or_null("DoorTileMap")
	var ground_detail_node: Node = world.get_node_or_null("GroundDetailTileMap")
	var hazard_node: Node = world.get_node_or_null("HazardTileMap")
	var ambient_node: Node = world.get_node_or_null("AmbientFxTileMap")
	assert_true(doors_node is TileMap, "DoorTileMap should be TileMap")
	assert_true(ground_detail_node is TileMap, "GroundDetailTileMap should be TileMap")
	assert_true(hazard_node is TileMap, "HazardTileMap should be TileMap")
	assert_true(ambient_node is TileMap, "AmbientFxTileMap should be TileMap")
	if not (doors_node is TileMap) or not (ground_detail_node is TileMap) or not (hazard_node is TileMap) or not (ambient_node is TileMap):
		return

	var door_tilemap: TileMap = doors_node as TileMap
	var ground_detail_tilemap: TileMap = ground_detail_node as TileMap
	var hazard_tilemap: TileMap = hazard_node as TileMap
	var ambient_tilemap: TileMap = ambient_node as TileMap
	var chapter_suffix_pairs: Array[Dictionary] = [
		{"chapter": "chapter_1", "suffix": "_ch1"},
		{"chapter": "chapter_2", "suffix": "_ch2"},
		{"chapter": "chapter_3", "suffix": "_ch3"},
		{"chapter": "chapter_4", "suffix": "_ch4"}
	]

	for pair: Dictionary in chapter_suffix_pairs:
		var chapter_id: String = str(pair.get("chapter", ""))
		var suffix: String = str(pair.get("suffix", ""))
		var room_index: int = _find_room_index_for_chapter(world, chapter_id)
		assert_gt(room_index, 0, "Run plan should contain room for %s" % chapter_id)
		if room_index <= 0:
			continue

		world.set("_room_index", room_index)
		world.set("_active_hazards", ["lava_pool"])
		world.call("_render_ground_detail_tiles_for_room", room_index)
		world.call("_render_door_tiles", true)
		world.call("_render_hazard_tiles")
		world.call("_render_ambient_fx_tiles")

		var ground_detail_tileset: TileSet = ground_detail_tilemap.tile_set
		var door_tileset: TileSet = door_tilemap.tile_set
		var hazard_tileset: TileSet = hazard_tilemap.tile_set
		var ambient_tileset: TileSet = ambient_tilemap.tile_set
		assert_not_null(ground_detail_tileset, "Ground detail tileset should exist for %s" % chapter_id)
		assert_not_null(door_tileset, "Door tileset should exist for %s" % chapter_id)
		assert_not_null(hazard_tileset, "Hazard tileset should exist for %s" % chapter_id)
		assert_not_null(ambient_tileset, "Ambient fx tileset should exist for %s" % chapter_id)
		if ground_detail_tileset != null:
			assert_true(ground_detail_tileset.resource_path.find(suffix) >= 0, "Ground detail tileset should match chapter suffix %s" % suffix)
		if door_tileset != null:
			assert_true(door_tileset.resource_path.find(suffix) >= 0, "Door tileset should match chapter suffix %s" % suffix)
		if hazard_tileset != null:
			assert_true(hazard_tileset.resource_path.find(suffix) >= 0, "Hazard tileset should match chapter suffix %s" % suffix)
		if ambient_tileset != null:
			assert_true(ambient_tileset.resource_path.find(suffix) >= 0, "Ambient fx tileset should match chapter suffix %s" % suffix)


func test_ambient_fx_tilemap_animates_tile_variants_over_time() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var ambient_node: Node = world.get_node_or_null("AmbientFxTileMap")
	assert_true(ambient_node is TileMap, "AmbientFxTileMap should be TileMap")
	if not (ambient_node is TileMap):
		return

	var ambient_tilemap: TileMap = ambient_node as TileMap
	world.set("_room_active", true)
	world.set("_current_room_type", "combat")
	world.call("_render_ambient_fx_tiles")

	var used_cells: Array[Vector2i] = ambient_tilemap.get_used_cells(0)
	assert_gte(used_cells.size(), 1, "AmbientFxTileMap should have cells to animate")
	if used_cells.is_empty():
		return

	var probe: Vector2i = used_cells[0]
	var before: Vector2i = ambient_tilemap.get_cell_atlas_coords(0, probe)
	world.call("_update_ambient_fx_animation", 0.5)
	var after: Vector2i = ambient_tilemap.get_cell_atlas_coords(0, probe)
	assert_ne(after, before, "Ambient fx tile atlas coords should advance after animation tick")


func test_chapter_visual_profile_affects_detail_tint_and_ambient_scroll() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var detail_node: Node = world.get_node_or_null("GroundDetailTileMap")
	var ambient_node: Node = world.get_node_or_null("AmbientFxTileMap")
	assert_true(detail_node is TileMap, "GroundDetailTileMap should be TileMap")
	assert_true(ambient_node is TileMap, "AmbientFxTileMap should be TileMap")
	if not (detail_node is TileMap) or not (ambient_node is TileMap):
		return

	var detail_tilemap: TileMap = detail_node as TileMap
	var ambient_tilemap: TileMap = ambient_node as TileMap
	var chapter_1_room: int = _find_room_index_for_chapter(world, "chapter_1")
	var chapter_4_room: int = _find_room_index_for_chapter(world, "chapter_4")
	assert_gt(chapter_1_room, 0, "Run plan should contain chapter_1 room")
	assert_gt(chapter_4_room, 0, "Run plan should contain chapter_4 room")
	if chapter_1_room <= 0 or chapter_4_room <= 0:
		return

	world.set("_room_active", true)
	world.set("_current_room_type", "combat")
	world.set("_active_hazards", ["lava_pool"])

	world.set("_room_index", chapter_1_room)
	world.call("_render_ground_detail_tiles_for_room", chapter_1_room)
	world.call("_render_ambient_fx_tiles")
	world.set("_ambient_fx_scroll_offset", Vector2.ZERO)
	world.call("_update_environment_visuals", 0.35)
	var chapter_1_detail_color: Color = detail_tilemap.modulate
	var ambient_before: Vector2 = ambient_tilemap.position
	world.call("_update_environment_visuals", 0.35)
	var ambient_after: Vector2 = ambient_tilemap.position
	assert_ne(ambient_after, ambient_before, "Ambient FX layer should scroll based on chapter visual profile")

	world.set("_room_index", chapter_4_room)
	world.call("_render_ground_detail_tiles_for_room", chapter_4_room)
	world.call("_render_ambient_fx_tiles")
	world.set("_ambient_fx_scroll_offset", Vector2.ZERO)
	world.call("_update_environment_visuals", 0.35)
	var chapter_4_detail_color: Color = detail_tilemap.modulate
	assert_ne(chapter_4_detail_color, chapter_1_detail_color, "Ground detail tint should differ between chapter visual profiles")


func test_visual_profile_pulse_and_wave_factors_change_with_time() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var chapter_4_room: int = _find_room_index_for_chapter(world, "chapter_4")
	assert_gt(chapter_4_room, 0, "Run plan should contain chapter_4 room")
	if chapter_4_room <= 0:
		return

	world.set("_room_index", chapter_4_room)
	var profile: Dictionary = world.call("_get_chapter_visual_profile", chapter_4_room)
	var detail_speed: float = float(profile.get("detail_pulse_speed", 0.0))
	var detail_amp: float = float(profile.get("detail_pulse_amplitude", 0.0))
	var ambient_speed: float = float(profile.get("ambient_wave_speed", 0.0))
	var ambient_amp: float = float(profile.get("ambient_wave_amplitude", 0.0))
	assert_gt(detail_speed, 0.0, "chapter_4 detail pulse speed should be configured")
	assert_gt(detail_amp, 0.0, "chapter_4 detail pulse amplitude should be configured")
	assert_gt(ambient_speed, 0.0, "chapter_4 ambient wave speed should be configured")
	assert_gt(ambient_amp, 0.0, "chapter_4 ambient wave amplitude should be configured")

	var factors_early: Dictionary = world.call("_get_visual_profile_anim_factors", detail_speed, detail_amp, ambient_speed, ambient_amp, 0.12)
	var factors_late: Dictionary = world.call("_get_visual_profile_anim_factors", detail_speed, detail_amp, ambient_speed, ambient_amp, 1.36)
	var detail_early: float = float(factors_early.get("detail_pulse", 0.0))
	var detail_late: float = float(factors_late.get("detail_pulse", 0.0))
	var ambient_early: float = float(factors_early.get("ambient_wave", 0.0))
	var ambient_late: float = float(factors_late.get("ambient_wave", 0.0))
	assert_ne(detail_early, detail_late, "Detail pulse factor should vary over time")
	assert_ne(ambient_early, ambient_late, "Ambient wave factor should vary over time")


func test_room_profiles_change_hazards_and_visual_profile_for_late_chapters() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	_set_room_plan(world, 101, "chapter_3", "combat")
	_set_room_plan(world, 102, "chapter_3", "elite")
	_set_room_plan(world, 103, "chapter_3", "boss")
	_set_room_plan(world, 104, "chapter_3", "safe_camp")
	_set_room_plan(world, 105, "chapter_4", "elite")

	var chapter_3_combat: Array[String] = world.call("_get_hazards_for_room", 101)
	var chapter_3_elite: Array[String] = world.call("_get_hazards_for_room", 102)
	var chapter_3_boss: Array[String] = world.call("_get_hazards_for_room", 103)
	var chapter_3_safe_camp: Array[String] = world.call("_get_hazards_for_room", 104)
	var chapter_4_elite: Array[String] = world.call("_get_hazards_for_room", 105)
	assert_eq(chapter_3_combat, ["ice_slide", "frostbite"], "chapter_3 combat hazards should keep the base frozen pair")
	assert_true(chapter_3_elite.has("blizzard"), "chapter_3 elite hazards should add blizzard pressure")
	assert_true(chapter_3_boss.has("crystal_reflection"), "chapter_3 boss hazards should add crystal_reflection")
	assert_eq(chapter_3_safe_camp.size(), 0, "safe camp should clear active hazards")
	assert_true(chapter_4_elite.has("spatial_distortion"), "chapter_4 elite hazards should add spatial_distortion")

	var chapter_3_combat_profile: Dictionary = world.call("_get_chapter_visual_profile", 101)
	var chapter_3_boss_profile: Dictionary = world.call("_get_chapter_visual_profile", 103)
	assert_gt(float(chapter_3_boss_profile.get("detail_alpha", 0.0)), float(chapter_3_combat_profile.get("detail_alpha", 0.0)), "boss room visual profile should intensify detail alpha")
	assert_eq(str(chapter_3_boss_profile.get("detail_tint", "")), "#E6F7FF", "boss room visual profile should apply the crystal reflection tint override")


func test_new_environment_hazards_affect_status_and_speed() -> void:
	var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
	assert_not_null(scene, "game_world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	assert_not_null(world, "game_world scene should instantiate")
	if world == null:
		return

	add_child_autofree(world)
	await get_tree().process_frame

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "Player should exist")
	if player == null:
		return

	var stats: Node = player.get_node_or_null("StatsComponent")
	var movement: Node = player.get_node_or_null("MovementComponent")
	assert_not_null(stats, "StatsComponent should exist")
	assert_not_null(movement, "MovementComponent should exist")
	if stats == null or movement == null:
		return

	_set_room_plan(world, 201, "chapter_3", "elite")
	_set_room_plan(world, 202, "chapter_4", "elite")

	stats.set("current_stamina", float(stats.get("stamina_max")))
	world.set("_room_active", true)
	world.set("_current_room_type", "elite")
	world.set("_room_index", 201)
	var chapter_3_hazards: Array[String] = world.call("_get_hazards_for_room", 201)
	world.set("_active_hazards", chapter_3_hazards)
	world.set("_hazard_tick_timer", 0.0)
	world.set("_frostbite", 0.0)
	world.set("_void_corruption", 0.0)

	world.call("_process_environment_hazards", 1.0)

	assert_gt(float(world.get("_frostbite")), 0.0, "blizzard should accumulate frostbite")
	assert_lt(float(stats.get("current_stamina")), float(stats.get("stamina_max")), "blizzard should drain stamina")
	assert_lt(float(movement.get("_environment_speed_multiplier")), 1.0, "new hazards should reduce movement speed")

	world.set("_room_index", 202)
	var chapter_4_hazards: Array[String] = world.call("_get_hazards_for_room", 202)
	world.set("_active_hazards", chapter_4_hazards)
	world.set("_hazard_tick_timer", 0.0)
	world.set("_void_corruption", 0.0)

	world.call("_process_environment_hazards", 1.0)

	assert_gt(float(world.get("_void_corruption")), 0.0, "spatial_distortion should accumulate void corruption")
	assert_lt(float(movement.get("_environment_speed_multiplier")), 1.0, "spatial distortion should also reduce movement speed")


func test_tile_atlas_manifest_declares_handdrawn_profile() -> void:
	var manifest_text: String = FileAccess.get_file_as_string("res://assets/sprites/tiles/atlas_manifest.json")
	assert_true(not manifest_text.is_empty(), "atlas_manifest.json should be readable")
	if manifest_text.is_empty():
		return

	var parsed: Variant = JSON.parse_string(manifest_text)
	assert_true(parsed is Dictionary, "atlas_manifest.json should parse to dictionary")
	if not (parsed is Dictionary):
		return

	var manifest: Dictionary = parsed
	assert_eq(str(manifest.get("style", "")), "handdrawn_v1", "Atlas manifest style should be handdrawn_v1")

	var atlases_var: Variant = manifest.get("atlases", [])
	assert_true(atlases_var is Array, "Atlas manifest should contain atlases array")
	if not (atlases_var is Array):
		return

	var atlases: Array = atlases_var
	assert_gte(atlases.size(), 10, "Atlas manifest should list all generated atlases")

	var files: Dictionary = {}
	for row_var: Variant in atlases:
		if row_var is Dictionary:
			var row: Dictionary = row_var
			files[str(row.get("file", ""))] = true

	assert_true(files.has("ground_ch1.png"), "Atlas manifest should include chapter ground atlas")
	assert_true(files.has("ground_detail_ch4.png"), "Atlas manifest should include chapter ground-detail atlas")
	assert_true(files.has("doors_ch2.png"), "Atlas manifest should include chapter door atlas")
	assert_true(files.has("hazard_overlay_ch3.png"), "Atlas manifest should include chapter hazard atlas")
	assert_true(files.has("ambient_fx_ch4.png"), "Atlas manifest should include chapter ambient atlas")
