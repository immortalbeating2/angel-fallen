extends Control

@onready var _meta_value: Label = $CenterContainer/VBoxContainer/MetaValue
@onready var _run_value: Label = $CenterContainer/VBoxContainer/RunValue
@onready var _best_value: Label = $CenterContainer/VBoxContainer/BestValue
@onready var _progress_value: Label = $CenterContainer/VBoxContainer/ProgressValue
@onready var _character_name_value: Label = $CenterContainer/VBoxContainer/CharacterNameValue
@onready var _character_desc_value: Label = $CenterContainer/VBoxContainer/CharacterDescValue
@onready var _character_stats_value: Label = $CenterContainer/VBoxContainer/CharacterStatsValue
@onready var _character_trait_value: Label = $CenterContainer/VBoxContainer/CharacterTraitValue
@onready var _character_unlock_value: Label = $CenterContainer/VBoxContainer/CharacterUnlockValue
@onready var _character_prev_button: Button = $CenterContainer/VBoxContainer/CharacterSwitchRow/CharacterPrevButton
@onready var _character_next_button: Button = $CenterContainer/VBoxContainer/CharacterSwitchRow/CharacterNextButton
@onready var _upgrade_1_button: Button = $CenterContainer/VBoxContainer/Upgrade1Button
@onready var _upgrade_2_button: Button = $CenterContainer/VBoxContainer/Upgrade2Button
@onready var _upgrade_3_button: Button = $CenterContainer/VBoxContainer/Upgrade3Button
@onready var _upgrade_4_button: Button = $CenterContainer/VBoxContainer/Upgrade4Button
@onready var _upgrade_5_button: Button = $CenterContainer/VBoxContainer/Upgrade5Button
@onready var _shop_message_value: Label = $CenterContainer/VBoxContainer/ShopMessageValue
@onready var _achievement_list_value: Label = $CenterContainer/VBoxContainer/AchievementListValue
@onready var _fragment_review_value: Label = $CenterContainer/VBoxContainer/FragmentReviewValue
@onready var _review_fragment_button: Button = $CenterContainer/VBoxContainer/ReviewFragmentButton
@onready var _ending_review_value: Label = $CenterContainer/VBoxContainer/EndingReviewValue
@onready var _review_ending_button: Button = $CenterContainer/VBoxContainer/ReviewEndingButton
@onready var _ending_theme_header: Label = $CenterContainer/VBoxContainer/EndingThemeHeader
@onready var _ending_theme_band_top: ColorRect = $CenterContainer/VBoxContainer/EndingThemeBandTop
@onready var _ending_theme_band_bottom: ColorRect = $CenterContainer/VBoxContainer/EndingThemeBandBottom
@onready var _last_run_value: Label = $CenterContainer/VBoxContainer/LastRunValue
@onready var _settings_overlay: Control = $SettingsOverlay
@onready var _runtime_settings_panel: VBoxContainer = $SettingsOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RuntimeSettingsPanel
@onready var _codex_overlay: Control = $CodexOverlay
@onready var _codex_title: Label = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexTitle
@onready var _codex_content: Label = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexContent
@onready var _codex_prev_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexNavRow/CodexPrevButton
@onready var _codex_next_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexNavRow/CodexNextButton
@onready var _codex_detail: Label = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexDetail
@onready var _codex_stats_value: Label = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsValue
@onready var _codex_stats_source_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsFilterRow/CodexStatsSourceButton
@onready var _codex_stats_chapter_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexStatsFilterRow/CodexStatsChapterButton
@onready var _codex_entry_prev_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexEntryNavRow/CodexEntryPrevButton
@onready var _codex_entry_next_button: Button = $CodexOverlay/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CodexEntryNavRow/CodexEntryNextButton

var _shop_message: String = ""
var _fragment_cursor: int = 0
var _ending_cursor: int = 0
var _character_cursor: int = 0
var _codex_category_index: int = 0
var _codex_entry_index: int = 0
var _codex_stats_source_filter_index: int = 0
var _codex_stats_chapter_filter_index: int = 0

const CODEX_CATEGORIES: Array[String] = ["characters", "weapons", "passives", "enemies", "accessories"]
const CODEX_CATEGORY_NAMES: Dictionary = {
    "characters": "Characters",
    "weapons": "Weapons",
    "passives": "Passives",
    "enemies": "Enemies",
    "accessories": "Accessories"
}
const CODEX_SOURCE_FILTERS: Array[Dictionary] = [
    {"id": "all", "label": "All Sources"},
    {"id": "character_select", "label": "Character Selection"},
    {"id": "run_start", "label": "Run Start"},
    {"id": "level_up_choice", "label": "Level Up Choice"},
    {"id": "enemy_kill", "label": "Enemy Defeat"},
    {"id": "accessory_pickup", "label": "Accessory Pickup"}
]
const CODEX_CHAPTER_FILTERS: Array[Dictionary] = [
    {"id": "all", "label": "All Chapters"},
    {"id": "chapter_1", "label": "Chapter 1"},
    {"id": "chapter_2", "label": "Chapter 2"},
    {"id": "chapter_3", "label": "Chapter 3"},
    {"id": "chapter_4", "label": "Chapter 4"},
    {"id": "global", "label": "Global"}
]
const PASSIVE_NAME_MAP: Dictionary = {
    "power": "Might",
    "vitality": "Vitality",
    "agility": "Agility",
    "endurance": "Endurance",
    "focus": "Focus",
    "precision": "Precision",
    "force": "Force"
}
const ACCESSORY_NAME_MAP: Dictionary = {
    "acc_heart_of_mine": "Heart of Mine",
    "acc_flame_core": "Flame Core",
    "acc_zero_mark": "Zero Mark",
    "acc_void_eye": "Void Eye"
}
const ENEMY_NAME_MAP: Dictionary = {
    "enemy_shadowling": "Shadowling",
    "enemy_stalker": "Night Stalker",
    "enemy_brute": "Abyss Brute",
    "enemy_hexcaster": "Hexcaster",
    "enemy_emberling": "Emberling",
    "enemy_scorch_runner": "Scorch Runner",
    "enemy_burn_guard": "Burn Guard",
    "enemy_flame_channeler": "Flame Channeler",
    "enemy_frostling": "Frostling",
    "enemy_glacier_runner": "Glacier Runner",
    "enemy_ice_guard": "Ice Guard",
    "enemy_blizzard_mage": "Blizzard Mage",
    "enemy_voidling": "Voidling",
    "enemy_rift_runner": "Rift Runner",
    "enemy_abyss_guard": "Abyss Guard",
    "enemy_void_priest": "Void Priest",
    "elite_shadowling": "Elite Shadowling",
    "elite_stalker": "Elite Night Stalker",
    "elite_brute": "Elite Abyss Brute",
    "elite_hexcaster": "Elite Hexcaster",
    "elite_emberling": "Elite Emberling",
    "elite_scorch_runner": "Elite Scorch Runner",
    "elite_burn_guard": "Elite Burn Guard",
    "elite_flame_channeler": "Elite Flame Channeler",
    "elite_frostling": "Elite Frostling",
    "elite_glacier_runner": "Elite Glacier Runner",
    "elite_ice_guard": "Elite Ice Guard",
    "elite_blizzard_mage": "Elite Blizzard Mage",
    "elite_voidling": "Elite Voidling",
    "elite_rift_runner": "Elite Rift Runner",
    "elite_abyss_guard": "Elite Abyss Guard",
    "elite_void_priest": "Elite Void Priest",
    "boss_rock_colossus": "Rock Colossus",
    "boss_flame_lord": "Flame Lord",
    "boss_frost_king": "Frost King",
    "boss_void_lord": "Void Lord"
}

const ENDING_THEME_DEFAULT: Dictionary = {
    "accent": Color(0.92, 0.94, 1.0, 1.0),
    "band_top": Color(0.34, 0.38, 0.52, 0.92),
    "band_bottom": Color(0.24, 0.28, 0.42, 0.88),
    "icon": "[ARCHIVE]",
    "title": "Unbound Fate"
}
const ENDING_THEME_MAP: Dictionary = {
    "nar_ending_redeem": {
        "accent": Color(0.78, 0.92, 1.0, 1.0),
        "band_top": Color(0.35, 0.52, 0.74, 0.92),
        "band_bottom": Color(0.22, 0.36, 0.56, 0.88),
        "icon": "[HALO]",
        "title": "Redeem"
    },
    "nar_ending_fall": {
        "accent": Color(1.0, 0.72, 0.70, 1.0),
        "band_top": Color(0.64, 0.22, 0.22, 0.92),
        "band_bottom": Color(0.46, 0.14, 0.16, 0.88),
        "icon": "[ABYSS]",
        "title": "Fall"
    },
    "nar_ending_balance": {
        "accent": Color(0.84, 0.96, 0.78, 1.0),
        "band_top": Color(0.3, 0.5, 0.32, 0.92),
        "band_bottom": Color(0.22, 0.38, 0.26, 0.88),
        "icon": "[TWILIGHT]",
        "title": "Balance"
    }
}


func _ready() -> void:
    GameManager.set_state(GameManager.GameState.MENU)
    if _settings_overlay != null:
        _settings_overlay.visible = false
    if _codex_overlay != null:
        _codex_overlay.visible = false
    _sync_character_cursor_from_save()
    _sync_codex_stats_filters_from_save()
    _refresh_meta_text()


func _unhandled_input(event: InputEvent) -> void:
    if _codex_overlay != null and _codex_overlay.visible:
        if event.is_action_pressed("pause") or event.is_action_pressed("interact"):
            _close_codex_overlay()
            return
        if event.is_action_pressed("narrative_choice_1"):
            _shift_codex_category(-1)
            return
        if event.is_action_pressed("narrative_choice_2"):
            _shift_codex_category(1)
            return
        if event is InputEventKey:
            var key_event: InputEventKey = event
            if key_event.pressed and not key_event.echo:
                if key_event.physical_keycode == KEY_3 or key_event.physical_keycode == KEY_KP_3 or key_event.physical_keycode == KEY_Q:
                    _shift_codex_entry(-1)
                    return
                if key_event.physical_keycode == KEY_4 or key_event.physical_keycode == KEY_KP_4 or key_event.physical_keycode == KEY_R:
                    _shift_codex_entry(1)
                    return
                if key_event.physical_keycode == KEY_5 or key_event.physical_keycode == KEY_KP_5:
                    _cycle_codex_stats_source_filter(1)
                    return
                if key_event.physical_keycode == KEY_6 or key_event.physical_keycode == KEY_KP_6:
                    _cycle_codex_stats_chapter_filter(1)
                    return

    if _settings_overlay == null or not _settings_overlay.visible:
        return

    if (event.is_action_pressed("pause") or event.is_action_pressed("interact")) and not _is_settings_capture_active():
        _close_settings_overlay()


func _on_start_pressed() -> void:
    if _codex_overlay != null and _codex_overlay.visible:
        _close_codex_overlay()
        return
    if _settings_overlay != null and _settings_overlay.visible:
        _close_settings_overlay()
        return
    if not _apply_selected_character():
        _shop_message = "Selected character is locked"
        _refresh_meta_text()
        return
    SceneManager.go_to_game_world()


func _on_quit_pressed() -> void:
    if _codex_overlay != null and _codex_overlay.visible:
        _close_codex_overlay()
        return
    if _settings_overlay != null and _settings_overlay.visible:
        _close_settings_overlay()
        return
    get_tree().quit()


func _on_reset_meta_pressed() -> void:
    SaveManager.reset_meta()
    _shop_message = "Meta data reset"
    _refresh_meta_text()


func _on_upgrade_1_pressed() -> void:
    _try_buy_upgrade(0)


func _on_upgrade_2_pressed() -> void:
    _try_buy_upgrade(1)


func _on_upgrade_3_pressed() -> void:
    _try_buy_upgrade(2)


func _on_upgrade_4_pressed() -> void:
    _try_buy_upgrade(3)


func _on_upgrade_5_pressed() -> void:
    _try_buy_upgrade(4)


func _on_review_fragment_button_pressed() -> void:
    _fragment_cursor += 1
    _refresh_fragment_review()


func _on_review_ending_button_pressed() -> void:
    _ending_cursor += 1
    _refresh_ending_review()


func _on_settings_button_pressed() -> void:
    _open_settings_overlay()


func _on_settings_close_button_pressed() -> void:
    _close_settings_overlay()


func _on_codex_button_pressed() -> void:
    _open_codex_overlay()


func _on_codex_close_button_pressed() -> void:
    _close_codex_overlay()


func _on_codex_prev_button_pressed() -> void:
    _shift_codex_category(-1)


func _on_codex_next_button_pressed() -> void:
    _shift_codex_category(1)


func _on_codex_entry_prev_button_pressed() -> void:
    _shift_codex_entry(-1)


func _on_codex_entry_next_button_pressed() -> void:
    _shift_codex_entry(1)


func _on_codex_stats_source_button_pressed() -> void:
    _cycle_codex_stats_source_filter(1)


func _on_codex_stats_chapter_button_pressed() -> void:
    _cycle_codex_stats_chapter_filter(1)


func _on_character_prev_pressed() -> void:
    var rows: Array[Dictionary] = _get_character_rows()
    if rows.is_empty():
        return
    _character_cursor = posmod(_character_cursor - 1, rows.size())
    _refresh_character_preview()


func _on_character_next_pressed() -> void:
    var rows: Array[Dictionary] = _get_character_rows()
    if rows.is_empty():
        return
    _character_cursor = posmod(_character_cursor + 1, rows.size())
    _refresh_character_preview()


func _refresh_meta_text() -> void:
    var meta: Dictionary = SaveManager.get_meta_data()
    var last_run: Dictionary = SaveManager.get_last_run()
    var unlocked_achievements: Array[String] = SaveManager.get_unlocked_achievements()
    var unlocked_endings: Array[String] = SaveManager.get_unlocked_endings()
    var achievements_config: Dictionary = ConfigManager.get_config("achievements", {})
    var total_achievements: int = 0
    var rows: Variant = achievements_config.get("achievements", [])
    if rows is Array:
        total_achievements = (rows as Array).size()

    _meta_value.text = str(meta.get("meta_currency", 0))
    _refresh_character_preview()
    _run_value.text = "%d runs / %d kills" % [
        int(meta.get("total_runs", 0)),
        int(meta.get("total_kills", 0))
    ]
    _best_value.text = "Highest Room %d | Best Lv %d | Victories %d" % [
        int(meta.get("highest_room", 1)),
        int(meta.get("best_level", 1)),
        int(meta.get("total_victories", 0))
    ]
    _progress_value.text = "Achievements %d/%d | Endings %d/3" % [
        unlocked_achievements.size(),
        total_achievements,
        unlocked_endings.size()
    ]
    _refresh_upgrade_buttons()
    _refresh_achievement_list()
    _refresh_fragment_review()
    _refresh_ending_review()
    _refresh_codex_overlay()

    if last_run.is_empty():
        _last_run_value.text = "No run record yet"
        return

    var ending_text: String = str(last_run.get("ending_id", ""))
    if ending_text == "":
        ending_text = "-"
    var new_achievements_count: int = 0
    var new_achievements_var: Variant = last_run.get("new_achievements", [])
    if new_achievements_var is Array:
        new_achievements_count = (new_achievements_var as Array).size()

    _last_run_value.text = "Last: %s | Rooms %d | Kills %d | Lv %d | Meta +%d | Ending %s | NewAch %d" % [
        str(last_run.get("outcome", "death")).to_upper(),
        int(last_run.get("rooms_cleared", 0)),
        int(last_run.get("kills", 0)),
        int(last_run.get("level_reached", 1)),
        int(last_run.get("meta_reward", 0)),
        ending_text,
        new_achievements_count
    ]


func _try_buy_upgrade(index: int) -> void:
    var rows: Array[Dictionary] = _get_meta_upgrade_rows()
    if index < 0 or index >= rows.size():
        return

    var row: Dictionary = rows[index]
    var upgrade_id: String = str(row.get("id", ""))
    var title: String = str(row.get("title", upgrade_id))
    var result: Dictionary = SaveManager.purchase_upgrade(upgrade_id)

    if bool(result.get("ok", false)):
        _shop_message = "Purchased %s -> Lv.%d" % [title, int(result.get("new_level", 0))]
    else:
        var reason: String = str(result.get("reason", "failed"))
        if reason == "not_enough_currency":
            _shop_message = "Need %d meta (have %d)" % [
                int(result.get("cost", 0)),
                int(result.get("currency", 0))
            ]
        elif reason == "max_level":
            _shop_message = "%s is already maxed" % title
        else:
            _shop_message = "Upgrade purchase failed"

    _refresh_meta_text()


func _refresh_upgrade_buttons() -> void:
    var rows: Array[Dictionary] = _get_meta_upgrade_rows()
    var buttons: Array[Button] = [
        _upgrade_1_button,
        _upgrade_2_button,
        _upgrade_3_button,
        _upgrade_4_button,
        _upgrade_5_button
    ]

    for i in range(buttons.size()):
        var button: Button = buttons[i]
        if i >= rows.size():
            button.visible = false
            continue

        button.visible = true
        var row: Dictionary = rows[i]
        var upgrade_id: String = str(row.get("id", ""))
        var title: String = str(row.get("title", upgrade_id))
        var max_level: int = int(row.get("max_level", 1))
        var level: int = SaveManager.get_upgrade_level(upgrade_id)
        var cost: int = SaveManager.get_upgrade_cost(upgrade_id)

        if level >= max_level or cost < 0:
            button.text = "%d) %s Lv.%d/%d (MAX)" % [i + 1, title, level, max_level]
            button.disabled = true
        else:
            button.text = "%d) %s Lv.%d/%d  Cost:%d" % [i + 1, title, level, max_level, cost]
            button.disabled = false

    if _shop_message == "":
        _shop_message_value.text = "Meta Shop: buy permanent upgrades"
    else:
        _shop_message_value.text = _shop_message


func _refresh_achievement_list() -> void:
    var rows_var: Variant = ConfigManager.get_config("achievements", {}).get("achievements", [])
    var rows: Array = []
    if rows_var is Array:
        rows = rows_var

    var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
    var lines: Array[String] = []
    lines.append("Achievements:")
    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var ach_id: String = str(row.get("id", ""))
        var title: String = str(row.get("title", ach_id))
        var mark: String = "[ ]"
        if unlocked.has(ach_id):
            mark = "[x]"
        lines.append("%s %s" % [mark, title])

    var endings: Array[String] = SaveManager.get_unlocked_endings()
    lines.append("Endings:")
    lines.append("%s Redeem" % ("[x]" if endings.has("nar_ending_redeem") else "[ ]"))
    lines.append("%s Fall" % ("[x]" if endings.has("nar_ending_fall") else "[ ]"))
    lines.append("%s Balance" % ("[x]" if endings.has("nar_ending_balance") else "[ ]"))

    var unlocked_fragments: Array[String] = SaveManager.get_unlocked_fragments()
    var fragment_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("memory_fragments", {})
    var fragment_rows: Dictionary = {}
    if fragment_rows_var is Dictionary:
        fragment_rows = fragment_rows_var

    lines.append("Memory Fragments:")
    lines.append("Unlocked %d / %d" % [unlocked_fragments.size(), fragment_rows.size()])
    for item: Variant in unlocked_fragments:
        var fragment_id: String = str(item)
        var fragment_title: String = fragment_id
        var row_var: Variant = fragment_rows.get(fragment_id, {})
        if row_var is Dictionary:
            fragment_title = str((row_var as Dictionary).get("title", fragment_id))
        lines.append("[x] %s" % fragment_title)

    _achievement_list_value.text = "\n".join(PackedStringArray(lines))


func _get_meta_upgrade_rows() -> Array[Dictionary]:
    var config: Dictionary = ConfigManager.get_config("meta_upgrades", {})
    var rows_var: Variant = config.get("upgrades", [])
    var rows: Array[Dictionary] = []
    if rows_var is Array:
        for item: Variant in rows_var:
            if item is Dictionary:
                rows.append(item)
    return rows


func _get_character_rows() -> Array[Dictionary]:
    var config: Dictionary = ConfigManager.get_config("characters", {})
    var rows_var: Variant = config.get("characters", [])
    var rows: Array[Dictionary] = []
    if rows_var is Array:
        for item: Variant in rows_var:
            if item is Dictionary:
                rows.append(item)
    return rows


func _get_default_character_id() -> String:
    var config: Dictionary = ConfigManager.get_config("characters", {})
    return str(config.get("default_character_id", "char_knight"))


func _sync_character_cursor_from_save() -> void:
    var rows: Array[Dictionary] = _get_character_rows()
    if rows.is_empty():
        _character_cursor = 0
        return

    var selected_id: String = _get_default_character_id()
    if SaveManager != null and SaveManager.has_method("get_selected_character_id"):
        selected_id = SaveManager.get_selected_character_id()
    if selected_id == "":
        selected_id = _get_default_character_id()

    var matched_index: int = -1
    for i in range(rows.size()):
        var row: Dictionary = rows[i]
        if str(row.get("id", "")) == selected_id and _is_character_row_unlocked(row):
            matched_index = i
            break

    if matched_index >= 0:
        _character_cursor = matched_index
        _apply_selected_character()
        return

    var fallback_index: int = _get_first_unlocked_character_index(rows)
    if fallback_index >= 0:
        _character_cursor = fallback_index
        _apply_selected_character()
        return

    _character_cursor = 0


func _refresh_character_preview() -> void:
    var rows: Array[Dictionary] = _get_character_rows()
    if rows.is_empty():
        if _character_prev_button != null:
            _character_prev_button.disabled = true
        if _character_next_button != null:
            _character_next_button.disabled = true
        _character_name_value.text = "Character: Missing config"
        _character_desc_value.text = "No character definitions found in data/balance/characters.json"
        _character_stats_value.text = "-"
        _character_trait_value.text = "Trait: -"
        _character_unlock_value.text = "Status: -"
        _character_unlock_value.modulate = Color(1, 1, 1, 1)
        return

    _character_cursor = posmod(_character_cursor, rows.size())
    if _character_prev_button != null:
        _character_prev_button.disabled = rows.size() <= 1
    if _character_next_button != null:
        _character_next_button.disabled = rows.size() <= 1

    var row: Dictionary = rows[_character_cursor]
    var is_unlocked: bool = _is_character_row_unlocked(row)
    var char_name: String = str(row.get("name", row.get("id", "Unknown")))
    var char_desc: String = str(row.get("description", ""))
    var lock_suffix: String = ""
    if not is_unlocked:
        lock_suffix = " [LOCKED]"
    _character_name_value.text = "Character (%d/%d): %s%s" % [_character_cursor + 1, rows.size(), char_name, lock_suffix]
    _character_desc_value.text = char_desc
    _character_stats_value.text = "HP %d | SPD %d | DMG %.1f | ATK %.2fs | ARM %.0f%% | CRIT %.0f%%" % [
        int(row.get("max_hp", 100)),
        int(row.get("move_speed", 180)),
        float(row.get("base_damage", 12.0)),
        float(row.get("attack_interval", 0.45)),
        float(row.get("armor", 0.0)) * 100.0,
        float(row.get("crit_chance", 0.08)) * 100.0
    ]
    _character_stats_value.text += "\nWeapon: %s" % _get_character_weapon_style_text(row)
    var trait_name: String = str(row.get("trait_name", "No Trait"))
    var trait_desc: String = str(row.get("trait_desc", "No additional effects."))
    _character_trait_value.text = "Trait: %s — %s" % [trait_name, trait_desc]
    if is_unlocked:
        _character_unlock_value.text = "Status: Unlocked"
        _character_unlock_value.modulate = Color(0.60, 0.95, 0.66, 1.0)
    else:
        _character_unlock_value.text = "Status: Locked — %s" % _get_character_unlock_hint(row)
        _character_unlock_value.modulate = Color(1.0, 0.62, 0.62, 1.0)
    _apply_selected_character()


func _apply_selected_character() -> bool:
    var rows: Array[Dictionary] = _get_character_rows()
    if rows.is_empty():
        return false
    _character_cursor = posmod(_character_cursor, rows.size())
    var row: Dictionary = rows[_character_cursor]
    if not _is_character_row_unlocked(row):
        return false

    var selected_id: String = str(row.get("id", _get_default_character_id()))
    if selected_id == "":
        selected_id = _get_default_character_id()
    GameManager.selected_character_id = selected_id
    if SaveManager != null and SaveManager.has_method("set_selected_character_id"):
        SaveManager.set_selected_character_id(selected_id)
    var profile_var: Variant = row.get("weapon_profile", {})
    if profile_var is Dictionary and SaveManager != null and SaveManager.has_method("unlock_codex_entry"):
            var style_id: String = str((profile_var as Dictionary).get("projectile_style", "")).strip_edges()
            if style_id != "":
                if not style_id.begins_with("wpn_"):
                    style_id = "wpn_%s" % style_id
                SaveManager.unlock_codex_entry("weapons", style_id, "character_select", "global")
    return true


func _get_first_unlocked_character_index(rows: Array[Dictionary]) -> int:
    for i in range(rows.size()):
        if _is_character_row_unlocked(rows[i]):
            return i
    return -1


func _is_character_row_unlocked(row: Dictionary) -> bool:
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
            var needed_runs: int = int(unlock_value)
            return int(SaveManager.get_meta_data().get("total_runs", 0)) >= needed_runs
        _:
            return true


func _get_character_unlock_hint(row: Dictionary) -> String:
    var custom_hint: String = str(row.get("unlock_desc", ""))
    if custom_hint != "":
        return custom_hint

    var unlock_type: String = str(row.get("unlock_type", "default"))
    var unlock_value: String = str(row.get("unlock_value", ""))
    match unlock_type:
        "default":
            return "Default unlocked"
        "achievement":
            return "Unlock achievement: %s" % unlock_value
        "ending":
            return "Unlock ending: %s" % unlock_value
        "meta_runs":
            return "Complete %s runs" % unlock_value
        _:
            return "Unavailable"


func _get_character_weapon_style_text(row: Dictionary) -> String:
    var profile_var: Variant = row.get("weapon_profile", {})
    if not (profile_var is Dictionary):
        return "Single Shot"

    var profile: Dictionary = profile_var
    var mode: String = str(profile.get("mode", "single")).to_lower()
    var count: int = max(1, int(profile.get("projectile_count", 1)))
    var hits: int = max(1, int(profile.get("projectile_hits", 1)))
    var spread: float = maxf(0.0, float(profile.get("spread_angle_deg", 0.0)))
    var jitter: float = maxf(0.0, float(profile.get("spread_jitter_deg", 0.0)))
    var style: String = str(profile.get("projectile_style", "default"))

    if mode == "spread":
        return "Spread x%d (%.0f deg +/- %.1f), Hits %d, Style %s" % [count, spread, jitter, hits, style]
    return "Single x%d, Hits %d, Style %s" % [count, hits, style]


func _open_codex_overlay() -> void:
    if _codex_overlay == null:
        return
    _codex_overlay.visible = true
    _codex_entry_index = 0
    _refresh_codex_overlay()


func _close_codex_overlay() -> void:
    if _codex_overlay == null:
        return
    _codex_overlay.visible = false


func _shift_codex_category(delta: int) -> void:
    if CODEX_CATEGORIES.is_empty():
        return
    _codex_category_index = posmod(_codex_category_index + delta, CODEX_CATEGORIES.size())
    _codex_entry_index = 0
    _refresh_codex_overlay()


func _shift_codex_entry(delta: int) -> void:
    var category: String = CODEX_CATEGORIES[posmod(_codex_category_index, CODEX_CATEGORIES.size())]
    var catalog: Array[Dictionary] = _build_codex_catalog(category)
    if catalog.is_empty():
        _codex_entry_index = 0
        _refresh_codex_overlay()
        return
    _codex_entry_index = posmod(_codex_entry_index + delta, catalog.size())
    _refresh_codex_overlay()


func _refresh_codex_overlay() -> void:
    if _codex_title == null or _codex_content == null:
        return
    if CODEX_CATEGORIES.is_empty():
        _codex_title.text = "Codex"
        _codex_content.text = "No codex categories configured"
        return

    _codex_category_index = posmod(_codex_category_index, CODEX_CATEGORIES.size())
    var category: String = CODEX_CATEGORIES[_codex_category_index]
    var codex: Dictionary = SaveManager.get_codex()
    var rows: Array[String] = []
    if codex.has(category):
        rows = _as_string_array(codex.get(category, []))

    var catalog: Array[Dictionary] = _build_codex_catalog(category)
    var unlocked_set: Dictionary = _to_string_set(rows)
    var unlocked_count: int = 0
    for item: Dictionary in catalog:
        if unlocked_set.has(str(item.get("id", ""))):
            unlocked_count += 1

    var category_name: String = str(CODEX_CATEGORY_NAMES.get(category, category.capitalize()))
    _codex_title.text = "Codex [%d/%d] - %s (%d/%d)" % [
        _codex_category_index + 1,
        CODEX_CATEGORIES.size(),
        category_name,
        unlocked_count,
        max(1, catalog.size())
    ]

    if _codex_prev_button != null:
        _codex_prev_button.disabled = CODEX_CATEGORIES.size() <= 1
    if _codex_next_button != null:
        _codex_next_button.disabled = CODEX_CATEGORIES.size() <= 1

    if not catalog.is_empty():
        _codex_entry_index = posmod(_codex_entry_index, catalog.size())
    else:
        _codex_entry_index = 0

    if _codex_entry_prev_button != null:
        _codex_entry_prev_button.disabled = catalog.size() <= 1
    if _codex_entry_next_button != null:
        _codex_entry_next_button.disabled = catalog.size() <= 1

    var lines: Array[String] = []
    lines.append("Unlocked %d / %d" % [unlocked_count, max(1, catalog.size())])
    if catalog.is_empty() and rows.is_empty():
        lines.append("-")
    else:
        for i in range(catalog.size()):
            var item: Dictionary = catalog[i]
            var entry_id: String = str(item.get("id", ""))
            var entry_name: String = str(item.get("name", _get_codex_entry_name(category, entry_id)))
            var hint: String = str(item.get("hint", ""))
            var mark: String = "[x]"
            if not unlocked_set.has(entry_id):
                mark = "[ ]"
            var pointer: String = "  "
            if i == _codex_entry_index:
                pointer = "> "
            var row_text: String = "%s%s %s" % [pointer, mark, entry_name]
            if mark == "[ ]" and hint != "":
                row_text += "  (%s)" % hint
            lines.append(row_text)

        for entry_id: String in rows:
            if _catalog_has_entry(catalog, entry_id):
                continue
            lines.append("[x] %s" % _get_codex_entry_name(category, entry_id))

    _codex_content.text = "\n".join(PackedStringArray(lines))
    _codex_detail.text = _build_codex_detail_text(category, catalog, unlocked_set)
    _refresh_codex_stats_panel()


func _refresh_codex_stats_panel() -> void:
    if _codex_stats_value == null:
        return

    var codex: Dictionary = SaveManager.get_codex()
    var lines: Array[String] = []
    lines.append("Codex Statistics")

    var global_total: int = 0
    var global_unlocked: int = 0

    for category: String in CODEX_CATEGORIES:
        var catalog: Array[Dictionary] = _build_codex_catalog(category)
        var total: int = catalog.size()
        var unlocked_rows: Array[String] = _as_string_array(codex.get(category, []))
        var unlocked_set: Dictionary = _to_string_set(unlocked_rows)
        var unlocked: int = 0
        for row: Dictionary in catalog:
            var entry_id: String = str(row.get("id", ""))
            if unlocked_set.has(entry_id):
                unlocked += 1

        global_total += total
        global_unlocked += unlocked

        var category_name: String = str(CODEX_CATEGORY_NAMES.get(category, category.capitalize()))
        lines.append("- %s %d/%d %s" % [
            category_name,
            unlocked,
            max(1, total),
            _build_progress_bar(unlocked, total, 14)
        ])

    lines.append("Global %d/%d %s" % [
        global_unlocked,
        max(1, global_total),
        _build_progress_bar(global_unlocked, global_total, 18)
    ])

    lines.append("Chapter Completion:")
    var chapter_progress: Array[Dictionary] = _build_chapter_completion_rows(codex)
    for row: Dictionary in chapter_progress:
        lines.append("- %s %d/%d %s" % [
            str(row.get("label", "Global")),
            int(row.get("unlocked", 0)),
            max(1, int(row.get("total", 0))),
            _build_progress_bar(int(row.get("unlocked", 0)), int(row.get("total", 0)), 12)
        ])

    var source_filter: Dictionary = _get_codex_source_filter_row()
    var chapter_filter: Dictionary = _get_codex_chapter_filter_row()
    var source_filter_id: String = str(source_filter.get("id", "all"))
    var chapter_filter_id: String = str(chapter_filter.get("id", "all"))

    if _codex_stats_source_button != null:
        _codex_stats_source_button.text = "Source: %s (5)" % str(source_filter.get("label", "All Sources"))
    if _codex_stats_chapter_button != null:
        _codex_stats_chapter_button.text = "Chapter: %s (6)" % str(chapter_filter.get("label", "All Chapters"))

    lines.append("Recent Unlocks (last 5):")
    lines.append("Filters -> Source: %s | Chapter: %s" % [
        str(source_filter.get("label", "All Sources")),
        str(chapter_filter.get("label", "All Chapters"))
    ])

    var filtered_recent: Array[Dictionary] = []
    var recent_rows: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(64)
    for row: Dictionary in recent_rows:
        if source_filter_id != "all":
            var row_source: String = str(row.get("source", ""))
            if row_source != source_filter_id:
                continue

        if chapter_filter_id != "all":
            var row_category: String = str(row.get("category", ""))
            var row_entry_id: String = str(row.get("entry_id", ""))
            var row_chapter: String = _normalize_codex_chapter_id(str(row.get("chapter_id", "")))
            if row_chapter == "":
                row_chapter = _resolve_codex_entry_chapter(row_category, row_entry_id)
            if row_chapter != chapter_filter_id:
                continue

        filtered_recent.append(row)
        if filtered_recent.size() >= 5:
            break

    if filtered_recent.is_empty():
        lines.append("- No entries match current filters")
    else:
        for row: Dictionary in filtered_recent:
            var category: String = str(row.get("category", ""))
            var entry_id: String = str(row.get("entry_id", ""))
            var source: String = str(row.get("source", ""))
            var discovered_at: String = str(row.get("discovered_at", ""))
            var chapter_id: String = _normalize_codex_chapter_id(str(row.get("chapter_id", "")))
            if chapter_id == "":
                chapter_id = _resolve_codex_entry_chapter(category, entry_id)
            var category_name: String = str(CODEX_CATEGORY_NAMES.get(category, category.capitalize()))
            var entry_name: String = _get_codex_entry_name(category, entry_id)
            var when_text: String = discovered_at
            if when_text == "":
                when_text = "time-unknown"
            lines.append("- [%s] %s | %s | %s | %s" % [
                category_name,
                entry_name,
                _prettify_source(source),
                _prettify_chapter_id(chapter_id),
                when_text
            ])

    _codex_stats_value.text = "\n".join(PackedStringArray(lines))


func _cycle_codex_stats_source_filter(delta: int) -> void:
    if CODEX_SOURCE_FILTERS.is_empty():
        return
    _codex_stats_source_filter_index = posmod(_codex_stats_source_filter_index + delta, CODEX_SOURCE_FILTERS.size())
    _persist_codex_stats_filters()
    _refresh_codex_stats_panel()


func _cycle_codex_stats_chapter_filter(delta: int) -> void:
    if CODEX_CHAPTER_FILTERS.is_empty():
        return
    _codex_stats_chapter_filter_index = posmod(_codex_stats_chapter_filter_index + delta, CODEX_CHAPTER_FILTERS.size())
    _persist_codex_stats_filters()
    _refresh_codex_stats_panel()


func _sync_codex_stats_filters_from_save() -> void:
    if SaveManager == null or not SaveManager.has_method("get_codex_stats_filters"):
        return

    var filters: Dictionary = SaveManager.get_codex_stats_filters()
    var source_id: String = str(filters.get("source", "all"))
    var chapter_id: String = str(filters.get("chapter", "all"))

    _codex_stats_source_filter_index = _find_filter_index(CODEX_SOURCE_FILTERS, source_id)
    _codex_stats_chapter_filter_index = _find_filter_index(CODEX_CHAPTER_FILTERS, chapter_id)


func _persist_codex_stats_filters() -> void:
    if SaveManager == null or not SaveManager.has_method("set_codex_stats_filters"):
        return

    var source_row: Dictionary = _get_codex_source_filter_row()
    var chapter_row: Dictionary = _get_codex_chapter_filter_row()
    SaveManager.set_codex_stats_filters(
        str(source_row.get("id", "all")),
        str(chapter_row.get("id", "all"))
    )


func _find_filter_index(rows: Array[Dictionary], target_id: String) -> int:
    if rows.is_empty():
        return 0
    for i in range(rows.size()):
        if str(rows[i].get("id", "")) == target_id:
            return i
    return 0


func _get_codex_source_filter_row() -> Dictionary:
    if CODEX_SOURCE_FILTERS.is_empty():
        return {"id": "all", "label": "All Sources"}
    _codex_stats_source_filter_index = posmod(_codex_stats_source_filter_index, CODEX_SOURCE_FILTERS.size())
    return CODEX_SOURCE_FILTERS[_codex_stats_source_filter_index]


func _get_codex_chapter_filter_row() -> Dictionary:
    if CODEX_CHAPTER_FILTERS.is_empty():
        return {"id": "all", "label": "All Chapters"}
    _codex_stats_chapter_filter_index = posmod(_codex_stats_chapter_filter_index, CODEX_CHAPTER_FILTERS.size())
    return CODEX_CHAPTER_FILTERS[_codex_stats_chapter_filter_index]


func _resolve_codex_entry_chapter(category: String, entry_id: String) -> String:
    if SaveManager != null and SaveManager.has_method("get_codex_entry_meta"):
        var meta: Dictionary = SaveManager.get_codex_entry_meta(category, entry_id)
        var chapter_from_meta: String = _normalize_codex_chapter_id(str(meta.get("chapter_id", "")))
        if chapter_from_meta != "":
            return chapter_from_meta

    match category:
        "enemies":
            match entry_id:
                "boss_rock_colossus":
                    return "chapter_1"
                "boss_flame_lord":
                    return "chapter_2"
                "boss_frost_king":
                    return "chapter_3"
                "boss_void_lord":
                    return "chapter_4"
                _:
                    return "global"
        "accessories":
            match entry_id:
                "acc_heart_of_mine":
                    return "chapter_1"
                "acc_flame_core":
                    return "chapter_2"
                "acc_zero_mark":
                    return "chapter_3"
                "acc_void_eye":
                    return "chapter_4"
                _:
                    return "global"
        _:
            return "global"


func _build_chapter_completion_rows(codex: Dictionary) -> Array[Dictionary]:
    var chapter_order: Array[String] = []
    for row: Dictionary in CODEX_CHAPTER_FILTERS:
        var chapter_id: String = str(row.get("id", ""))
        if chapter_id == "" or chapter_id == "all":
            continue
        chapter_order.append(chapter_id)

    var totals: Dictionary = {}
    var unlocked: Dictionary = {}
    for chapter_id: String in chapter_order:
        totals[chapter_id] = 0
        unlocked[chapter_id] = 0

    for category: String in CODEX_CATEGORIES:
        var catalog: Array[Dictionary] = _build_codex_catalog(category)
        if catalog.is_empty():
            continue

        var unlocked_rows: Array[String] = _as_string_array(codex.get(category, []))
        var unlocked_set: Dictionary = _to_string_set(unlocked_rows)
        for item: Dictionary in catalog:
            var entry_id: String = str(item.get("id", ""))
            var chapter_id: String = _resolve_codex_entry_chapter(category, entry_id)
            if not totals.has(chapter_id):
                chapter_id = "global"
            totals[chapter_id] = int(totals.get(chapter_id, 0)) + 1
            if unlocked_set.has(entry_id):
                unlocked[chapter_id] = int(unlocked.get(chapter_id, 0)) + 1

    var rows: Array[Dictionary] = []
    for chapter_id: String in chapter_order:
        rows.append({
            "id": chapter_id,
            "label": _prettify_chapter_id(chapter_id),
            "unlocked": int(unlocked.get(chapter_id, 0)),
            "total": int(totals.get(chapter_id, 0))
        })
    return rows


func _normalize_codex_chapter_id(value: String) -> String:
    var chapter_id: String = value.strip_edges().to_lower()
    if chapter_id == "":
        return ""
    for row: Dictionary in CODEX_CHAPTER_FILTERS:
        if str(row.get("id", "")) == chapter_id:
            return chapter_id
    return ""


func _prettify_chapter_id(chapter_id: String) -> String:
    match chapter_id:
        "chapter_1":
            return "Chapter 1"
        "chapter_2":
            return "Chapter 2"
        "chapter_3":
            return "Chapter 3"
        "chapter_4":
            return "Chapter 4"
        _:
            return "Global"


func _build_progress_bar(current: int, total: int, width: int) -> String:
    var safe_total: int = maxi(0, total)
    var safe_current: int = clampi(current, 0, safe_total)
    var safe_width: int = maxi(4, width)
    var ratio: float = 0.0
    if safe_total > 0:
        ratio = float(safe_current) / float(safe_total)
    var filled: int = int(round(ratio * safe_width))
    filled = clampi(filled, 0, safe_width)
    var bar: String = "["
    bar += "#".repeat(filled)
    bar += "-".repeat(safe_width - filled)
    bar += "]"
    return "%s %3d%%" % [bar, int(round(ratio * 100.0))]


func _get_codex_entry_name(category: String, entry_id: String) -> String:
    match category:
        "characters":
            return _lookup_character_name(entry_id)
        "weapons":
            return _lookup_weapon_name(entry_id)
        "passives":
            return str(PASSIVE_NAME_MAP.get(entry_id, _prettify_id(entry_id)))
        "enemies":
            return str(ENEMY_NAME_MAP.get(entry_id, _prettify_id(entry_id)))
        "accessories":
            return str(ACCESSORY_NAME_MAP.get(entry_id, _prettify_id(entry_id)))
        _:
            return _prettify_id(entry_id)


func _build_codex_catalog(category: String) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    match category:
        "characters":
            var rows: Array[Dictionary] = _get_character_rows()
            for row: Dictionary in rows:
                var character_id: String = str(row.get("id", "")).strip_edges()
                if character_id == "":
                    continue
                result.append({
                    "id": character_id,
                    "name": str(row.get("name", _prettify_id(character_id))),
                    "hint": _get_character_unlock_hint(row)
                })
        "weapons":
            var map: Dictionary = _build_weapon_name_map()
            var keys: Array[String] = _sorted_string_keys(map)
            for weapon_id: String in keys:
                result.append({
                    "id": weapon_id,
                    "name": str(map.get(weapon_id, _prettify_id(weapon_id))),
                    "hint": "Unlock by selecting a character using this style"
                })
        "passives":
            var passive_keys: Array[String] = _sorted_string_keys(PASSIVE_NAME_MAP)
            for passive_id: String in passive_keys:
                result.append({
                    "id": passive_id,
                    "name": str(PASSIVE_NAME_MAP.get(passive_id, passive_id)),
                    "hint": "Choose this upgrade during level up"
                })
        "enemies":
            var enemy_keys: Array[String] = _sorted_string_keys(ENEMY_NAME_MAP)
            for enemy_id: String in enemy_keys:
                result.append({
                    "id": enemy_id,
                    "name": str(ENEMY_NAME_MAP.get(enemy_id, enemy_id)),
                    "hint": "Defeat this enemy type"
                })
        "accessories":
            var accessory_keys: Array[String] = _sorted_string_keys(ACCESSORY_NAME_MAP)
            for accessory_id: String in accessory_keys:
                result.append({
                    "id": accessory_id,
                    "name": str(ACCESSORY_NAME_MAP.get(accessory_id, accessory_id)),
                    "hint": "Acquire from boss/event drops"
                })
        _:
            pass
    return result


func _catalog_has_entry(catalog: Array[Dictionary], entry_id: String) -> bool:
    for row: Dictionary in catalog:
        if str(row.get("id", "")) == entry_id:
            return true
    return false


func _sorted_string_keys(source: Dictionary) -> Array[String]:
    var out: Array[String] = []
    for key: Variant in source.keys():
        out.append(str(key))
    out.sort()
    return out


func _to_string_set(rows: Array[String]) -> Dictionary:
    var set_map: Dictionary = {}
    for row: String in rows:
        set_map[row] = true
    return set_map


func _build_codex_detail_text(category: String, catalog: Array[Dictionary], unlocked_set: Dictionary) -> String:
    if catalog.is_empty():
        return "Entry Detail\n-"

    var item: Dictionary = catalog[_codex_entry_index]
    var entry_id: String = str(item.get("id", ""))
    var entry_name: String = str(item.get("name", entry_id))
    var hint: String = str(item.get("hint", ""))
    var unlocked: bool = unlocked_set.has(entry_id)

    var meta: Dictionary = {}
    if SaveManager != null and SaveManager.has_method("get_codex_entry_meta"):
        meta = SaveManager.get_codex_entry_meta(category, entry_id)

    var source: String = str(meta.get("source", ""))
    var chapter_id: String = _normalize_codex_chapter_id(str(meta.get("chapter_id", "")))
    var discovered_at: String = str(meta.get("discovered_at", ""))
    var run_index: int = int(meta.get("run_index", 0))

    var lines: Array[String] = []
    lines.append("Entry Detail")
    lines.append("Name: %s" % entry_name)
    lines.append("Status: %s" % ("Unlocked" if unlocked else "Locked"))
    lines.append("ID: %s" % entry_id)
    if hint != "":
        lines.append("Hint: %s" % hint)

    if unlocked:
        if source != "":
            lines.append("Source: %s" % _prettify_source(source))
        if chapter_id != "":
            lines.append("Chapter: %s" % _prettify_chapter_id(chapter_id))
        if discovered_at != "":
            lines.append("First Discover: %s" % discovered_at)
        if run_index > 0:
            lines.append("Run Index: #%d" % run_index)

    return "\n".join(PackedStringArray(lines))


func _prettify_source(source: String) -> String:
    match source:
        "default":
            return "Default"
        "profile_sync":
            return "Profile Sync"
        "character_select":
            return "Character Selection"
        "run_start":
            return "Run Start"
        "level_up_choice":
            return "Level Up Choice"
        "enemy_kill":
            return "Enemy Defeat"
        "accessory_pickup":
            return "Accessory Pickup"
        _:
            return _prettify_id(source)


func _lookup_character_name(character_id: String) -> String:
    var rows: Array[Dictionary] = _get_character_rows()
    for row: Dictionary in rows:
        if str(row.get("id", "")) == character_id:
            return str(row.get("name", character_id))
    return _prettify_id(character_id)


func _lookup_weapon_name(weapon_id: String) -> String:
    var names: Dictionary = _build_weapon_name_map()
    if names.has(weapon_id):
        return str(names.get(weapon_id, weapon_id))
    return _prettify_id(weapon_id)


func _build_weapon_name_map() -> Dictionary:
    var map: Dictionary = {}
    var rows: Array[Dictionary] = _get_character_rows()
    for row: Dictionary in rows:
        var character_name: String = str(row.get("name", row.get("id", "Character")))
        var profile_var: Variant = row.get("weapon_profile", {})
        if profile_var is Dictionary:
            var profile: Dictionary = profile_var
            var style: String = str(profile.get("projectile_style", "default")).strip_edges()
            if style != "":
                var weapon_key: String = style
                if not weapon_key.begins_with("wpn_"):
                    weapon_key = "wpn_%s" % weapon_key
                map[weapon_key] = "%s Signature Weapon" % character_name
    return map


func _prettify_id(raw_id: String) -> String:
    var text: String = raw_id
    if text.begins_with("char_") or text.begins_with("wpn_") or text.begins_with("acc_") or text.begins_with("enemy_"):
        var parts: PackedStringArray = text.split("_", false, 1)
        if parts.size() == 2:
            text = parts[1]
    text = text.replace("_", " ")
    return text.capitalize()


func _as_string_array(value: Variant) -> Array[String]:
    var out: Array[String] = []
    if value is Array:
        for item: Variant in value:
            var row: String = str(item).strip_edges()
            if row != "":
                out.append(row)
    return out


func _refresh_fragment_review() -> void:
    var unlocked_fragments: Array[String] = SaveManager.get_unlocked_fragments()
    if unlocked_fragments.is_empty():
        _review_fragment_button.disabled = true
        _fragment_review_value.text = "Memory Archive: no fragments unlocked yet"
        _fragment_cursor = 0
        return

    _review_fragment_button.disabled = false
    _fragment_cursor = posmod(_fragment_cursor, unlocked_fragments.size())
    var fragment_id: String = unlocked_fragments[_fragment_cursor]

    var fragment_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("memory_fragments", {})
    var row: Dictionary = {}
    if fragment_rows_var is Dictionary:
        var row_var: Variant = (fragment_rows_var as Dictionary).get(fragment_id, {})
        if row_var is Dictionary:
            row = row_var

    var title: String = str(row.get("title", fragment_id))
    var text: String = str(row.get("text", "No memory text."))
    _fragment_review_value.text = "Memory Archive (%d/%d)\n%s\n%s" % [
        _fragment_cursor + 1,
        unlocked_fragments.size(),
        title,
        text
    ]


func _refresh_ending_review() -> void:
    var unlocked_endings: Array[String] = _get_ordered_unlocked_endings()
    if unlocked_endings.is_empty():
        _review_ending_button.disabled = true
        _review_ending_button.text = "Review Next Ending"
        _ending_review_value.text = "Ending Archive: no endings unlocked yet"
        _ending_cursor = 0
        _apply_ending_theme("")
        return

    _review_ending_button.disabled = false
    _ending_cursor = posmod(_ending_cursor, unlocked_endings.size())
    var ending_id: String = unlocked_endings[_ending_cursor]

    var ending_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("endings", {})
    var row: Dictionary = {}
    if ending_rows_var is Dictionary:
        var row_var: Variant = (ending_rows_var as Dictionary).get(ending_id, {})
        if row_var is Dictionary:
            row = row_var

    var title: String = str(row.get("title", ending_id))
    var story: String = str(row.get("story", "No ending story."))
    var first_unlock: String = str(row.get("epilogue_first_unlock", "-"))
    var repeat_unlock: String = str(row.get("epilogue_repeat", "-"))
    _apply_ending_theme(ending_id)
    _ending_review_value.text = "Ending Archive (%d/%d)\n%s\nStory: %s\nFirst Unlock: %s\nRepeat: %s" % [
        _ending_cursor + 1,
        unlocked_endings.size(),
        title,
        story,
        first_unlock,
        repeat_unlock
    ]


func _get_ordered_unlocked_endings() -> Array[String]:
    var unlocked: Array[String] = SaveManager.get_unlocked_endings()
    var ordered: Array[String] = []
    var preferred: Array[String] = [
        "nar_ending_redeem",
        "nar_ending_fall",
        "nar_ending_balance"
    ]

    for item: Variant in preferred:
        var ending_id: String = str(item)
        if unlocked.has(ending_id):
            ordered.append(ending_id)

    for item: Variant in unlocked:
        var ending_id: String = str(item)
        if not ordered.has(ending_id):
            ordered.append(ending_id)

    return ordered


func _apply_ending_theme(ending_id: String) -> void:
    var theme: Dictionary = _get_ending_theme(ending_id)
    var tint: Color = theme.get("accent", ENDING_THEME_DEFAULT["accent"])
    var band_top: Color = theme.get("band_top", ENDING_THEME_DEFAULT["band_top"])
    var band_bottom: Color = theme.get("band_bottom", ENDING_THEME_DEFAULT["band_bottom"])
    var icon: String = str(theme.get("icon", ENDING_THEME_DEFAULT["icon"]))
    var title: String = str(theme.get("title", ENDING_THEME_DEFAULT["title"]))

    if _ending_review_value != null:
        _ending_review_value.modulate = tint
    if _review_ending_button != null:
        _review_ending_button.modulate = tint
        _review_ending_button.text = "Review Next Ending %s" % icon
    if _ending_theme_header != null:
        _ending_theme_header.modulate = tint
        _ending_theme_header.text = "%s  Theme: %s" % [icon, title]
    if _ending_theme_band_top != null:
        _ending_theme_band_top.color = band_top
    if _ending_theme_band_bottom != null:
        _ending_theme_band_bottom.color = band_bottom


func _get_ending_theme(ending_id: String) -> Dictionary:
    if ENDING_THEME_MAP.has(ending_id):
        return ENDING_THEME_MAP[ending_id]
    return ENDING_THEME_DEFAULT


func _open_settings_overlay() -> void:
    if _settings_overlay == null:
        return
    _settings_overlay.visible = true
    if _runtime_settings_panel != null and _runtime_settings_panel.has_method("sync_from_save"):
        _runtime_settings_panel.sync_from_save()


func _close_settings_overlay() -> void:
    if _settings_overlay == null:
        return
    _settings_overlay.visible = false


func _is_settings_capture_active() -> bool:
    if _runtime_settings_panel == null:
        return false
    if not _runtime_settings_panel.has_method("is_capturing_input"):
        return false
    return bool(_runtime_settings_panel.is_capturing_input())
