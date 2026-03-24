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

const CODEX_CATEGORIES: Array[String] = ["characters", "weapons", "passives", "enemies", "accessories", "archives"]
const CODEX_CATEGORY_NAMES: Dictionary = {
    "characters": "Characters",
    "weapons": "Weapons",
    "passives": "Passives",
    "enemies": "Enemies",
    "accessories": "Accessories",
    "archives": "Archives"
}
const CODEX_SOURCE_FILTERS: Array[Dictionary] = [
    {"id": "all", "label": "All Sources"},
    {"id": "character_select", "label": "Character Selection"},
    {"id": "run_start", "label": "Run Start"},
    {"id": "level_up_choice", "label": "Level Up Choice"},
    {"id": "enemy_kill", "label": "Enemy Defeat"},
    {"id": "accessory_pickup", "label": "Accessory Pickup"},
    {"id": "difficulty_clear", "label": "Difficulty Clear"},
    {"id": "difficulty_hidden_clear", "label": "Nightmare Hidden Clear"},
    {"id": "hidden_layer_clear", "label": "Hidden Layer Clear"},
    {"id": "hidden_layer_mastery", "label": "Hidden Layer Mastery"}
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
const ARCHIVE_CODEX_ENTRIES: Array[Dictionary] = [
    {
        "id": "fs1_echo_archive",
        "name": "Time Rift Archive",
        "hint": "Clear Time Rift once to preserve the fracture archive.",
        "layer_id": "FS1",
        "entry_kind": "clear"
    },
    {
        "id": "fs1_echo_mastery",
        "name": "Time Rift Mastery",
        "hint": "Collect all four echo bosses across Time Rift runs.",
        "layer_id": "FS1",
        "entry_kind": "mastery"
    },
    {
        "id": "fs2_trial_archive",
        "name": "Genesis Forge Archive",
        "hint": "Clear Genesis Forge once to stabilize the forge archive.",
        "layer_id": "FS2",
        "entry_kind": "clear"
    },
    {
        "id": "fs2_trial_mastery",
        "name": "Genesis Forge Mastery",
        "hint": "Archive all five forge trials across Genesis Forge runs.",
        "layer_id": "FS2",
        "entry_kind": "mastery"
    },
    {
        "id": "hard_clear_archive",
        "name": "Hard Archive",
        "hint": "Clear any run on Hard difficulty.",
        "difficulty_tier": 1,
        "entry_kind": "difficulty_clear"
    },
    {
        "id": "nightmare_clear_archive",
        "name": "Nightmare Archive",
        "hint": "Clear any run on Nightmare difficulty.",
        "difficulty_tier": 2,
        "entry_kind": "difficulty_clear"
    },
    {
        "id": "nightmare_hidden_archive",
        "name": "Nightmare Hidden Archive",
        "hint": "Clear any hidden layer on Nightmare difficulty.",
        "difficulty_tier": 2,
        "entry_kind": "difficulty_hidden"
    }
]

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
    var new_codex_count: int = 0
    var new_codex_var: Variant = last_run.get("new_codex_unlocks", [])
    if new_codex_var is Array:
        new_codex_count = (new_codex_var as Array).size()
    var new_difficulty_count: int = 0
    var new_difficulty_var: Variant = last_run.get("new_difficulty_unlocks", [])
    if new_difficulty_var is Array:
        new_difficulty_count = (new_difficulty_var as Array).size()
    var new_meta_return_count: int = 0
    var new_meta_return_var: Variant = last_run.get("new_meta_return_unlocks", [])
    if new_meta_return_var is Array:
        new_meta_return_count = (new_meta_return_var as Array).size()
    var difficulty_label: String = str(last_run.get("difficulty_label", "")).strip_edges()
    if difficulty_label == "":
        difficulty_label = "Normal"
    var difficulty_summary: String = str(last_run.get("difficulty_summary", "")).strip_edges()
    var challenge_difficulty_summary: String = difficulty_summary
    var meta_return_summary: String = str(last_run.get("meta_return_summary", "")).strip_edges()
    var meta_return_next_hint: String = str(last_run.get("meta_return_next_hint", "")).strip_edges()
    var challenge_layer_id: String = str(last_run.get("challenge_layer_id", "")).strip_edges().to_upper()
    var challenge_layer_title: String = str(last_run.get("challenge_layer_title", "Challenge Layer")).strip_edges()
    var challenge_layer_phase: String = str(last_run.get("challenge_layer_phase", "")).strip_edges()
    var challenge_reward_title: String = str(last_run.get("challenge_layer_reward_title", "")).strip_edges()
    var challenge_reward_payload: Variant = last_run.get("challenge_layer_reward_payload", {})
    var challenge_reward_summary: String = str(last_run.get("challenge_layer_reward_summary", "")).strip_edges()
    var challenge_settlement_summary: String = str(last_run.get("challenge_layer_settlement_summary", "")).strip_edges()
    var challenge_layer_rooms_cleared: int = int(last_run.get("challenge_layer_rooms_cleared", 0))
    var challenge_layer_kills: int = int(last_run.get("challenge_layer_kills", 0))
    var challenge_layer_record: Variant = last_run.get("challenge_layer_record", {})
    var fragment_triggers: Variant = last_run.get("fragment_triggers", [])
    var fragment_recap_var: Variant = last_run.get("fragment_recap", {})
    var fragment_recap: Dictionary = fragment_recap_var as Dictionary if fragment_recap_var is Dictionary else {}
    var hidden_layer_hook_var: Variant = last_run.get("hidden_layer_hook", {})
    var hidden_layer_hook: Dictionary = hidden_layer_hook_var as Dictionary if hidden_layer_hook_var is Dictionary else {}
    var hidden_layer_story_var: Variant = last_run.get("hidden_layer_story", {})
    var hidden_layer_story: Dictionary = hidden_layer_story_var as Dictionary if hidden_layer_story_var is Dictionary else {}
    var hidden_layer_statuses_var: Variant = last_run.get("hidden_layer_statuses", {})
    var hidden_layer_statuses: Dictionary = hidden_layer_statuses_var as Dictionary if hidden_layer_statuses_var is Dictionary else {}
    var hidden_layer_id: String = str(last_run.get("hidden_layer_id", "")).strip_edges().to_upper()
    var hidden_layer_reward_summary: String = str(last_run.get("hidden_layer_reward_summary", "")).strip_edges()
    var hidden_layer_gameplay: Variant = last_run.get("hidden_layer_gameplay", {})
    var hidden_layer_record: Variant = last_run.get("hidden_layer_record", {})
    var new_hidden_layers: Array[String] = []
    var new_hidden_layers_var: Variant = last_run.get("new_hidden_layers", [])
    if new_hidden_layers_var is Array:
        for item: Variant in new_hidden_layers_var:
            var layer_text: String = str(item).strip_edges().to_upper()
            if layer_text != "":
                new_hidden_layers.append(layer_text)
    var epilogue_branch_var: Variant = last_run.get("epilogue_branch", {})
    var epilogue_branch: Dictionary = epilogue_branch_var as Dictionary if epilogue_branch_var is Dictionary else {}
    var ending_payoff_var: Variant = last_run.get("ending_payoff", {})
    var ending_payoff: Dictionary = ending_payoff_var as Dictionary if ending_payoff_var is Dictionary else {}
    var ending_epilogue: String = str(last_run.get("ending_epilogue", "")).strip_edges()
    var narrative_choices: Variant = last_run.get("narrative_choices", [])
    var chapter_route_styles: Variant = last_run.get("chapter_route_styles", {})
    var route_style_timeline: Variant = last_run.get("route_style_timeline", [])
    var chapter_effect_timeline: Variant = last_run.get("chapter_effect_timeline", [])
    var ending_epilogue_chain: Array[String] = []
    var ending_epilogue_chain_var: Variant = last_run.get("ending_epilogue_chain", [])
    if ending_epilogue_chain_var is Array:
        for item: Variant in ending_epilogue_chain_var:
            var chain_text: String = str(item).strip_edges()
            if chain_text != "":
                ending_epilogue_chain.append(chain_text)

    _last_run_value.text = "Last: %s | Rooms %d | Kills %d | Lv %d | Meta +%d | Diff %s | Ending %s | NewAch %d | NewCodex %d | NewDiff %d | NewReturn %d" % [
        str(last_run.get("outcome", "death")).to_upper(),
        int(last_run.get("rooms_cleared", 0)),
        int(last_run.get("kills", 0)),
        int(last_run.get("level_reached", 1)),
        int(last_run.get("meta_reward", 0)),
        difficulty_label,
        ending_text,
        new_achievements_count,
        new_codex_count,
        new_difficulty_count,
        new_meta_return_count
    ]
    if difficulty_summary != "":
        _last_run_value.text += " | %s" % difficulty_summary
    if meta_return_summary != "":
        _last_run_value.text += " | %s" % meta_return_summary
    if challenge_layer_id != "":
        _last_run_value.text += " | Challenge %s" % challenge_layer_id
    if challenge_reward_title != "":
        _last_run_value.text += " | Reward %s" % challenge_reward_title
    if not fragment_recap.is_empty():
        var recap_title: String = str(fragment_recap.get("title", "Archive Recap")).strip_edges()
        var trigger_count: int = int(fragment_recap.get("trigger_count", 0))
        var new_unlock_count: int = int(fragment_recap.get("new_unlock_count", 0))
        var recap_arc_id: String = str(fragment_recap.get("arc_id", "")).strip_edges().to_upper()
        var recap_style_echo: String = str(fragment_recap.get("style_echo", "")).strip_edges()
        var recap_summary: String = str(fragment_recap.get("summary", "")).strip_edges()
        var recap_pace_hint: String = str(fragment_recap.get("pace_hint", "")).strip_edges()
        var recap_trigger_focus: PackedStringArray = PackedStringArray()
        var recap_trigger_types_var: Variant = fragment_recap.get("trigger_types", [])
        if recap_trigger_types_var is Array:
            for item: Variant in recap_trigger_types_var:
                var trigger_text: String = str(item).strip_edges()
                if trigger_text != "":
                    recap_trigger_focus.append(trigger_text.to_upper())
        _last_run_value.text += " | FragRecap %s %d/%d" % [recap_title, trigger_count, new_unlock_count]
        _last_run_value.text += "\nRecap Stats: triggers=%d | new=%d" % [trigger_count, new_unlock_count]
        if recap_arc_id != "" or recap_style_echo != "":
            var route_parts: PackedStringArray = PackedStringArray()
            if recap_arc_id != "":
                route_parts.append(recap_arc_id)
            if recap_style_echo != "":
                route_parts.append(recap_style_echo)
            _last_run_value.text += "\nRoute Echo: %s" % " | ".join(route_parts)
        if recap_summary != "":
            _last_run_value.text += "\nRecap: %s" % recap_summary
        if recap_pace_hint != "":
            _last_run_value.text += "\nPace: %s" % recap_pace_hint
        if not recap_trigger_focus.is_empty():
            _last_run_value.text += "\nTrigger Focus: %s" % ", ".join(recap_trigger_focus)
        _last_run_value.text += "\nReview Entry: Memory Altar -> Archive Recap"
    if not hidden_layer_hook.is_empty():
        var hidden_target_layer: String = str(hidden_layer_hook.get("target_layer", "FS?")).strip_edges().to_upper()
        var hidden_title: String = str(hidden_layer_hook.get("title", "Unknown Hook")).strip_edges()
        var hidden_status: String = "READY" if bool(hidden_layer_hook.get("ready", false)) else "TRACKING"
        var hidden_teaser: String = str(hidden_layer_hook.get("teaser", "")).strip_edges()
        var hidden_unlock_hint: String = str(hidden_layer_hook.get("unlock_hint", "")).strip_edges()
        var hidden_arc_id: String = str(hidden_layer_hook.get("arc_id", "")).strip_edges().to_upper()
        var hidden_style_echo: String = str(hidden_layer_hook.get("style_echo", "")).strip_edges()
        _last_run_value.text += "\nHidden Route: %s -> %s [%s]" % [hidden_target_layer, hidden_title, hidden_status]
        if hidden_teaser != "":
            _last_run_value.text += "\nHidden Teaser: %s" % hidden_teaser
        if hidden_unlock_hint != "":
            _last_run_value.text += "\nHidden Unlock Hint: %s" % hidden_unlock_hint
        if hidden_arc_id != "" or hidden_style_echo != "":
            var hidden_route_parts: PackedStringArray = PackedStringArray()
            if hidden_arc_id != "":
                hidden_route_parts.append(hidden_arc_id)
            if hidden_style_echo != "":
                hidden_route_parts.append(hidden_style_echo)
            _last_run_value.text += "\nHidden Route Echo: %s" % " | ".join(hidden_route_parts)
        _last_run_value.text += "\nHidden Review Entry: Memory Altar -> Hidden Route Lead"
    if not hidden_layer_story.is_empty():
        var story_layer_id: String = str(hidden_layer_story.get("layer_id", "FS?")).strip_edges().to_upper()
        var story_arc_id: String = str(hidden_layer_story.get("arc_id", "")).strip_edges().to_upper()
        var story_title: String = str(hidden_layer_story.get("title", "Hidden Archive")).strip_edges()
        var story_body: String = str(hidden_layer_story.get("body", "")).strip_edges()
        var story_style_echo: String = str(hidden_layer_story.get("style_echo", "")).strip_edges()
        var story_archive_echo: String = str(hidden_layer_story.get("archive_echo", "")).strip_edges()
        var story_ending_id: String = str(hidden_layer_story.get("ending_id", hidden_layer_story.get("ending_link", ""))).strip_edges()
        var story_fragment_title: String = str(hidden_layer_story.get("fragment_title", hidden_layer_story.get("fragment_id", ""))).strip_edges()
        var story_fragment_text: String = str(hidden_layer_story.get("fragment_text", "")).strip_edges()
        var story_fragment_state: String = "NEW" if bool(hidden_layer_story.get("fragment_newly_unlocked", false)) else "ECHO"
        _last_run_value.text += "\nHidden Story: %s -> %s [%s]" % [story_layer_id, story_title, story_arc_id]
        if story_body != "":
            _last_run_value.text += "\nStory Body: %s" % story_body
        if story_arc_id != "" or story_style_echo != "":
            var story_route_parts: PackedStringArray = PackedStringArray()
            if story_arc_id != "":
                story_route_parts.append(story_arc_id)
            if story_style_echo != "":
                story_route_parts.append(story_style_echo)
            _last_run_value.text += "\nStory Route Echo: %s" % " | ".join(story_route_parts)
        if story_archive_echo != "":
            _last_run_value.text += "\nStory Archive Echo: %s" % story_archive_echo
        if story_ending_id != "":
            _last_run_value.text += "\nStory Ending Link: %s [%s]" % [
                story_ending_id.trim_prefix("nar_ending_").to_upper(),
                "READY" if bool(hidden_layer_story.get("ending_ready", false)) else "TRACKING"
            ]
        if story_fragment_title != "":
            _last_run_value.text += "\nStory Fragment Archive: %s [%s]" % [story_fragment_title, story_fragment_state]
        if story_fragment_text != "":
            _last_run_value.text += "\nStory Fragment Text: %s" % story_fragment_text
        _last_run_value.text += "\nStory Review Entry: Memory Altar -> Hidden Layer Track"
    if not hidden_layer_statuses.is_empty():
        _last_run_value.text += "\nHidden Layers:"
        for layer_id: String in ["FS1", "FS2"]:
            var status_var: Variant = hidden_layer_statuses.get(layer_id, {})
            if not (status_var is Dictionary):
                continue
            var status: Dictionary = status_var
            var state_label: String = "UNLOCKED" if bool(status.get("unlocked", false)) else "LOCKED"
            if new_hidden_layers.has(layer_id):
                state_label = "NEW"
            _last_run_value.text += "\n%s -> %s [%s]" % [
                layer_id,
                str(status.get("title", layer_id)).strip_edges(),
                state_label
            ]
            _last_run_value.text += "\nProgress: %s" % str(status.get("progress_label", "No progress")).strip_edges()
            var status_detail: String = str(status.get("detail", "")).strip_edges()
            if status_detail != "":
                _last_run_value.text += "\nRule: %s" % status_detail
            var status_entry_hint: String = str(status.get("entry_hint", "")).strip_edges()
            if status_entry_hint != "":
                _last_run_value.text += "\nEntry: %s" % status_entry_hint
            var status_reward_summary: String = str(status.get("reward_summary", "")).strip_edges()
            if status_reward_summary != "":
                _last_run_value.text += "\nReward: %s" % status_reward_summary
            var status_settlement_summary: String = str(status.get("settlement_summary", "")).strip_edges()
            if status_settlement_summary != "":
                _last_run_value.text += "\nSettlement: %s" % status_settlement_summary
            var status_record_label: String = str(status.get("record_label", "")).strip_edges()
            if status_record_label != "":
                _last_run_value.text += "\nRecord: %s" % status_record_label
            var status_story_label: String = str(status.get("story_label", "")).strip_edges()
            if status_story_label != "":
                _last_run_value.text += "\nArchive: %s" % status_story_label
            var status_gameplay_label: String = str(status.get("gameplay_label", "")).strip_edges()
            if status_gameplay_label != "":
                _last_run_value.text += "\nGameplay: %s" % status_gameplay_label
            var status_collection_label: String = str(status.get("collection_label", "")).strip_edges()
            if status_collection_label != "":
                _last_run_value.text += "\nCollection: %s" % status_collection_label
            var status_mastery_label: String = str(status.get("mastery_label", "")).strip_edges()
            if status_mastery_label != "":
                _last_run_value.text += "\nMastery: %s" % status_mastery_label
        _last_run_value.text += "\nReview Entry: Memory Altar -> Hidden Layer Track"
    var hidden_layer_clear_summary: String = _build_last_run_hidden_layer_clear_summary(
        hidden_layer_id,
        hidden_layer_reward_summary,
        hidden_layer_gameplay,
        hidden_layer_record
    )
    if hidden_layer_clear_summary != "":
        _last_run_value.text += "\n%s" % hidden_layer_clear_summary
    var challenge_layer_summary: String = _build_last_run_challenge_layer_summary(
        challenge_layer_id,
        challenge_layer_title,
        challenge_layer_phase,
        challenge_reward_title,
        challenge_reward_payload,
        challenge_reward_summary,
        challenge_settlement_summary,
        challenge_difficulty_summary,
        challenge_layer_rooms_cleared,
        challenge_layer_kills,
        challenge_layer_record
    )
    if challenge_layer_summary != "":
        _last_run_value.text += "\n%s" % challenge_layer_summary
    var fragment_trigger_summary: String = _build_last_run_fragment_trigger_summary(fragment_triggers)
    if fragment_trigger_summary != "":
        _last_run_value.text += "\n%s" % fragment_trigger_summary
    var burst_unlocks_summary: String = _build_last_run_burst_unlocks_summary(
        new_achievements_var,
        new_codex_var,
        new_difficulty_var,
        new_meta_return_var
    )
    if burst_unlocks_summary != "":
        _last_run_value.text += "\n%s" % burst_unlocks_summary
    var meta_return_block: String = _build_last_run_meta_return_block(meta_return_summary, meta_return_next_hint)
    if meta_return_block != "":
        _last_run_value.text += "\n%s" % meta_return_block
    var choices_summary: String = _build_last_run_choices_summary(narrative_choices)
    if choices_summary != "":
        _last_run_value.text += "\n%s" % choices_summary
    var route_style_summary: String = _build_last_run_route_style_summary(chapter_route_styles, route_style_timeline)
    if route_style_summary != "":
        _last_run_value.text += "\n%s" % route_style_summary
    var effect_timeline_summary: String = _build_last_run_chapter_effect_timeline_summary(chapter_effect_timeline)
    if effect_timeline_summary != "":
        _last_run_value.text += "\n%s" % effect_timeline_summary
    if not epilogue_branch.is_empty():
        var branch_title: String = str(epilogue_branch.get("title", "Archive Branch")).strip_edges()
        var branch_body: String = str(epilogue_branch.get("body", "")).strip_edges()
        var branch_key: String = str(epilogue_branch.get("branch_key", "")).strip_edges()
        var branch_mode: String = _get_branch_mode_label(branch_key)
        var branch_archive_hook: String = str(epilogue_branch.get("archive_hook", "")).strip_edges()
        var branch_style_echo: String = str(epilogue_branch.get("style_echo", "")).strip_edges()
        _last_run_value.text += "\nEpilogue Branch: %s [%s]" % [branch_title, branch_mode]
        if branch_body != "":
            _last_run_value.text += "\nBranch Body: %s" % branch_body
        if branch_style_echo != "":
            _last_run_value.text += "\nBranch Echo: %s" % branch_style_echo
        if branch_archive_hook != "":
            _last_run_value.text += "\nArchive Hook: %s" % branch_archive_hook
        _last_run_value.text += "\nBranch Review Entry: Ending Archive -> Current Ending"
    if not ending_payoff.is_empty():
        var payoff_title: String = str(ending_payoff.get("title", "Final Payoff")).strip_edges()
        var payoff_summary: String = str(ending_payoff.get("summary", "")).strip_edges()
        var payoff_legacy: String = str(ending_payoff.get("legacy", "")).strip_edges()
        var payoff_fragment_hook: String = str(ending_payoff.get("fragment_hook", "")).strip_edges()
        var payoff_arc_id: String = str(ending_payoff.get("arc_id", "")).strip_edges().to_upper()
        var payoff_style_echo: String = str(ending_payoff.get("style_echo", "")).strip_edges()
        if payoff_title != "":
            _last_run_value.text += "\nEnding Payoff: %s" % payoff_title
        if payoff_arc_id != "" or payoff_style_echo != "":
            var payoff_route_parts: PackedStringArray = PackedStringArray()
            if payoff_arc_id != "":
                payoff_route_parts.append(payoff_arc_id)
            if payoff_style_echo != "":
                payoff_route_parts.append(payoff_style_echo)
            _last_run_value.text += "\nPayoff Echo: %s" % " | ".join(payoff_route_parts)
        if payoff_summary != "":
            _last_run_value.text += "\nPayoff Summary: %s" % payoff_summary
        if payoff_legacy != "":
            _last_run_value.text += "\nLegacy: %s" % payoff_legacy
        if payoff_fragment_hook != "":
            _last_run_value.text += "\nFragment Hook: %s" % payoff_fragment_hook
        _last_run_value.text += "\nPayoff Review Entry: Ending Archive -> Current Ending"
    if ending_epilogue != "":
        _last_run_value.text += "\nEpilogue: %s" % ending_epilogue
        _last_run_value.text += "\nEpilogue Review Entry: Ending Archive -> Current Ending"
    if not ending_epilogue_chain.is_empty():
        _last_run_value.text += "\nEpilogue Chain:"
        for chain_row: String in ending_epilogue_chain:
            _last_run_value.text += "\n- %s" % chain_row
        _last_run_value.text += "\nChain Review Entry: Ending Archive -> Current Ending"


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
        elif reason == "meta_return_locked":
            _shop_message = str(result.get("next_hint", "Meta return milestone required")).strip_edges()
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
        var cap: int = max_level
        var next_hint: String = ""
        if SaveManager != null and SaveManager.has_method("get_meta_upgrade_level_cap"):
            cap = int(SaveManager.get_meta_upgrade_level_cap(upgrade_id))
        if SaveManager != null and SaveManager.has_method("get_meta_upgrade_next_hint"):
            next_hint = str(SaveManager.get_meta_upgrade_next_hint(upgrade_id)).strip_edges()

        if level >= max_level or cost < 0:
            if level >= max_level:
                button.text = "%d) %s Lv.%d/%d (MAX)" % [i + 1, title, level, max_level]
                button.disabled = true
            else:
                button.text = "%d) %s Lv.%d/%d (%s)" % [i + 1, title, level, max_level, next_hint]
                button.disabled = true
        else:
            button.text = "%d) %s Lv.%d/%d  Cost:%d [Cap %d]" % [i + 1, title, level, max_level, cost, cap]
            button.disabled = false

    if _shop_message == "":
        var default_message: String = "Meta Shop: buy permanent upgrades"
        if SaveManager != null and SaveManager.has_method("get_meta_return_profile"):
            var meta_return_profile: Dictionary = SaveManager.get_meta_return_profile()
            var summary: String = str(meta_return_profile.get("summary", "")).strip_edges()
            var next_hint: String = str(meta_return_profile.get("next_hint", "")).strip_edges()
            if summary != "":
                default_message += " | %s" % summary
            if next_hint != "":
                default_message += " | %s" % next_hint
        if SaveManager != null and SaveManager.has_method("get_meta_upgrade_progression_summary"):
            var upgrade_progression: Dictionary = SaveManager.get_meta_upgrade_progression_summary()
            var progression_summary: String = str(upgrade_progression.get("summary", "")).strip_edges()
            var progression_hint: String = str(upgrade_progression.get("next_hint", "")).strip_edges()
            if progression_summary != "":
                default_message += " | %s" % progression_summary
            if progression_hint != "":
                default_message += " | %s" % progression_hint
        _shop_message_value.text = default_message
    else:
        _shop_message_value.text = _shop_message


func _refresh_achievement_list() -> void:
    var rows_var: Variant = ConfigManager.get_config("achievements", {}).get("achievements", [])
    var rows: Array = []
    if rows_var is Array:
        rows = rows_var

    var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
    var achievement_meta: Dictionary = {}
    if SaveManager != null and SaveManager.has_method("get_achievement_meta"):
        achievement_meta = SaveManager.get_achievement_meta()
    var lines: Array[String] = []
    lines.append("Achievements:")
    lines.append("Progress: %d/%d" % [unlocked.size(), rows.size()])
    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var ach_id: String = str(row.get("id", ""))
        var title: String = str(row.get("title", ach_id))
        var mark: String = "[ ]"
        var timeline_suffix: String = ""
        if unlocked.has(ach_id):
            mark = "[x]"
            var meta_row_var: Variant = achievement_meta.get(ach_id, {})
            if meta_row_var is Dictionary:
                var meta_row: Dictionary = meta_row_var as Dictionary
                timeline_suffix = _format_unlock_timeline_suffix(int(meta_row.get("run_index", 0)), str(meta_row.get("discovered_at", "")))
        lines.append("%s %s%s" % [mark, title, timeline_suffix])

    var achievement_group_progress: Array[Dictionary] = _build_achievement_group_progress(rows, unlocked)
    lines.append("Category Progress:")
    for row: Dictionary in achievement_group_progress:
        lines.append("- %s %d/%d" % [
            str(row.get("label", "Run")),
            int(row.get("unlocked", 0)),
            int(row.get("total", 0))
        ])

    var recent_unlocks: Array[Dictionary] = []
    if SaveManager != null and SaveManager.has_method("get_achievement_recent_unlocks"):
        recent_unlocks = SaveManager.get_achievement_recent_unlocks(5)
    lines.append("Recent Group Breakdown:")
    for row: Dictionary in _build_achievement_recent_group_rows(recent_unlocks):
        lines.append("- %s %d" % [
            str(row.get("label", "Run")),
            int(row.get("count", 0))
        ])
    lines.append("Recent Unlocks (last 5):")
    if recent_unlocks.is_empty():
        lines.append("-")
    else:
        for row: Dictionary in recent_unlocks:
            var recent_id: String = str(row.get("achievement_id", "")).strip_edges()
            lines.append("- [%s] %s%s" % [
                _get_achievement_group_label(str(row.get("condition", ""))),
                _get_achievement_title(recent_id),
                _format_unlock_timeline_suffix(int(row.get("run_index", 0)), str(row.get("discovered_at", "")))
            ])

    var endings: Array[String] = SaveManager.get_unlocked_endings()
    var ending_meta: Dictionary = {}
    if SaveManager != null and SaveManager.has_method("get_ending_meta"):
        ending_meta = SaveManager.get_ending_meta()
    var ending_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("endings", {})
    var ending_rows: Dictionary = {}
    if ending_rows_var is Dictionary:
        ending_rows = ending_rows_var
    lines.append("Endings:")
    lines.append("Endings Progress: %d/3" % endings.size())
    lines.append("Recent Endings:")
    if endings.is_empty():
        lines.append("-")
    else:
        var recent_endings: Array[Dictionary] = []
        if SaveManager != null and SaveManager.has_method("get_ending_recent_unlocks"):
            recent_endings = SaveManager.get_ending_recent_unlocks(5)
        if recent_endings.is_empty():
            var ordered_endings: Array[String] = _get_ordered_unlocked_endings()
            for index: int in range(ordered_endings.size() - 1, max(-1, ordered_endings.size() - 6), -1):
                var fallback_ending_id: String = str(ordered_endings[index])
                var fallback_ending_title: String = fallback_ending_id
                var fallback_ending_row_var: Variant = ending_rows.get(fallback_ending_id, {})
                if fallback_ending_row_var is Dictionary:
                    fallback_ending_title = str((fallback_ending_row_var as Dictionary).get("title", fallback_ending_id))
                lines.append("- %s" % fallback_ending_title)
        else:
            for row: Dictionary in recent_endings:
                var recent_ending_id: String = str(row.get("ending_id", "")).strip_edges()
                if recent_ending_id == "":
                    continue
                var recent_ending_title: String = recent_ending_id
                var recent_ending_row_var: Variant = ending_rows.get(recent_ending_id, {})
                if recent_ending_row_var is Dictionary:
                    recent_ending_title = str((recent_ending_row_var as Dictionary).get("title", recent_ending_id))
                lines.append("- %s%s" % [
                    recent_ending_title,
                    _format_unlock_timeline_suffix(int(row.get("run_index", 0)), str(row.get("discovered_at", "")))
                ])
    var redeem_meta_var: Variant = ending_meta.get("nar_ending_redeem", {})
    var redeem_meta: Dictionary = redeem_meta_var as Dictionary if redeem_meta_var is Dictionary else {}
    var redeem_suffix: String = _format_unlock_timeline_suffix(int(redeem_meta.get("run_index", 0)), str(redeem_meta.get("discovered_at", ""))) if endings.has("nar_ending_redeem") else ""
    lines.append("%s Redeem%s" % [("[x]" if endings.has("nar_ending_redeem") else "[ ]"), redeem_suffix])

    var fall_meta_var: Variant = ending_meta.get("nar_ending_fall", {})
    var fall_meta: Dictionary = fall_meta_var as Dictionary if fall_meta_var is Dictionary else {}
    var fall_suffix: String = _format_unlock_timeline_suffix(int(fall_meta.get("run_index", 0)), str(fall_meta.get("discovered_at", ""))) if endings.has("nar_ending_fall") else ""
    lines.append("%s Fall%s" % [("[x]" if endings.has("nar_ending_fall") else "[ ]"), fall_suffix])

    var balance_meta_var: Variant = ending_meta.get("nar_ending_balance", {})
    var balance_meta: Dictionary = balance_meta_var as Dictionary if balance_meta_var is Dictionary else {}
    var balance_suffix: String = _format_unlock_timeline_suffix(int(balance_meta.get("run_index", 0)), str(balance_meta.get("discovered_at", ""))) if endings.has("nar_ending_balance") else ""
    lines.append("%s Balance%s" % [("[x]" if endings.has("nar_ending_balance") else "[ ]"), balance_suffix])

    var unlocked_fragments: Array[String] = SaveManager.get_ordered_unlocked_fragments()
    var fragment_meta: Dictionary = {}
    if SaveManager != null and SaveManager.has_method("get_fragment_meta"):
        fragment_meta = SaveManager.get_fragment_meta()
    var fragment_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("memory_fragments", {})
    var fragment_rows: Dictionary = {}
    if fragment_rows_var is Dictionary:
        fragment_rows = fragment_rows_var

    lines.append("Memory Fragments:")
    lines.append("Unlocked %d / %d" % [unlocked_fragments.size(), fragment_rows.size()])
    lines.append("Fragment progress: %d / %d" % [unlocked_fragments.size(), max(fragment_rows.size(), 1)])
    lines.append("Recent Fragments (last 5):")
    if unlocked_fragments.is_empty():
        lines.append("-")
    else:
        var recent_fragments: Array[Dictionary] = []
        if SaveManager != null and SaveManager.has_method("get_fragment_recent_unlocks"):
            recent_fragments = SaveManager.get_fragment_recent_unlocks(5)
        if recent_fragments.is_empty():
            for index: int in range(unlocked_fragments.size() - 1, max(-1, unlocked_fragments.size() - 6), -1):
                var fallback_fragment_id: String = str(unlocked_fragments[index])
                var fallback_fragment_title: String = fallback_fragment_id
                var fallback_fragment_row_var: Variant = fragment_rows.get(fallback_fragment_id, {})
                if fallback_fragment_row_var is Dictionary:
                    fallback_fragment_title = str((fallback_fragment_row_var as Dictionary).get("title", fallback_fragment_id))
                lines.append("- %s" % fallback_fragment_title)
        else:
            for row: Dictionary in recent_fragments:
                var recent_fragment_id: String = str(row.get("fragment_id", "")).strip_edges()
                if recent_fragment_id == "":
                    continue
                var recent_fragment_title: String = recent_fragment_id
                var recent_fragment_row_var: Variant = fragment_rows.get(recent_fragment_id, {})
                if recent_fragment_row_var is Dictionary:
                    recent_fragment_title = str((recent_fragment_row_var as Dictionary).get("title", recent_fragment_id))
                lines.append("- %s%s" % [
                    recent_fragment_title,
                    _format_unlock_timeline_suffix(int(row.get("run_index", 0)), str(row.get("discovered_at", "")))
                ])
    for item: Variant in unlocked_fragments:
        var fragment_id: String = str(item)
        var fragment_title: String = fragment_id
        var row_var: Variant = fragment_rows.get(fragment_id, {})
        var fragment_timeline_suffix: String = ""
        if row_var is Dictionary:
            fragment_title = str((row_var as Dictionary).get("title", fragment_id))
        var fragment_meta_row_var: Variant = fragment_meta.get(fragment_id, {})
        if fragment_meta_row_var is Dictionary:
            var fragment_meta_row: Dictionary = fragment_meta_row_var as Dictionary
            fragment_timeline_suffix = _format_unlock_timeline_suffix(
                int(fragment_meta_row.get("run_index", 0)),
                str(fragment_meta_row.get("discovered_at", ""))
            )
        lines.append("[x] %s%s" % [fragment_title, fragment_timeline_suffix])

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
        _apply_selected_character(false)
        return

    var fallback_index: int = _get_first_unlocked_character_index(rows)
    if fallback_index >= 0:
        _character_cursor = fallback_index
        _apply_selected_character(false)
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
    _apply_selected_character(false)


func _apply_selected_character(persist_selection: bool = true) -> bool:
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
    if not persist_selection:
        return true
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
    var codex_meta: Dictionary = {}
    if SaveManager != null and SaveManager.has_method("get_codex_meta"):
        codex_meta = SaveManager.get_codex_meta()
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
            var timeline_suffix: String = ""
            if mark == "[x]":
                var meta_key: String = "%s:%s" % [category, entry_id]
                var meta_row_var: Variant = codex_meta.get(meta_key, {})
                var meta_row: Dictionary = meta_row_var as Dictionary if meta_row_var is Dictionary else {}
                timeline_suffix = _format_unlock_timeline_suffix(int(meta_row.get("run_index", 0)), str(meta_row.get("discovered_at", "")))
            var row_text: String = "%s%s %s%s" % [pointer, mark, entry_name, timeline_suffix]
            if mark == "[ ]" and hint != "":
                row_text += "  (%s)" % hint
            lines.append(row_text)

        for entry_id: String in rows:
            if _catalog_has_entry(catalog, entry_id):
                continue
            var fallback_timeline_suffix: String = ""
            var fallback_meta_key: String = "%s:%s" % [category, entry_id]
            var fallback_meta_var: Variant = codex_meta.get(fallback_meta_key, {})
            var fallback_meta: Dictionary = fallback_meta_var as Dictionary if fallback_meta_var is Dictionary else {}
            fallback_timeline_suffix = _format_unlock_timeline_suffix(int(fallback_meta.get("run_index", 0)), str(fallback_meta.get("discovered_at", "")))
            lines.append("[x] %s%s" % [_get_codex_entry_name(category, entry_id), fallback_timeline_suffix])

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

    lines.append("Source Breakdown:")
    for row: Dictionary in _build_codex_source_breakdown_rows():
        lines.append("- %s %d" % [
            str(row.get("label", "Unknown")),
            int(row.get("count", 0))
        ])

    var source_filter: Dictionary = _get_codex_source_filter_row()
    var chapter_filter: Dictionary = _get_codex_chapter_filter_row()
    var source_filter_id: String = str(source_filter.get("id", "all"))
    var chapter_filter_id: String = str(chapter_filter.get("id", "all"))
    var filtered_recent: Array[Dictionary] = []
    var recent_rows: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(64)

    if _codex_stats_source_button != null:
        _codex_stats_source_button.text = "Source: %s (5)" % str(source_filter.get("label", "All Sources"))
    if _codex_stats_chapter_button != null:
        _codex_stats_chapter_button.text = "Chapter: %s (6)" % str(chapter_filter.get("label", "All Chapters"))

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

    lines.append("Recent Category Breakdown:")
    for row: Dictionary in _build_codex_recent_category_rows(filtered_recent):
        lines.append("- %s %d" % [
            str(row.get("label", "Unknown")),
            int(row.get("count", 0))
        ])

    lines.append("Recent Chapter Breakdown:")
    for row: Dictionary in _build_codex_recent_chapter_rows(filtered_recent):
        lines.append("- %s %d" % [
            str(row.get("label", "Unknown")),
            int(row.get("count", 0))
        ])

    lines.append("Recent Source Breakdown:")
    for row: Dictionary in _build_codex_recent_source_rows(filtered_recent):
        lines.append("- %s %d" % [
            str(row.get("label", "Unknown")),
            int(row.get("count", 0))
        ])

    lines.append("Recent Unlocks (last 5):")
    lines.append("Filters -> Source: %s | Chapter: %s" % [
        str(source_filter.get("label", "All Sources")),
        str(chapter_filter.get("label", "All Chapters"))
    ])
    lines.append("Visible Recent Window: %d/5" % filtered_recent.size())

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
            var timeline_suffix: String = _format_unlock_timeline_suffix(int(row.get("run_index", 0)), discovered_at)
            if timeline_suffix == "":
                timeline_suffix = " | time-unknown"
            lines.append("- [%s] %s | %s | %s%s" % [
                category_name,
                entry_name,
                _prettify_source(source),
                _prettify_chapter_id(chapter_id),
                timeline_suffix
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
        "archives":
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


func _build_codex_source_breakdown_rows() -> Array[Dictionary]:
    var counts: Dictionary = {}
    var recent_rows: Array[Dictionary] = SaveManager.get_codex_recent_unlocks(256)
    for row: Dictionary in recent_rows:
        var source_id: String = str(row.get("source", "")).strip_edges()
        if source_id == "":
            continue
        counts[source_id] = int(counts.get(source_id, 0)) + 1

    var ordered_rows: Array[Dictionary] = []
    for filter_row: Dictionary in CODEX_SOURCE_FILTERS:
        var source_id: String = str(filter_row.get("id", "")).strip_edges()
        if source_id == "" or source_id == "all":
            continue
        var count: int = int(counts.get(source_id, 0))
        if count <= 0:
            continue
        ordered_rows.append({
            "id": source_id,
            "label": _prettify_source(source_id),
            "count": count
        })
    return ordered_rows


func _build_codex_recent_category_rows(recent_rows: Array[Dictionary]) -> Array[Dictionary]:
    var counts: Dictionary = {}
    for row: Dictionary in recent_rows:
        var category_id: String = str(row.get("category", "")).strip_edges()
        if category_id == "":
            continue
        counts[category_id] = int(counts.get(category_id, 0)) + 1

    var ordered_rows: Array[Dictionary] = []
    for category_id: String in CODEX_CATEGORIES:
        var count: int = int(counts.get(category_id, 0))
        if count <= 0:
            continue
        ordered_rows.append({
            "id": category_id,
            "label": str(CODEX_CATEGORY_NAMES.get(category_id, category_id.capitalize())),
            "count": count
        })
    return ordered_rows


func _build_codex_recent_chapter_rows(recent_rows: Array[Dictionary]) -> Array[Dictionary]:
    var counts: Dictionary = {}
    for row: Dictionary in recent_rows:
        var category_id: String = str(row.get("category", "")).strip_edges()
        var entry_id: String = str(row.get("entry_id", "")).strip_edges()
        var chapter_id: String = _normalize_codex_chapter_id(str(row.get("chapter_id", "")))
        if chapter_id == "":
            chapter_id = _resolve_codex_entry_chapter(category_id, entry_id)
        if chapter_id == "":
            chapter_id = "global"
        counts[chapter_id] = int(counts.get(chapter_id, 0)) + 1

    var ordered_rows: Array[Dictionary] = []
    for filter_row: Dictionary in CODEX_CHAPTER_FILTERS:
        var chapter_id: String = str(filter_row.get("id", "")).strip_edges()
        if chapter_id == "" or chapter_id == "all":
            continue
        var count: int = int(counts.get(chapter_id, 0))
        if count <= 0:
            continue
        ordered_rows.append({
            "id": chapter_id,
            "label": _prettify_chapter_id(chapter_id),
            "count": count
        })
    return ordered_rows


func _build_codex_recent_source_rows(recent_rows: Array[Dictionary]) -> Array[Dictionary]:
    var counts: Dictionary = {}
    for row: Dictionary in recent_rows:
        var source_id: String = str(row.get("source", "")).strip_edges()
        if source_id == "":
            continue
        counts[source_id] = int(counts.get(source_id, 0)) + 1

    var ordered_rows: Array[Dictionary] = []
    for filter_row: Dictionary in CODEX_SOURCE_FILTERS:
        var source_id: String = str(filter_row.get("id", "")).strip_edges()
        if source_id == "" or source_id == "all":
            continue
        var count: int = int(counts.get(source_id, 0))
        if count <= 0:
            continue
        ordered_rows.append({
            "id": source_id,
            "label": _prettify_source(source_id),
            "count": count
        })
    return ordered_rows


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
        "archives":
            return _lookup_archive_name(entry_id)
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
        "archives":
            for row: Dictionary in ARCHIVE_CODEX_ENTRIES:
                result.append(row.duplicate(true))
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
    if category == "archives":
        for archive_line: String in _build_archive_codex_detail_lines(entry_id):
            lines.append(archive_line)

    if unlocked:
        if source != "":
            lines.append("Source: %s" % _prettify_source(source))
        if chapter_id != "":
            lines.append("Chapter: %s" % _prettify_chapter_id(chapter_id))
        var timeline_line: String = _format_unlock_timeline_line("Unlocked", run_index, discovered_at)
        if timeline_line != "":
            lines.append(timeline_line)

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
        "difficulty_clear":
            return "Difficulty Clear"
        "difficulty_hidden_clear":
            return "Nightmare Hidden Clear"
        "hidden_layer_clear":
            return "Hidden Layer Clear"
        "hidden_layer_mastery":
            return "Hidden Layer Mastery"
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


func _lookup_archive_name(entry_id: String) -> String:
    var row: Dictionary = _get_archive_codex_entry(entry_id)
    if not row.is_empty():
        return str(row.get("name", entry_id))
    return _prettify_id(entry_id)


func _get_archive_codex_entry(entry_id: String) -> Dictionary:
    for row: Dictionary in ARCHIVE_CODEX_ENTRIES:
        if str(row.get("id", "")) == entry_id:
            return row.duplicate(true)
    return {}


func _build_archive_codex_detail_lines(entry_id: String) -> Array[String]:
    var lines: Array[String] = []
    var row: Dictionary = _get_archive_codex_entry(entry_id)
    if row.is_empty() or SaveManager == null:
        return lines

    if row.has("difficulty_tier"):
        return _build_difficulty_archive_detail_lines(row)

    if not SaveManager.has_method("get_hidden_layer_status"):
        return lines

    var layer_id: String = str(row.get("layer_id", "")).strip_edges()
    var entry_kind: String = str(row.get("entry_kind", "clear")).strip_edges()
    var status: Dictionary = SaveManager.get_hidden_layer_status(layer_id)
    if status.is_empty():
        return lines

    lines.append("Layer: %s" % str(status.get("title", layer_id)))
    lines.append("Progress: %s" % str(status.get("progress_label", "No progress")))

    var collection_label: String = str(status.get("collection_label", "")).strip_edges()
    if collection_label != "":
        lines.append("Collection: %s" % collection_label)
    elif entry_kind == "mastery":
        lines.append("Collection: Incomplete")

    var gameplay_label: String = str(status.get("gameplay_label", "")).strip_edges()
    if gameplay_label != "":
        lines.append("Gameplay: %s" % gameplay_label)

    var story_label: String = str(status.get("story_label", "")).strip_edges()
    if story_label != "" and entry_kind == "clear":
        lines.append("Archive: %s" % story_label)

    var mastery_label: String = str(status.get("mastery_label", "")).strip_edges()
    if mastery_label != "":
        lines.append("Mastery: %s" % mastery_label)
    elif entry_kind == "mastery":
        lines.append("Mastery: Not mastered")

    if bool(status.get("collection_bonus_claimed", false)):
        lines.append("Bonus: Claimed")
    elif bool(status.get("collection_mastered", false)):
        lines.append("Bonus: Ready")

    return lines


func _build_difficulty_archive_detail_lines(row: Dictionary) -> Array[String]:
    var lines: Array[String] = []
    var tier: int = int(row.get("difficulty_tier", 0))
    var entry_kind: String = str(row.get("entry_kind", "difficulty_clear")).strip_edges()
    var difficulty_label: String = "Tier %d" % tier
    if SaveManager.has_method("get_difficulty_label"):
        difficulty_label = str(SaveManager.get_difficulty_label(tier))
    var difficulty_summary: String = ""
    if SaveManager.has_method("get_difficulty_summary"):
        difficulty_summary = str(SaveManager.get_difficulty_summary(tier)).strip_edges()
    var record: Dictionary = {}
    if SaveManager.has_method("get_difficulty_record"):
        record = SaveManager.get_difficulty_record(tier)

    lines.append("Tier: %s" % difficulty_label)
    if difficulty_summary != "":
        lines.append("Risk Profile: %s" % difficulty_summary)
    lines.append("Clears: %d" % int(record.get("clears", 0)))
    lines.append("Best Rooms: %d" % int(record.get("best_rooms", 0)))
    lines.append("Best Kills: %d" % int(record.get("best_kills", 0)))
    if entry_kind == "difficulty_hidden":
        lines.append("Hidden Clears: %d" % int(record.get("hidden_layer_clears", 0)))

    return lines


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


func _get_achievement_title(achievement_id: String) -> String:
    var rows_var: Variant = ConfigManager.get_config("achievements", {}).get("achievements", [])
    if rows_var is Array:
        for item: Variant in rows_var:
            if not (item is Dictionary):
                continue
            var row: Dictionary = item
            if str(row.get("id", "")).strip_edges() == achievement_id.strip_edges():
                return str(row.get("title", achievement_id))
    return achievement_id


func _get_achievement_group_label(condition: String) -> String:
    var normalized: String = condition.strip_edges().to_lower()
    if normalized.begins_with("hidden_layer_"):
        return "Hidden Layer"
    if normalized.begins_with("difficulty_"):
        return "Difficulty"
    return "Run"


func _format_unlock_timeline_suffix(run_index: int, discovered_at: String) -> String:
    var parts: Array[String] = []
    # 解锁记录可能只有 run_index 或只有时间戳，这里统一拼成可复用后缀。
    if run_index > 0:
        parts.append("Run #%d" % run_index)
    var when_text: String = discovered_at.strip_edges()
    if when_text != "":
        parts.append(when_text)
    if parts.is_empty():
        return ""
    return " | %s" % " | ".join(parts)


func _format_unlock_timeline_line(prefix: String, run_index: int, discovered_at: String) -> String:
    var suffix: String = _format_unlock_timeline_suffix(run_index, discovered_at)
    if suffix == "":
        return ""
    var normalized: String = suffix
    if normalized.begins_with(" | "):
        normalized = normalized.substr(3)
    return "%s: %s" % [prefix, normalized]


func _get_branch_mode_label(branch_key: String) -> String:
    match branch_key:
        "first_unlock":
            return "FIRST"
        "repeat_unlock":
            return "REPEAT"
        _:
            return "ARCHIVE"


func _build_last_run_burst_unlocks_summary(raw_achievements: Variant, raw_codex: Variant, raw_difficulty: Variant, raw_meta_return: Variant) -> String:
    var rows: Array[String] = []
    # 将不同来源的本局解锁汇总成同一块摘要，避免菜单层重复拼装展示逻辑。
    rows.append_array(_build_achievement_unlock_rows(_as_string_array(raw_achievements)))
    rows.append_array(_build_codex_unlock_rows(raw_codex))
    rows.append_array(_build_difficulty_unlock_rows(raw_difficulty))
    rows.append_array(_build_meta_return_unlock_rows(raw_meta_return))
    if rows.is_empty():
        return ""
    rows.push_front("Burst Unlocks:")
    return "\n".join(PackedStringArray(rows))


func _build_last_run_meta_return_block(summary: String, next_hint: String) -> String:
    if summary == "" and next_hint == "":
        return ""
    var rows: Array[String] = ["Meta Return:"]
    if summary != "":
        rows.append(summary)
    if next_hint != "":
        rows.append(next_hint)
    return "\n".join(PackedStringArray(rows))


func _build_last_run_fragment_trigger_summary(raw_triggers: Variant) -> String:
    if not (raw_triggers is Array):
        return ""

    var rows: Array[String] = []
    for item: Variant in raw_triggers:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var fragment_title: String = str(row.get("fragment_title", row.get("fragment_id", "Fragment"))).strip_edges()
        if fragment_title == "":
            fragment_title = str(row.get("fragment_id", "Fragment")).strip_edges()
        var chapter_id: String = str(row.get("chapter_id", "chapter")).strip_edges()
        var trigger_type: String = str(row.get("trigger_type", "trigger")).strip_edges()
        var prefix: String = "Unlocked" if bool(row.get("newly_unlocked", false)) else "Echoed"
        rows.append("%s: %s [%s/%s]" % [prefix, fragment_title, chapter_id, trigger_type])

    if rows.is_empty():
        return ""
    rows.push_front("Fragments:")
    return "\n".join(PackedStringArray(rows))


func _build_achievement_unlock_rows(achievement_ids: Array[String]) -> Array[String]:
    var rows: Array[String] = []
    for achievement_id: String in achievement_ids:
        var normalized_id: String = achievement_id.strip_edges()
        if normalized_id == "":
            continue
        rows.append("Achievement: %s" % _get_achievement_title(normalized_id))
    return rows


func _build_codex_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var category: String = str(row.get("category", "")).strip_edges().to_lower()
        var entry_id: String = str(row.get("entry_id", "")).strip_edges()
        if category == "" or entry_id == "":
            continue
        var line: String = "Codex: [%s] %s" % [
            _get_codex_category_label(category),
            _get_codex_entry_title(category, entry_id)
        ]
        var source: String = str(row.get("source", "")).strip_edges()
        if source != "":
            line += " (%s)" % _get_codex_source_label(source)
        rows.append(line)
    return rows


func _build_difficulty_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var label: String = str(row.get("label", _prettify_id(str(row.get("tier", ""))))).strip_edges()
        if label == "":
            continue
        rows.append("Difficulty: %s unlocked" % label)
    return rows


func _build_meta_return_unlock_rows(raw_unlocks: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (raw_unlocks is Array):
        return rows
    for item: Variant in raw_unlocks:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var label: String = str(row.get("label", "")).strip_edges()
        if label == "":
            continue
        var line: String = "Meta Return: %s" % label
        var bonus_text: String = str(row.get("bonus_text", "")).strip_edges()
        if bonus_text != "":
            line += " (%s)" % bonus_text
        rows.append(line)
    return rows


func _get_codex_category_label(category: String) -> String:
    match category.strip_edges().to_lower():
        "characters":
            return "Characters"
        "weapons":
            return "Weapons"
        "passives":
            return "Passives"
        "enemies":
            return "Enemies"
        "accessories":
            return "Accessories"
        "archives":
            return "Archives"
        _:
            return _prettify_id(category)


func _get_codex_entry_title(category: String, entry_id: String) -> String:
    match category.strip_edges().to_lower():
        "archives":
            return _get_archive_codex_title(entry_id)
        "enemies":
            var boss_title: String = _get_boss_echo_title(entry_id)
            if boss_title != "":
                return boss_title
            return _prettify_id(entry_id)
        _:
            return _prettify_id(entry_id)


func _get_codex_source_label(source: String) -> String:
    match source.strip_edges():
        "difficulty_clear":
            return "Difficulty Clear"
        "difficulty_hidden_clear":
            return "Nightmare Hidden Clear"
        "hidden_layer_clear":
            return "Hidden Layer Clear"
        "hidden_layer_mastery":
            return "Hidden Layer Mastery"
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


func _get_archive_codex_title(entry_id: String) -> String:
    for item: Dictionary in ARCHIVE_CODEX_ENTRIES:
        if str(item.get("id", "")).strip_edges() == entry_id.strip_edges():
            return str(item.get("name", entry_id)).strip_edges()
    return _prettify_id(entry_id)


func _get_boss_echo_title(entry_id: String) -> String:
    return str(ENEMY_NAME_MAP.get(entry_id, "")).strip_edges()


func _build_last_run_choices_summary(raw_choices: Variant) -> String:
    if not (raw_choices is Array):
        return ""

    var choices: Array = raw_choices
    if choices.is_empty():
        return ""

    var lines: Array[String] = ["Narrative Choices:"]
    var display_limit: int = mini(6, choices.size())
    for i in range(display_limit):
        var item: Variant = choices[i]
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var chapter_id: String = str(row.get("chapter_id", "chapter"))
        var segment_id: String = str(row.get("segment_id", "segment"))
        var choice_id: String = str(row.get("choice_id", "choice"))
        var alignment_delta: float = float(row.get("alignment_delta", 0.0))
        lines.append("- %s / %s -> %s (%+.0f)" % [chapter_id, segment_id, choice_id, alignment_delta])

    if choices.size() > display_limit:
        lines.append("... +%d more" % (choices.size() - display_limit))

    return "\n".join(PackedStringArray(lines))


func _build_last_run_route_style_summary(raw_styles: Variant, raw_timeline: Variant) -> String:
    var styles: Dictionary = {}
    if raw_styles is Dictionary:
        styles = raw_styles

    var has_timeline: bool = raw_timeline is Array and not (raw_timeline as Array).is_empty()
    if styles.is_empty() and not has_timeline:
        return ""

    var lines: Array[String] = ["Route Style Evolution:"]
    var chapter_parts: Array[String] = []
    for idx in range(1, 5):
        var chapter_id: String = "chapter_%d" % idx
        var style_id: String = str(styles.get(chapter_id, "neutral"))
        chapter_parts.append("CH%d:%s" % [idx, _last_run_route_style_label_for_id(style_id)])
    lines.append("  " + " | ".join(PackedStringArray(chapter_parts)))

    if has_timeline:
        var timeline: Array = raw_timeline
        lines.append("Locks:")
        var limit: int = mini(6, timeline.size())
        for i in range(limit):
            var row_var: Variant = timeline[i]
            if not (row_var is Dictionary):
                continue
            var row: Dictionary = row_var
            lines.append("- R%d %s -> %s (slot %d)" % [
                int(row.get("room_index", 0)),
                str(row.get("chapter_id", "chapter")),
                _last_run_route_style_label_for_id(str(row.get("style_id", "neutral"))),
                int(row.get("selected_slot", 0)) + 1
            ])
        if timeline.size() > limit:
            lines.append("... +%d more" % (timeline.size() - limit))
    else:
        lines.append("Locks: none (all chapters remained NEUTRAL)")

    return "\n".join(PackedStringArray(lines))


func _last_run_route_style_label_for_id(style_id: String) -> String:
    match style_id:
        "vanguard":
            return "VANGUARD"
        "raider":
            return "RAIDER"
        _:
            return "NEUTRAL"


func _build_last_run_chapter_effect_timeline_summary(raw_timeline: Variant) -> String:
    if not (raw_timeline is Array):
        return ""

    var timeline: Array = raw_timeline
    if timeline.is_empty():
        return ""

    var counts: Dictionary = _count_last_run_timeline_modes(timeline)
    var lines: Array[String] = [
        "[ALL] Chapter Effect Timeline: Full Replay",
        "Segments -> BOON:%d  CURSE:%d  MIXED:%d" % [
            int(counts.get("boon", 0)),
            int(counts.get("curse", 0)),
            int(counts.get("mixed", 0))
        ]
    ]
    var display_limit: int = 8
    var shown: int = 0
    for item: Variant in timeline:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var room_index: int = int(row.get("room_index", 0))
        var chapter_id: String = str(row.get("chapter_id", "chapter"))
        var icon: String = str(row.get("icon", "[~]"))
        var title: String = str(row.get("title", "Chapter Effect"))
        var duration_rooms: int = int(row.get("duration_rooms", 1))
        var desc: String = str(row.get("desc", ""))

        var body: String = "- R%d %s %s %s (%dR)" % [room_index, chapter_id, icon, title, duration_rooms]
        if desc != "":
            body += " | %s" % desc
        lines.append(body)
        shown += 1
        if shown >= display_limit:
            break

    if timeline.size() > shown:
        lines.append("... +%d more" % (timeline.size() - shown))

    return "\n".join(PackedStringArray(lines))


func _count_last_run_timeline_modes(timeline: Array) -> Dictionary:
    var counts: Dictionary = {
        "boon": 0,
        "curse": 0,
        "mixed": 0
    }
    for item: Variant in timeline:
        if not (item is Dictionary):
            continue
        var mode: String = _resolve_last_run_timeline_row_mode(item)
        counts[mode] = int(counts.get(mode, 0)) + 1
    return counts


func _resolve_last_run_timeline_row_mode(row: Dictionary) -> String:
    var score: float = _last_run_timeline_row_score(row)
    if score >= 0.25:
        return "boon"
    if score <= -0.25:
        return "curse"
    return "mixed"


func _last_run_timeline_row_score(row: Dictionary) -> float:
    if row.has("score"):
        return float(row.get("score", 0.0))

    var icon: String = str(row.get("icon", "[~]"))
    if icon == "[+]":
        return 1.0
    if icon == "[-]":
        return -1.0
    return 0.0


func _build_last_run_hidden_layer_clear_summary(layer_id: String, reward_summary: String, gameplay_var: Variant, record_var: Variant) -> String:
    if layer_id == "":
        return ""

    var lines: Array[String] = ["Hidden Clear: %s completion archived" % layer_id]
    if reward_summary != "":
        lines.append("Reward Cache: %s" % reward_summary)

    if gameplay_var is Dictionary and not (gameplay_var as Dictionary).is_empty():
        lines.append_array(_build_last_run_hidden_layer_clear_gameplay_rows(layer_id, gameplay_var as Dictionary))

    if record_var is Dictionary and not (record_var as Dictionary).is_empty():
        var record: Dictionary = record_var as Dictionary
        lines.append("Archive Stats: attempts=%d | clears=%d | best_rooms=%d" % [
            int(record.get("attempts", 0)),
            int(record.get("clears", 0)),
            int(record.get("best_rooms_cleared", 0))
        ])

    return "\n".join(PackedStringArray(lines))


func _build_last_run_hidden_layer_clear_gameplay_rows(layer_id: String, gameplay: Dictionary) -> Array[String]:
    var rows: Array[String] = []
    match layer_id:
        "FS1":
            var parts: Array[String] = []
            var pressure_label: String = str(gameplay.get("pressure_label", "Rift Surge")).strip_edges()
            var pressure_stage: int = int(gameplay.get("pressure_stage", 0))
            var required_stage: int = int(gameplay.get("required_pressure_stage", 0))
            if pressure_stage > 0 or required_stage > 0:
                parts.append("%s %d/%d" % [pressure_label, pressure_stage, maxi(required_stage, pressure_stage)])
            var survival_seconds: float = float(gameplay.get("survival_seconds", 0.0))
            if survival_seconds > 0.0:
                parts.append("Hold %.1fs" % survival_seconds)
            var echo_title: String = str(gameplay.get("boss_echo_title", gameplay.get("boss_echo_id", ""))).strip_edges()
            if echo_title != "":
                parts.append("Echo %s" % echo_title)
            if not parts.is_empty():
                rows.append("Pressure: %s" % " | ".join(PackedStringArray(parts)))
            var echo_collection: Array[String] = _as_string_array(gameplay.get("boss_echo_collection", []))
            if not echo_collection.is_empty():
                var echo_titles: Array[String] = []
                for boss_id: String in echo_collection:
                    var echo_title_item: String = str(gameplay.get("boss_echo_title", "")).strip_edges() if boss_id == str(gameplay.get("boss_echo_id", "")).strip_edges() else str(ENEMY_NAME_MAP.get(boss_id, "")).strip_edges()
                    if echo_title_item != "":
                        echo_titles.append(echo_title_item)
                var collection_text: String = "Echoes %d/4" % echo_collection.size()
                if not echo_titles.is_empty():
                    collection_text += " | %s" % ", ".join(PackedStringArray(echo_titles))
                rows.append("Collection: %s" % collection_text)
            var mastery_label_fs1: String = str(gameplay.get("mastery_label", "")).strip_edges()
            if mastery_label_fs1 != "":
                rows.append("Mastery: %s" % mastery_label_fs1)
        "FS2":
            var trial_label: String = str(gameplay.get("trial_label", "")).strip_edges()
            if trial_label == "":
                var trial_depth: int = int(gameplay.get("trial_depth", 0))
                var trial_depth_max: int = maxi(trial_depth, int(gameplay.get("trial_depth_max", 0)))
                if trial_depth > 0:
                    trial_label = "Forge Trial %d/%d" % [trial_depth, maxi(1, trial_depth_max)]
            if trial_label != "":
                rows.append("Trial: %s" % trial_label)
            var trial_labels: Array[String] = _as_string_array(gameplay.get("trial_labels", []))
            if not trial_labels.is_empty():
                var deepest_label: String = str(gameplay.get("deepest_trial_label", trial_labels[trial_labels.size() - 1])).strip_edges()
                var collection_text_fs2: String = "Trials %d/%d" % [trial_labels.size(), maxi(1, int(gameplay.get("trial_depth_max", 5)))]
                if deepest_label != "":
                    collection_text_fs2 += " | %s" % deepest_label
                rows.append("Collection: %s" % collection_text_fs2)
            var mastery_label_fs2: String = str(gameplay.get("mastery_label", "")).strip_edges()
            if mastery_label_fs2 != "":
                rows.append("Mastery: %s" % mastery_label_fs2)
    return rows


func _build_last_run_challenge_layer_summary(layer_id: String, title: String, phase: String, reward_title: String, reward_payload_var: Variant, reward_summary: String, settlement_summary: String, difficulty_summary: String, rooms_cleared: int, kills: int, record_var: Variant) -> String:
    if layer_id == "":
        return ""

    var rows: Array[String] = ["Challenge Layer:", "%s -> %s" % [layer_id, title if title != "" else "Challenge Layer"]]
    if phase != "":
        rows.append("Phase: %s" % phase.capitalize())
    if reward_title != "":
        rows.append("Reward Choice: %s" % reward_title)
    if reward_payload_var is Dictionary and not (reward_payload_var as Dictionary).is_empty():
        var reward_payload: Dictionary = reward_payload_var as Dictionary
        rows.append("Reward Detail: Meta +%d | Sigil +%d | Insight +%d" % [
            int(reward_payload.get("meta_bonus", 0)),
            int(reward_payload.get("sigils", 0)),
            int(reward_payload.get("insight", 0))
        ])
    if settlement_summary != "":
        rows.append("Settlement: %s" % settlement_summary)
    if difficulty_summary != "":
        rows.append("Difficulty tuning: %s" % difficulty_summary)
    if reward_summary != "":
        rows.append(reward_summary)
    if rooms_cleared > 0 or kills > 0:
        rows.append("Run Stats: rooms=%d | kills=%d" % [rooms_cleared, kills])
    if record_var is Dictionary and not (record_var as Dictionary).is_empty():
        var record: Dictionary = record_var as Dictionary
        rows.append("Archive Stats: attempts=%d | clears=%d | best_rooms=%d | best_kills=%d" % [
            int(record.get("attempts", 0)),
            int(record.get("clears", 0)),
            int(record.get("best_rooms", 0)),
            int(record.get("best_kills", 0))
        ])
        rows.append("Reward Ledger: Meta +%d | Sigil +%d | Insight +%d" % [
            int(record.get("total_meta_bonus", 0)),
            int(record.get("total_sigils", 0)),
            int(record.get("total_insight", 0))
        ])
        var last_reward_title: String = str(record.get("last_reward_title", "")).strip_edges()
        if last_reward_title != "":
            rows.append("Last Reward: %s" % last_reward_title)
    return "\n".join(PackedStringArray(rows))


func _build_achievement_group_progress(rows: Array, unlocked: Array[String]) -> Array[Dictionary]:
    var totals: Dictionary = {
        "Run": 0,
        "Hidden Layer": 0,
        "Difficulty": 0
    }
    var progress: Dictionary = {
        "Run": 0,
        "Hidden Layer": 0,
        "Difficulty": 0
    }

    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var ach_id: String = str(row.get("id", "")).strip_edges()
        var label: String = _get_achievement_group_label(str(row.get("condition", "")))
        totals[label] = int(totals.get(label, 0)) + 1
        if unlocked.has(ach_id):
            progress[label] = int(progress.get(label, 0)) + 1

    return [
        {"label": "Run", "unlocked": int(progress.get("Run", 0)), "total": int(totals.get("Run", 0))},
        {"label": "Hidden Layer", "unlocked": int(progress.get("Hidden Layer", 0)), "total": int(totals.get("Hidden Layer", 0))},
        {"label": "Difficulty", "unlocked": int(progress.get("Difficulty", 0)), "total": int(totals.get("Difficulty", 0))}
    ]


func _build_achievement_recent_group_rows(recent_unlocks: Array[Dictionary]) -> Array[Dictionary]:
    var counts: Dictionary = {
        "Run": 0,
        "Hidden Layer": 0,
        "Difficulty": 0
    }

    for row: Dictionary in recent_unlocks:
        var label: String = _get_achievement_group_label(str(row.get("condition", "")))
        counts[label] = int(counts.get(label, 0)) + 1

    return [
        {"label": "Run", "count": int(counts.get("Run", 0))},
        {"label": "Hidden Layer", "count": int(counts.get("Hidden Layer", 0))},
        {"label": "Difficulty", "count": int(counts.get("Difficulty", 0))}
    ]


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
    var unlocked_fragments: Array[String] = SaveManager.get_ordered_unlocked_fragments()
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
    var fragment_run_index: int = 0
    var fragment_discovered_at: String = ""
    if SaveManager != null and SaveManager.has_method("get_fragment_meta"):
        var fragment_meta: Dictionary = SaveManager.get_fragment_meta()
        var meta_row_var: Variant = fragment_meta.get(fragment_id, {})
        if meta_row_var is Dictionary:
            var meta_row: Dictionary = meta_row_var as Dictionary
            fragment_run_index = int(meta_row.get("run_index", 0))
            fragment_discovered_at = str(meta_row.get("discovered_at", ""))
    var timeline_line: String = _format_unlock_timeline_line("Unlocked", fragment_run_index, fragment_discovered_at)
    var fragment_lines: PackedStringArray = [
        "Memory Archive (%d/%d)" % [_fragment_cursor + 1, unlocked_fragments.size()],
        title
    ]
    if timeline_line != "":
        fragment_lines.append(timeline_line)
    fragment_lines.append(text)
    _fragment_review_value.text = "\n".join(fragment_lines)


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
    var ending_run_index: int = 0
    var ending_discovered_at: String = ""
    if SaveManager != null and SaveManager.has_method("get_ending_meta"):
        var ending_meta: Dictionary = SaveManager.get_ending_meta()
        var meta_row_var: Variant = ending_meta.get(ending_id, {})
        if meta_row_var is Dictionary:
            var meta_row: Dictionary = meta_row_var as Dictionary
            ending_run_index = int(meta_row.get("run_index", 0))
            ending_discovered_at = str(meta_row.get("discovered_at", ""))
    var timeline_line: String = _format_unlock_timeline_line("Unlocked", ending_run_index, ending_discovered_at)
    _apply_ending_theme(ending_id)
    var last_run: Dictionary = SaveManager.get_last_run() if SaveManager != null else {}
    var payoff_title: String = ""
    var payoff_summary: String = ""
    var payoff_legacy: String = ""
    var payoff_fragment_hook: String = ""
    var payoff_arc_id: String = ""
    var payoff_style_echo: String = ""
    var active_epilogue: String = ""
    var epilogue_chain_rows: Array[String] = []
    var branch_title: String = ""
    var branch_mode: String = ""
    var branch_body: String = ""
    var branch_style_echo: String = ""
    var branch_archive_hook: String = ""
    if str(last_run.get("ending_id", "")).strip_edges() == ending_id:
        active_epilogue = str(last_run.get("ending_epilogue", "")).strip_edges()
        var last_payoff_var: Variant = last_run.get("ending_payoff", {})
        if last_payoff_var is Dictionary and not (last_payoff_var as Dictionary).is_empty():
            var last_payoff: Dictionary = last_payoff_var as Dictionary
            payoff_title = str(last_payoff.get("title", "Final Payoff")).strip_edges()
            payoff_summary = str(last_payoff.get("summary", "")).strip_edges()
            payoff_legacy = str(last_payoff.get("legacy", "")).strip_edges()
            payoff_fragment_hook = str(last_payoff.get("fragment_hook", "")).strip_edges()
            payoff_arc_id = str(last_payoff.get("arc_id", "")).strip_edges().to_upper()
            payoff_style_echo = str(last_payoff.get("style_echo", "")).strip_edges()
        var last_chain_var: Variant = last_run.get("ending_epilogue_chain", [])
        if last_chain_var is Array:
            for item: Variant in last_chain_var:
                var chain_text: String = str(item).strip_edges()
                if chain_text != "":
                    epilogue_chain_rows.append(chain_text)
        var last_branch_var: Variant = last_run.get("epilogue_branch", {})
        if last_branch_var is Dictionary and not (last_branch_var as Dictionary).is_empty():
            var last_branch: Dictionary = last_branch_var as Dictionary
            branch_title = str(last_branch.get("title", "Archive Branch")).strip_edges()
            branch_mode = _get_branch_mode_label(str(last_branch.get("branch_key", "")).strip_edges())
            branch_body = str(last_branch.get("body", "")).strip_edges()
            branch_style_echo = str(last_branch.get("style_echo", "")).strip_edges()
            branch_archive_hook = str(last_branch.get("archive_hook", "")).strip_edges()
    var ending_lines: PackedStringArray = [
        "Ending Archive (%d/%d)" % [_ending_cursor + 1, unlocked_endings.size()],
        title
    ]
    if timeline_line != "":
        ending_lines.append(timeline_line)
    ending_lines.append("Story: %s" % story)
    ending_lines.append("First Unlock: %s" % first_unlock)
    ending_lines.append("Repeat: %s" % repeat_unlock)
    if active_epilogue != "":
        ending_lines.append("Epilogue: %s" % active_epilogue)
        ending_lines.append("Epilogue Review Entry: Ending Archive -> Current Ending")
    if payoff_title != "":
        ending_lines.append("Ending Payoff: %s" % payoff_title)
    if payoff_arc_id != "" or payoff_style_echo != "":
        var payoff_route_parts: PackedStringArray = PackedStringArray()
        if payoff_arc_id != "":
            payoff_route_parts.append(payoff_arc_id)
        if payoff_style_echo != "":
            payoff_route_parts.append(payoff_style_echo)
        ending_lines.append("Payoff Echo: %s" % " | ".join(payoff_route_parts))
    if payoff_summary != "":
        ending_lines.append("Payoff Summary: %s" % payoff_summary)
    if payoff_legacy != "":
        ending_lines.append("Legacy: %s" % payoff_legacy)
    if payoff_fragment_hook != "":
        ending_lines.append("Fragment Hook: %s" % payoff_fragment_hook)
    if payoff_title != "":
        ending_lines.append("Payoff Review Entry: Ending Archive -> Current Ending")
    if not epilogue_chain_rows.is_empty():
        ending_lines.append("Epilogue Chain:")
        for chain_row: String in epilogue_chain_rows:
            ending_lines.append("- %s" % chain_row)
        ending_lines.append("Chain Review Entry: Ending Archive -> Current Ending")
    if branch_title != "":
        ending_lines.append("Epilogue Branch: %s [%s]" % [branch_title, branch_mode])
    if branch_body != "":
        ending_lines.append("Branch Body: %s" % branch_body)
    if branch_style_echo != "":
        ending_lines.append("Branch Echo: %s" % branch_style_echo)
    if branch_archive_hook != "":
        ending_lines.append("Archive Hook: %s" % branch_archive_hook)
    if branch_title != "":
        ending_lines.append("Review Entry: Ending Archive -> Current Ending")
    _ending_review_value.text = "\n".join(ending_lines)


func _get_ordered_unlocked_endings() -> Array[String]:
    if SaveManager != null and SaveManager.has_method("get_ordered_unlocked_endings"):
        return SaveManager.get_ordered_unlocked_endings()
    return SaveManager.get_unlocked_endings()


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
