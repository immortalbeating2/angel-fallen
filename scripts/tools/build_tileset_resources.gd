extends SceneTree

const TILE_SIZE: int = 32
const SOURCE_ID: int = 0


func _init() -> void:
    var success: bool = true

    success = _save_tileset("res://assets/sprites/tiles/ground_ch1.png", "res://resources/tilesets/game_world_ground_ch1.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_ch2.png", "res://resources/tilesets/game_world_ground_ch2.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_ch3.png", "res://resources/tilesets/game_world_ground_ch3.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_ch4.png", "res://resources/tilesets/game_world_ground_ch4.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_detail_ch1.png", "res://resources/tilesets/game_world_ground_detail_ch1.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_detail_ch2.png", "res://resources/tilesets/game_world_ground_detail_ch2.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_detail_ch3.png", "res://resources/tilesets/game_world_ground_detail_ch3.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ground_detail_ch4.png", "res://resources/tilesets/game_world_ground_detail_ch4.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/doors_ch1.png", "res://resources/tilesets/game_world_doors_ch1.tres", 2) and success
    success = _save_tileset("res://assets/sprites/tiles/doors_ch2.png", "res://resources/tilesets/game_world_doors_ch2.tres", 2) and success
    success = _save_tileset("res://assets/sprites/tiles/doors_ch3.png", "res://resources/tilesets/game_world_doors_ch3.tres", 2) and success
    success = _save_tileset("res://assets/sprites/tiles/doors_ch4.png", "res://resources/tilesets/game_world_doors_ch4.tres", 2) and success
    success = _save_tileset("res://assets/sprites/tiles/hazard_overlay_ch1.png", "res://resources/tilesets/game_world_hazard_overlay_ch1.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/hazard_overlay_ch2.png", "res://resources/tilesets/game_world_hazard_overlay_ch2.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/hazard_overlay_ch3.png", "res://resources/tilesets/game_world_hazard_overlay_ch3.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/hazard_overlay_ch4.png", "res://resources/tilesets/game_world_hazard_overlay_ch4.tres", 3) and success
    success = _save_tileset("res://assets/sprites/tiles/ambient_fx_ch1.png", "res://resources/tilesets/game_world_ambient_fx_ch1.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ambient_fx_ch2.png", "res://resources/tilesets/game_world_ambient_fx_ch2.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ambient_fx_ch3.png", "res://resources/tilesets/game_world_ambient_fx_ch3.tres", 4) and success
    success = _save_tileset("res://assets/sprites/tiles/ambient_fx_ch4.png", "res://resources/tilesets/game_world_ambient_fx_ch4.tres", 4) and success

    success = _save_tileset("res://assets/sprites/tiles/doors.png", "res://resources/tilesets/game_world_doors.tres", 2) and success
    success = _save_tileset("res://assets/sprites/tiles/hazard_overlay.png", "res://resources/tilesets/game_world_hazard_overlay.tres", 3) and success

    if success:
        print("TileSet resources generated in res://resources/tilesets")
        quit(0)
    else:
        push_error("Failed to generate one or more TileSet resources")
        quit(1)


func _save_tileset(texture_path: String, output_path: String, variant_count: int) -> bool:
    var texture: Texture2D = load(texture_path)
    if texture == null:
        push_error("Cannot load texture: %s" % texture_path)
        return false

    var source: TileSetAtlasSource = TileSetAtlasSource.new()
    source.texture = texture
    source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
    for atlas_x: int in range(maxi(1, variant_count)):
        source.create_tile(Vector2i(atlas_x, 0))

    var tileset: TileSet = TileSet.new()
    tileset.add_source(source, SOURCE_ID)

    var err: int = ResourceSaver.save(tileset, output_path)
    if err != OK:
        push_error("ResourceSaver.save failed: %s -> err %d" % [output_path, err])
        return false
    return true
