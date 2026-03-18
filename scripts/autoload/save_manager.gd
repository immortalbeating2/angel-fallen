extends Node

const SAVE_PATH: String = "user://meta_save.json"
const ENDING_REDEEM: String = "nar_ending_redeem"
const ENDING_FALL: String = "nar_ending_fall"
const ENDING_BALANCE: String = "nar_ending_balance"

var _meta: Dictionary = {}
var _last_run: Dictionary = {}


func _ready() -> void:
    load_meta()
    if EventBus != null and EventBus.has_signal("memory_fragment_found") and not EventBus.memory_fragment_found.is_connected(_on_memory_fragment_found):
        EventBus.memory_fragment_found.connect(_on_memory_fragment_found)


func get_meta() -> Dictionary:
    return _meta.duplicate(true)


func get_last_run() -> Dictionary:
    return _last_run.duplicate(true)


func get_unlocked_achievements() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_achievements", []))


func get_unlocked_endings() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_endings", []))


func get_unlocked_fragments() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_fragments", []))


func get_upgrade_levels() -> Dictionary:
    var levels_var: Variant = _meta.get("upgrade_levels", {})
    if levels_var is Dictionary:
        return (levels_var as Dictionary).duplicate(true)
    return {}


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
    _meta["upgrade_levels"] = _as_int_dictionary(data.get("upgrade_levels", {}))
    _last_run = data.get("last_run", {})


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

    var reward: int = _calc_meta_reward(result)

    _meta["meta_currency"] = int(_meta.get("meta_currency", 0)) + reward
    _meta["total_runs"] = int(_meta.get("total_runs", 0)) + 1
    _meta["total_kills"] = int(_meta.get("total_kills", 0)) + kills
    _meta["highest_room"] = maxi(int(_meta.get("highest_room", 1)), rooms_cleared + 1)
    _meta["best_level"] = maxi(int(_meta.get("best_level", 1)), level_reached)
    if outcome == "victory":
        _meta["total_victories"] = int(_meta.get("total_victories", 0)) + 1
        ending_id = _resolve_ending(alignment)
        _unlock_ending(ending_id)
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
        "new_achievements": unlocked_in_run,
        "narrative_choices": result.get("narrative_choices", [])
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
        "upgrade_levels": {}
    }


func _on_memory_fragment_found(fragment_id: String) -> void:
    unlock_memory_fragment(fragment_id)


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


func _unlock_ending(ending_id: String) -> void:
    if ending_id == "":
        return
    var endings: Array[String] = _as_string_array(_meta.get("unlocked_endings", []))
    if endings.has(ending_id):
        return

    endings.append(ending_id)
    _meta["unlocked_endings"] = endings
    EventBus.ending_unlocked.emit(ending_id)


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
