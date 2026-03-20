extends Node2D

@onready var _room_timer_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomTimeValue
@onready var _room_status_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue
@onready var _room_kill_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomKillValue
@onready var _background: ColorRect = $Background
@onready var _ground_tilemap: TileMap = $GroundTileMap
@onready var _ground_detail_tilemap: TileMap = $GroundDetailTileMap
@onready var _door_tilemap: TileMap = $DoorTileMap
@onready var _hazard_tilemap: TileMap = $HazardTileMap
@onready var _ambient_fx_tilemap: TileMap = $AmbientFxTileMap
@onready var _hazard_flash: ColorRect = $HazardFlash
@onready var _spawner: Node2D = $EnemySpawner
@onready var _map_generator: Node = $MapGenerator
@onready var _player: CharacterBody2D = $Player
@onready var _pickups_root: Node2D = $Pickups
@onready var _left_door: Polygon2D = $Doors/LeftDoor
@onready var _right_door: Polygon2D = $Doors/RightDoor
@onready var _narrative_system: Node = $NarrativeSystem
@onready var _narrative_event_panel: Control = $NarrativeEventPanel
@onready var _chapter_intro_panel: Control = $ChapterIntroPanel
@onready var _chapter_transition_panel: Control = $ChapterTransitionPanel
@onready var _memory_altar_panel: Control = $MemoryAltarPanel
@onready var _pause_panel: Control = $PausePanel
@onready var _run_result_panel: Control = $RunResultPanel

@export var pickup_scene: PackedScene

var _room_index: int = 1
var _kills_in_room: int = 0
var _required_kills: int = 12
var _room_active: bool = false
var _current_room_type: String = "combat"
var _gold: int = 0
var _ore: int = 0
var _alignment: float = 0.0
var _shop_offers: Array[Dictionary] = []
var _shop_restock_base_cost: int = 20
var _shop_restock_cost: int = 20
var _shop_restock_growth: float = 0.35
var _shop_restock_cap: int = 180
var _shop_restock_count: int = 0
var _shop_last_economy_factor: float = 1.0
var _shop_chapter_price_mult: float = 1.0
var _shop_chapter_id: String = "chapter_1"
var _shop_chapter_overrides: Dictionary = {}
var _shop_route_overrides: Dictionary = {}
var _shop_quality_weights: Dictionary = {}
var _shop_pools: Dictionary = {}
var _shop_base_quality_weights: Dictionary = {}
var _shop_base_pools: Dictionary = {}
var _shop_category_weights: Dictionary = {}
var _shop_base_category_weights: Dictionary = {}

var _shop_base_restock_cost: int = 20
var _shop_base_restock_growth: float = 0.35
var _shop_base_restock_cap: int = 180

var _shop_catchup_target_per_room: float = 26.0
var _shop_catchup_max_discount: float = 0.35
var _shop_catchup_high_gold_markup: float = 0.15
var _shop_catchup_high_gold_threshold_mult: float = 1.8
var _shop_base_catchup_target_per_room: float = 26.0
var _shop_base_catchup_max_discount: float = 0.35
var _shop_base_catchup_high_gold_markup: float = 0.15
var _shop_base_catchup_high_gold_threshold_mult: float = 1.8

var _shop_ore_exchange_enabled: bool = true
var _shop_ore_exchange_ore_cost: int = 2
var _shop_ore_exchange_gold_gain: int = 14
var _shop_ore_exchange_max_trades: int = 3
var _shop_ore_exchange_bonus_chance: float = 0.15
var _shop_ore_exchange_bonus_gold: int = 4
var _shop_ore_exchange_count: int = 0
var _shop_base_ore_exchange_enabled: bool = true
var _shop_base_ore_exchange_ore_cost: int = 2
var _shop_base_ore_exchange_gold_gain: int = 14
var _shop_base_ore_exchange_max_trades: int = 3
var _shop_base_ore_exchange_bonus_chance: float = 0.15
var _shop_base_ore_exchange_bonus_gold: int = 4
var _shop_route_price_mult: float = 1.0
var _shop_route_target_mult: float = 1.0
var _shop_route_max_discount_add: float = 0.0
var _shop_route_high_markup_add: float = 0.0
var _shop_route_exchange_gold_add: int = 0
var _shop_message: String = ""
var _camp_message: String = ""
var _camp_route_chosen: bool = false
var _run_kills: int = 0
var _run_rooms_cleared: int = 0
var _run_finished: bool = false
var _returning_to_menu: bool = false
var _chapter_intro_pending: bool = false
var _narrative_event_pending: bool = false
var _chapter_transition_pending: bool = false
var _memory_altar_pending: bool = false
var _pause_menu_pending: bool = false
var _shown_chapter_intro: Dictionary = {}
var _active_blessing_id: String = "none"
var _equipped_accessories: Array[String] = []
var _chapter_effect_timeline: Array[Dictionary] = []
var _active_chapter_effects: Array[Dictionary] = []
var _chapter_effects_this_room: Array[Dictionary] = []
var _active_hazards: Array[String] = []
var _frostbite: float = 0.0
var _void_corruption: float = 0.0
var _hazard_tick_timer: float = 0.0
var _hazard_wave: float = 0.0
var _target_background_color: Color = Color(0.10, 0.09, 0.13, 1.0)
var _chapter_effect_spawn_rate_mult: float = 1.0
var _chapter_effect_enemy_hp_mult: float = 1.0
var _chapter_effect_enemy_damage_mult: float = 1.0
var _chapter_effect_hazard_mult: float = 1.0
var _chapter_effect_move_speed_mult: float = 1.0
var _chapter_effect_damage_bonus: float = 0.0
var _chapter_effect_armor_bonus: float = 0.0
var _chapter_effect_applied_armor_bonus: float = 0.0
var _room_history: Dictionary = {}
var _run_plan: Dictionary = {}
var _room_plan_map: Dictionary = {}
var _run_room_count: int = 15
var _run_layout_cols: int = 5
var _run_map_bounds: Dictionary = {}
var _pending_next_rooms: Array[int] = []
var _selected_next_room_slot: int = 0
var _chapter_route_styles: Dictionary = {}
var _current_route_style: String = "neutral"
var _route_event_weight_mult: float = 1.0
var _route_hazard_mult: float = 1.0
var _route_gold_drop_mult: float = 1.0
var _route_ore_drop_mult: float = 1.0
var _route_theme_tint: Color = Color(0.18, 0.34, 0.50, 1.0)
var _route_theme_blend: float = 0.0
var _route_boss_style_profile: Dictionary = {}
var _route_style_profiles: Dictionary = {}
var _route_style_timeline: Array[Dictionary] = []
var _treasure_challenge_enabled: bool = false
var _treasure_challenge_combat_mode: String = "elite"
var _treasure_required_kills_base: int = 4
var _treasure_required_kills_per_room: int = 1
var _treasure_gold_reward_base: int = 32
var _treasure_gold_reward_per_room: int = 2
var _treasure_ore_reward_base: int = 1
var _treasure_ore_reward_step_rooms: int = 5
var _treasure_accessory_chance_base: float = 0.28
var _treasure_accessory_chance_vanguard: float = 0.34
var _treasure_accessory_chance_raider: float = 0.24
var _treasure_rewards_deployed: bool = false

const ROOM_TYPE_COMBAT: String = "combat"
const ROOM_TYPE_BOSS: String = "boss"
const ROOM_TYPE_EVENT: String = "event"
const ROOM_TYPE_SHOP: String = "shop"
const ROOM_TYPE_TREASURE: String = "treasure"
const ROOM_TYPE_SAFE_CAMP: String = "safe_camp"
const ROOM_TYPE_ELITE: String = "elite"
const TILE_SOURCE_ID: int = 0
const TILE_GRID_WIDTH: int = 40
const TILE_GRID_HEIGHT: int = 23
const GROUND_DETAIL_TILE_VARIANTS: int = 4
const HAZARD_TILE_SOURCE_ID: int = 0
const HAZARD_TILE_VARIANTS: int = 3
const AMBIENT_FX_TILE_SOURCE_ID: int = 0
const AMBIENT_FX_TILE_VARIANTS: int = 4
const GROUND_TILESET_PATHS: Dictionary = {
    "chapter_1": "res://resources/tilesets/game_world_ground_ch1.tres",
    "chapter_2": "res://resources/tilesets/game_world_ground_ch2.tres",
    "chapter_3": "res://resources/tilesets/game_world_ground_ch3.tres",
    "chapter_4": "res://resources/tilesets/game_world_ground_ch4.tres"
}
const GROUND_DETAIL_TILESET_PATHS: Dictionary = {
    "chapter_1": "res://resources/tilesets/game_world_ground_detail_ch1.tres",
    "chapter_2": "res://resources/tilesets/game_world_ground_detail_ch2.tres",
    "chapter_3": "res://resources/tilesets/game_world_ground_detail_ch3.tres",
    "chapter_4": "res://resources/tilesets/game_world_ground_detail_ch4.tres"
}
const DOOR_TILESET_PATHS: Dictionary = {
    "chapter_1": "res://resources/tilesets/game_world_doors_ch1.tres",
    "chapter_2": "res://resources/tilesets/game_world_doors_ch2.tres",
    "chapter_3": "res://resources/tilesets/game_world_doors_ch3.tres",
    "chapter_4": "res://resources/tilesets/game_world_doors_ch4.tres"
}
const HAZARD_TILESET_PATHS: Dictionary = {
    "chapter_1": "res://resources/tilesets/game_world_hazard_overlay_ch1.tres",
    "chapter_2": "res://resources/tilesets/game_world_hazard_overlay_ch2.tres",
    "chapter_3": "res://resources/tilesets/game_world_hazard_overlay_ch3.tres",
    "chapter_4": "res://resources/tilesets/game_world_hazard_overlay_ch4.tres"
}
const AMBIENT_FX_TILESET_PATHS: Dictionary = {
    "chapter_1": "res://resources/tilesets/game_world_ambient_fx_ch1.tres",
    "chapter_2": "res://resources/tilesets/game_world_ambient_fx_ch2.tres",
    "chapter_3": "res://resources/tilesets/game_world_ambient_fx_ch3.tres",
    "chapter_4": "res://resources/tilesets/game_world_ambient_fx_ch4.tres"
}

var _ground_tilesets: Dictionary = {}
var _ground_detail_tilesets: Dictionary = {}
var _door_tilesets: Dictionary = {}
var _hazard_tilesets: Dictionary = {}
var _ambient_fx_tilesets: Dictionary = {}
var _hazard_anim_cells: Array[Dictionary] = []
var _hazard_anim_timer: float = 0.0
var _hazard_anim_frame: int = 0
var _ambient_fx_anim_cells: Array[Dictionary] = []
var _ambient_fx_anim_timer: float = 0.0
var _ambient_fx_anim_frame: int = 0
var _ambient_fx_scroll_offset: Vector2 = Vector2.ZERO
var _visual_profile_anim_time: float = 0.0


func _is_combat_progress_room(room_type: String) -> bool:
    if room_type == ROOM_TYPE_COMBAT or room_type == ROOM_TYPE_ELITE or room_type == ROOM_TYPE_BOSS:
        return true
    if room_type == ROOM_TYPE_TREASURE and _treasure_challenge_enabled:
        return true
    return false


func _ready() -> void:
    add_to_group("game_world")
    randomize()
    if pickup_scene == null:
        pickup_scene = load("res://scenes/game/pickup.tscn")
    if pickup_scene != null and ObjectPool != null:
        ObjectPool.register_scene("pickup_basic", pickup_scene, 32)

    _load_shop_economy_config()
    _load_treasure_challenge_config()
    _build_run_plan()
    _run_kills = 0
    _run_rooms_cleared = 0
    _run_finished = false
    _returning_to_menu = false
    _chapter_intro_pending = false
    _narrative_event_pending = false
    _chapter_transition_pending = false
    _memory_altar_pending = false
    _pause_menu_pending = false
    _shown_chapter_intro = {}
    _active_blessing_id = "none"
    _chapter_effect_timeline.clear()
    _active_chapter_effects.clear()
    _chapter_effects_this_room.clear()
    _chapter_effect_applied_armor_bonus = 0.0
    _room_history.clear()
    _pending_next_rooms.clear()
    _selected_next_room_slot = 0
    _chapter_route_styles.clear()
    _current_route_style = "neutral"
    _route_event_weight_mult = 1.0
    _route_hazard_mult = 1.0
    _route_gold_drop_mult = 1.0
    _route_ore_drop_mult = 1.0
    _route_theme_tint = Color(0.18, 0.34, 0.50, 1.0)
    _route_theme_blend = 0.0
    _route_boss_style_profile = {}
    _route_style_timeline.clear()
    _load_route_style_profiles()
    _room_index = _get_run_start_room()
    _initialize_tile_layers()

    GameManager.set_state(GameManager.GameState.PLAYING)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.player_died.connect(_on_player_died)
    EventBus.gold_changed.emit(_gold)
    EventBus.ore_changed.emit(_ore)
    EventBus.route_changed.emit(_alignment)
    EventBus.frostbite_changed.emit(_frostbite)
    EventBus.void_corruption_changed.emit(_void_corruption)
    _apply_selected_character_profile()
    _apply_meta_upgrades()
    if _narrative_system != null and _narrative_system.has_method("reset_run_choices"):
        _narrative_system.reset_run_choices()
    if _narrative_event_panel != null and _narrative_event_panel.has_signal("event_choice_committed"):
        _narrative_event_panel.event_choice_committed.connect(_on_event_choice_committed)
    if _narrative_event_panel != null and _narrative_event_panel.has_signal("event_closed"):
        _narrative_event_panel.event_closed.connect(_on_event_closed)
    if _chapter_intro_panel != null and _chapter_intro_panel.has_signal("intro_closed"):
        _chapter_intro_panel.intro_closed.connect(_on_intro_closed)
    if _chapter_transition_panel != null and _chapter_transition_panel.has_signal("choice_committed"):
        _chapter_transition_panel.choice_committed.connect(_on_transition_choice_committed)
    if _chapter_transition_panel != null and _chapter_transition_panel.has_signal("transition_closed"):
        _chapter_transition_panel.transition_closed.connect(_on_transition_closed)
    if _memory_altar_panel != null and _memory_altar_panel.has_signal("altar_closed"):
        _memory_altar_panel.altar_closed.connect(_on_memory_altar_closed)
    if _pause_panel != null and _pause_panel.has_signal("resume_requested"):
        _pause_panel.resume_requested.connect(_on_pause_resume_requested)
    if _pause_panel != null and _pause_panel.has_signal("retreat_requested"):
        _pause_panel.retreat_requested.connect(_on_pause_retreat_requested)
    if _pause_panel != null and _pause_panel.has_signal("quit_to_menu_requested"):
        _pause_panel.quit_to_menu_requested.connect(_on_pause_quit_to_menu_requested)
    if _run_result_panel != null and _run_result_panel.has_signal("back_to_menu_requested"):
        _run_result_panel.back_to_menu_requested.connect(_on_run_result_back_to_menu)
    if _pause_panel != null and _pause_panel.has_method("close_panel"):
        _pause_panel.close_panel()
    get_tree().paused = false
    _start_room()


func _process(delta: float) -> void:
    if _room_active and _is_combat_progress_room(_current_room_type) and _spawner != null and _spawner.has_method("get_room_time"):
        _room_timer_label.text = "%.1f s" % _spawner.get_room_time()
    elif not _room_active:
        _room_timer_label.text = "-"

    _room_kill_label.text = "%d / %d" % [_kills_in_room, _required_kills]
    _process_environment_hazards(delta)
    _update_environment_visuals(delta)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if _chapter_intro_pending or _narrative_event_pending or _chapter_transition_pending or _memory_altar_pending:
            return

        if _pause_menu_pending:
            _close_pause_panel()
            return

        if GameManager.current_state == GameManager.GameState.PLAYING and not _run_finished:
            _open_pause_panel()
        elif _run_finished:
            SceneManager.go_to_main_menu()
        return

    if GameManager.current_state != GameManager.GameState.PLAYING:
        return

    if _chapter_intro_pending:
        return

    if _narrative_event_pending:
        return

    if _chapter_transition_pending:
        return

    if _memory_altar_pending:
        return

    if _pause_menu_pending:
        return

    if not _room_active and _current_room_type == ROOM_TYPE_SHOP:
        if event.is_action_pressed("shop_buy_1"):
            _try_buy_shop_slot(0)
            return
        if event.is_action_pressed("shop_buy_2"):
            _try_buy_shop_slot(1)
            return
        if event.is_action_pressed("shop_buy_3"):
            _try_buy_shop_slot(2)
            return
        if event.is_action_pressed("shop_buy_4"):
            _try_buy_shop_slot(3)
            return
        if event.is_action_pressed("shop_restock"):
            _try_restock_shop()
            return
        if event.is_action_pressed("shop_exchange_ore"):
            _try_exchange_ore_for_gold()
            return

    if not _room_active and _current_room_type == ROOM_TYPE_SAFE_CAMP:
        if event.is_action_pressed("camp_forge_damage"):
            _try_forge_damage()
            return
        if event.is_action_pressed("camp_forge_speed"):
            _try_forge_speed()
            return
        if event.is_action_pressed("camp_memory_altar"):
            _open_memory_altar()
            return
        if event.is_action_pressed("camp_route_holy"):
            _try_route_choice("holy")
            return
        if event.is_action_pressed("camp_route_void"):
            _try_route_choice("void")
            return

    if not _room_active and _pending_next_rooms.size() > 1:
        if event.is_action_pressed("narrative_choice_1"):
            _selected_next_room_slot = 0
            _refresh_idle_route_prompt()
            return
        if event.is_action_pressed("narrative_choice_2"):
            _selected_next_room_slot = mini(1, _pending_next_rooms.size() - 1)
            _refresh_idle_route_prompt()
            return

    if event.is_action_pressed("interact") and not _room_active:
        _advance_to_next_room()


func get_room_progress_text() -> String:
    return "%d / %d" % [_kills_in_room, _required_kills]


func get_room_status_text() -> String:
    return _room_status_label.text


func get_gold_amount() -> int:
    return _gold


func get_ore_amount() -> int:
    return _ore


func get_room_type_text() -> String:
    return _current_room_type


func get_alignment_value() -> float:
    return _alignment


func get_accessories_text() -> String:
    if _equipped_accessories.is_empty():
        return "-"
    return ", ".join(PackedStringArray(_equipped_accessories))


func get_active_hazards_text() -> String:
    if _active_hazards.is_empty():
        return "-"
    return ", ".join(PackedStringArray(_active_hazards))


func get_frostbite_value() -> float:
    return _frostbite


func get_void_corruption_value() -> float:
    return _void_corruption


func get_chapter_effects_hud_text() -> String:
    if _chapter_effects_this_room.is_empty():
        return "-"

    var rows: Array[String] = []
    for item: Variant in _chapter_effects_this_room:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        rows.append("%s %s (%dR)" % [
            str(row.get("icon", "[~]")),
            str(row.get("title", "Effect")),
            int(row.get("remaining_rooms", 1))
        ])

    if rows.is_empty():
        return "-"
    return "\n".join(PackedStringArray(rows))


func get_route_style_hud_text() -> String:
    var rows: Array[String] = []
    rows.append("Current: %s" % _get_route_style_label())

    var chapter_rows: Array[String] = []
    for idx in range(1, 5):
        var chapter_id: String = "chapter_%d" % idx
        var style_id: String = str(_chapter_route_styles.get(chapter_id, "neutral"))
        chapter_rows.append("CH%d:%s" % [idx, _get_route_style_label(style_id)])
    rows.append(" | ".join(PackedStringArray(chapter_rows)))

    if not _route_style_timeline.is_empty():
        var latest: Dictionary = _route_style_timeline[_route_style_timeline.size() - 1]
        rows.append("Latest lock: R%d %s -> %s" % [
            int(latest.get("room_index", _room_index)),
            str(latest.get("chapter_id", "chapter")),
            _get_route_style_label(str(latest.get("style_id", "neutral")))
        ])

    return "\n".join(PackedStringArray(rows))


func get_minimap_text() -> String:
    var coordinate_lookup: Dictionary = _build_minimap_coordinate_lookup()
    if not coordinate_lookup.is_empty():
        var bounds: Dictionary = _get_minimap_bounds()
        var min_x: int = int(bounds.get("min_x", 0))
        var max_x: int = int(bounds.get("max_x", 0))
        var min_y: int = int(bounds.get("min_y", 0))
        var max_y: int = int(bounds.get("max_y", 0))

        var coord_rows: Array[String] = []
        for map_y in range(min_y, max_y + 1):
            var parts: Array[String] = []
            for map_x in range(min_x, max_x + 1):
                var coord_key: String = "%d:%d" % [map_x, map_y]
                if not coordinate_lookup.has(coord_key):
                    parts.append("----")
                    continue

                var room_id: int = int(coordinate_lookup.get(coord_key, 0))
                parts.append(_build_minimap_room_token(room_id))
            coord_rows.append(" ".join(PackedStringArray(parts)))
        return "\n".join(PackedStringArray(coord_rows))

    return _build_minimap_index_grid()


func _build_minimap_index_grid() -> String:
    var room_count: int = _get_run_room_count()
    var cols: int = _get_run_layout_cols()
    var rows_count: int = int(ceil(float(room_count) / float(cols)))
    var rows: Array[String] = []
    for row_index in range(rows_count):
        var parts: Array[String] = []
        for col_index in range(cols):
            var room_id: int = row_index * cols + col_index + 1
            if room_id > room_count:
                parts.append("----")
            else:
                parts.append(_build_minimap_room_token(room_id))
        rows.append(" ".join(PackedStringArray(parts)))
    return "\n".join(PackedStringArray(rows))


func _build_minimap_coordinate_lookup() -> Dictionary:
    var lookup: Dictionary = {}
    for room_id_var: Variant in _room_plan_map.keys():
        var room_id: int = int(room_id_var)
        var row_var: Variant = _room_plan_map.get(room_id, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        if not row.has("map_x") or not row.has("map_y"):
            continue
        var key: String = "%d:%d" % [int(row.get("map_x", 0)), int(row.get("map_y", 0))]
        lookup[key] = room_id
    return lookup


func _get_minimap_bounds() -> Dictionary:
    if not _run_map_bounds.is_empty():
        return _run_map_bounds

    var has_any: bool = false
    var min_x: int = 0
    var max_x: int = 0
    var min_y: int = 0
    var max_y: int = 0
    for row_var: Variant in _room_plan_map.values():
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        if not row.has("map_x") or not row.has("map_y"):
            continue
        var map_x: int = int(row.get("map_x", 0))
        var map_y: int = int(row.get("map_y", 0))
        if not has_any:
            min_x = map_x
            max_x = map_x
            min_y = map_y
            max_y = map_y
            has_any = true
        else:
            min_x = mini(min_x, map_x)
            max_x = maxi(max_x, map_x)
            min_y = mini(min_y, map_y)
            max_y = maxi(max_y, map_y)

    if has_any:
        return {
            "min_x": min_x,
            "max_x": max_x,
            "min_y": min_y,
            "max_y": max_y,
            "cols": max_x - min_x + 1,
            "rows": max_y - min_y + 1
        }

    var cols: int = _get_run_layout_cols()
    var rows_count: int = int(ceil(float(_get_run_room_count()) / float(cols)))
    return {
        "min_x": 0,
        "max_x": cols - 1,
        "min_y": 0,
        "max_y": maxi(0, rows_count - 1),
        "cols": cols,
        "rows": rows_count
    }


func _build_minimap_room_token(room_id: int) -> String:
    if not _room_history.has(room_id):
        return "??"

    var row_var: Variant = _room_history.get(room_id, {})
    if not (row_var is Dictionary):
        return "??"

    var row: Dictionary = row_var
    var room_type: String = str(row.get("type", ROOM_TYPE_COMBAT))
    var completed: bool = bool(row.get("completed", false))
    var marker: String = _room_type_to_minimap_marker(room_type)
    if completed:
        marker = marker.to_lower()

    var token: String = "%02d%s" % [room_id, marker]
    if room_id == _room_index and not _run_finished:
        return ">%s<" % token
    return token


func _room_type_to_minimap_marker(room_type: String) -> String:
    match room_type:
        ROOM_TYPE_BOSS:
            return "B"
        ROOM_TYPE_EVENT:
            return "E"
        ROOM_TYPE_SHOP:
            return "S"
        ROOM_TYPE_TREASURE:
            return "T"
        ROOM_TYPE_SAFE_CAMP:
            return "H"
        ROOM_TYPE_ELITE:
            return "L"
        _:
            return "C"


func _ensure_room_history(index: int, room_type: String) -> void:
    _room_history[index] = {
        "type": room_type,
        "completed": bool((_room_history.get(index, {}) as Dictionary).get("completed", false))
    }


func _mark_room_completed(index: int) -> void:
    if not _room_history.has(index):
        return
    var row_var: Variant = _room_history.get(index, {})
    if row_var is Dictionary:
        var row: Dictionary = row_var
        row["completed"] = true
        _room_history[index] = row


func _start_room() -> void:
    if _room_index > _get_run_room_count():
        _finish_run("victory")
        return

    _clear_active_enemies()
    _clear_active_pickups()
    _chapter_intro_pending = false
    _narrative_event_pending = false
    _chapter_transition_pending = false
    _memory_altar_pending = false
    _pause_menu_pending = false
    _pending_next_rooms.clear()
    _selected_next_room_slot = 0
    _current_room_type = _resolve_room_type(_room_index)
    _sync_route_style_for_room(_room_index)
    if GameManager != null and GameManager.has_method("set_run_context"):
        GameManager.set_run_context(_room_index, _current_room_type, _get_chapter_id_for_room(_room_index))
    _ensure_room_history(_room_index, _current_room_type)
    _active_hazards = _get_hazards_for_room(_room_index)
    _ambient_fx_scroll_offset = Vector2.ZERO
    _visual_profile_anim_time = 0.0
    _render_hazard_tiles()
    _render_ambient_fx_tiles()
    _advance_chapter_effects_for_room()
    _apply_room_theme(_room_index)
    _treasure_rewards_deployed = false

    _kills_in_room = 0
    _required_kills = 0
    _hazard_tick_timer = 0.0
    EventBus.room_entered.emit("room_%d" % _room_index, _current_room_type)

    if _should_show_chapter_intro(_room_index):
        _show_chapter_intro(_room_index)
        return

    _enter_current_room_type()


func _enter_current_room_type() -> void:
    if _current_room_type == ROOM_TYPE_COMBAT:
        _enter_combat_room()
    elif _current_room_type == ROOM_TYPE_ELITE:
        _enter_elite_room()
    elif _current_room_type == ROOM_TYPE_BOSS:
        _enter_boss_room()
    elif _current_room_type == ROOM_TYPE_EVENT:
        _enter_event_room()
    elif _current_room_type == ROOM_TYPE_SHOP:
        _enter_shop_room()
    elif _current_room_type == ROOM_TYPE_TREASURE:
        _enter_treasure_room()
    else:
        _enter_safe_camp_room()


func _should_show_chapter_intro(index: int) -> bool:
    var room_plan: Dictionary = _get_room_plan(index)
    if room_plan.is_empty():
        return false
    if not bool(room_plan.get("show_intro", false)):
        return false
    var chapter_key: String = str(room_plan.get("chapter_id", _get_chapter_id_for_room(index)))
    return not bool(_shown_chapter_intro.get(chapter_key, false))


func _show_chapter_intro(index: int) -> void:
    _room_active = false
    _chapter_intro_pending = true
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    _room_timer_label.text = "-"
    _room_status_label.text = "Chapter briefing..."

    var chapter_index: int = _get_chapter_index_for_room(index)
    if _chapter_intro_panel != null and _chapter_intro_panel.has_method("show_intro"):
        _chapter_intro_panel.show_intro(chapter_index, get_active_hazards_text(), _get_active_blessing_text())


func _on_intro_closed() -> void:
    _chapter_intro_pending = false
    _shown_chapter_intro[_get_chapter_id_for_room(_room_index)] = true
    _enter_current_room_type()


func _enter_combat_room() -> void:
    _required_kills = 10 + _room_index * 3
    _room_active = true
    _room_timer_label.text = "0.0 s"
    _room_status_label.text = "Combat Room %d: Defeat %d enemies | Hazards: %s | Effects: %s" % [
        _room_index,
        _required_kills,
        get_active_hazards_text(),
        _get_active_chapter_effects_text()
    ]
    _room_status_label.text += " | Style: %s" % _get_route_style_label()
    _set_doors_locked(true)

    if _spawner != null and _spawner.has_method("start_room_combat"):
        _spawner.start_room_combat(_room_index, "normal")


func _enter_elite_room() -> void:
    _required_kills = 6 + _room_index * 2
    _room_active = true
    _room_timer_label.text = "0.0 s"
    _room_status_label.text = "Elite Room %d: Eliminate %d elites | Hazards: %s | Effects: %s" % [
        _room_index,
        _required_kills,
        get_active_hazards_text(),
        _get_active_chapter_effects_text()
    ]
    _room_status_label.text += " | Style: %s" % _get_route_style_label()
    _set_doors_locked(true)

    if _spawner != null and _spawner.has_method("start_room_combat"):
        _spawner.start_room_combat(_room_index, "elite")


func _enter_boss_room() -> void:
    _required_kills = 1
    _room_active = true
    _room_timer_label.text = "0.0 s"
    var boss_id: String = _get_boss_id_for_room(_room_index)
    _room_status_label.text = "Boss Room %d: Defeat %s | Hazards: %s | Effects: %s" % [
        _room_index,
        _get_boss_title(boss_id),
        get_active_hazards_text(),
        _get_active_chapter_effects_text()
    ]
    _room_status_label.text += " | Style: %s" % _get_route_style_label()
    _set_doors_locked(true)

    if _spawner != null and _spawner.has_method("start_room_combat"):
        _spawner.start_room_combat(_room_index, "boss", boss_id, _route_boss_style_profile)


func _enter_shop_room() -> void:
    _room_active = false
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    _apply_shop_chapter_profile(_get_chapter_id_for_room(_room_index))

    _set_frostbite(maxf(0.0, _frostbite - 18.0))
    _set_void_corruption(maxf(0.0, _void_corruption - 14.0))

    _shop_restock_count = 0
    _shop_ore_exchange_count = 0
    _shop_restock_cost = _shop_restock_base_cost
    _shop_offers = _build_shop_offers()
    _prepare_next_room_candidates()
    _shop_message = "Shop refreshed. Buy with 1-4."
    _update_shop_text()


func _enter_treasure_room() -> void:
    if _treasure_challenge_enabled:
        _required_kills = maxi(1, _treasure_required_kills_base + _room_index * _treasure_required_kills_per_room)
        _room_active = true
        _set_doors_locked(true)
        _room_timer_label.text = "0.0 s"
        _room_status_label.text = "Treasure Room %d: Clear elite cache (%d) | Hazards: %s | Effects: %s | Style: %s" % [
            _room_index,
            _required_kills,
            get_active_hazards_text(),
            _get_active_chapter_effects_text(),
            _get_route_style_label()
        ]

        if _spawner != null and _spawner.has_method("start_room_combat"):
            _spawner.start_room_combat(_room_index, _treasure_challenge_combat_mode)
        return

    _room_active = false
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    _room_timer_label.text = "-"
    _prepare_next_room_candidates()
    _deploy_treasure_rewards("Treasure cache opened")


func _deploy_treasure_rewards(status_prefix: String) -> void:
    if _treasure_rewards_deployed:
        return

    _treasure_rewards_deployed = true
    var player_pos: Vector2 = _player.global_position if _player != null else global_position
    var gold_reward: int = _scale_drop_amount(_treasure_gold_reward_base + _room_index * _treasure_gold_reward_per_room, _route_gold_drop_mult)
    var ore_step_rooms: int = maxi(1, _treasure_ore_reward_step_rooms)
    var ore_reward: int = _scale_drop_amount(_treasure_ore_reward_base + int((_room_index + 1) / ore_step_rooms), _route_ore_drop_mult)
    _spawn_direct_pickup("gold", gold_reward, "treasure_gold", player_pos + Vector2(-18.0, -8.0))
    _spawn_direct_pickup("ore", ore_reward, "treasure_ore", player_pos + Vector2(18.0, -10.0))

    var accessory_chance: float = _treasure_accessory_chance_base
    if _current_route_style == "vanguard":
        accessory_chance = _treasure_accessory_chance_vanguard
    elif _current_route_style == "raider":
        accessory_chance = _treasure_accessory_chance_raider
    accessory_chance = clampf(accessory_chance, 0.0, 1.0)

    var accessory_note: String = ""
    if randf() <= accessory_chance:
        _spawn_direct_pickup("accessory", 1, "accessory_drop", player_pos + Vector2(0.0, 10.0))
        accessory_note = " + accessory cache"

    _prepare_next_room_candidates()
    _room_status_label.text = "%s: Loot deployed (Gold +%d, Ore +%d%s) | Style: %s\n%s" % [
        status_prefix,
        gold_reward,
        ore_reward,
        accessory_note,
        _get_route_style_label(),
        _get_next_route_hint_text()
    ]


func _enter_event_room() -> void:
    _room_active = false
    _narrative_event_pending = false
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    var chapter_index: int = _get_chapter_index_for_room(_room_index)
    var event_data: Dictionary = {}
    if _narrative_system != null and _narrative_system.has_method("get_chapter_event"):
        event_data = _narrative_system.get_chapter_event(chapter_index, _alignment, _current_route_style, _route_event_weight_mult)

    if event_data.is_empty():
        _room_status_label.text = "Event Room: no event data. Press E for next room"
        return

    _room_timer_label.text = "-"
    _prepare_next_room_candidates()
    _room_status_label.text = "Event Room: choose your path | Effects: %s | Style: %s" % [_get_active_chapter_effects_text(), _get_route_style_label()]
    _narrative_event_pending = true
    if _narrative_event_panel != null and _narrative_event_panel.has_method("show_event_panel"):
        _narrative_event_panel.show_event_panel(event_data, _alignment)


func _enter_safe_camp_room() -> void:
    _room_active = false
    _set_doors_locked(false)
    _camp_route_chosen = false
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    var health_component: Node = _player.get_node_or_null("HealthComponent")
    if health_component != null and health_component.has_method("heal"):
        health_component.heal(25.0)

    var stats: Node = _player.get_node_or_null("StatsComponent")
    if stats != null and stats.get("stamina_max") != null:
        stats.current_stamina = stats.stamina_max

    _set_frostbite(maxf(0.0, _frostbite - 45.0))
    _set_void_corruption(maxf(0.0, _void_corruption - 40.0))

    _prepare_next_room_candidates()
    _camp_message = "Recovered: +25 HP, stamina refilled"
    _update_camp_text()


func _on_enemy_killed(_enemy_id: String, _position: Vector2) -> void:
    _run_kills += 1
    var drop_table_id: String = _resolve_drop_table_for_enemy(_enemy_id)
    _spawn_drops(_position, drop_table_id)

    if not _room_active:
        return

    if not _is_combat_progress_room(_current_room_type):
        return

    _kills_in_room += 1

    if _kills_in_room >= _required_kills:
        call_deferred("_try_clear_room")


func _try_clear_room() -> void:
    if not _is_combat_progress_room(_current_room_type):
        return

    if _spawner != null and _spawner.has_method("get_alive_count"):
        if _spawner.get_alive_count() > 0:
            return

    _room_active = false
    _run_rooms_cleared += 1
    _mark_room_completed(_room_index)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    EventBus.room_cleared.emit("room_%d" % _room_index)
    _set_doors_locked(false)
    var next_rooms: Array[int] = _prepare_next_room_candidates()
    if _current_room_type == ROOM_TYPE_TREASURE:
        _deploy_treasure_rewards("Treasure cache secured")
    if _current_room_type == ROOM_TYPE_BOSS:
        if next_rooms.is_empty():
            _finish_run("victory")
            return
        var chapter: int = _get_chapter_index_for_room(_room_index)
        EventBus.memory_fragment_found.emit("memory_ch%d_boss" % chapter)
        _begin_chapter_transition(chapter)
    elif _current_room_type == ROOM_TYPE_TREASURE:
        if next_rooms.is_empty():
            _finish_run("victory")
            return
    else:
        if next_rooms.is_empty():
            _finish_run("victory")
            return
        _room_status_label.text = "Room Cleared! %s" % _get_next_route_hint_text()


func _on_player_died(_reason: String) -> void:
    _finish_run("death")


func _finish_run(outcome: String) -> void:
    if _run_finished:
        return
    _run_finished = true
    _reset_pause_state()

    GameManager.set_state(GameManager.GameState.GAME_OVER)
    _room_active = false
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    var level_reached: int = 1
    var progression: Node = _player.get_node_or_null("ProgressionComponent")
    if progression != null and progression.get("current_level") != null:
        level_reached = int(progression.current_level)

    var run_result: Dictionary = SaveManager.submit_run_result({
        "outcome": outcome,
        "rooms_cleared": _run_rooms_cleared,
        "kills": _run_kills,
        "level_reached": level_reached,
        "gold": _gold,
        "ore": _ore,
        "alignment": _alignment,
        "narrative_choices": _narrative_system.get_run_choices() if _narrative_system != null and _narrative_system.has_method("get_run_choices") else [],
        "chapter_effect_timeline": _chapter_effect_timeline.duplicate(true),
        "chapter_route_styles": _chapter_route_styles.duplicate(true),
        "route_style_timeline": _route_style_timeline.duplicate(true)
    })

    _room_status_label.text = "Run Ended: %s | Meta +%d" % [
        outcome.to_upper(),
        int(run_result.get("meta_reward", 0))
    ]

    if _run_result_panel != null and _run_result_panel.has_method("show_result"):
        _run_result_panel.show_result(run_result)
    else:
        call_deferred("_return_to_main_menu")


func _return_to_main_menu() -> void:
    if _returning_to_menu:
        return
    _returning_to_menu = true
    GameManager.set_state(GameManager.GameState.MENU)
    SceneManager.go_to_main_menu()


func _on_run_result_back_to_menu() -> void:
    _return_to_main_menu()


func _open_pause_panel() -> void:
    if _run_finished or _pause_menu_pending:
        return

    _pause_menu_pending = true
    GameManager.set_state(GameManager.GameState.PAUSED)
    get_tree().paused = true
    EventBus.game_paused.emit(true)

    if _pause_panel != null and _pause_panel.has_method("open_panel"):
        _pause_panel.open_panel(_room_index, _current_room_type, _alignment)


func _close_pause_panel() -> void:
    if not _pause_menu_pending:
        return
    _reset_pause_state()


func _reset_pause_state() -> void:
    _pause_menu_pending = false
    get_tree().paused = false
    EventBus.game_paused.emit(false)

    if _pause_panel != null and _pause_panel.has_method("close_panel"):
        _pause_panel.close_panel()

    if not _run_finished:
        GameManager.set_state(GameManager.GameState.PLAYING)


func _on_pause_resume_requested() -> void:
    _close_pause_panel()


func _on_pause_retreat_requested() -> void:
    _reset_pause_state()
    _finish_run("retreat")


func _on_pause_quit_to_menu_requested() -> void:
    _reset_pause_state()
    GameManager.set_state(GameManager.GameState.MENU)
    SceneManager.go_to_main_menu()


func _begin_chapter_transition(chapter: int) -> void:
    _chapter_transition_pending = true
    _room_status_label.text = "Boss down! Chapter %d cleared. Resolve chapter transition..." % chapter
    if _chapter_transition_panel != null and _chapter_transition_panel.has_method("show_transition"):
        _chapter_transition_panel.show_transition(chapter, _alignment)


func _on_transition_choice_committed(chapter_id: String, choice_id: String, alignment_delta: float) -> void:
    _alignment = clampf(_alignment + alignment_delta, -100.0, 100.0)
    EventBus.route_changed.emit(_alignment)
    EventBus.narrative_choice.emit(chapter_id, "chapter_transition", choice_id)
    var transition_segment_id: String = _get_transition_segment_id(chapter_id)
    if _narrative_system != null and _narrative_system.has_method("is_registered_narrative_id"):
        if not _narrative_system.is_registered_narrative_id(transition_segment_id):
            push_warning("Missing narrative index id: %s" % transition_segment_id)
    if _narrative_system != null and _narrative_system.has_method("record_choice"):
        _narrative_system.record_choice(chapter_id, transition_segment_id, choice_id, alignment_delta)
    _apply_transition_blessing(choice_id)
    _room_status_label.text = "Transition choice: %s (%+.0f). Press E to continue" % [
        choice_id,
        alignment_delta
    ]


func _on_transition_closed() -> void:
    _chapter_transition_pending = false
    _room_status_label.text = "Chapter transition resolved. %s" % _get_next_route_hint_text()


func _on_event_choice_committed(event_id: String, choice_id: String, choice_data: Dictionary) -> void:
    var chapter_id: String = _get_chapter_id_for_room(_room_index)
    _apply_event_choice_effects(choice_data)
    EventBus.narrative_choice.emit(chapter_id, event_id, choice_id)
    if _narrative_system != null and _narrative_system.has_method("record_choice"):
        _narrative_system.record_choice(chapter_id, event_id, choice_id, float(choice_data.get("alignment_delta", 0.0)))

    var effect_var: Variant = choice_data.get("chapter_effect", {})
    if effect_var is Dictionary and not (effect_var as Dictionary).is_empty():
        _room_status_label.text = "Event committed: %s | New chapter effect queued: %s" % [
            choice_id,
            str((effect_var as Dictionary).get("title", "effect"))
        ]


func _on_event_closed() -> void:
    _narrative_event_pending = false
    _room_status_label.text = "Event resolved. Next room effects: %s | %s" % [_get_pending_chapter_effects_text(), _get_next_route_hint_text()]


func _apply_event_choice_effects(choice_data: Dictionary) -> void:
    _gold = maxi(0, _gold + int(choice_data.get("gold", 0)))
    _ore = maxi(0, _ore + int(choice_data.get("ore", 0)))
    EventBus.gold_changed.emit(_gold)
    EventBus.ore_changed.emit(_ore)

    var alignment_delta: float = float(choice_data.get("alignment_delta", 0.0))
    if not is_zero_approx(alignment_delta):
        _alignment = clampf(_alignment + alignment_delta, -100.0, 100.0)
        EventBus.route_changed.emit(_alignment)

    _set_frostbite(_frostbite + float(choice_data.get("frostbite_delta", 0.0)))
    _set_void_corruption(_void_corruption + float(choice_data.get("void_delta", 0.0)))

    var blessing: String = str(choice_data.get("blessing", ""))
    if blessing != "":
        _apply_transition_blessing(blessing)

    var chapter_effect_var: Variant = choice_data.get("chapter_effect", {})
    if chapter_effect_var is Dictionary:
        _queue_chapter_effect(chapter_effect_var)


func _apply_transition_blessing(choice_id: String) -> void:
    _clear_active_blessing_effects()

    var stats: Node = _player.get_node_or_null("StatsComponent")
    var health: Node = _player.get_node_or_null("HealthComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")
    if stats == null:
        _active_blessing_id = "none"
        return

    if choice_id == "holy_vow":
        _active_blessing_id = "holy_vow"
        if stats.get("armor") != null:
            stats.armor = minf(0.75, stats.armor + 0.05)
        if stats.get("frostbite_resistance") != null:
            stats.frostbite_resistance = minf(0.75, stats.frostbite_resistance + 0.04)
        if health != null and health.has_method("heal"):
            health.heal(20.0)
    elif choice_id == "void_oath":
        _active_blessing_id = "void_oath"
        if weapon != null and weapon.get("base_damage") != null:
            weapon.base_damage += 1.8
        if stats.get("crit_chance") != null:
            stats.crit_chance = minf(0.95, stats.crit_chance + 0.04)
        if stats.get("armor") != null:
            stats.armor = maxf(0.0, stats.armor - 0.04)
        if stats.get("void_resistance") != null:
            stats.void_resistance = minf(0.75, stats.void_resistance + 0.05)
    else:
        _active_blessing_id = "none"

    if health != null and health.get("current_hp") != null and health.get("max_hp") != null:
        EventBus.health_changed.emit(float(health.current_hp), float(health.max_hp))


func _clear_active_blessing_effects() -> void:
    if _active_blessing_id == "none":
        return

    var stats: Node = _player.get_node_or_null("StatsComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")
    if stats == null:
        _active_blessing_id = "none"
        return

    match _active_blessing_id:
        "holy_vow":
            if stats.get("armor") != null:
                stats.armor = maxf(0.0, stats.armor - 0.05)
            if stats.get("frostbite_resistance") != null:
                stats.frostbite_resistance = maxf(0.0, stats.frostbite_resistance - 0.04)
        "void_oath":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage = maxf(1.0, weapon.base_damage - 1.8)
            if stats.get("crit_chance") != null:
                stats.crit_chance = maxf(0.0, stats.crit_chance - 0.04)
            if stats.get("armor") != null:
                stats.armor = minf(0.75, stats.armor + 0.04)
            if stats.get("void_resistance") != null:
                stats.void_resistance = maxf(0.0, stats.void_resistance - 0.05)

    _active_blessing_id = "none"


func _queue_chapter_effect(effect_data: Dictionary) -> void:
    if effect_data.is_empty():
        return

    var duration_rooms: int = maxi(1, int(effect_data.get("duration_rooms", 2)))
    var effects_var: Variant = effect_data.get("effects", {})
    if not (effects_var is Dictionary):
        return

    var packed_effect: Dictionary = {
        "id": str(effect_data.get("id", "effect_unknown")),
        "title": str(effect_data.get("title", "Chapter Effect")),
        "desc": str(effect_data.get("desc", "")),
        "remaining_rooms": duration_rooms,
        "effects": (effects_var as Dictionary).duplicate(true)
    }
    var icon: String = "[~]"
    var score: float = 0.0
    var packed_effects_var: Variant = packed_effect.get("effects", {})
    if packed_effects_var is Dictionary:
        icon = _get_chapter_effect_icon(packed_effects_var)
        score = _evaluate_chapter_effect_score(packed_effects_var)

    _active_chapter_effects.append(packed_effect)
    _chapter_effect_timeline.append({
        "room_index": _room_index,
        "chapter_id": _get_chapter_id_for_room(_room_index),
        "effect_id": str(packed_effect.get("id", "effect_unknown")),
        "title": str(packed_effect.get("title", "Chapter Effect")),
        "desc": str(packed_effect.get("desc", "")),
        "duration_rooms": duration_rooms,
        "icon": icon,
        "score": score
    })
    _camp_message = "Gained chapter effect: %s (%d rooms)" % [packed_effect["title"], duration_rooms]


func _advance_chapter_effects_for_room() -> void:
    _chapter_effect_spawn_rate_mult = 1.0
    _chapter_effect_enemy_hp_mult = 1.0
    _chapter_effect_enemy_damage_mult = 1.0
    _chapter_effect_hazard_mult = 1.0
    _chapter_effect_move_speed_mult = 1.0
    _chapter_effect_damage_bonus = 0.0
    _chapter_effect_armor_bonus = 0.0
    _chapter_effects_this_room.clear()

    var retained_effects: Array[Dictionary] = []
    for item: Variant in _active_chapter_effects:
        if not (item is Dictionary):
            continue

        var row: Dictionary = (item as Dictionary).duplicate(true)
        var remaining_rooms: int = int(row.get("remaining_rooms", 0))
        if remaining_rooms <= 0:
            continue

        var effects_var: Variant = row.get("effects", {})
        var effects_map: Dictionary = {}
        if effects_var is Dictionary:
            effects_map = (effects_var as Dictionary).duplicate(true)
            _accumulate_chapter_effect_modifiers(effects_var)

        _chapter_effects_this_room.append({
            "id": str(row.get("id", "effect")),
            "title": str(row.get("title", "Chapter Effect")),
            "remaining_rooms": remaining_rooms,
            "icon": _get_chapter_effect_icon(effects_map),
            "score": _evaluate_chapter_effect_score(effects_map)
        })

        row["remaining_rooms"] = remaining_rooms - 1
        if int(row.get("remaining_rooms", 0)) > 0:
            retained_effects.append(row)

    _active_chapter_effects = retained_effects
    _apply_chapter_effect_runtime()


func _accumulate_chapter_effect_modifiers(effects: Dictionary) -> void:
    _chapter_effect_spawn_rate_mult *= maxf(0.55, float(effects.get("enemy_spawn_rate_mult", 1.0)))
    _chapter_effect_enemy_hp_mult *= maxf(0.55, float(effects.get("enemy_hp_mult", 1.0)))
    _chapter_effect_enemy_damage_mult *= maxf(0.55, float(effects.get("enemy_damage_mult", 1.0)))
    _chapter_effect_hazard_mult *= maxf(0.5, float(effects.get("hazard_intensity_mult", 1.0)))
    _chapter_effect_move_speed_mult *= clampf(float(effects.get("move_speed_mult", 1.0)), 0.6, 1.4)
    _chapter_effect_damage_bonus += float(effects.get("damage_bonus_pct", 0.0))
    _chapter_effect_armor_bonus += float(effects.get("armor_bonus", 0.0))


func _apply_chapter_effect_runtime() -> void:
    var stats: Node = _player.get_node_or_null("StatsComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")

    if _spawner != null and _spawner.has_method("set_runtime_modifiers"):
        _spawner.set_runtime_modifiers(_chapter_effect_spawn_rate_mult, _chapter_effect_enemy_hp_mult, _chapter_effect_enemy_damage_mult)

    if weapon != null and weapon.get("external_damage_bonus_pct") != null:
        weapon.external_damage_bonus_pct = _chapter_effect_damage_bonus

    var desired_armor_bonus: float = clampf(_chapter_effect_armor_bonus, -0.3, 0.3)
    if stats != null and stats.get("armor") != null:
        var delta: float = desired_armor_bonus - _chapter_effect_applied_armor_bonus
        if not is_zero_approx(delta):
            stats.armor = clampf(stats.armor + delta, 0.0, 0.75)
        _chapter_effect_applied_armor_bonus = desired_armor_bonus
    else:
        _chapter_effect_applied_armor_bonus = 0.0


func _get_active_chapter_effects_text() -> String:
    if _chapter_effects_this_room.is_empty():
        return "none"

    var rows: Array[String] = []
    for item: Variant in _chapter_effects_this_room:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        rows.append("%s %s(%d)" % [
            str(row.get("icon", "[~]")),
            str(row.get("title", "Effect")),
            int(row.get("remaining_rooms", 1))
        ])
    if rows.is_empty():
        return "none"
    return ", ".join(PackedStringArray(rows))


func _get_pending_chapter_effects_text() -> String:
    if _active_chapter_effects.is_empty():
        return "none"

    var rows: Array[String] = []
    for item: Variant in _active_chapter_effects:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var effects_var: Variant = row.get("effects", {})
        var icon: String = "[~]"
        if effects_var is Dictionary:
            icon = _get_chapter_effect_icon(effects_var)
        rows.append("%s(%d)" % [
            "%s %s" % [icon, str(row.get("title", "Effect"))],
            int(row.get("remaining_rooms", 0))
        ])
    if rows.is_empty():
        return "none"
    return ", ".join(PackedStringArray(rows))


func _get_chapter_effect_icon(effects: Dictionary) -> String:
    var score: float = _evaluate_chapter_effect_score(effects)
    if score >= 0.25:
        return "[+]"
    if score <= -0.25:
        return "[-]"
    return "[~]"


func _evaluate_chapter_effect_score(effects: Dictionary) -> float:
    if effects.is_empty():
        return 0.0

    var score: float = 0.0
    score += float(effects.get("damage_bonus_pct", 0.0)) * 1.0
    score += float(effects.get("armor_bonus", 0.0)) * 1.2

    var move_mult: float = float(effects.get("move_speed_mult", 1.0))
    score += (move_mult - 1.0) * 1.4

    var spawn_mult: float = float(effects.get("enemy_spawn_rate_mult", 1.0))
    score += (1.0 - spawn_mult) * 0.9

    var hp_mult: float = float(effects.get("enemy_hp_mult", 1.0))
    score += (1.0 - hp_mult) * 0.9

    var dmg_mult: float = float(effects.get("enemy_damage_mult", 1.0))
    score += (1.0 - dmg_mult) * 1.1

    var hazard_mult: float = float(effects.get("hazard_intensity_mult", 1.0))
    score += (1.0 - hazard_mult) * 1.1
    return score


func _get_active_blessing_text() -> String:
    match _active_blessing_id:
        "holy_vow":
            return "Holy Vow (+armor, +frost resist, +heal)"
        "void_oath":
            return "Void Oath (+damage, +crit, -armor)"
        _:
            return "None"


func _build_run_plan() -> void:
    _run_plan = {}
    _room_plan_map = {}
    _run_room_count = 15
    _run_layout_cols = 5
    _run_map_bounds = {}

    var config: Dictionary = ConfigManager.get_config("map_generation", {})
    if _map_generator != null and _map_generator.has_method("generate_run_plan"):
        _run_plan = _map_generator.generate_run_plan(config)
    elif not config.is_empty():
        _run_plan = config

    _run_room_count = maxi(1, int(_run_plan.get("room_count", 15)))
    _run_layout_cols = clampi(int(_run_plan.get("layout_cols", 5)), 3, 8)
    var map_bounds_var: Variant = _run_plan.get("map_bounds", {})
    if map_bounds_var is Dictionary:
        _run_map_bounds = (map_bounds_var as Dictionary).duplicate(true)

    var room_map_var: Variant = _run_plan.get("room_plan_map", {})
    if room_map_var is Dictionary:
        _room_plan_map = (room_map_var as Dictionary).duplicate(true)
    else:
        var rooms_var: Variant = _run_plan.get("rooms", [])
        if rooms_var is Array:
            for item: Variant in rooms_var:
                if not (item is Dictionary):
                    continue
                var row: Dictionary = item
                _room_plan_map[int(row.get("index", 0))] = row


func _get_room_plan(index: int) -> Dictionary:
    var row_var: Variant = _room_plan_map.get(index, {})
    if row_var is Dictionary:
        return row_var
    return {}


func _get_run_room_count() -> int:
    return maxi(1, _run_room_count)


func _get_run_layout_cols() -> int:
    return clampi(_run_layout_cols, 3, 16)


func _get_run_start_room() -> int:
    var start_room: int = int(_run_plan.get("start_room", 1))
    if start_room < 1:
        start_room = 1
    return start_room


func _prepare_next_room_candidates() -> Array[int]:
    var room_plan: Dictionary = _get_room_plan(_room_index)
    var next_rows_out: Array[int] = []
    var next_rows_var: Variant = room_plan.get("next_rooms", [])
    if next_rows_var is Array:
        for item: Variant in next_rows_var:
            var room_id: int = int(item)
            if room_id > 0 and not next_rows_out.has(room_id):
                next_rows_out.append(room_id)

    _pending_next_rooms = next_rows_out
    _selected_next_room_slot = clampi(_selected_next_room_slot, 0, maxi(0, _pending_next_rooms.size() - 1))
    return _pending_next_rooms


func _advance_to_next_room() -> void:
    var next_rooms: Array[int] = _prepare_next_room_candidates()
    if next_rooms.is_empty():
        if not _run_finished:
            _finish_run("victory")
        return

    var selected_slot: int = clampi(_selected_next_room_slot, 0, next_rooms.size() - 1)
    if next_rooms.size() > 1:
        _commit_route_style_choice(_get_chapter_id_for_room(_room_index), selected_slot)
    var next_room_id: int = next_rooms[selected_slot]
    _mark_room_completed(_room_index)
    _room_index = next_room_id
    _start_room()


func _refresh_idle_route_prompt() -> void:
    if _room_active:
        return
    var route_hint: String = _get_next_route_hint_text()
    if route_hint == "":
        return

    if _current_room_type == ROOM_TYPE_SHOP:
        _update_shop_text()
    elif _current_room_type == ROOM_TYPE_SAFE_CAMP:
        _update_camp_text()
    else:
        _room_status_label.text = "Route updated: %s" % route_hint


func _get_next_route_hint_text() -> String:
    var next_rooms: Array[int] = _prepare_next_room_candidates()
    if next_rooms.is_empty():
        return "No route remains. Press E to finish run"

    if next_rooms.size() == 1:
        return "Press E -> %s" % _format_room_route_brief(next_rooms[0])

    var rows: Array[String] = []
    var chapter_id: String = _get_chapter_id_for_room(_room_index)
    var chapter_style_locked: bool = _chapter_route_styles.has(chapter_id)
    for idx in range(mini(2, next_rooms.size())):
        var token: String = "[%d]%s" % [idx + 1, _format_room_route_brief(next_rooms[idx])]
        if not chapter_style_locked:
            var style_preview: String = "vanguard"
            if idx == 1:
                style_preview = "raider"
            token += "{%s}" % style_preview
        if idx == _selected_next_room_slot:
            token = "*" + token
        rows.append(token)
    return "Routes: %s | E to confirm" % "  ".join(PackedStringArray(rows))


func _format_room_route_brief(room_id: int) -> String:
    var room_plan: Dictionary = _get_room_plan(room_id)
    var room_type: String = str(room_plan.get("room_type", ROOM_TYPE_COMBAT))
    return "R%d-%s" % [room_id, room_type.to_upper()]


func _load_route_style_profiles() -> void:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var styles_var: Variant = config.get("route_styles", {})
    if styles_var is Dictionary:
        _route_style_profiles = (styles_var as Dictionary).duplicate(true)
    else:
        _route_style_profiles = {}

    if not _route_style_profiles.has("neutral"):
        _route_style_profiles["neutral"] = {
            "event_weight_mult": 1.0,
            "hazard_mult": 1.0,
            "gold_drop_mult": 1.0,
            "ore_drop_mult": 1.0,
            "theme_tint": "#2e5785",
            "theme_blend": 0.0,
            "boss_hp_mult": 1.0,
            "boss_damage_mult": 1.0,
            "boss_speed_mult": 1.0,
            "boss_scale_mult": 1.0,
            "boss_color": "#f2733a"
        }


func _sync_route_style_for_room(index: int) -> void:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var style_id: String = str(_chapter_route_styles.get(chapter_id, "neutral")).strip_edges()
    if style_id == "":
        style_id = "neutral"
    _current_route_style = style_id
    _apply_route_style_profile(style_id)


func _commit_route_style_choice(chapter_id: String, selected_slot: int) -> void:
    if chapter_id == "":
        return
    if _chapter_route_styles.has(chapter_id):
        return

    var style_id: String = "neutral"
    if selected_slot <= 0:
        style_id = "vanguard"
    elif selected_slot == 1:
        style_id = "raider"

    _chapter_route_styles[chapter_id] = style_id
    _route_style_timeline.append({
        "room_index": _room_index,
        "chapter_id": chapter_id,
        "selected_slot": selected_slot,
        "style_id": style_id
    })
    if chapter_id == _get_chapter_id_for_room(_room_index):
        _current_route_style = style_id
        _apply_route_style_profile(style_id)


func _apply_route_style_profile(style_id: String) -> void:
    if _route_style_profiles.is_empty():
        _load_route_style_profiles()

    var fallback: Dictionary = _route_style_profiles.get("neutral", {
        "event_weight_mult": 1.0,
        "hazard_mult": 1.0,
        "gold_drop_mult": 1.0,
        "ore_drop_mult": 1.0,
        "theme_tint": "#2e5785",
        "theme_blend": 0.0,
        "boss_hp_mult": 1.0,
        "boss_damage_mult": 1.0,
        "boss_speed_mult": 1.0,
        "boss_scale_mult": 1.0,
        "boss_color": "#f2733a"
    })
    var row: Dictionary = _route_style_profiles.get(style_id, fallback)

    _route_event_weight_mult = clampf(float(row.get("event_weight_mult", 1.0)), 0.5, 1.8)
    _route_hazard_mult = clampf(float(row.get("hazard_mult", 1.0)), 0.6, 1.5)
    _route_gold_drop_mult = clampf(float(row.get("gold_drop_mult", 1.0)), 0.5, 2.0)
    _route_ore_drop_mult = clampf(float(row.get("ore_drop_mult", 1.0)), 0.5, 2.0)

    var theme_tint_raw: String = str(row.get("theme_tint", "#2e5785"))
    _route_theme_tint = Color.from_string(theme_tint_raw, Color(0.18, 0.34, 0.50, 1.0))
    _route_theme_tint.a = 1.0
    _route_theme_blend = clampf(float(row.get("theme_blend", 0.0)), 0.0, 0.5)

    _route_boss_style_profile = {
        "hp_mult": clampf(float(row.get("boss_hp_mult", 1.0)), 0.7, 1.4),
        "damage_mult": clampf(float(row.get("boss_damage_mult", 1.0)), 0.7, 1.5),
        "speed_mult": clampf(float(row.get("boss_speed_mult", 1.0)), 0.7, 1.5),
        "scale_mult": clampf(float(row.get("boss_scale_mult", 1.0)), 0.85, 1.25),
        "color": str(row.get("boss_color", "#f2733a"))
    }


func _apply_shop_route_profile(style_id: String) -> void:
    _shop_route_price_mult = 1.0
    _shop_route_target_mult = 1.0
    _shop_route_max_discount_add = 0.0
    _shop_route_high_markup_add = 0.0
    _shop_route_exchange_gold_add = 0

    var profile_var: Variant = _shop_route_overrides.get(style_id, {})
    if not (profile_var is Dictionary):
        return
    var profile: Dictionary = profile_var

    _shop_route_price_mult = clampf(float(profile.get("price_mult", 1.0)), 0.7, 1.5)
    _shop_route_target_mult = clampf(float(profile.get("target_gold_mult", 1.0)), 0.6, 1.8)
    _shop_route_max_discount_add = clampf(float(profile.get("max_discount_add", 0.0)), -0.35, 0.35)
    _shop_route_high_markup_add = clampf(float(profile.get("high_markup_add", 0.0)), -0.25, 0.35)
    _shop_route_exchange_gold_add = clampi(int(profile.get("exchange_gold_add", 0)), -15, 25)

    var quality_mult_var: Variant = profile.get("quality_weight_mult", {})
    if quality_mult_var is Dictionary:
        var quality_mult: Dictionary = quality_mult_var
        for key in _shop_quality_weights.keys():
            var base_weight: float = maxf(0.0, float(_shop_quality_weights.get(key, 0.0)))
            var mult: float = clampf(float(quality_mult.get(key, 1.0)), 0.0, 3.0)
            _shop_quality_weights[key] = base_weight * mult

    var category_mult_var: Variant = profile.get("category_weight_mult", {})
    if category_mult_var is Dictionary:
        var category_mult: Dictionary = category_mult_var
        for key in _shop_category_weights.keys():
            var base_weight: float = maxf(0.0, float(_shop_category_weights.get(key, 0.0)))
            var mult: float = clampf(float(category_mult.get(key, 1.0)), 0.0, 3.0)
            _shop_category_weights[key] = base_weight * mult


func _get_route_style_label(style_id: String = "") -> String:
    var resolved: String = style_id
    if resolved == "":
        resolved = _current_route_style
    match resolved:
        "vanguard":
            return "VANGUARD"
        "raider":
            return "RAIDER"
        _:
            return "NEUTRAL"


func _get_chapter_id_for_room(index: int) -> String:
    var room_plan: Dictionary = _get_room_plan(index)
    if not room_plan.is_empty():
        var chapter_id: String = str(room_plan.get("chapter_id", "")).strip_edges()
        if chapter_id != "":
            return chapter_id
    return "chapter_%d" % (1 + int((index - 1) / 4))


func _get_chapter_index_for_room(index: int) -> int:
    var room_plan: Dictionary = _get_room_plan(index)
    if not room_plan.is_empty():
        return maxi(1, int(room_plan.get("chapter_index", 1)))
    return 1 + int((index - 1) / 4)


func _get_transition_segment_id(chapter_id: String) -> String:
    match chapter_id:
        "chapter_1":
            return "nar_ch1_end"
        "chapter_2":
            return "nar_ch2_end"
        "chapter_3":
            return "nar_ch3_end"
        _:
            return "nar_unknown_transition"


func _apply_meta_upgrades() -> void:
    var levels: Dictionary = SaveManager.get_upgrade_levels()
    if levels.is_empty():
        return

    var config: Dictionary = ConfigManager.get_config("meta_upgrades", {})
    var rows_var: Variant = config.get("upgrades", [])
    if not (rows_var is Array):
        return

    var stats: Node = _player.get_node_or_null("StatsComponent")
    var health: Node = _player.get_node_or_null("HealthComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")

    for item: Variant in rows_var:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var upgrade_id: String = str(row.get("id", ""))
        var level: int = int(levels.get(upgrade_id, 0))
        if level <= 0:
            continue

        var effect: String = str(row.get("effect", ""))
        var value_per_level: float = float(row.get("value_per_level", 0.0))
        var total_value: float = value_per_level * level

        match effect:
            "max_hp":
                if health != null and health.get("max_hp") != null:
                    health.max_hp += total_value
                    health.current_hp = health.max_hp
            "damage_bonus_pct":
                if stats != null and stats.get("damage_bonus_pct") != null:
                    stats.damage_bonus_pct += total_value
            "move_speed":
                if stats != null and stats.get("base_move_speed") != null:
                    stats.base_move_speed += total_value
            "crit_chance":
                if stats != null and stats.get("crit_chance") != null:
                    stats.crit_chance = minf(0.95, stats.crit_chance + total_value)
            "stamina_max":
                if stats != null and stats.get("stamina_max") != null:
                    stats.stamina_max += total_value
                    stats.current_stamina = stats.stamina_max
            "weapon_damage_flat":
                if weapon != null and weapon.get("base_damage") != null:
                    weapon.base_damage += total_value
            "armor":
                if stats != null and stats.get("armor") != null:
                    stats.armor = minf(0.75, stats.armor + total_value)
            "frostbite_resistance":
                if stats != null and stats.get("frostbite_resistance") != null:
                    stats.frostbite_resistance = minf(0.75, stats.frostbite_resistance + total_value)
            "void_resistance":
                if stats != null and stats.get("void_resistance") != null:
                    stats.void_resistance = minf(0.75, stats.void_resistance + total_value)

    if health != null and health.get("current_hp") != null and health.get("max_hp") != null:
        EventBus.health_changed.emit(float(health.current_hp), float(health.max_hp))
    if stats != null and stats.get("current_stamina") != null and stats.get("stamina_max") != null:
        EventBus.stamina_changed.emit(float(stats.current_stamina), float(stats.stamina_max))


func _apply_selected_character_profile() -> void:
    var config: Dictionary = ConfigManager.get_config("characters", {})
    var rows_var: Variant = config.get("characters", [])
    if not (rows_var is Array):
        return

    var rows: Array = rows_var
    if rows.is_empty():
        return

    var default_character_id: String = str(config.get("default_character_id", "char_knight"))
    var selected_id: String = str(GameManager.selected_character_id)
    if selected_id == "" and SaveManager != null and SaveManager.has_method("get_selected_character_id"):
        selected_id = SaveManager.get_selected_character_id()
    if selected_id == "":
        selected_id = default_character_id

    var selected_candidate: Dictionary = {}
    var default_candidate: Dictionary = {}
    var selected_row: Dictionary = {}
    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var row_id: String = str(row.get("id", ""))
        if row_id == selected_id:
            selected_candidate = row
        if row_id == default_character_id:
            default_candidate = row

    if not selected_candidate.is_empty() and _is_character_row_unlocked_runtime(selected_candidate):
        selected_row = selected_candidate
    elif not default_candidate.is_empty() and _is_character_row_unlocked_runtime(default_candidate):
        selected_row = default_candidate
    else:
        for item: Variant in rows:
            if item is Dictionary:
                var unlocked_row: Dictionary = item
                if _is_character_row_unlocked_runtime(unlocked_row):
                    selected_row = unlocked_row
                    break

    if selected_row.is_empty() and rows[0] is Dictionary:
        selected_row = rows[0]
    if selected_row.is_empty():
        return

    selected_id = str(selected_row.get("id", selected_id))
    GameManager.selected_character_id = selected_id
    if SaveManager != null and SaveManager.has_method("set_selected_character_id"):
        SaveManager.set_selected_character_id(selected_id)

    var stats: Node = _player.get_node_or_null("StatsComponent")
    var health: Node = _player.get_node_or_null("HealthComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")

    if health != null:
        if health.get("max_hp") != null:
            health.max_hp = float(selected_row.get("max_hp", health.max_hp))
        if health.get("current_hp") != null:
            health.current_hp = health.max_hp

    if stats != null:
        if stats.get("base_move_speed") != null:
            stats.base_move_speed = float(selected_row.get("move_speed", stats.base_move_speed))
        if stats.get("stamina_max") != null:
            stats.stamina_max = float(selected_row.get("stamina_max", stats.stamina_max))
        if stats.get("current_stamina") != null:
            stats.current_stamina = stats.stamina_max
        if stats.get("armor") != null:
            stats.armor = clampf(float(selected_row.get("armor", stats.armor)), 0.0, 0.75)
        if stats.get("crit_chance") != null:
            stats.crit_chance = clampf(float(selected_row.get("crit_chance", stats.crit_chance)), 0.0, 0.95)
        if stats.get("crit_multiplier") != null:
            stats.crit_multiplier = maxf(1.1, float(selected_row.get("crit_multiplier", stats.crit_multiplier)))

    if weapon != null:
        var weapon_codex_id: String = ""
        var base_weapon_id: String = "wpn_magic_missile"
        if weapon.get("base_damage") != null:
            weapon.base_damage = float(selected_row.get("base_damage", weapon.base_damage))
        if weapon.get("attack_interval") != null:
            weapon.attack_interval = maxf(0.12, float(selected_row.get("attack_interval", weapon.attack_interval)))

        var weapon_profile_var: Variant = selected_row.get("weapon_profile", {})
        if weapon_profile_var is Dictionary:
            var weapon_profile: Dictionary = weapon_profile_var
            base_weapon_id = str(weapon_profile.get("weapon_id", base_weapon_id)).strip_edges()
            if weapon.get("weapon_mode") != null:
                weapon.weapon_mode = str(weapon_profile.get("mode", weapon.weapon_mode))
            if weapon.get("projectile_count") != null:
                weapon.projectile_count = clampi(int(weapon_profile.get("projectile_count", weapon.projectile_count)), 1, 7)
            if weapon.get("spread_angle_deg") != null:
                weapon.spread_angle_deg = clampf(float(weapon_profile.get("spread_angle_deg", weapon.spread_angle_deg)), 0.0, 45.0)
            if weapon.get("spread_jitter_deg") != null:
                weapon.spread_jitter_deg = clampf(float(weapon_profile.get("spread_jitter_deg", weapon.spread_jitter_deg)), 0.0, 15.0)
            if weapon.get("projectile_hits") != null:
                weapon.projectile_hits = clampi(int(weapon_profile.get("projectile_hits", weapon.projectile_hits)), 1, 8)
            if weapon.get("projectile_style") != null:
                weapon.projectile_style = str(weapon_profile.get("projectile_style", weapon.projectile_style))
            weapon_codex_id = str(weapon_profile.get("projectile_style", "")).strip_edges()

        if weapon.has_method("reset_weapon_state"):
            weapon.reset_weapon_state(base_weapon_id)

        if weapon_codex_id == "":
            weapon_codex_id = str(selected_row.get("id", "")).strip_edges()
        if weapon_codex_id != "" and not weapon_codex_id.begins_with("wpn_"):
            weapon_codex_id = "wpn_%s" % weapon_codex_id
        if weapon_codex_id != "" and SaveManager != null and SaveManager.has_method("unlock_codex_entry"):
            SaveManager.unlock_codex_entry("weapons", weapon_codex_id, "run_start", _get_chapter_id_for_room(_room_index))

    var trait_effects_var: Variant = selected_row.get("trait_effects", {})
    if trait_effects_var is Dictionary:
        var trait_effects: Dictionary = trait_effects_var
        if health != null:
            if health.get("max_hp") != null:
                health.max_hp += float(trait_effects.get("max_hp_bonus", 0.0))
            if health.get("current_hp") != null:
                health.current_hp = health.max_hp

        if stats != null:
            if stats.get("base_move_speed") != null:
                stats.base_move_speed *= maxf(0.1, float(trait_effects.get("move_speed_mult", 1.0)))
            if stats.get("armor") != null:
                stats.armor = clampf(stats.armor + float(trait_effects.get("armor_bonus", 0.0)), 0.0, 0.75)
            if stats.get("damage_bonus_pct") != null:
                stats.damage_bonus_pct += float(trait_effects.get("damage_bonus_pct", 0.0))
            if stats.get("crit_chance") != null:
                stats.crit_chance = clampf(stats.crit_chance + float(trait_effects.get("crit_chance_bonus", 0.0)), 0.0, 0.95)
            if stats.get("crit_multiplier") != null:
                stats.crit_multiplier = maxf(1.1, stats.crit_multiplier + float(trait_effects.get("crit_multiplier_bonus", 0.0)))
            if stats.get("frostbite_resistance") != null:
                stats.frostbite_resistance = clampf(stats.frostbite_resistance + float(trait_effects.get("frostbite_resistance_bonus", 0.0)), 0.0, 0.75)
            if stats.get("void_resistance") != null:
                stats.void_resistance = clampf(stats.void_resistance + float(trait_effects.get("void_resistance_bonus", 0.0)), 0.0, 0.75)

        if weapon != null:
            if weapon.get("base_damage") != null:
                weapon.base_damage += float(trait_effects.get("weapon_damage_flat", 0.0))
            if weapon.get("attack_interval") != null:
                weapon.attack_interval = maxf(0.12, weapon.attack_interval * maxf(0.1, float(trait_effects.get("attack_interval_mult", 1.0))))

    if health != null and health.get("current_hp") != null and health.get("max_hp") != null:
        EventBus.health_changed.emit(float(health.current_hp), float(health.max_hp))
    if stats != null and stats.get("current_stamina") != null and stats.get("stamina_max") != null:
        EventBus.stamina_changed.emit(float(stats.current_stamina), float(stats.stamina_max))


func _is_character_row_unlocked_runtime(row: Dictionary) -> bool:
    var unlock_type: String = str(row.get("unlock_type", "default"))
    var unlock_value: String = str(row.get("unlock_value", ""))
    match unlock_type:
        "default":
            return true
        "achievement":
            return SaveManager.get_unlocked_achievements().has(unlock_value)
        "ending":
            return SaveManager.get_unlocked_endings().has(unlock_value)
        "meta_runs":
            return int(SaveManager.get_meta_data().get("total_runs", 0)) >= int(unlock_value)
        _:
            return true


func _resolve_room_type(index: int) -> String:
    var room_plan: Dictionary = _get_room_plan(index)
    if not room_plan.is_empty():
        var room_type: String = str(room_plan.get("room_type", ROOM_TYPE_COMBAT))
        match room_type:
            ROOM_TYPE_COMBAT, ROOM_TYPE_ELITE, ROOM_TYPE_BOSS, ROOM_TYPE_EVENT, ROOM_TYPE_SHOP, ROOM_TYPE_TREASURE, ROOM_TYPE_SAFE_CAMP:
                return room_type

    if index == 4 or index == 8 or index == 12 or index == 15:
        return ROOM_TYPE_BOSS
    if index > 1 and index % 5 == 0:
        return ROOM_TYPE_SAFE_CAMP
    if index > 1 and index % 7 == 0:
        return ROOM_TYPE_EVENT
    if index > 1 and index % 3 == 0:
        return ROOM_TYPE_SHOP
    return ROOM_TYPE_COMBAT


func _get_boss_id_for_room(index: int) -> String:
    var room_plan: Dictionary = _get_room_plan(index)
    if not room_plan.is_empty():
        var boss_id: String = str(room_plan.get("boss_id", "")).strip_edges()
        if boss_id != "":
            return boss_id

    match index:
        4:
            return "boss_rock_colossus"
        8:
            return "boss_flame_lord"
        12:
            return "boss_frost_king"
        15:
            return "boss_void_lord"
        _:
            return "boss_unknown"


func _get_boss_title(boss_id: String) -> String:
    match boss_id:
        "boss_rock_colossus":
            return "Rock Colossus"
        "boss_flame_lord":
            return "Flame Lord"
        "boss_frost_king":
            return "Frost King"
        "boss_void_lord":
            return "Void Lord"
        _:
            return boss_id


func _set_doors_locked(locked: bool) -> void:
    if _left_door == null or _right_door == null:
        return

    if locked:
        _left_door.color = Color(0.88, 0.22, 0.22, 1.0)
        _right_door.color = Color(0.88, 0.22, 0.22, 1.0)
        _left_door.position.x = 420.0
        _right_door.position.x = 860.0
    else:
        _left_door.color = Color(0.26, 0.76, 0.32, 1.0)
        _right_door.color = Color(0.26, 0.76, 0.32, 1.0)
        _left_door.position.x = 170.0
        _right_door.position.x = 1110.0

    _render_door_tiles(locked)


func _build_shop_offers() -> Array[Dictionary]:
    var offers: Array[Dictionary] = []
    var config: Dictionary = ConfigManager.get_config("shop_items", {})
    var slots: int = int(config.get("slots", 4))
    var pools: Dictionary = _shop_pools
    var quality_weights: Dictionary = _shop_quality_weights
    var category_weights: Dictionary = _shop_category_weights
    var economy_factor: float = _compute_shop_economy_factor()
    _shop_last_economy_factor = economy_factor

    for _i in range(slots):
        var category: String = _pick_shop_category(pools, category_weights)
        var item_id: String = _pick_shop_item_id(pools, category)
        var quality: String = _roll_quality(quality_weights)
        var offer: Dictionary = _build_shop_offer(item_id, category, quality, economy_factor)
        offers.append(offer)

    return offers


func _pick_shop_category(pools: Dictionary, category_weights: Dictionary) -> String:
    var keys: Array = pools.keys()
    if keys.is_empty():
        return "consumable"

    var total: float = 0.0
    var weighted: Dictionary = {}
    for key_var in keys:
        var key: String = str(key_var)
        var rows_var: Variant = pools.get(key, [])
        if not (rows_var is Array) or (rows_var as Array).is_empty():
            continue
        var weight: float = maxf(0.0, float(category_weights.get(key, 1.0)))
        if weight <= 0.0:
            continue
        weighted[key] = weight
        total += weight

    if total <= 0.0 or weighted.is_empty():
        return str(keys[randi_range(0, keys.size() - 1)])

    var roll: float = randf() * total
    var cursor: float = 0.0
    for key in weighted.keys():
        cursor += float(weighted.get(key, 0.0))
        if roll <= cursor:
            return str(key)

    return str(weighted.keys()[weighted.keys().size() - 1])


func _pick_shop_item_id(pools: Dictionary, category: String) -> String:
    var candidates_var: Variant = pools.get(category, [])
    if candidates_var is Array and not (candidates_var as Array).is_empty():
        var candidates: Array = candidates_var
        return str(candidates[randi_range(0, candidates.size() - 1)])

    return "hp_potion"


func _roll_quality(quality_weights: Dictionary) -> String:
    if quality_weights.is_empty():
        return "common"

    var total: float = 0.0
    for key: Variant in quality_weights.keys():
        total += maxf(0.0, float(quality_weights.get(key, 0.0)))

    if total <= 0.0:
        return "common"

    var roll: float = randf() * total
    var cursor: float = 0.0
    for key: Variant in quality_weights.keys():
        cursor += maxf(0.0, float(quality_weights.get(key, 0.0)))
        if roll <= cursor:
            return str(key)

    return "common"


func _build_shop_offer(item_id: String, category: String, quality: String, economy_factor: float = 1.0) -> Dictionary:
    var quality_mult: float = _get_quality_price_mult(quality)
    var base_price: int = 20

    match category:
        "consumable":
            base_price = 16
        "passive":
            base_price = 34
        "weapon":
            base_price = 46

    var floor_mult: float = 1.0 + float(maxi(0, _room_index - 1)) * 0.08
    var price: int = int(round(base_price * quality_mult * floor_mult * economy_factor * _shop_chapter_price_mult * _shop_route_price_mult))
    var info: Dictionary = _get_shop_item_info(item_id)

    return {
        "id": item_id,
        "category": category,
        "quality": quality,
        "price": max(6, price),
        "title": str(info.get("title", item_id)),
        "desc": str(info.get("desc", "")),
        "sold": false
    }


func _get_quality_price_mult(quality: String) -> float:
    match quality:
        "rare":
            return 1.4
        "epic":
            return 2.0
        "legendary":
            return 3.2
        _:
            return 1.0


func _get_shop_item_info(item_id: String) -> Dictionary:
    match item_id:
        "hp_potion":
            return {"title": "HP Potion", "desc": "Heal 35 HP"}
        "stamina_tonic":
            return {"title": "Stamina Tonic", "desc": "Restore 60 stamina"}
        "pas_might":
            return {"title": "Might Sigil", "desc": "+15% damage"}
        "pas_armor":
            return {"title": "Armor Plate", "desc": "+8% armor (cap 75%)"}
        "pas_focus":
            return {"title": "Focus Sigil", "desc": "-8% weapon interval"}
        "pas_precision":
            return {"title": "Precision Lens", "desc": "+5% crit chance"}
        "pas_force":
            return {"title": "Force Relic", "desc": "+16% crit multiplier"}
        "pas_fortune":
            return {"title": "Fortune Sigil", "desc": "+22 gold and better route readiness"}
        "pas_resolve":
            return {"title": "Resolve Plate", "desc": "+5% armor and +12 stamina max"}
        "pas_momentum":
            return {"title": "Momentum Circuit", "desc": "+14 move speed and faster weapon cycle"}
        "pas_overcharge":
            return {"title": "Overcharge Sigil", "desc": "+10% damage and +3% crit chance"}
        "pas_bastion":
            return {"title": "Bastion Crest", "desc": "+18 max HP and +4% armor"}
        "pas_siphon":
            return {"title": "Siphon Rune", "desc": "+8% damage and recover 14 stamina"}
        "pas_zeal":
            return {"title": "Zeal Sigil", "desc": "+9% damage and +12% crit multiplier"}
        "pas_warding":
            return {"title": "Warding Seal", "desc": "+14 max HP and +3% armor"}
        "pas_harvest":
            return {"title": "Harvest Glyph", "desc": "+18 gold and +8 stamina restore"}
        "wpn_magic_missile":
            return {"title": "Missile Core", "desc": "+4 weapon damage"}
        "wpn_holy_cross":
            return {"title": "Holy Crest", "desc": "+5.5 damage, +3% crit"}
        "wpn_arcane_comet":
            return {"title": "Arcane Comet", "desc": "+5 damage, spread pattern boost"}
        "wpn_holy_judgment":
            return {"title": "Holy Judgment", "desc": "+6.5 damage and +1 projectile hit"}
        "wpn_shadow_tempest":
            return {"title": "Shadow Tempest", "desc": "Faster attacks and wider volley"}
        "wpn_solar_supernova":
            return {"title": "Solar Supernova", "desc": "+8 damage and +2 projectile hits"}
        "wpn_sacred_lance":
            return {"title": "Sacred Lance", "desc": "+6 damage, +1 hit, focused single lance"}
        "wpn_void_chain":
            return {"title": "Void Chain", "desc": "+5 damage, chained spread volley"}
        "wpn_frost_orb":
            return {"title": "Frost Orb", "desc": "+4.5 damage, +1 hit, faster cadence"}
        "wpn_storm_bow":
            return {"title": "Storm Bow", "desc": "+4.8 damage and wider arrow volley"}
        "wpn_radiant_hammer":
            return {"title": "Radiant Hammer", "desc": "+6.8 damage, +2 hits, focused impact"}
        "wpn_blood_rite":
            return {"title": "Blood Rite", "desc": "+5.8 damage and chained spread ritual"}
        "wpn_vowblade":
            return {"title": "Vowblade", "desc": "+6.2 damage, focused strike, +1 hit"}
        "wpn_nether_shard":
            return {"title": "Nether Shard", "desc": "+5.4 damage and unstable void spread"}
        "wpn_astral_disc":
            return {"title": "Astral Disc", "desc": "+5.0 damage, faster cycle, +1 hit"}
        _:
            return {"title": item_id, "desc": "Unknown effect"}


func _try_buy_shop_slot(slot_index: int) -> void:
    if slot_index < 0 or slot_index >= _shop_offers.size():
        return

    var offer: Dictionary = _shop_offers[slot_index]
    if bool(offer.get("sold", false)):
        _shop_message = "Slot %d already sold" % (slot_index + 1)
        _update_shop_text()
        return

    var price: int = int(offer.get("price", 0))
    if _gold < price:
        _shop_message = "Not enough gold (%d/%d)" % [_gold, price]
        _update_shop_text()
        return

    _gold -= price
    EventBus.gold_changed.emit(_gold)
    _apply_shop_item_effect(str(offer.get("id", "")))

    offer["sold"] = true
    _shop_offers[slot_index] = offer
    _shop_message = "Bought %s" % str(offer.get("title", "item"))
    _update_shop_text()


func _try_restock_shop() -> void:
    if _gold < _shop_restock_cost:
        _shop_message = "Need %d gold to restock" % _shop_restock_cost
        _update_shop_text()
        return

    _gold -= _shop_restock_cost
    EventBus.gold_changed.emit(_gold)
    _shop_restock_count += 1
    _shop_offers = _build_shop_offers()
    _shop_message = "Restocked for %d gold" % _shop_restock_cost
    _recompute_restock_cost()
    _update_shop_text()


func _try_exchange_ore_for_gold() -> void:
    if not _shop_ore_exchange_enabled:
        _shop_message = "Ore exchange unavailable"
        _update_shop_text()
        return

    if _shop_ore_exchange_count >= _shop_ore_exchange_max_trades:
        _shop_message = "Ore exchange cap reached"
        _update_shop_text()
        return

    if _ore < _shop_ore_exchange_ore_cost:
        _shop_message = "Need %d ore for exchange" % _shop_ore_exchange_ore_cost
        _update_shop_text()
        return

    _ore -= _shop_ore_exchange_ore_cost
    var gold_gain: int = _shop_ore_exchange_gold_gain + _shop_route_exchange_gold_add
    gold_gain = maxi(1, gold_gain)
    if randf() <= _shop_ore_exchange_bonus_chance:
        gold_gain += _shop_ore_exchange_bonus_gold
    _gold += gold_gain
    _shop_ore_exchange_count += 1
    EventBus.ore_changed.emit(_ore)
    EventBus.gold_changed.emit(_gold)

    _shop_message = "Exchanged %d ore -> +%d gold (%d/%d)" % [
        _shop_ore_exchange_ore_cost,
        gold_gain,
        _shop_ore_exchange_count,
        _shop_ore_exchange_max_trades
    ]
    _update_shop_text()


func _apply_shop_item_effect(item_id: String) -> void:
    var stats: Node = _player.get_node_or_null("StatsComponent")
    var health: Node = _player.get_node_or_null("HealthComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")

    match item_id:
        "hp_potion":
            if health != null and health.has_method("heal"):
                health.heal(35.0)
        "stamina_tonic":
            if stats != null and stats.get("stamina_max") != null:
                stats.current_stamina = minf(stats.stamina_max, stats.current_stamina + 60.0)
        "pas_might":
            if stats != null and stats.get("damage_bonus_pct") != null:
                stats.damage_bonus_pct += 0.15
        "pas_armor":
            if stats != null and stats.get("armor") != null:
                stats.armor = minf(0.75, stats.armor + 0.08)
        "pas_focus":
            if weapon != null and weapon.get("attack_interval") != null:
                weapon.attack_interval = maxf(0.12, weapon.attack_interval * 0.92)
        "pas_precision":
            if stats != null and stats.get("crit_chance") != null:
                stats.crit_chance = minf(0.95, stats.crit_chance + 0.05)
        "pas_force":
            if stats != null and stats.get("crit_multiplier") != null:
                stats.crit_multiplier += 0.16
        "pas_fortune":
            _gold += 22
            EventBus.gold_changed.emit(_gold)
        "pas_resolve":
            if stats != null:
                if stats.get("armor") != null:
                    stats.armor = minf(0.75, float(stats.armor) + 0.05)
                if stats.get("stamina_max") != null and stats.get("current_stamina") != null:
                    stats.stamina_max += 12.0
                    stats.current_stamina = minf(stats.stamina_max, stats.current_stamina + 12.0)
        "pas_momentum":
            if stats != null and stats.get("base_move_speed") != null:
                stats.base_move_speed += 14.0
            if weapon != null and weapon.get("attack_interval") != null:
                weapon.attack_interval = maxf(0.08, float(weapon.attack_interval) * 0.95)
        "pas_overcharge":
            if stats != null:
                if stats.get("damage_bonus_pct") != null:
                    stats.damage_bonus_pct += 0.10
                if stats.get("crit_chance") != null:
                    stats.crit_chance = minf(0.95, float(stats.crit_chance) + 0.03)
        "pas_bastion":
            if health != null and health.get("max_hp") != null:
                health.max_hp += 18.0
            if stats != null and stats.get("armor") != null:
                stats.armor = minf(0.75, float(stats.armor) + 0.04)
        "pas_siphon":
            if stats != null:
                if stats.get("damage_bonus_pct") != null:
                    stats.damage_bonus_pct += 0.08
                if stats.get("stamina_max") != null and stats.get("current_stamina") != null:
                    stats.current_stamina = minf(float(stats.stamina_max), float(stats.current_stamina) + 14.0)
        "pas_zeal":
            if stats != null:
                if stats.get("damage_bonus_pct") != null:
                    stats.damage_bonus_pct += 0.09
                if stats.get("crit_multiplier") != null:
                    stats.crit_multiplier += 0.12
        "pas_warding":
            if health != null and health.get("max_hp") != null:
                health.max_hp += 14.0
            if stats != null and stats.get("armor") != null:
                stats.armor = minf(0.75, float(stats.armor) + 0.03)
        "pas_harvest":
            _gold += 18
            EventBus.gold_changed.emit(_gold)
            if stats != null and stats.get("stamina_max") != null and stats.get("current_stamina") != null:
                stats.current_stamina = minf(float(stats.stamina_max), float(stats.current_stamina) + 8.0)
        "wpn_magic_missile":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage += 4.0
        "wpn_holy_cross":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage += 5.5
            if stats != null and stats.get("crit_chance") != null:
                stats.crit_chance = minf(0.95, stats.crit_chance + 0.03)
        "wpn_arcane_comet":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 5.0
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(maxi(int(weapon.projectile_count), 3), 1, 7)
                if weapon.get("spread_angle_deg") != null:
                    weapon.spread_angle_deg = clampf(maxf(float(weapon.spread_angle_deg), 14.0), 0.0, 45.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "arcane_comet"
        "wpn_holy_judgment":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 6.5
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 1, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "holy_judgment"
            if stats != null and stats.get("crit_chance") != null:
                stats.crit_chance = minf(0.95, stats.crit_chance + 0.02)
        "wpn_shadow_tempest":
            if weapon != null:
                if weapon.get("attack_interval") != null:
                    weapon.attack_interval = maxf(0.1, weapon.attack_interval * 0.9)
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(int(weapon.projectile_count) + 1, 1, 7)
                if weapon.get("spread_jitter_deg") != null:
                    weapon.spread_jitter_deg = clampf(float(weapon.spread_jitter_deg) + 2.0, 0.0, 15.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "shadow_tempest"
        "wpn_solar_supernova":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 8.0
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 2, 1, 12)
                if weapon.get("spread_angle_deg") != null:
                    weapon.spread_angle_deg = clampf(float(weapon.spread_angle_deg) + 6.0, 0.0, 45.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "solar_supernova"
        "wpn_sacred_lance":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 6.0
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "single"
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 1, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "sacred_lance"
        "wpn_void_chain":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 5.0
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(maxi(int(weapon.projectile_count), 2) + 1, 1, 8)
                if weapon.get("spread_jitter_deg") != null:
                    weapon.spread_jitter_deg = clampf(float(weapon.spread_jitter_deg) + 3.0, 0.0, 20.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "void_chain"
        "wpn_frost_orb":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 4.5
                if weapon.get("attack_interval") != null:
                    weapon.attack_interval = maxf(0.08, float(weapon.attack_interval) * 0.94)
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 1, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "frost_orb"
        "wpn_storm_bow":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 4.8
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(maxi(int(weapon.projectile_count), 3) + 1, 1, 8)
                if weapon.get("spread_angle_deg") != null:
                    weapon.spread_angle_deg = clampf(float(weapon.spread_angle_deg) + 5.0, 0.0, 45.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "storm_bow"
        "wpn_radiant_hammer":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 6.8
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "single"
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 2, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "radiant_hammer"
        "wpn_blood_rite":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 5.8
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(maxi(int(weapon.projectile_count), 2) + 1, 1, 8)
                if weapon.get("spread_jitter_deg") != null:
                    weapon.spread_jitter_deg = clampf(float(weapon.spread_jitter_deg) + 2.0, 0.0, 20.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "blood_rite"
        "wpn_vowblade":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 6.2
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "single"
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 1, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "vowblade"
        "wpn_nether_shard":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 5.4
                if weapon.get("weapon_mode") != null:
                    weapon.weapon_mode = "spread"
                if weapon.get("projectile_count") != null:
                    weapon.projectile_count = clampi(maxi(int(weapon.projectile_count), 3) + 1, 1, 8)
                if weapon.get("spread_jitter_deg") != null:
                    weapon.spread_jitter_deg = clampf(float(weapon.spread_jitter_deg) + 2.5, 0.0, 20.0)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "nether_shard"
        "wpn_astral_disc":
            if weapon != null:
                if weapon.get("base_damage") != null:
                    weapon.base_damage += 5.0
                if weapon.get("attack_interval") != null:
                    weapon.attack_interval = maxf(0.08, float(weapon.attack_interval) * 0.93)
                if weapon.get("projectile_hits") != null:
                    weapon.projectile_hits = clampi(int(weapon.projectile_hits) + 1, 1, 12)
                if weapon.get("projectile_style") != null:
                    weapon.projectile_style = "astral_disc"


func _update_shop_text() -> void:
    var lines: Array[String] = []
    lines.append("Shop Room %d | Gold: %d" % [_room_index, _gold])

    for i in range(_shop_offers.size()):
        var offer: Dictionary = _shop_offers[i]
        var sold_tag: String = ""
        if bool(offer.get("sold", false)):
            sold_tag = " [SOLD]"
        lines.append("%d) [%s] %s - %dG%s" % [
            i + 1,
            str(offer.get("quality", "common")).to_upper(),
            str(offer.get("title", "Item")),
            int(offer.get("price", 0)),
            sold_tag
        ])

    lines.append("R: Restock (%dG)" % _shop_restock_cost)
    if _shop_ore_exchange_enabled:
        lines.append("T: Exchange %d ore -> %dG (%d/%d)" % [
            _shop_ore_exchange_ore_cost,
            _shop_ore_exchange_gold_gain,
            _shop_ore_exchange_count,
            _shop_ore_exchange_max_trades
        ])

    if _shop_last_economy_factor < 0.995:
        lines.append("Economy Assist: -%d%% prices" % int(round((1.0 - _shop_last_economy_factor) * 100.0)))
    elif _shop_last_economy_factor > 1.005:
        lines.append("Economy Pressure: +%d%% prices" % int(round((_shop_last_economy_factor - 1.0) * 100.0)))
    else:
        lines.append("Economy: standard pricing")

    lines.append("Chapter profile: %s (price x%.2f, restock %dG)" % [
        _shop_chapter_id,
        _shop_chapter_price_mult,
        _shop_restock_base_cost
    ])
    lines.append("Route style: %s (price x%.2f, exchange %+dG)" % [
        _get_route_style_label(),
        _shop_route_price_mult,
        _shop_route_exchange_gold_add
    ])
    lines.append("Shop bias: %s" % _get_shop_bias_text())

    lines.append("Chapter hazards ahead: %s" % get_active_hazards_text())
    lines.append(_get_next_route_hint_text())
    lines.append("Active chapter effects: %s" % _get_active_chapter_effects_text())
    if _shop_message != "":
        lines.append(_shop_message)

    _room_status_label.text = "\n".join(PackedStringArray(lines))


func _load_treasure_challenge_config() -> void:
    _treasure_challenge_enabled = false
    _treasure_challenge_combat_mode = "elite"
    _treasure_required_kills_base = 4
    _treasure_required_kills_per_room = 1
    _treasure_gold_reward_base = 32
    _treasure_gold_reward_per_room = 2
    _treasure_ore_reward_base = 1
    _treasure_ore_reward_step_rooms = 5
    _treasure_accessory_chance_base = 0.28
    _treasure_accessory_chance_vanguard = 0.34
    _treasure_accessory_chance_raider = 0.24

    var map_config: Dictionary = ConfigManager.get_config("map_generation", {})
    var treasure_var: Variant = map_config.get("treasure_challenge", {})
    if not (treasure_var is Dictionary):
        return

    var treasure_cfg: Dictionary = treasure_var
    _treasure_challenge_enabled = bool(treasure_cfg.get("enabled", false))
    var combat_mode: String = str(treasure_cfg.get("combat_mode", "elite")).strip_edges()
    if combat_mode != "elite" and combat_mode != "normal":
        combat_mode = "elite"
    _treasure_challenge_combat_mode = combat_mode
    _treasure_required_kills_base = maxi(1, int(treasure_cfg.get("required_kills_base", 4)))
    _treasure_required_kills_per_room = maxi(0, int(treasure_cfg.get("required_kills_per_room", 1)))
    _treasure_gold_reward_base = maxi(1, int(treasure_cfg.get("gold_reward_base", 32)))
    _treasure_gold_reward_per_room = maxi(0, int(treasure_cfg.get("gold_reward_per_room", 2)))
    _treasure_ore_reward_base = maxi(1, int(treasure_cfg.get("ore_reward_base", 1)))
    _treasure_ore_reward_step_rooms = maxi(1, int(treasure_cfg.get("ore_reward_step_rooms", 5)))
    _treasure_accessory_chance_base = clampf(float(treasure_cfg.get("accessory_chance_base", 0.28)), 0.0, 1.0)
    _treasure_accessory_chance_vanguard = clampf(float(treasure_cfg.get("accessory_chance_vanguard", 0.34)), 0.0, 1.0)
    _treasure_accessory_chance_raider = clampf(float(treasure_cfg.get("accessory_chance_raider", 0.24)), 0.0, 1.0)


func _load_shop_economy_config() -> void:
    var shop_config: Dictionary = ConfigManager.get_config("shop_items", {})
    var quality_var: Variant = shop_config.get("quality_weights", {})
    if quality_var is Dictionary:
        _shop_base_quality_weights = (quality_var as Dictionary).duplicate(true)
    else:
        _shop_base_quality_weights = {
            "common": 65.0,
            "rare": 25.0,
            "epic": 8.0,
            "legendary": 2.0
        }

    var category_var: Variant = shop_config.get("category_weights", {})
    if category_var is Dictionary:
        _shop_base_category_weights = (category_var as Dictionary).duplicate(true)
    else:
        _shop_base_category_weights = {
            "consumable": 1.0,
            "passive": 1.0,
            "weapon": 1.0
        }

    var pools_var: Variant = shop_config.get("pools", {})
    if pools_var is Dictionary:
        _shop_base_pools = (pools_var as Dictionary).duplicate(true)
    else:
        _shop_base_pools = {
            "consumable": ["hp_potion", "stamina_tonic"],
            "passive": ["pas_might", "pas_armor"],
            "weapon": ["wpn_magic_missile", "wpn_holy_cross"]
        }

    _shop_base_restock_cost = maxi(4, int(shop_config.get("restock_cost", 20)))
    _shop_base_restock_growth = clampf(float(shop_config.get("restock_growth", 0.35)), 0.0, 1.2)
    _shop_base_restock_cap = maxi(_shop_base_restock_cost, int(shop_config.get("restock_cost_cap", 180)))

    var catchup_var: Variant = shop_config.get("catchup_discount", {})
    if catchup_var is Dictionary:
        var catchup: Dictionary = catchup_var
        _shop_base_catchup_target_per_room = maxf(6.0, float(catchup.get("target_gold_per_room", 26.0)))
        _shop_base_catchup_max_discount = clampf(float(catchup.get("max_discount", 0.35)), 0.0, 0.75)
        _shop_base_catchup_high_gold_markup = clampf(float(catchup.get("high_gold_markup", 0.15)), 0.0, 0.45)
        _shop_base_catchup_high_gold_threshold_mult = maxf(1.0, float(catchup.get("high_gold_threshold_mult", 1.8)))

    var exchange_var: Variant = shop_config.get("ore_exchange", {})
    if exchange_var is Dictionary:
        var exchange: Dictionary = exchange_var
        _shop_base_ore_exchange_enabled = bool(exchange.get("enabled", true))
        _shop_base_ore_exchange_ore_cost = maxi(1, int(exchange.get("ore_per_trade", 2)))
        _shop_base_ore_exchange_gold_gain = maxi(1, int(exchange.get("gold_per_trade", 14)))
        _shop_base_ore_exchange_max_trades = maxi(1, int(exchange.get("max_trades_per_shop", 3)))
        _shop_base_ore_exchange_bonus_chance = clampf(float(exchange.get("bonus_trade_chance", 0.15)), 0.0, 1.0)
        _shop_base_ore_exchange_bonus_gold = maxi(0, int(exchange.get("bonus_gold", 4)))

    var chapter_overrides_var: Variant = shop_config.get("chapter_overrides", {})
    if chapter_overrides_var is Dictionary:
        _shop_chapter_overrides = (chapter_overrides_var as Dictionary).duplicate(true)
    else:
        _shop_chapter_overrides = {}

    var route_overrides_var: Variant = shop_config.get("route_style_overrides", {})
    if route_overrides_var is Dictionary:
        _shop_route_overrides = (route_overrides_var as Dictionary).duplicate(true)
    else:
        _shop_route_overrides = {}

    _apply_shop_chapter_profile("chapter_1")


func _apply_shop_chapter_profile(chapter_id: String) -> void:
    _shop_chapter_id = chapter_id
    _shop_chapter_price_mult = 1.0
    _shop_quality_weights = _shop_base_quality_weights.duplicate(true)
    _shop_category_weights = _shop_base_category_weights.duplicate(true)
    _shop_pools = _shop_base_pools.duplicate(true)

    _shop_restock_base_cost = _shop_base_restock_cost
    _shop_restock_growth = _shop_base_restock_growth
    _shop_restock_cap = _shop_base_restock_cap

    _shop_catchup_target_per_room = _shop_base_catchup_target_per_room
    _shop_catchup_max_discount = _shop_base_catchup_max_discount
    _shop_catchup_high_gold_markup = _shop_base_catchup_high_gold_markup
    _shop_catchup_high_gold_threshold_mult = _shop_base_catchup_high_gold_threshold_mult

    _shop_ore_exchange_enabled = _shop_base_ore_exchange_enabled
    _shop_ore_exchange_ore_cost = _shop_base_ore_exchange_ore_cost
    _shop_ore_exchange_gold_gain = _shop_base_ore_exchange_gold_gain
    _shop_ore_exchange_max_trades = _shop_base_ore_exchange_max_trades
    _shop_ore_exchange_bonus_chance = _shop_base_ore_exchange_bonus_chance
    _shop_ore_exchange_bonus_gold = _shop_base_ore_exchange_bonus_gold

    var profile_var: Variant = _shop_chapter_overrides.get(chapter_id, {})
    if profile_var is Dictionary:
        var profile: Dictionary = profile_var
        _shop_chapter_price_mult = clampf(float(profile.get("price_mult", 1.0)), 0.6, 1.6)

        var restock_cost_mult: float = clampf(float(profile.get("restock_cost_mult", 1.0)), 0.6, 1.9)
        var restock_growth_add: float = clampf(float(profile.get("restock_growth_add", 0.0)), -0.5, 0.8)
        var catchup_target_mult: float = clampf(float(profile.get("target_gold_mult", 1.0)), 0.5, 2.0)
        var max_discount_add: float = clampf(float(profile.get("max_discount_add", 0.0)), -0.4, 0.4)
        var high_markup_add: float = clampf(float(profile.get("high_markup_add", 0.0)), -0.3, 0.3)
        var exchange_gold_add: int = int(profile.get("ore_exchange_gold_add", 0))
        var exchange_trade_add: int = int(profile.get("ore_exchange_max_trades_add", 0))
        var exchange_bonus_chance_add: float = clampf(float(profile.get("ore_exchange_bonus_chance_add", 0.0)), -0.6, 0.6)
        var exchange_bonus_gold_add: int = int(profile.get("ore_exchange_bonus_gold_add", 0))

        var quality_mult_var: Variant = profile.get("quality_weight_mult", {})
        if quality_mult_var is Dictionary:
            var quality_mult: Dictionary = quality_mult_var
            for key in _shop_quality_weights.keys():
                var base_weight: float = maxf(0.0, float(_shop_quality_weights.get(key, 0.0)))
                var mult: float = clampf(float(quality_mult.get(key, 1.0)), 0.0, 3.5)
                _shop_quality_weights[key] = base_weight * mult

        var category_mult_var: Variant = profile.get("category_weight_mult", {})
        if category_mult_var is Dictionary:
            var category_mult: Dictionary = category_mult_var
            for key in _shop_category_weights.keys():
                var base_weight: float = maxf(0.0, float(_shop_category_weights.get(key, 0.0)))
                var mult: float = clampf(float(category_mult.get(key, 1.0)), 0.0, 3.0)
                _shop_category_weights[key] = base_weight * mult

        var pool_override_var: Variant = profile.get("pool_overrides", {})
        if pool_override_var is Dictionary:
            var pool_overrides: Dictionary = pool_override_var
            for category_var in pool_overrides.keys():
                var category: String = str(category_var)
                var list_var: Variant = pool_overrides.get(category, [])
                if list_var is Array and not (list_var as Array).is_empty():
                    _shop_pools[category] = (list_var as Array).duplicate(true)

        _shop_restock_base_cost = maxi(4, int(round(float(_shop_base_restock_cost) * restock_cost_mult)))
        _shop_restock_growth = clampf(_shop_base_restock_growth + restock_growth_add, 0.0, 1.2)
        _shop_restock_cap = maxi(_shop_restock_base_cost, int(round(float(_shop_base_restock_cap) * restock_cost_mult)))

        _shop_catchup_target_per_room = maxf(6.0, _shop_base_catchup_target_per_room * catchup_target_mult)
        _shop_catchup_max_discount = clampf(_shop_base_catchup_max_discount + max_discount_add, 0.0, 0.75)
        _shop_catchup_high_gold_markup = clampf(_shop_base_catchup_high_gold_markup + high_markup_add, 0.0, 0.45)

        _shop_ore_exchange_gold_gain = maxi(1, _shop_base_ore_exchange_gold_gain + exchange_gold_add)
        _shop_ore_exchange_max_trades = maxi(1, _shop_base_ore_exchange_max_trades + exchange_trade_add)
        _shop_ore_exchange_bonus_chance = clampf(_shop_base_ore_exchange_bonus_chance + exchange_bonus_chance_add, 0.0, 1.0)
        _shop_ore_exchange_bonus_gold = maxi(0, _shop_base_ore_exchange_bonus_gold + exchange_bonus_gold_add)

    _apply_shop_route_profile(_current_route_style)

    var quality_total: float = 0.0
    for key in _shop_quality_weights.keys():
        quality_total += maxf(0.0, float(_shop_quality_weights.get(key, 0.0)))
    if quality_total <= 0.0:
        _shop_quality_weights = _shop_base_quality_weights.duplicate(true)

    var category_total: float = 0.0
    for key in _shop_category_weights.keys():
        category_total += maxf(0.0, float(_shop_category_weights.get(key, 0.0)))
    if category_total <= 0.0:
        _shop_category_weights = _shop_base_category_weights.duplicate(true)

    _shop_restock_cost = _shop_restock_base_cost


func _get_shop_bias_text() -> String:
    var top_quality: String = "common"
    var top_quality_weight: float = -1.0
    for key_var in _shop_quality_weights.keys():
        var key: String = str(key_var)
        var weight: float = float(_shop_quality_weights.get(key, 0.0))
        if weight > top_quality_weight:
            top_quality_weight = weight
            top_quality = key

    var top_category: String = "consumable"
    var top_category_weight: float = -1.0
    for key_var in _shop_category_weights.keys():
        var key: String = str(key_var)
        var weight: float = float(_shop_category_weights.get(key, 0.0))
        if weight > top_category_weight:
            top_category_weight = weight
            top_category = key

    return "%s-heavy, %s quality focus" % [top_category, top_quality]


func _compute_shop_economy_factor() -> float:
    var target_gold: float = _shop_catchup_target_per_room * _shop_route_target_mult * float(maxi(1, _room_index))
    if target_gold <= 0.0:
        return 1.0

    var max_discount: float = clampf(_shop_catchup_max_discount + _shop_route_max_discount_add, 0.0, 0.75)
    var high_markup: float = clampf(_shop_catchup_high_gold_markup + _shop_route_high_markup_add, 0.0, 0.45)

    if float(_gold) < target_gold:
        var deficit_ratio: float = clampf((target_gold - float(_gold)) / target_gold, 0.0, 1.0)
        return clampf(1.0 - max_discount * deficit_ratio, 0.55, 1.35)

    var high_gold_threshold: float = target_gold * _shop_catchup_high_gold_threshold_mult
    if float(_gold) <= high_gold_threshold:
        return 1.0

    var over_ratio: float = clampf((float(_gold) - high_gold_threshold) / maxf(1.0, high_gold_threshold), 0.0, 1.0)
    return clampf(1.0 + high_markup * over_ratio, 0.70, 1.50)


func _recompute_restock_cost() -> void:
    var growth_factor: float = pow(1.0 + _shop_restock_growth, float(_shop_restock_count))
    var grown_cost: int = int(round(float(_shop_restock_base_cost) * growth_factor))
    _shop_restock_cost = mini(_shop_restock_cap, maxi(_shop_restock_base_cost, grown_cost))


func _try_forge_damage() -> void:
    if _ore < 3:
        _camp_message = "Need 3 ore for damage forge"
        _update_camp_text()
        return

    var weapon: Node = _player.get_node_or_null("AutoWeapon")
    if weapon != null and weapon.get("base_damage") != null:
        _ore -= 3
        EventBus.ore_changed.emit(_ore)
        weapon.base_damage *= 1.10
        _camp_message = "Forge complete: +10% weapon damage"
    else:
        _camp_message = "Forge failed: no weapon"

    _update_camp_text()


func _try_forge_speed() -> void:
    if _ore < 5:
        _camp_message = "Need 5 ore for speed forge"
        _update_camp_text()
        return

    var weapon: Node = _player.get_node_or_null("AutoWeapon")
    if weapon != null and weapon.get("attack_interval") != null:
        _ore -= 5
        EventBus.ore_changed.emit(_ore)
        weapon.attack_interval = maxf(0.12, weapon.attack_interval * 0.93)
        _camp_message = "Forge complete: faster attack interval"
    else:
        _camp_message = "Forge failed: no weapon"

    _update_camp_text()


func _try_route_choice(choice_id: String) -> void:
    if _camp_route_chosen:
        _camp_message = "Route already chosen in this camp"
        _update_camp_text()
        return

    var delta: float = 0.0
    if choice_id == "holy":
        delta = 12.0
    elif choice_id == "void":
        delta = -12.0

    _alignment = clampf(_alignment + delta, -100.0, 100.0)
    _camp_route_chosen = true
    EventBus.route_changed.emit(_alignment)

    var chapter_id: String = _get_chapter_id_for_room(_room_index)
    EventBus.narrative_choice.emit(chapter_id, "safe_camp_route", choice_id)

    _camp_message = "Route shifted: %s (%+.0f)" % [choice_id.to_upper(), delta]
    _update_camp_text()


func _open_memory_altar() -> void:
    if _current_room_type != ROOM_TYPE_SAFE_CAMP or _room_active:
        return
    if _memory_altar_panel == null or not _memory_altar_panel.has_method("show_archive"):
        return

    var unlocked_fragments: Array[String] = SaveManager.get_unlocked_fragments()
    _memory_altar_pending = true
    _memory_altar_panel.show_archive(unlocked_fragments, 0)
    _room_status_label.text = "Memory Altar opened (%d fragments). Review with 1/2, close with E/Esc" % unlocked_fragments.size()


func _on_memory_altar_closed() -> void:
    _memory_altar_pending = false
    if _current_room_type == ROOM_TYPE_SAFE_CAMP and not _room_active:
        _update_camp_text()


func _update_camp_text() -> void:
    var lines: Array[String] = []
    lines.append("Safe Camp %d | Ore: %d | Alignment: %.0f (%s)" % [
        _room_index,
        _ore,
        _alignment,
        _get_route_tier()
    ])
    lines.append("Branch style: %s" % _get_route_style_label())
    lines.append("Purification: Frostbite %.0f%% | Void %.0f%%" % [_frostbite, _void_corruption])
    lines.append("F: Forge Damage (3 ore) | G: Forge Speed (5 ore)")
    lines.append("T: Memory Altar (review unlocked fragments)")
    lines.append("Q: Choose Holy Route | V: Choose Void Route")
    lines.append("Chapter hazards ahead: %s" % get_active_hazards_text())
    lines.append("Active chapter effects: %s" % _get_active_chapter_effects_text())
    lines.append(_get_next_route_hint_text())
    if _camp_message != "":
        lines.append(_camp_message)

    _room_status_label.text = "\n".join(PackedStringArray(lines))


func _get_route_tier() -> String:
    if _alignment >= 60.0:
        return "REDEEM"
    if _alignment <= -60.0:
        return "FALL"
    return "BALANCE"


func _get_hazard_intensity() -> float:
    var base_intensity: float = 0.0
    if _current_room_type == ROOM_TYPE_BOSS:
        base_intensity = 1.35
    elif _current_room_type == ROOM_TYPE_ELITE:
        base_intensity = 1.15
    elif _current_room_type == ROOM_TYPE_COMBAT:
        base_intensity = 1.0
    elif _current_room_type == ROOM_TYPE_TREASURE and _treasure_challenge_enabled:
        base_intensity = 1.05
    return base_intensity * _chapter_effect_hazard_mult * _route_hazard_mult


func _get_resistance(stats: Node, property_name: String) -> float:
    if stats == null or stats.get(property_name) == null:
        return 0.0
    return clampf(float(stats.get(property_name)), 0.0, 0.75)


func _apply_room_theme(index: int) -> void:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    var palette_var: Variant = chapter_row.get("tile_palette", [])
    if not (palette_var is Array):
        _target_background_color = Color(0.10, 0.09, 0.13, 1.0)
        _render_ground_tiles_for_room(index)
        _render_ground_detail_tiles_for_room(index)
        return

    var palette: Array = palette_var
    if palette.is_empty():
        _target_background_color = Color(0.10, 0.09, 0.13, 1.0)
        _render_ground_tiles_for_room(index)
        _render_ground_detail_tiles_for_room(index)
        return

    _target_background_color = Color.html(str(palette[0]))
    _render_ground_tiles_for_room(index)
    _render_ground_detail_tiles_for_room(index)


func _initialize_tile_layers() -> void:
    _load_tileset_resources()

    if _ground_tilemap != null:
        var ground_tileset: TileSet = _get_ground_tileset_for_room(_room_index)
        if ground_tileset != null:
            _ground_tilemap.tile_set = ground_tileset
    if _ground_detail_tilemap != null:
        var ground_detail_tileset: TileSet = _get_ground_detail_tileset_for_room(_room_index)
        if ground_detail_tileset != null:
            _ground_detail_tilemap.tile_set = ground_detail_tileset
    if _door_tilemap != null:
        var door_tileset: TileSet = _get_door_tileset_for_room(_room_index)
        if door_tileset != null:
            _door_tilemap.tile_set = door_tileset
    if _hazard_tilemap != null:
        var hazard_tileset: TileSet = _get_hazard_tileset_for_room(_room_index)
        if hazard_tileset != null:
            _hazard_tilemap.tile_set = hazard_tileset
        _hazard_tilemap.modulate = Color(0.18, 0.34, 0.50, 0.0)
    if _ambient_fx_tilemap != null:
        var ambient_tileset: TileSet = _get_ambient_fx_tileset_for_room(_room_index)
        if ambient_tileset != null:
            _ambient_fx_tilemap.tile_set = ambient_tileset
        _ambient_fx_tilemap.modulate = Color(0.82, 0.88, 0.95, 0.0)
        _ambient_fx_tilemap.position = Vector2.ZERO
    _ambient_fx_scroll_offset = Vector2.ZERO
    _visual_profile_anim_time = 0.0
    _render_ground_tiles_for_room(_room_index)
    _render_ground_detail_tiles_for_room(_room_index)
    _render_door_tiles(false)
    _render_hazard_tiles()
    _render_ambient_fx_tiles()


func _load_tileset_resources() -> void:
    if _ground_tilesets.is_empty():
        for chapter_id_var: Variant in GROUND_TILESET_PATHS.keys():
            var chapter_id: String = str(chapter_id_var)
            var path: String = str(GROUND_TILESET_PATHS.get(chapter_id, ""))
            var tileset: TileSet = load(path)
            if tileset != null:
                _ground_tilesets[chapter_id] = tileset

    if _ground_detail_tilesets.is_empty():
        for chapter_id_var: Variant in GROUND_DETAIL_TILESET_PATHS.keys():
            var chapter_id: String = str(chapter_id_var)
            var path: String = str(GROUND_DETAIL_TILESET_PATHS.get(chapter_id, ""))
            var tileset: TileSet = load(path)
            if tileset != null:
                _ground_detail_tilesets[chapter_id] = tileset

    if _door_tilesets.is_empty():
        for chapter_id_var: Variant in DOOR_TILESET_PATHS.keys():
            var chapter_id: String = str(chapter_id_var)
            var path: String = str(DOOR_TILESET_PATHS.get(chapter_id, ""))
            var tileset: TileSet = load(path)
            if tileset != null:
                _door_tilesets[chapter_id] = tileset

    if _hazard_tilesets.is_empty():
        for chapter_id_var: Variant in HAZARD_TILESET_PATHS.keys():
            var chapter_id: String = str(chapter_id_var)
            var path: String = str(HAZARD_TILESET_PATHS.get(chapter_id, ""))
            var tileset: TileSet = load(path)
            if tileset != null:
                _hazard_tilesets[chapter_id] = tileset

    if _ambient_fx_tilesets.is_empty():
        for chapter_id_var: Variant in AMBIENT_FX_TILESET_PATHS.keys():
            var chapter_id: String = str(chapter_id_var)
            var path: String = str(AMBIENT_FX_TILESET_PATHS.get(chapter_id, ""))
            var tileset: TileSet = load(path)
            if tileset != null:
                _ambient_fx_tilesets[chapter_id] = tileset


func _get_ground_tileset_for_room(index: int) -> TileSet:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var chapter_tileset: TileSet = _ground_tilesets.get(chapter_id, null) as TileSet
    if chapter_tileset != null:
        return chapter_tileset

    return _ground_tilesets.get("chapter_1", null) as TileSet


func _get_door_tileset_for_room(index: int) -> TileSet:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var chapter_tileset: TileSet = _door_tilesets.get(chapter_id, null) as TileSet
    if chapter_tileset != null:
        return chapter_tileset

    return _door_tilesets.get("chapter_1", null) as TileSet


func _get_ground_detail_tileset_for_room(index: int) -> TileSet:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var chapter_tileset: TileSet = _ground_detail_tilesets.get(chapter_id, null) as TileSet
    if chapter_tileset != null:
        return chapter_tileset

    return _ground_detail_tilesets.get("chapter_1", null) as TileSet


func _get_hazard_tileset_for_room(index: int) -> TileSet:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var chapter_tileset: TileSet = _hazard_tilesets.get(chapter_id, null) as TileSet
    if chapter_tileset != null:
        return chapter_tileset

    return _hazard_tilesets.get("chapter_1", null) as TileSet


func _get_ambient_fx_tileset_for_room(index: int) -> TileSet:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var chapter_tileset: TileSet = _ambient_fx_tilesets.get(chapter_id, null) as TileSet
    if chapter_tileset != null:
        return chapter_tileset

    return _ambient_fx_tilesets.get("chapter_1", null) as TileSet


func _render_ground_tiles_for_room(index: int) -> void:
    if _ground_tilemap == null:
        return

    var ground_tileset: TileSet = _get_ground_tileset_for_room(index)
    if ground_tileset != null:
        _ground_tilemap.tile_set = ground_tileset
    if _ground_tilemap.tile_set == null:
        return

    _ground_tilemap.clear()

    for y: int in range(TILE_GRID_HEIGHT):
        for x: int in range(TILE_GRID_WIDTH):
            var atlas_x: int = int((x + y + index) % 3)
            _ground_tilemap.set_cell(0, Vector2i(x, y), TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)


func _render_ground_detail_tiles_for_room(index: int) -> void:
    if _ground_detail_tilemap == null:
        return

    var detail_tileset: TileSet = _get_ground_detail_tileset_for_room(index)
    if detail_tileset != null:
        _ground_detail_tilemap.tile_set = detail_tileset
    if _ground_detail_tilemap.tile_set == null:
        return

    _ground_detail_tilemap.clear()
    var chapter_id: String = _get_chapter_id_for_room(index)
    var density: int = 13
    if chapter_id == "chapter_2":
        density = 11
    elif chapter_id == "chapter_3":
        density = 15
    elif chapter_id == "chapter_4":
        density = 10

    var seed: int = index * 113 + chapter_id.hash()
    for y: int in range(TILE_GRID_HEIGHT):
        for x: int in range(TILE_GRID_WIDTH):
            if posmod(x * 11 + y * 7 + seed, density) != 0:
                continue
            var atlas_x: int = int(posmod(x * 5 + y * 3 + seed, GROUND_DETAIL_TILE_VARIANTS))
            _ground_detail_tilemap.set_cell(0, Vector2i(x, y), TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)


func _render_door_tiles(locked: bool) -> void:
    if _door_tilemap == null:
        return

    var door_tileset: TileSet = _get_door_tileset_for_room(_room_index)
    if door_tileset != null:
        _door_tilemap.tile_set = door_tileset
    if _door_tilemap.tile_set == null:
        return

    _door_tilemap.clear()
    var atlas_x: int = 1 if locked else 0
    var left_col: int = 12 if locked else 4
    var right_col: int = 26 if locked else 34

    for y: int in range(8, 15):
        for width: int in range(2):
            _door_tilemap.set_cell(0, Vector2i(left_col + width, y), TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)
            _door_tilemap.set_cell(0, Vector2i(right_col + width, y), TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)


func _render_hazard_tiles() -> void:
    if _hazard_tilemap == null:
        return

    var hazard_tileset: TileSet = _get_hazard_tileset_for_room(_room_index)
    if hazard_tileset != null:
        _hazard_tilemap.tile_set = hazard_tileset
    if _hazard_tilemap.tile_set == null:
        return

    _hazard_tilemap.clear()
    _hazard_anim_cells.clear()
    _hazard_anim_timer = 0.0
    _hazard_anim_frame = 0
    if _active_hazards.is_empty():
        return

    var hazard_signature: String = "|".join(_active_hazards)
    var seed: int = hazard_signature.hash() + _room_index * 97
    for y: int in range(TILE_GRID_HEIGHT):
        for x: int in range(TILE_GRID_WIDTH):
            if posmod(x * 3 + y * 5 + seed, 4) == 0:
                continue
            var phase: int = int(posmod(x * 17 + y * 31 + seed, HAZARD_TILE_VARIANTS))
            var cell_pos: Vector2i = Vector2i(x, y)
            _hazard_tilemap.set_cell(0, cell_pos, HAZARD_TILE_SOURCE_ID, Vector2i(phase, 0), 0)
            _hazard_anim_cells.append({"pos": cell_pos, "phase": phase})


func _render_ambient_fx_tiles() -> void:
    if _ambient_fx_tilemap == null:
        return

    var ambient_tileset: TileSet = _get_ambient_fx_tileset_for_room(_room_index)
    if ambient_tileset != null:
        _ambient_fx_tilemap.tile_set = ambient_tileset
    if _ambient_fx_tilemap.tile_set == null:
        return

    _ambient_fx_tilemap.clear()
    _ambient_fx_anim_cells.clear()
    _ambient_fx_anim_timer = 0.0
    _ambient_fx_anim_frame = 0

    var chapter_id: String = _get_chapter_id_for_room(_room_index)
    var density: int = 19
    if chapter_id == "chapter_2":
        density = 17
    elif chapter_id == "chapter_3":
        density = 22
    elif chapter_id == "chapter_4":
        density = 16

    var room_seed: int = _room_index * 149 + chapter_id.hash()
    for y: int in range(TILE_GRID_HEIGHT):
        for x: int in range(TILE_GRID_WIDTH):
            if posmod(x * 7 + y * 13 + room_seed, density) != 0:
                continue
            var phase: int = int(posmod(x * 19 + y * 11 + room_seed, AMBIENT_FX_TILE_VARIANTS))
            var cell_pos: Vector2i = Vector2i(x, y)
            _ambient_fx_tilemap.set_cell(0, cell_pos, AMBIENT_FX_TILE_SOURCE_ID, Vector2i(phase, 0), 0)
            _ambient_fx_anim_cells.append({"pos": cell_pos, "phase": phase})


func _update_hazard_tile_animation(delta: float) -> void:
    if _hazard_tilemap == null or _hazard_tilemap.tile_set == null:
        return
    if _hazard_anim_cells.is_empty() or _active_hazards.is_empty():
        return

    var interval: float = _get_hazard_anim_interval(_room_index)
    if interval <= 0.0:
        return

    _hazard_anim_timer += delta
    if _hazard_anim_timer < interval:
        return

    var steps: int = maxi(1, int(floor(_hazard_anim_timer / interval)))
    _hazard_anim_timer = fposmod(_hazard_anim_timer, interval)
    _hazard_anim_frame = int(posmod(_hazard_anim_frame + steps, HAZARD_TILE_VARIANTS))

    for row_var: Variant in _hazard_anim_cells:
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var pos_var: Variant = row.get("pos", Vector2i.ZERO)
        if not (pos_var is Vector2i):
            continue
        var cell_pos: Vector2i = pos_var
        var phase: int = int(row.get("phase", 0))
        var atlas_x: int = int(posmod(phase + _hazard_anim_frame, HAZARD_TILE_VARIANTS))
        _hazard_tilemap.set_cell(0, cell_pos, HAZARD_TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)


func _update_ambient_fx_animation(delta: float) -> void:
    if _ambient_fx_tilemap == null or _ambient_fx_tilemap.tile_set == null:
        return
    if _ambient_fx_anim_cells.is_empty():
        return

    var interval: float = _get_ambient_fx_interval(_room_index)
    if interval <= 0.0:
        return

    _ambient_fx_anim_timer += delta
    if _ambient_fx_anim_timer < interval:
        return

    var steps: int = maxi(1, int(floor(_ambient_fx_anim_timer / interval)))
    _ambient_fx_anim_timer = fposmod(_ambient_fx_anim_timer, interval)
    _ambient_fx_anim_frame = int(posmod(_ambient_fx_anim_frame + steps, AMBIENT_FX_TILE_VARIANTS))

    for row_var: Variant in _ambient_fx_anim_cells:
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var pos_var: Variant = row.get("pos", Vector2i.ZERO)
        if not (pos_var is Vector2i):
            continue
        var cell_pos: Vector2i = pos_var
        var phase: int = int(row.get("phase", 0))
        var atlas_x: int = int(posmod(phase + _ambient_fx_anim_frame, AMBIENT_FX_TILE_VARIANTS))
        _ambient_fx_tilemap.set_cell(0, cell_pos, AMBIENT_FX_TILE_SOURCE_ID, Vector2i(atlas_x, 0), 0)


func _update_environment_visuals(delta: float) -> void:
    if _background != null:
        _background.color = _background.color.lerp(_target_background_color, clampf(delta * 2.4, 0.0, 1.0))

    _visual_profile_anim_time += delta

    _update_hazard_tile_animation(delta)
    _update_ambient_fx_animation(delta)

    var visual_profile: Dictionary = _get_chapter_visual_profile(_room_index)
    var detail_tint: Color = _get_visual_profile_color(visual_profile, "detail_tint", "#D4DEE6")
    var detail_alpha_mult: float = _get_visual_profile_value(visual_profile, "detail_alpha", 0.65, 0.20, 1.00)
    var detail_pulse_speed: float = _get_visual_profile_value(visual_profile, "detail_pulse_speed", 0.0, 0.0, 6.0)
    var detail_pulse_amplitude: float = _get_visual_profile_value(visual_profile, "detail_pulse_amplitude", 0.0, 0.0, 0.25)
    var hazard_alpha_mult: float = _get_visual_profile_value(visual_profile, "hazard_alpha_mult", 1.0, 0.40, 1.60)
    var ambient_alpha_mult: float = _get_visual_profile_value(visual_profile, "ambient_alpha_mult", 1.0, 0.40, 1.60)
    var ambient_wave_speed: float = _get_visual_profile_value(visual_profile, "ambient_wave_speed", 0.0, 0.0, 6.0)
    var ambient_wave_amplitude: float = _get_visual_profile_value(visual_profile, "ambient_wave_amplitude", 0.0, 0.0, 0.25)
    var ambient_scroll_x: float = _get_visual_profile_value(visual_profile, "ambient_scroll_speed_x", 0.0, -8.0, 8.0)
    var ambient_scroll_y: float = _get_visual_profile_value(visual_profile, "ambient_scroll_speed_y", 0.0, -8.0, 8.0)
    var anim_factors: Dictionary = _get_visual_profile_anim_factors(
        detail_pulse_speed,
        detail_pulse_amplitude,
        ambient_wave_speed,
        ambient_wave_amplitude,
        _visual_profile_anim_time
    )
    var detail_pulse: float = float(anim_factors.get("detail_pulse", 0.0))
    var ambient_wave: float = float(anim_factors.get("ambient_wave", 0.0))

    if _ground_detail_tilemap != null:
        var detail_color: Color = detail_tint.lerp(_route_theme_tint, _route_theme_blend * 0.20)
        var detail_alpha: float = 0.08
        if _room_active and _is_combat_progress_room(_current_room_type):
            detail_alpha = 0.12 + 0.03 * _get_hazard_intensity()
        detail_alpha = clampf(detail_alpha + detail_pulse, 0.02, 0.95)
        detail_color.a = clampf(detail_alpha * detail_alpha_mult, 0.0, 0.90)
        _ground_detail_tilemap.modulate = _ground_detail_tilemap.modulate.lerp(detail_color, clampf(delta * 2.2, 0.0, 1.0))

    if _hazard_tilemap != null:
        var tint_color: Color = _resolve_hazard_tint_color()
        var intensity: float = _get_hazard_intensity()
        var target_alpha: float = 0.0
        if _room_active and intensity > 0.0 and not _active_hazards.is_empty():
            target_alpha = (0.08 + 0.10 * intensity) * hazard_alpha_mult
        tint_color.a = target_alpha
        _hazard_tilemap.modulate = _hazard_tilemap.modulate.lerp(tint_color, clampf(delta * 3.0, 0.0, 1.0))

    if _ambient_fx_tilemap != null:
        var chapter_id: String = _get_chapter_id_for_room(_room_index)
        var ambient_color: Color = Color(0.82, 0.88, 0.95, 1.0)
        if chapter_id == "chapter_2":
            ambient_color = Color(0.94, 0.62, 0.38, 1.0)
        elif chapter_id == "chapter_3":
            ambient_color = Color(0.70, 0.90, 1.0, 1.0)
        elif chapter_id == "chapter_4":
            ambient_color = Color(0.90, 0.56, 0.98, 1.0)

        ambient_color = ambient_color.lerp(_route_theme_tint, _route_theme_blend * 0.35)
        var ambient_alpha: float = 0.0
        if _room_active and _is_combat_progress_room(_current_room_type):
            ambient_alpha = (0.05 + 0.02 * _get_hazard_intensity()) * ambient_alpha_mult
            ambient_alpha = maxf(0.0, ambient_alpha + ambient_wave)
        ambient_color.a = ambient_alpha
        _ambient_fx_tilemap.modulate = _ambient_fx_tilemap.modulate.lerp(ambient_color, clampf(delta * 2.6, 0.0, 1.0))

        _ambient_fx_scroll_offset.x = wrapf(_ambient_fx_scroll_offset.x + ambient_scroll_x * delta, -24.0, 24.0)
        _ambient_fx_scroll_offset.y = wrapf(_ambient_fx_scroll_offset.y + ambient_scroll_y * delta, -24.0, 24.0)
        _ambient_fx_tilemap.position = _ambient_fx_scroll_offset

    if _hazard_flash != null:
        _hazard_flash.color.a = maxf(0.0, _hazard_flash.color.a - 1.35 * delta)


func _resolve_hazard_tint_color() -> Color:
    var hazard_color: Color
    if _active_hazards.has("void_corruption") or _active_hazards.has("void_rift"):
        hazard_color = Color(0.40, 0.20, 0.62, 1.0)
    elif _active_hazards.has("frostbite") or _active_hazards.has("ice_slide"):
        hazard_color = Color(0.48, 0.66, 0.84, 1.0)
    elif _active_hazards.has("lava_pool"):
        hazard_color = Color(0.70, 0.28, 0.20, 1.0)
    elif _active_hazards.has("spore_cloud"):
        hazard_color = Color(0.38, 0.60, 0.32, 1.0)
    else:
        hazard_color = Color(0.18, 0.34, 0.50, 1.0)

    var blended: Color = hazard_color.lerp(_route_theme_tint, _route_theme_blend)
    blended.a = 0.0
    return blended


func _trigger_hazard_flash(flash_color: Color) -> void:
    if _hazard_flash == null:
        return
    _hazard_flash.color = flash_color


func _get_chapter_environment_row(index: int) -> Dictionary:
    var chapter_id: String = _get_chapter_id_for_room(index)
    var config: Dictionary = ConfigManager.get_config("environment_config", {})
    var chapters: Dictionary = config.get("chapters", {})
    return chapters.get(chapter_id, {})


func _get_hazard_anim_interval(index: int) -> float:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    return clampf(float(chapter_row.get("hazard_anim_interval", 0.16)), 0.08, 0.40)


func _get_ambient_fx_interval(index: int) -> float:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    return clampf(float(chapter_row.get("ambient_fx_interval", 0.24)), 0.12, 0.60)


func _get_chapter_visual_profile(index: int) -> Dictionary:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    var profile_var: Variant = chapter_row.get("visual_profile", {})
    if profile_var is Dictionary:
        return profile_var
    return {}


func _get_visual_profile_value(profile: Dictionary, key: String, default_value: float, min_value: float, max_value: float) -> float:
    return clampf(float(profile.get(key, default_value)), min_value, max_value)


func _get_visual_profile_color(profile: Dictionary, key: String, default_hex: String) -> Color:
    var raw: String = str(profile.get(key, default_hex))
    var is_hex: bool = raw.begins_with("#") and (raw.length() == 7 or raw.length() == 9)
    if not is_hex:
        raw = default_hex
    return Color.html(raw)


func _get_visual_profile_anim_factors(
    detail_pulse_speed: float,
    detail_pulse_amplitude: float,
    ambient_wave_speed: float,
    ambient_wave_amplitude: float,
    time_value: float
) -> Dictionary:
    var detail_pulse: float = 0.0
    if detail_pulse_speed > 0.0 and detail_pulse_amplitude > 0.0:
        detail_pulse = sin(time_value * detail_pulse_speed + float(_room_index) * 0.37) * detail_pulse_amplitude

    var ambient_wave: float = 0.0
    if ambient_wave_speed > 0.0 and ambient_wave_amplitude > 0.0:
        ambient_wave = sin(time_value * ambient_wave_speed + float(_room_index) * 0.21 + 1.2) * ambient_wave_amplitude

    return {
        "detail_pulse": detail_pulse,
        "ambient_wave": ambient_wave
    }


func _process_environment_hazards(delta: float) -> void:
    _hazard_wave += delta

    var is_hazard_room: bool = _room_active and _is_combat_progress_room(_current_room_type)
    var intensity: float = _get_hazard_intensity()

    if not is_hazard_room:
        _set_frostbite(_frostbite - 12.0 * delta)
        _set_void_corruption(_void_corruption - 10.0 * delta)
        _apply_environment_speed_modifier(false)
        if _hazard_flash != null:
            _hazard_flash.color.a = maxf(0.0, _hazard_flash.color.a - 1.6 * delta)
        return

    var stats: Node = _player.get_node_or_null("StatsComponent")
    var frost_resist: float = _get_resistance(stats, "frostbite_resistance")
    var void_resist: float = _get_resistance(stats, "void_resistance")

    if _active_hazards.has("water_flow"):
        var flow_force: Vector2 = Vector2(cos(_hazard_wave * 0.85) * 36.0 * delta * intensity, 0.0)
        _player.apply_knockback(flow_force)

    if _active_hazards.has("conveyor"):
        _player.apply_knockback(Vector2(42.0 * delta * intensity, 0.0))

    if _active_hazards.has("spore_cloud") and stats != null and stats.get("current_stamina") != null:
        stats.current_stamina = maxf(0.0, stats.current_stamina - 7.0 * delta * intensity)
        EventBus.stamina_changed.emit(float(stats.current_stamina), float(stats.stamina_max))

    if _active_hazards.has("frostbite"):
        _set_frostbite(_frostbite + 6.2 * delta * intensity * (1.0 - frost_resist))

    if _active_hazards.has("void_corruption"):
        _set_void_corruption(_void_corruption + 5.4 * delta * intensity * (1.0 - void_resist))

    _hazard_tick_timer += delta
    if _hazard_tick_timer >= 1.0:
        _hazard_tick_timer = 0.0
        var tick_damage: float = 0.0

        if _active_hazards.has("lava_pool"):
            tick_damage += 4.0 * intensity
        if _active_hazards.has("spore_cloud"):
            tick_damage += 1.6 * intensity
        if _active_hazards.has("void_rift"):
            tick_damage += (2.5 + _void_corruption * 0.015) * intensity * (1.0 - void_resist)

        if _frostbite >= 100.0:
            tick_damage += 4.8 * intensity * (1.0 - frost_resist)
            _set_frostbite(80.0)
            _trigger_hazard_flash(Color(0.58, 0.82, 1.0, 0.32))

        if _void_corruption >= 100.0:
            tick_damage += 6.5 * intensity * (1.0 - void_resist)
            _set_void_corruption(82.0)
            _trigger_hazard_flash(Color(0.76, 0.24, 0.95, 0.34))

        if tick_damage > 0.0:
            _player.apply_damage(tick_damage)
            _trigger_hazard_flash(Color(0.85, 0.25, 0.2, 0.2))

    _apply_environment_speed_modifier(true)


func _apply_environment_speed_modifier(include_room_hazards: bool) -> void:
    var move_component: Node = _player.get_node_or_null("MovementComponent")
    if move_component == null or not move_component.has_method("set_environment_speed_multiplier"):
        return

    var multiplier: float = 1.0
    if include_room_hazards and _active_hazards.has("ice_slide"):
        multiplier *= 0.90
    if _frostbite >= 80.0:
        multiplier *= 0.60
    elif _frostbite >= 50.0:
        multiplier *= 0.78

    multiplier *= _chapter_effect_move_speed_mult

    move_component.set_environment_speed_multiplier(multiplier)


func _set_frostbite(value: float) -> void:
    var clamped: float = clampf(value, 0.0, 100.0)
    if is_equal_approx(clamped, _frostbite):
        return
    _frostbite = clamped
    EventBus.frostbite_changed.emit(_frostbite)


func _set_void_corruption(value: float) -> void:
    var clamped: float = clampf(value, 0.0, 100.0)
    if is_equal_approx(clamped, _void_corruption):
        return
    _void_corruption = clamped
    EventBus.void_corruption_changed.emit(_void_corruption)


func _get_hazards_for_room(index: int) -> Array[String]:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    var hazards_var: Variant = chapter_row.get("hazards", [])

    var hazards: Array[String] = []
    if hazards_var is Array:
        for item: Variant in hazards_var:
            hazards.append(str(item))
    return hazards


func _clear_active_enemies() -> void:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if node == null or not is_instance_valid(node):
            continue
        if ObjectPool != null and node.get_parent() == ObjectPool:
            continue
        if ObjectPool != null:
            ObjectPool.release("enemy_basic", node)
        else:
            node.queue_free()


func _clear_active_pickups() -> void:
    for node: Node in get_tree().get_nodes_in_group("pickup"):
        if node == null or not is_instance_valid(node):
            continue
        if ObjectPool != null and node.get_parent() == ObjectPool:
            continue
        if node.has_method("on_pool_released") and ObjectPool != null:
            ObjectPool.release("pickup_basic", node)
        else:
            node.queue_free()


func _spawn_drops(position: Vector2, table_id: String = "normal") -> void:
    var table: Dictionary = _get_drop_table(table_id)
    var guaranteed: Array = table.get("guaranteed", [])

    for item: Variant in guaranteed:
        _spawn_pickup_from_item(str(item), position)

    var weighted_drop: String = _roll_weighted_drop(table.get("weighted", []))
    if weighted_drop != "":
        _spawn_pickup_from_item(weighted_drop, position + Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0)))


func _resolve_drop_table_for_enemy(enemy_id: String) -> String:
    if enemy_id.begins_with("boss_"):
        return "boss"
    if enemy_id.begins_with("elite_"):
        return "elite"
    return "normal"


func _get_drop_table(table_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("drop_tables", {})
    var table: Variant = config.get(table_id, {})
    if table is Dictionary:
        return table
    return {}


func _roll_weighted_drop(weighted_rows: Array) -> String:
    if weighted_rows.is_empty():
        return ""

    var total_weight: float = 0.0
    for row_variant: Variant in weighted_rows:
        if row_variant is Dictionary:
            total_weight += maxf(0.0, float((row_variant as Dictionary).get("weight", 0.0)))

    if total_weight <= 0.0:
        return ""

    var roll: float = randf() * total_weight
    var cursor: float = 0.0
    for row_variant: Variant in weighted_rows:
        if not (row_variant is Dictionary):
            continue
        var row: Dictionary = row_variant
        cursor += maxf(0.0, float(row.get("weight", 0.0)))
        if roll <= cursor:
            return str(row.get("id", ""))

    return ""


func _spawn_pickup_from_item(item_id: String, position: Vector2) -> void:
    var mapped: Dictionary = _map_item_to_pickup(item_id)
    if mapped.is_empty():
        return

    _spawn_direct_pickup(
        str(mapped.get("type", "xp")),
        int(mapped.get("amount", 1)),
        item_id,
        position
    )


func _spawn_direct_pickup(pickup_type: String, amount: int, pickup_id: String, position: Vector2) -> void:
    if pickup_scene == null or _pickups_root == null:
        return

    var pickup: Node2D
    if ObjectPool != null:
        pickup = ObjectPool.acquire("pickup_basic", _pickups_root) as Node2D
    if pickup == null:
        pickup = pickup_scene.instantiate() as Node2D
    if pickup == null:
        return

    pickup.global_position = position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
    if pickup.has_method("configure"):
        pickup.configure(pickup_type, amount, pickup_id)
    else:
        pickup.set("pickup_type", pickup_type)
        pickup.set("amount", amount)
        pickup.set("pickup_id", pickup_id)

    if pickup.has_signal("picked"):
        var callback: Callable = Callable(self, "_on_pickup_collected")
        if not pickup.picked.is_connected(callback):
            pickup.picked.connect(callback)

    if pickup.get_parent() == null:
        _pickups_root.add_child(pickup)


func _map_item_to_pickup(item_id: String) -> Dictionary:
    match item_id:
        "xp_gem_small":
            return {"type": "xp", "amount": 5}
        "xp_gem_medium":
            return {"type": "xp", "amount": 12}
        "xp_gem_large":
            return {"type": "xp", "amount": 28}
        "gold_small":
            return {"type": "gold", "amount": _scale_drop_amount(8, _route_gold_drop_mult)}
        "gold_medium":
            return {"type": "gold", "amount": _scale_drop_amount(20, _route_gold_drop_mult)}
        "ore_small":
            return {"type": "ore", "amount": _scale_drop_amount(1, _route_ore_drop_mult)}
        "ore_medium":
            return {"type": "ore", "amount": _scale_drop_amount(2, _route_ore_drop_mult)}
        "ore_large":
            return {"type": "ore", "amount": _scale_drop_amount(4, _route_ore_drop_mult)}
        "hp_orb":
            return {"type": "hp", "amount": 10}
        "chest_common":
            return {"type": "gold", "amount": _scale_drop_amount(24, _route_gold_drop_mult)}
        "chest_rare":
            return {"type": "gold", "amount": _scale_drop_amount(40, _route_gold_drop_mult)}
        "accessory_drop":
            return {"type": "accessory", "amount": 1}
        _:
            return {}


func _scale_drop_amount(base_amount: int, multiplier: float) -> int:
    return maxi(1, int(round(float(base_amount) * maxf(0.0, multiplier))))


func _on_pickup_collected(pickup_type: String, amount: int, pickup_id: String) -> void:
    match pickup_type:
        "xp":
            if _player != null and _player.has_method("gain_xp"):
                _player.gain_xp(amount)
        "gold":
            _gold += amount
            EventBus.gold_changed.emit(_gold)
        "ore":
            _ore += amount
            EventBus.ore_changed.emit(_ore)
        "hp":
            var health_component: Node = _player.get_node_or_null("HealthComponent")
            if health_component != null and health_component.has_method("heal"):
                health_component.heal(float(amount))
        "accessory":
            pass
        _:
            pass

    if pickup_id == "accessory_drop":
        _grant_random_accessory()


func _grant_random_accessory() -> void:
    var accessory_id: String = _roll_accessory_id()
    if accessory_id == "":
        return

    if _equipped_accessories.has(accessory_id):
        _gold += 22
        EventBus.gold_changed.emit(_gold)
        _room_status_label.text = "Duplicate accessory converted to 22 gold"
        return

    if _equipped_accessories.size() >= 2:
        _gold += 30
        EventBus.gold_changed.emit(_gold)
        _room_status_label.text = "Accessory slots full -> converted to 30 gold"
        return

    _equipped_accessories.append(accessory_id)
    _apply_accessory_effect(accessory_id)
    EventBus.accessory_acquired.emit(accessory_id)
    _room_status_label.text = "Accessory equipped: %s" % accessory_id


func _roll_accessory_id() -> String:
    var pool: Array[String] = ["acc_heart_of_mine", "acc_flame_core", "acc_zero_mark", "acc_void_eye"]
    if pool.is_empty():
        return ""
    return pool[randi_range(0, pool.size() - 1)]


func _apply_accessory_effect(accessory_id: String) -> void:
    var stats: Node = _player.get_node_or_null("StatsComponent")
    var health: Node = _player.get_node_or_null("HealthComponent")
    var weapon: Node = _player.get_node_or_null("AutoWeapon")

    match accessory_id:
        "acc_heart_of_mine":
            if health != null and health.get("max_hp") != null:
                health.max_hp += 18.0
                if health.has_method("heal"):
                    health.heal(18.0)
            if stats != null and stats.get("frostbite_resistance") != null:
                stats.frostbite_resistance = minf(0.75, stats.frostbite_resistance + 0.08)
        "acc_flame_core":
            if stats != null and stats.get("damage_bonus_pct") != null:
                stats.damage_bonus_pct += 0.12
        "acc_zero_mark":
            if stats != null and stats.get("crit_chance") != null:
                stats.crit_chance = minf(0.95, stats.crit_chance + 0.06)
        "acc_void_eye":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage += 3.0
            if stats != null and stats.get("armor") != null:
                stats.armor = minf(0.75, stats.armor + 0.05)
            if stats != null and stats.get("void_resistance") != null:
                stats.void_resistance = minf(0.75, stats.void_resistance + 0.12)

    if health != null and health.get("current_hp") != null and health.get("max_hp") != null:
        EventBus.health_changed.emit(float(health.current_hp), float(health.max_hp))
