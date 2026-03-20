extends GutTest

const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


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
