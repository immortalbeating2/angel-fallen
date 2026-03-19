extends Node

const SAVE_PATH: String = "user://meta_save.json"
const ENDING_REDEEM: String = "nar_ending_redeem"
const ENDING_FALL: String = "nar_ending_fall"
const ENDING_BALANCE: String = "nar_ending_balance"

var _meta: Dictionary = {}
var _last_run: Dictionary = {}


func _ready() -> void:
    load_meta()
    apply_input_bindings()
    apply_runtime_settings()
    if EventBus != null and EventBus.has_signal("memory_fragment_found") and not EventBus.memory_fragment_found.is_connected(_on_memory_fragment_found):
        EventBus.memory_fragment_found.connect(_on_memory_fragment_found)
    if EventBus != null and EventBus.has_signal("enemy_killed") and not EventBus.enemy_killed.is_connected(_on_enemy_killed):
        EventBus.enemy_killed.connect(_on_enemy_killed)
    if EventBus != null and EventBus.has_signal("accessory_acquired") and not EventBus.accessory_acquired.is_connected(_on_accessory_acquired):
        EventBus.accessory_acquired.connect(_on_accessory_acquired)


func get_meta_data() -> Dictionary:
    return _meta.duplicate(true)


func get_last_run() -> Dictionary:
    return _last_run.duplicate(true)


func get_unlocked_achievements() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_achievements", []))


func get_unlocked_endings() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_endings", []))


func get_unlocked_fragments() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_fragments", []))


func get_selected_character_id() -> String:
    return str(_meta.get("selected_character_id", "char_knight"))


func get_codex() -> Dictionary:
    var codex_var: Variant = _meta.get("codex", {})
    return _sanitize_codex(codex_var)


func get_codex_meta() -> Dictionary:
    var codex_meta_var: Variant = _meta.get("codex_meta", {})
    return _sanitize_codex_meta(codex_meta_var)


func get_codex_stats_filters() -> Dictionary:
    var filter_var: Variant = _meta.get("codex_stats_filters", {})
    return _sanitize_codex_stats_filters(filter_var)


func set_codex_stats_filters(source_id: String, chapter_id: String) -> void:
    var current: Dictionary = get_codex_stats_filters()
    current["source"] = source_id
    current["chapter"] = chapter_id
    _meta["codex_stats_filters"] = _sanitize_codex_stats_filters(current)
    save_meta()


func get_codex_entry_meta(category: String, entry_id: String) -> Dictionary:
    var codex_meta: Dictionary = get_codex_meta()
    var key: String = "%s:%s" % [category.to_lower().strip_edges(), entry_id.strip_edges()]
    var row_var: Variant = codex_meta.get(key, {})
    if row_var is Dictionary:
        return (row_var as Dictionary).duplicate(true)
    return {}


func get_codex_unlock_counts() -> Dictionary:
    var codex: Dictionary = get_codex()
    var counts: Dictionary = {}
    var total: int = 0
    for key_var: Variant in codex.keys():
        var key: String = str(key_var)
        var rows: Array[String] = _as_string_array(codex.get(key, []))
        counts[key] = rows.size()
        total += rows.size()
    counts["global"] = total
    return counts


func get_codex_recent_unlocks(limit: int = 5) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var codex_meta: Dictionary = get_codex_meta()
    for key_var: Variant in codex_meta.keys():
        var key: String = str(key_var)
        var row_var: Variant = codex_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = (row_var as Dictionary).duplicate(true)
        var source: String = str(row.get("source", "")).strip_edges().to_lower()
        if source == "default" or source == "profile_sync":
            continue
        row["meta_key"] = key
        rows.append(row)

    rows.sort_custom(Callable(self, "_sort_codex_recent_desc"))
    var safe_limit: int = maxi(0, limit)
    if rows.size() > safe_limit:
        rows.resize(safe_limit)
    return rows


func set_selected_character_id(character_id: String) -> void:
    if character_id == "":
        return
    if get_selected_character_id() == character_id:
        return
    _meta["selected_character_id"] = character_id
    unlock_codex_entry("characters", character_id, "character_select")
    save_meta()


func unlock_codex_entry(category: String, entry_id: String, source: String = "", chapter_id: String = "") -> bool:
    var normalized_category: String = category.to_lower().strip_edges()
    var normalized_id: String = entry_id.strip_edges()
    var resolved_chapter_id: String = _resolve_codex_chapter_id(chapter_id)
    if normalized_category == "" or normalized_id == "":
        return false

    var codex: Dictionary = get_codex()
    if not codex.has(normalized_category):
        codex[normalized_category] = []

    var rows: Array[String] = _as_string_array(codex.get(normalized_category, []))
    if rows.has(normalized_id):
        var existing_meta: Dictionary = get_codex_meta()
        var existing_key: String = "%s:%s" % [normalized_category, normalized_id]
        if existing_meta.has(existing_key):
            var meta_row_var: Variant = existing_meta.get(existing_key, {})
            if meta_row_var is Dictionary:
                var meta_row: Dictionary = (meta_row_var as Dictionary).duplicate(true)
                var changed: bool = false
                if str(meta_row.get("chapter_id", "")).strip_edges() == "":
                    meta_row["chapter_id"] = resolved_chapter_id
                    changed = true
                if str(meta_row.get("source", "")).strip_edges() == "" and source.strip_edges() != "":
                    meta_row["source"] = source.strip_edges()
                    changed = true
                if changed:
                    existing_meta[existing_key] = meta_row
                    _meta["codex_meta"] = existing_meta
                    save_meta()
        return false

    rows.append(normalized_id)
    codex[normalized_category] = rows
    _meta["codex"] = codex

    var codex_meta: Dictionary = get_codex_meta()
    var meta_key: String = "%s:%s" % [normalized_category, normalized_id]
    codex_meta[meta_key] = _build_codex_meta_row(normalized_category, normalized_id, source, resolved_chapter_id)
    _meta["codex_meta"] = codex_meta

    if EventBus != null and EventBus.has_signal("codex_unlocked"):
        EventBus.codex_unlocked.emit(normalized_category, normalized_id)

    save_meta()
    return true


func get_upgrade_levels() -> Dictionary:
    var levels_var: Variant = _meta.get("upgrade_levels", {})
    if levels_var is Dictionary:
        return (levels_var as Dictionary).duplicate(true)
    return {}


func get_runtime_settings() -> Dictionary:
    var settings_var: Variant = _meta.get("runtime_settings", {})
    return _sanitize_runtime_settings(settings_var)


func get_default_runtime_settings() -> Dictionary:
    return _default_runtime_settings().duplicate(true)


func get_input_bindings() -> Dictionary:
    var bindings_var: Variant = _meta.get("input_bindings", {})
    return _sanitize_input_bindings(bindings_var)


func get_default_input_bindings() -> Dictionary:
    return _default_input_bindings().duplicate(true)


func update_input_bindings(bindings_patch: Dictionary) -> Dictionary:
    var merged: Dictionary = get_input_bindings()
    for key: Variant in bindings_patch.keys():
        merged[str(key)] = bindings_patch.get(key)
    _meta["input_bindings"] = _sanitize_input_bindings(merged)
    save_meta()
    apply_input_bindings()
    return get_input_bindings()


func reset_input_bindings() -> Dictionary:
    _meta["input_bindings"] = _default_input_bindings()
    save_meta()
    apply_input_bindings()
    return get_input_bindings()


func update_runtime_settings(patch: Dictionary) -> Dictionary:
    var current: Dictionary = get_runtime_settings()
    for key: Variant in patch.keys():
        current[str(key)] = patch.get(key)
    _meta["runtime_settings"] = _sanitize_runtime_settings(current)
    save_meta()
    apply_runtime_settings()
    return get_runtime_settings()


func get_upgrade_level(upgrade_id: String) -> int:
    var levels: Dictionary = get_upgrade_levels()
    return int(levels.get(upgrade_id, 0))


func get_upgrade_cost(upgrade_id: String) -> int:
    var row: Dictionary = _find_upgrade_row(upgrade_id)
    if row.is_empty():
        return -1

    var level: int = get_upgrade_level(upgrade_id)
    var max_level: int = int(row.get("max_level", 1))
    if level >= max_level:
        return -1

    var base_cost: int = int(row.get("base_cost", 50))
    var step_cost: int = int(row.get("cost_step", 25))
    return max(1, base_cost + step_cost * level)


func purchase_upgrade(upgrade_id: String) -> Dictionary:
    var row: Dictionary = _find_upgrade_row(upgrade_id)
    if row.is_empty():
        return {"ok": false, "reason": "missing_upgrade"}

    var cost: int = get_upgrade_cost(upgrade_id)
    if cost < 0:
        return {"ok": false, "reason": "max_level"}

    var currency: int = int(_meta.get("meta_currency", 0))
    if currency < cost:
        return {"ok": false, "reason": "not_enough_currency", "cost": cost, "currency": currency}

    var levels: Dictionary = get_upgrade_levels()
    var new_level: int = int(levels.get(upgrade_id, 0)) + 1
    levels[upgrade_id] = new_level
    _meta["upgrade_levels"] = levels
    _meta["meta_currency"] = currency - cost
    save_meta()

    return {
        "ok": true,
        "id": upgrade_id,
        "new_level": new_level,
        "cost": cost,
        "meta_currency": int(_meta.get("meta_currency", 0))
    }


func unlock_memory_fragment(fragment_id: String) -> bool:
    if fragment_id == "":
        return false

    var rows: Array[String] = get_unlocked_fragments()
    if rows.has(fragment_id):
        return false

    rows.append(fragment_id)
    _meta["unlocked_fragments"] = rows
    save_meta()
    return true


func load_meta() -> void:
    _meta = _default_meta()
    _last_run = {}

    if not FileAccess.file_exists(SAVE_PATH):
        save_meta()
        return

    var text: String = FileAccess.get_file_as_string(SAVE_PATH)
    var parsed: Variant = JSON.parse_string(text)
    if not (parsed is Dictionary):
        push_warning("Meta save corrupted, fallback to default")
        save_meta()
        return

    var data: Dictionary = parsed
    _meta["meta_currency"] = int(data.get("meta_currency", 0))
    _meta["total_runs"] = int(data.get("total_runs", 0))
    _meta["total_kills"] = int(data.get("total_kills", 0))
    _meta["highest_room"] = int(data.get("highest_room", 1))
    _meta["best_level"] = int(data.get("best_level", 1))
    _meta["best_alignment"] = float(data.get("best_alignment", 0.0))
    _meta["total_victories"] = int(data.get("total_victories", 0))
    _meta["unlocked_achievements"] = _as_string_array(data.get("unlocked_achievements", []))
    _meta["unlocked_endings"] = _as_string_array(data.get("unlocked_endings", []))
    _meta["unlocked_fragments"] = _as_string_array(data.get("unlocked_fragments", []))
    _meta["selected_character_id"] = str(data.get("selected_character_id", "char_knight"))
    _meta["upgrade_levels"] = _as_int_dictionary(data.get("upgrade_levels", {}))
    _meta["input_bindings"] = _sanitize_input_bindings(data.get("input_bindings", {}))
    _meta["runtime_settings"] = _sanitize_runtime_settings(data.get("runtime_settings", {}))
    _meta["codex"] = _sanitize_codex(data.get("codex", {}))
    _meta["codex_meta"] = _sanitize_codex_meta(data.get("codex_meta", {}))
    _meta["codex_stats_filters"] = _sanitize_codex_stats_filters(data.get("codex_stats_filters", {}))
    _last_run = data.get("last_run", {})

    var selected_character_id: String = str(_meta.get("selected_character_id", "")).strip_edges()
    if selected_character_id != "":
        var codex: Dictionary = get_codex()
        var rows: Array[String] = _as_string_array(codex.get("characters", []))
        if not rows.has(selected_character_id):
            rows.append(selected_character_id)
            codex["characters"] = rows
            _meta["codex"] = codex

        var codex_meta: Dictionary = get_codex_meta()
        var selected_key: String = "characters:%s" % selected_character_id
        if not codex_meta.has(selected_key):
            codex_meta[selected_key] = _build_codex_meta_row("characters", selected_character_id, "profile_sync", "global")
            _meta["codex_meta"] = codex_meta


func save_meta() -> void:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("Cannot write save file: %s" % SAVE_PATH)
        return

    var payload: Dictionary = _meta.duplicate(true)
    payload["last_run"] = _last_run
    file.store_string(JSON.stringify(payload, "  "))


func submit_run_result(result: Dictionary) -> Dictionary:
    var rooms_cleared: int = int(result.get("rooms_cleared", 0))
    var kills: int = int(result.get("kills", 0))
    var level_reached: int = int(result.get("level_reached", 1))
    var alignment: float = float(result.get("alignment", 0.0))
    var outcome: String = str(result.get("outcome", "death"))
    var ending_id: String = ""
    var ending_new_unlock: bool = false

    var reward: int = _calc_meta_reward(result)

    _meta["meta_currency"] = int(_meta.get("meta_currency", 0)) + reward
    _meta["total_runs"] = int(_meta.get("total_runs", 0)) + 1
    _meta["total_kills"] = int(_meta.get("total_kills", 0)) + kills
    _meta["highest_room"] = maxi(int(_meta.get("highest_room", 1)), rooms_cleared + 1)
    _meta["best_level"] = maxi(int(_meta.get("best_level", 1)), level_reached)
    if outcome == "victory":
        _meta["total_victories"] = int(_meta.get("total_victories", 0)) + 1
        ending_id = _resolve_ending(alignment)
        ending_new_unlock = _unlock_ending(ending_id)
    if absf(alignment) > absf(float(_meta.get("best_alignment", 0.0))):
        _meta["best_alignment"] = alignment

    var unlocked_in_run: Array[String] = _process_achievements(result)

    _last_run = {
        "outcome": outcome,
        "rooms_cleared": rooms_cleared,
        "kills": kills,
        "level_reached": level_reached,
        "gold": int(result.get("gold", 0)),
        "ore": int(result.get("ore", 0)),
        "alignment": alignment,
        "meta_reward": reward,
        "ending_id": ending_id,
        "ending_new_unlock": ending_new_unlock,
        "ending_epilogue": _get_ending_epilogue(ending_id, ending_new_unlock),
        "new_achievements": unlocked_in_run,
        "narrative_choices": result.get("narrative_choices", []),
        "chapter_effect_timeline": result.get("chapter_effect_timeline", []),
        "chapter_route_styles": result.get("chapter_route_styles", {}),
        "route_style_timeline": result.get("route_style_timeline", [])
    }

    save_meta()
    return _last_run.duplicate(true)


func reset_meta() -> void:
    _meta = _default_meta()
    _last_run = {}
    save_meta()


func _calc_meta_reward(result: Dictionary) -> int:
    var kills: int = int(result.get("kills", 0))
    var rooms_cleared: int = int(result.get("rooms_cleared", 0))
    var level_reached: int = int(result.get("level_reached", 1))
    var gold: int = int(result.get("gold", 0))
    var ore: int = int(result.get("ore", 0))
    var outcome: String = str(result.get("outcome", "death"))

    var reward: int = 12
    reward += int(kills * 0.25)
    reward += rooms_cleared * 9
    reward += max(0, level_reached - 1) * 2
    reward += int(gold * 0.1)
    reward += ore * 3
    if outcome == "victory":
        reward += 60

    return maxi(5, reward)


func _default_meta() -> Dictionary:
    return {
        "meta_currency": 0,
        "total_runs": 0,
        "total_kills": 0,
        "highest_room": 1,
        "best_level": 1,
        "best_alignment": 0.0,
        "total_victories": 0,
        "unlocked_achievements": [],
        "unlocked_endings": [],
        "unlocked_fragments": [],
        "selected_character_id": "char_knight",
        "upgrade_levels": {},
        "input_bindings": _default_input_bindings(),
        "codex": {
            "characters": ["char_knight"],
            "weapons": [],
            "passives": [],
            "enemies": [],
            "accessories": []
        },
        "codex_meta": {
            "characters:char_knight": {
                "category": "characters",
            "entry_id": "char_knight",
            "source": "default",
            "chapter_id": "global",
            "discovered_at": "init",
            "run_index": 0
        }
        },
        "codex_stats_filters": {
            "source": "all",
            "chapter": "all"
        },
        "runtime_settings": _default_runtime_settings()
    }


func _default_runtime_settings() -> Dictionary:
    return {
        "master_volume": 1.0,
        "bgm_volume": 1.0,
        "sfx_volume": 1.0,
        "ambience_volume": 1.0,
        "screen_shake": 1.0,
        "ui_scale": 1.0
    }


func _default_input_bindings() -> Dictionary:
    if GameManager != null and GameManager.has_method("get_default_input_bindings"):
        return GameManager.get_default_input_bindings()
    return {
        "move_up": {"keys": [KEY_W, KEY_UP], "joypad_buttons": [JOY_BUTTON_DPAD_UP]},
        "move_down": {"keys": [KEY_S, KEY_DOWN], "joypad_buttons": [JOY_BUTTON_DPAD_DOWN]},
        "move_left": {"keys": [KEY_A, KEY_LEFT], "joypad_buttons": [JOY_BUTTON_DPAD_LEFT]},
        "move_right": {"keys": [KEY_D, KEY_RIGHT], "joypad_buttons": [JOY_BUTTON_DPAD_RIGHT]},
        "sprint": {"keys": [KEY_SHIFT], "joypad_buttons": [JOY_BUTTON_RIGHT_SHOULDER]},
        "interact": {"keys": [KEY_E], "joypad_buttons": [JOY_BUTTON_A]},
        "pause": {"keys": [KEY_ESCAPE], "joypad_buttons": [JOY_BUTTON_START]}
    }


func _sanitize_input_bindings(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    if GameManager != null and GameManager.has_method("sanitize_input_bindings"):
        return GameManager.sanitize_input_bindings(source)
    return _default_input_bindings()


func _sanitize_runtime_settings(value: Variant) -> Dictionary:
    var defaults: Dictionary = _default_runtime_settings()
    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    var out: Dictionary = defaults.duplicate(true)
    out["master_volume"] = clampf(float(source.get("master_volume", out["master_volume"])), 0.0, 1.0)
    out["bgm_volume"] = clampf(float(source.get("bgm_volume", out["bgm_volume"])), 0.0, 1.0)
    out["sfx_volume"] = clampf(float(source.get("sfx_volume", out["sfx_volume"])), 0.0, 1.0)
    out["ambience_volume"] = clampf(float(source.get("ambience_volume", out["ambience_volume"])), 0.0, 1.0)
    out["screen_shake"] = clampf(float(source.get("screen_shake", out["screen_shake"])), 0.0, 1.0)
    out["ui_scale"] = clampf(float(source.get("ui_scale", out["ui_scale"])), 0.8, 1.5)
    return out


func apply_runtime_settings() -> void:
    var settings: Dictionary = get_runtime_settings()
    if AudioManager != null and AudioManager.has_method("apply_runtime_settings"):
        AudioManager.apply_runtime_settings(settings)

    var scale: float = clampf(float(settings.get("ui_scale", 1.0)), 0.8, 1.5)
    if get_tree() != null and get_tree().root != null:
        get_tree().root.content_scale_factor = scale

    if EventBus != null and EventBus.has_signal("settings_changed"):
        EventBus.settings_changed.emit(settings)


func apply_input_bindings() -> void:
    var bindings: Dictionary = get_input_bindings()
    if GameManager != null and GameManager.has_method("apply_input_bindings"):
        GameManager.apply_input_bindings(bindings)


func _on_memory_fragment_found(fragment_id: String) -> void:
    unlock_memory_fragment(fragment_id)


func _on_enemy_killed(enemy_id: String, _position: Vector2) -> void:
    unlock_codex_entry("enemies", enemy_id, "enemy_kill", _resolve_codex_chapter_id(""))


func _on_accessory_acquired(accessory_id: String) -> void:
    unlock_codex_entry("accessories", accessory_id, "accessory_pickup", _resolve_codex_chapter_id(""))


func _process_achievements(result: Dictionary) -> Array[String]:
    var unlocked: Array[String] = _as_string_array(_meta.get("unlocked_achievements", []))
    var config: Dictionary = ConfigManager.get_config("achievements", {})
    var rows: Array = config.get("achievements", [])
    var new_unlocks: Array[String] = []

    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var ach_id: String = str(row.get("id", ""))
        var condition: String = str(row.get("condition", ""))
        if ach_id == "" or condition == "":
            continue
        if unlocked.has(ach_id):
            continue
        if not _check_achievement_condition(condition, result):
            continue

        unlocked.append(ach_id)
        new_unlocks.append(ach_id)
        EventBus.achievement_unlocked.emit(ach_id, str(row.get("title", ach_id)))

    _meta["unlocked_achievements"] = unlocked
    return new_unlocks


func _check_achievement_condition(condition: String, result: Dictionary) -> bool:
    if condition.begins_with("clear_floor_"):
        var needed_room: int = _extract_suffix_int(condition, "clear_floor_")
        return int(result.get("rooms_cleared", 0)) >= needed_room

    if condition.begins_with("alignment_ge_"):
        var needed_alignment: int = _extract_suffix_int(condition, "alignment_ge_")
        return float(result.get("alignment", 0.0)) >= float(needed_alignment)

    if condition.begins_with("alignment_le_"):
        var max_alignment: int = _extract_suffix_int(condition, "alignment_le_")
        return float(result.get("alignment", 0.0)) <= float(max_alignment)

    if condition.begins_with("kills_ge_"):
        var needed_kills: int = _extract_suffix_int(condition, "kills_ge_")
        return int(result.get("kills", 0)) >= needed_kills

    if condition.begins_with("reach_level_"):
        var needed_level: int = _extract_suffix_int(condition, "reach_level_")
        return int(result.get("level_reached", 1)) >= needed_level

    if condition == "victory_once":
        return str(result.get("outcome", "")) == "victory"

    return false


func _resolve_ending(alignment: float) -> String:
    if alignment >= 60.0:
        return ENDING_REDEEM
    if alignment <= -60.0:
        return ENDING_FALL
    return ENDING_BALANCE


func _unlock_ending(ending_id: String) -> bool:
    if ending_id == "":
        return false
    var endings: Array[String] = _as_string_array(_meta.get("unlocked_endings", []))
    if endings.has(ending_id):
        return false

    endings.append(ending_id)
    _meta["unlocked_endings"] = endings
    EventBus.ending_unlocked.emit(ending_id)
    return true


func _get_ending_epilogue(ending_id: String, newly_unlocked: bool) -> String:
    if ending_id == "":
        return ""

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var ending_rows_var: Variant = config.get("endings", {})
    if ending_rows_var is Dictionary:
        var row_var: Variant = (ending_rows_var as Dictionary).get(ending_id, {})
        if row_var is Dictionary:
            var row: Dictionary = row_var
            if newly_unlocked:
                return str(row.get("epilogue_first_unlock", row.get("story", "")))
            return str(row.get("epilogue_repeat", row.get("story", "")))

    if newly_unlocked:
        return "A new ending is engraved into the memory archive."
    return "The ending echoes differently on this repeated cycle."


func _extract_suffix_int(value: String, prefix: String) -> int:
    var suffix: String = value.trim_prefix(prefix)
    if suffix.is_valid_int():
        return int(suffix)
    return 0


func _as_string_array(value: Variant) -> Array[String]:
    var result: Array[String] = []
    if value is Array:
        for item: Variant in value:
            result.append(str(item))
    return result


func _as_int_dictionary(value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if value is Dictionary:
        var source: Dictionary = value
        for key: Variant in source.keys():
            result[str(key)] = int(source.get(key, 0))
    return result


func _sanitize_codex(value: Variant) -> Dictionary:
    var template: Dictionary = {
        "characters": [],
        "weapons": [],
        "passives": [],
        "enemies": [],
        "accessories": []
    }

    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    var out: Dictionary = template.duplicate(true)
    for key: Variant in out.keys():
        var key_name: String = str(key)
        out[key_name] = _as_string_array(source.get(key_name, []))
    return out


func _sanitize_codex_meta(value: Variant) -> Dictionary:
    var out: Dictionary = {}
    if not (value is Dictionary):
        return out

    var source: Dictionary = value
    for key_var: Variant in source.keys():
        var key: String = str(key_var)
        var row_var: Variant = source.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        out[key] = {
            "category": str(row.get("category", "")),
            "entry_id": str(row.get("entry_id", "")),
            "source": str(row.get("source", "")),
            "chapter_id": _resolve_codex_chapter_id(str(row.get("chapter_id", ""))),
            "discovered_at": str(row.get("discovered_at", "")),
            "run_index": int(row.get("run_index", 0))
        }
    return out


func _sanitize_codex_stats_filters(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    var source_id: String = str(source.get("source", "all")).strip_edges().to_lower()
    var chapter_id: String = str(source.get("chapter", "all")).strip_edges().to_lower()
    if source_id == "":
        source_id = "all"
    if chapter_id == "":
        chapter_id = "all"

    return {
        "source": source_id,
        "chapter": chapter_id
    }


func _build_codex_meta_row(category: String, entry_id: String, source: String, chapter_id: String = "") -> Dictionary:
    var now_text: String = Time.get_datetime_string_from_system(true, true)
    var run_index: int = int(_meta.get("total_runs", 0)) + 1
    return {
        "category": category,
        "entry_id": entry_id,
        "source": source.strip_edges(),
        "chapter_id": _resolve_codex_chapter_id(chapter_id),
        "discovered_at": now_text,
        "run_index": run_index
    }


func _resolve_codex_chapter_id(chapter_id: String) -> String:
    var normalized: String = chapter_id.strip_edges().to_lower()
    if _is_valid_chapter_id(normalized):
        return normalized

    if GameManager != null:
        var runtime_chapter: String = str(GameManager.current_chapter_id).strip_edges().to_lower()
        if _is_valid_chapter_id(runtime_chapter):
            return runtime_chapter

    return "global"


func _is_valid_chapter_id(chapter_id: String) -> bool:
    if chapter_id == "global":
        return true
    if not chapter_id.begins_with("chapter_"):
        return false
    var suffix: String = chapter_id.trim_prefix("chapter_")
    if not suffix.is_valid_int():
        return false
    return int(suffix) > 0


func _sort_codex_recent_desc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a > run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a > time_b

    var entry_a: String = str(a.get("entry_id", ""))
    var entry_b: String = str(b.get("entry_id", ""))
    return entry_a < entry_b


func _find_upgrade_row(upgrade_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("meta_upgrades", {})
    var rows: Variant = config.get("upgrades", [])
    if not (rows is Array):
        return {}

    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        if str(row.get("id", "")) == upgrade_id:
            return row

    return {}
