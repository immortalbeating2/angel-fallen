extends Node2D

@onready var _room_timer_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomTimeValue
@onready var _room_status_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomStatusValue
@onready var _room_kill_label: Label = $HUD/MarginContainer/PanelContainer/VBoxContainer/RoomKillValue
@onready var _background: ColorRect = $Background
@onready var _hazard_tint: ColorRect = $HazardTint
@onready var _hazard_flash: ColorRect = $HazardFlash
@onready var _spawner: Node2D = $EnemySpawner
@onready var _player: CharacterBody2D = $Player
@onready var _pickups_root: Node2D = $Pickups
@onready var _left_door: Polygon2D = $Doors/LeftDoor
@onready var _right_door: Polygon2D = $Doors/RightDoor
@onready var _narrative_system: Node = $NarrativeSystem
@onready var _narrative_event_panel: Control = $NarrativeEventPanel
@onready var _chapter_intro_panel: Control = $ChapterIntroPanel
@onready var _chapter_transition_panel: Control = $ChapterTransitionPanel
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
var _shop_restock_cost: int = 20
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
var _shown_chapter_intro: Dictionary = {}
var _active_blessing_id: String = "none"
var _equipped_accessories: Array[String] = []
var _active_hazards: Array[String] = []
var _frostbite: float = 0.0
var _void_corruption: float = 0.0
var _hazard_tick_timer: float = 0.0
var _hazard_wave: float = 0.0
var _target_background_color: Color = Color(0.10, 0.09, 0.13, 1.0)

const ROOM_TYPE_COMBAT: String = "combat"
const ROOM_TYPE_BOSS: String = "boss"
const ROOM_TYPE_EVENT: String = "event"
const ROOM_TYPE_SHOP: String = "shop"
const ROOM_TYPE_SAFE_CAMP: String = "safe_camp"


func _ready() -> void:
    add_to_group("game_world")
    randomize()
    if pickup_scene == null:
        pickup_scene = load("res://scenes/game/pickup.tscn")
    if pickup_scene != null and ObjectPool != null:
        ObjectPool.register_scene("pickup_basic", pickup_scene, 32)

    var shop_config: Dictionary = ConfigManager.get_config("shop_items", {})
    _shop_restock_cost = int(shop_config.get("restock_cost", 20))
    _run_kills = 0
    _run_rooms_cleared = 0
    _run_finished = false
    _returning_to_menu = false
    _chapter_intro_pending = false
    _narrative_event_pending = false
    _chapter_transition_pending = false
    _shown_chapter_intro = {}
    _active_blessing_id = "none"

    GameManager.set_state(GameManager.GameState.PLAYING)
    EventBus.enemy_killed.connect(_on_enemy_killed)
    EventBus.player_died.connect(_on_player_died)
    EventBus.gold_changed.emit(_gold)
    EventBus.ore_changed.emit(_ore)
    EventBus.route_changed.emit(_alignment)
    EventBus.frostbite_changed.emit(_frostbite)
    EventBus.void_corruption_changed.emit(_void_corruption)
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
    if _run_result_panel != null and _run_result_panel.has_signal("back_to_menu_requested"):
        _run_result_panel.back_to_menu_requested.connect(_on_run_result_back_to_menu)
    _start_room()


func _process(delta: float) -> void:
    if _room_active and (_current_room_type == ROOM_TYPE_COMBAT or _current_room_type == ROOM_TYPE_BOSS) and _spawner != null and _spawner.has_method("get_room_time"):
        _room_timer_label.text = "%.1f s" % _spawner.get_room_time()
    elif not _room_active:
        _room_timer_label.text = "-"

    _room_kill_label.text = "%d / %d" % [_kills_in_room, _required_kills]
    _process_environment_hazards(delta)
    _update_environment_visuals(delta)


func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if _chapter_intro_pending or _narrative_event_pending or _chapter_transition_pending:
            return
        if GameManager.current_state == GameManager.GameState.PLAYING and not _run_finished:
            _finish_run("retreat")
        else:
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

    if not _room_active and _current_room_type == ROOM_TYPE_SAFE_CAMP:
        if event.is_action_pressed("camp_forge_damage"):
            _try_forge_damage()
            return
        if event.is_action_pressed("camp_forge_speed"):
            _try_forge_speed()
            return
        if event.is_action_pressed("camp_route_holy"):
            _try_route_choice("holy")
            return
        if event.is_action_pressed("camp_route_void"):
            _try_route_choice("void")
            return

    if event.is_action_pressed("interact") and not _room_active:
        _room_index += 1
        _start_room()


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


func _start_room() -> void:
    _clear_active_enemies()
    _clear_active_pickups()
    _chapter_intro_pending = false
    _narrative_event_pending = false
    _chapter_transition_pending = false
    _current_room_type = _resolve_room_type(_room_index)
    _active_hazards = _get_hazards_for_room(_room_index)
    _apply_room_theme(_room_index)

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
    elif _current_room_type == ROOM_TYPE_BOSS:
        _enter_boss_room()
    elif _current_room_type == ROOM_TYPE_EVENT:
        _enter_event_room()
    elif _current_room_type == ROOM_TYPE_SHOP:
        _enter_shop_room()
    else:
        _enter_safe_camp_room()


func _should_show_chapter_intro(index: int) -> bool:
    if index != 1 and index != 5 and index != 9 and index != 13:
        return false
    var chapter_key: String = _get_chapter_id_for_room(index)
    return not bool(_shown_chapter_intro.get(chapter_key, false))


func _show_chapter_intro(index: int) -> void:
    _room_active = false
    _chapter_intro_pending = true
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    _room_timer_label.text = "-"
    _room_status_label.text = "Chapter briefing..."

    var chapter_index: int = 1 + int((index - 1) / 4)
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
    _room_status_label.text = "Combat Room %d: Defeat %d enemies | Hazards: %s" % [_room_index, _required_kills, get_active_hazards_text()]
    _set_doors_locked(true)

    if _spawner != null and _spawner.has_method("start_room_combat"):
        _spawner.start_room_combat(_room_index, "normal")


func _enter_boss_room() -> void:
    _required_kills = 1
    _room_active = true
    _room_timer_label.text = "0.0 s"
    var boss_id: String = _get_boss_id_for_room(_room_index)
    _room_status_label.text = "Boss Room %d: Defeat %s | Hazards: %s" % [_room_index, _get_boss_title(boss_id), get_active_hazards_text()]
    _set_doors_locked(true)

    if _spawner != null and _spawner.has_method("start_room_combat"):
        _spawner.start_room_combat(_room_index, "boss", boss_id)


func _enter_shop_room() -> void:
    _room_active = false
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    _set_frostbite(maxf(0.0, _frostbite - 18.0))
    _set_void_corruption(maxf(0.0, _void_corruption - 14.0))

    _shop_offers = _build_shop_offers()
    _shop_message = "Shop refreshed. Buy with 1-4."
    _update_shop_text()


func _enter_event_room() -> void:
    _room_active = false
    _narrative_event_pending = false
    _set_doors_locked(false)
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    var chapter_index: int = _get_chapter_index_for_room(_room_index)
    var event_data: Dictionary = {}
    if _narrative_system != null and _narrative_system.has_method("get_chapter_event"):
        event_data = _narrative_system.get_chapter_event(chapter_index)

    if event_data.is_empty():
        _room_status_label.text = "Event Room: no event data. Press E for next room"
        return

    _room_timer_label.text = "-"
    _room_status_label.text = "Event Room: choose your path"
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

    _camp_message = "Recovered: +25 HP, stamina refilled"
    _update_camp_text()


func _on_enemy_killed(_enemy_id: String, _position: Vector2) -> void:
    _run_kills += 1
    var drop_table_id: String = _resolve_drop_table_for_enemy(_enemy_id)
    _spawn_drops(_position, drop_table_id)

    if not _room_active:
        return

    if _current_room_type != ROOM_TYPE_COMBAT and _current_room_type != ROOM_TYPE_BOSS:
        return

    _kills_in_room += 1

    if _kills_in_room >= _required_kills:
        call_deferred("_try_clear_room")


func _try_clear_room() -> void:
    if _current_room_type != ROOM_TYPE_COMBAT and _current_room_type != ROOM_TYPE_BOSS:
        return

    if _spawner != null and _spawner.has_method("get_alive_count"):
        if _spawner.get_alive_count() > 0:
            return

    _room_active = false
    _run_rooms_cleared += 1
    if _spawner != null and _spawner.has_method("stop_room_combat"):
        _spawner.stop_room_combat()

    EventBus.room_cleared.emit("room_%d" % _room_index)
    _set_doors_locked(false)
    if _room_index >= 15:
        _finish_run("victory")
    elif _current_room_type == ROOM_TYPE_BOSS:
        var chapter: int = int(ceil(float(_room_index) / 4.0))
        EventBus.memory_fragment_found.emit("memory_ch%d_boss" % chapter)
        _begin_chapter_transition(chapter)
    else:
        _room_status_label.text = "Room Cleared! Press E for next room"


func _on_player_died(_reason: String) -> void:
    _finish_run("death")


func _finish_run(outcome: String) -> void:
    if _run_finished:
        return
    _run_finished = true

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
        "narrative_choices": _narrative_system.get_run_choices() if _narrative_system != null and _narrative_system.has_method("get_run_choices") else []
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
    SceneManager.go_to_main_menu()


func _on_run_result_back_to_menu() -> void:
    _return_to_main_menu()


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
    _room_status_label.text = "Chapter transition resolved. Press E for next room"


func _on_event_choice_committed(event_id: String, choice_id: String, choice_data: Dictionary) -> void:
    var chapter_id: String = _get_chapter_id_for_room(_room_index)
    _apply_event_choice_effects(choice_data)
    EventBus.narrative_choice.emit(chapter_id, event_id, choice_id)
    if _narrative_system != null and _narrative_system.has_method("record_choice"):
        _narrative_system.record_choice(chapter_id, event_id, choice_id, float(choice_data.get("alignment_delta", 0.0)))


func _on_event_closed() -> void:
    _narrative_event_pending = false
    _room_status_label.text = "Event resolved. Press E for next room"


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


func _get_active_blessing_text() -> String:
    match _active_blessing_id:
        "holy_vow":
            return "Holy Vow (+armor, +frost resist, +heal)"
        "void_oath":
            return "Void Oath (+damage, +crit, -armor)"
        _:
            return "None"


func _get_chapter_id_for_room(index: int) -> String:
    return "chapter_%d" % (1 + int((index - 1) / 4))


func _get_chapter_index_for_room(index: int) -> int:
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


func _resolve_room_type(index: int) -> String:
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


func _build_shop_offers() -> Array[Dictionary]:
    var offers: Array[Dictionary] = []
    var config: Dictionary = ConfigManager.get_config("shop_items", {})
    var slots: int = int(config.get("slots", 4))
    var pools: Dictionary = config.get("pools", {})
    var quality_weights: Dictionary = config.get("quality_weights", {})

    for _i in range(slots):
        var category: String = _pick_shop_category(pools)
        var item_id: String = _pick_shop_item_id(pools, category)
        var quality: String = _roll_quality(quality_weights)
        var offer: Dictionary = _build_shop_offer(item_id, category, quality)
        offers.append(offer)

    return offers


func _pick_shop_category(pools: Dictionary) -> String:
    var keys: Array = pools.keys()
    if keys.is_empty():
        return "consumable"
    return str(keys[randi_range(0, keys.size() - 1)])


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


func _build_shop_offer(item_id: String, category: String, quality: String) -> Dictionary:
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
    var price: int = int(round(base_price * quality_mult * floor_mult))
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
        "wpn_magic_missile":
            return {"title": "Missile Core", "desc": "+4 weapon damage"}
        "wpn_holy_cross":
            return {"title": "Holy Crest", "desc": "+5.5 damage, +3% crit"}
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
    _shop_offers = _build_shop_offers()
    _shop_message = "Restocked for %d gold" % _shop_restock_cost
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
        "wpn_magic_missile":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage += 4.0
        "wpn_holy_cross":
            if weapon != null and weapon.get("base_damage") != null:
                weapon.base_damage += 5.5
            if stats != null and stats.get("crit_chance") != null:
                stats.crit_chance = minf(0.95, stats.crit_chance + 0.03)


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

    lines.append("R: Restock (%dG) | E: Next Room" % _shop_restock_cost)
    lines.append("Chapter hazards ahead: %s" % get_active_hazards_text())
    if _shop_message != "":
        lines.append(_shop_message)

    _room_status_label.text = "\n".join(PackedStringArray(lines))


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

    var chapter_id: String = "chapter_%d" % (1 + int((_room_index - 1) / 4))
    EventBus.narrative_choice.emit(chapter_id, "safe_camp_route", choice_id)

    _camp_message = "Route shifted: %s (%+.0f)" % [choice_id.to_upper(), delta]
    _update_camp_text()


func _update_camp_text() -> void:
    var lines: Array[String] = []
    lines.append("Safe Camp %d | Ore: %d | Alignment: %.0f (%s)" % [
        _room_index,
        _ore,
        _alignment,
        _get_route_tier()
    ])
    lines.append("Purification: Frostbite %.0f%% | Void %.0f%%" % [_frostbite, _void_corruption])
    lines.append("F: Forge Damage (3 ore) | G: Forge Speed (5 ore)")
    lines.append("Q: Choose Holy Route | V: Choose Void Route")
    lines.append("Chapter hazards ahead: %s" % get_active_hazards_text())
    lines.append("E: Next Room")
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
    if _current_room_type == ROOM_TYPE_BOSS:
        return 1.35
    if _current_room_type == ROOM_TYPE_COMBAT:
        return 1.0
    return 0.0


func _get_resistance(stats: Node, property_name: String) -> float:
    if stats == null or stats.get(property_name) == null:
        return 0.0
    return clampf(float(stats.get(property_name)), 0.0, 0.75)


func _apply_room_theme(index: int) -> void:
    var chapter_row: Dictionary = _get_chapter_environment_row(index)
    var palette_var: Variant = chapter_row.get("tile_palette", [])
    if not (palette_var is Array):
        _target_background_color = Color(0.10, 0.09, 0.13, 1.0)
        return

    var palette: Array = palette_var
    if palette.is_empty():
        _target_background_color = Color(0.10, 0.09, 0.13, 1.0)
        return

    _target_background_color = Color.html(str(palette[0]))


func _update_environment_visuals(delta: float) -> void:
    if _background != null:
        _background.color = _background.color.lerp(_target_background_color, clampf(delta * 2.4, 0.0, 1.0))

    if _hazard_tint != null:
        var tint_color: Color = _resolve_hazard_tint_color()
        var intensity: float = _get_hazard_intensity()
        var target_alpha: float = 0.0
        if _room_active and intensity > 0.0:
            target_alpha = 0.06 + 0.05 * intensity
        tint_color.a = target_alpha
        _hazard_tint.color = _hazard_tint.color.lerp(tint_color, clampf(delta * 2.8, 0.0, 1.0))

    if _hazard_flash != null:
        _hazard_flash.color.a = maxf(0.0, _hazard_flash.color.a - 1.35 * delta)


func _resolve_hazard_tint_color() -> Color:
    if _active_hazards.has("void_corruption") or _active_hazards.has("void_rift"):
        return Color(0.40, 0.20, 0.62, 0.0)
    if _active_hazards.has("frostbite") or _active_hazards.has("ice_slide"):
        return Color(0.48, 0.66, 0.84, 0.0)
    if _active_hazards.has("lava_pool"):
        return Color(0.70, 0.28, 0.20, 0.0)
    if _active_hazards.has("spore_cloud"):
        return Color(0.38, 0.60, 0.32, 0.0)
    return Color(0.18, 0.34, 0.50, 0.0)


func _trigger_hazard_flash(flash_color: Color) -> void:
    if _hazard_flash == null:
        return
    _hazard_flash.color = flash_color


func _get_chapter_environment_row(index: int) -> Dictionary:
    var chapter_id: String = "chapter_%d" % (1 + int((index - 1) / 4))
    var config: Dictionary = ConfigManager.get_config("environment_config", {})
    var chapters: Dictionary = config.get("chapters", {})
    return chapters.get(chapter_id, {})


func _process_environment_hazards(delta: float) -> void:
    _hazard_wave += delta

    var is_hazard_room: bool = _room_active and (_current_room_type == ROOM_TYPE_COMBAT or _current_room_type == ROOM_TYPE_BOSS)
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
        if node != null and is_instance_valid(node):
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
            return {"type": "gold", "amount": 8}
        "gold_medium":
            return {"type": "gold", "amount": 20}
        "ore_small":
            return {"type": "ore", "amount": 1}
        "ore_medium":
            return {"type": "ore", "amount": 2}
        "ore_large":
            return {"type": "ore", "amount": 4}
        "hp_orb":
            return {"type": "hp", "amount": 10}
        "chest_common":
            return {"type": "gold", "amount": 24}
        "chest_rare":
            return {"type": "gold", "amount": 40}
        "accessory_drop":
            return {"type": "accessory", "amount": 1}
        _:
            return {}


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
