extends Node

const MAX_WEAPON_SLOTS: int = 6
const MAX_PASSIVE_SLOTS: int = 6
const MAX_LEVEL: int = 8

var weapon_slots: Array[Dictionary] = []
var passive_slots: Array[Dictionary] = []
var _level_config: Dictionary = {}


func _ready() -> void:
    _ensure_config_loaded()


func setup_starting_weapon(weapon_id: String, style: String = "") -> Dictionary:
    weapon_slots.clear()
    passive_slots.clear()
    var clean_id: String = weapon_id.strip_edges()
    if clean_id == "":
        clean_id = "wpn_magic_missile"
    var row: Dictionary = _create_weapon_slot(clean_id, style, 1)
    weapon_slots.append(row)
    return {"accepted": true, "slot_index": 0, "level": 1, "weapon": row.duplicate(true)}


func add_or_level_weapon(weapon_id: String, style: String = "") -> Dictionary:
    var clean_id: String = weapon_id.strip_edges()
    if clean_id == "":
        return {"accepted": false, "reason": "invalid_weapon_id"}

    var index: int = _find_slot_index(weapon_slots, clean_id)
    if index >= 0:
        var slot: Dictionary = weapon_slots[index]
        slot["level"] = mini(MAX_LEVEL, int(slot.get("level", 1)) + 1)
        slot["stats"] = get_weapon_level_profile(clean_id, int(slot.get("level", 1)))
        slot["evolved"] = bool(slot.get("evolved", false))
        weapon_slots[index] = slot
        return {"accepted": true, "upgraded": true, "slot_index": index, "level": int(slot.get("level", 1)), "weapon": slot.duplicate(true)}

    if weapon_slots.size() >= MAX_WEAPON_SLOTS:
        return {"accepted": false, "reason": "weapon_slots_full", "slot_index": -1}

    var new_slot: Dictionary = _create_weapon_slot(clean_id, style, 1)
    weapon_slots.append(new_slot)
    return {"accepted": true, "upgraded": false, "slot_index": weapon_slots.size() - 1, "level": 1, "weapon": new_slot.duplicate(true)}


func add_or_level_passive(passive_id: String) -> Dictionary:
    var clean_id: String = passive_id.strip_edges()
    if clean_id == "":
        return {"accepted": false, "reason": "invalid_passive_id"}

    var index: int = _find_slot_index(passive_slots, clean_id)
    if index >= 0:
        var slot: Dictionary = passive_slots[index]
        slot["level"] = mini(MAX_LEVEL, int(slot.get("level", 1)) + 1)
        passive_slots[index] = slot
        return {"accepted": true, "upgraded": true, "slot_index": index, "level": int(slot.get("level", 1)), "passive": slot.duplicate(true)}

    if passive_slots.size() >= MAX_PASSIVE_SLOTS:
        return {"accepted": false, "reason": "passive_slots_full", "slot_index": -1}

    var new_slot: Dictionary = {"id": clean_id, "level": 1, "stats": {}}
    passive_slots.append(new_slot)
    return {"accepted": true, "upgraded": false, "slot_index": passive_slots.size() - 1, "level": 1, "passive": new_slot.duplicate(true)}


func get_weapon_level(weapon_id: String) -> int:
    var index: int = _find_slot_index(weapon_slots, weapon_id)
    if index < 0:
        return 0
    return int(weapon_slots[index].get("level", 0))


func get_passive_level(passive_id: String) -> int:
    var index: int = _find_slot_index(passive_slots, passive_id)
    if index < 0:
        return 0
    return int(passive_slots[index].get("level", 0))


func is_weapon_full(weapon_id: String) -> bool:
    return get_weapon_level(weapon_id) >= MAX_LEVEL


func mark_weapon_evolved(weapon_id: String, result_weapon_id: String = "") -> void:
    var index: int = _find_slot_index(weapon_slots, weapon_id)
    if index < 0:
        return
    var slot: Dictionary = weapon_slots[index]
    slot["evolved"] = true
    if result_weapon_id.strip_edges() != "":
        slot["evolved_id"] = result_weapon_id.strip_edges()
    weapon_slots[index] = slot


func apply_weapon_evolution(recipe: Dictionary) -> bool:
    var weapon_id: String = str(recipe.get("weapon_id", "")).strip_edges()
    var result_weapon_id: String = str(recipe.get("result_weapon_id", "")).strip_edges()
    if weapon_id == "" or result_weapon_id == "":
        return false

    var index: int = _find_slot_index(weapon_slots, weapon_id)
    if index < 0:
        return false

    var profile_var: Variant = recipe.get("evolution_profile", {})
    var profile: Dictionary = profile_var.duplicate(true) if profile_var is Dictionary else {}
    profile["weapon_id"] = result_weapon_id
    profile["level"] = MAX_LEVEL
    profile["max_level"] = MAX_LEVEL

    var slot: Dictionary = weapon_slots[index]
    slot["evolved"] = true
    slot["evolved_id"] = result_weapon_id
    slot["stats"] = profile
    if profile.has("projectile_style"):
        slot["style"] = str(profile.get("projectile_style", slot.get("style", "")))
    weapon_slots[index] = slot
    return true


func has_weapon_evolved(weapon_id: String, result_weapon_id: String = "") -> bool:
    var index: int = _find_slot_index(weapon_slots, weapon_id)
    if index < 0:
        return false
    var slot: Dictionary = weapon_slots[index]
    if result_weapon_id.strip_edges() != "":
        return str(slot.get("evolved_id", "")) == result_weapon_id.strip_edges()
    return bool(slot.get("evolved", false))


func get_weapon_level_profile(weapon_id: String, level: int = -1) -> Dictionary:
    _ensure_config_loaded()
    var clean_id: String = weapon_id.strip_edges()
    var target_level: int = clampi(level, 1, MAX_LEVEL)
    if level < 0:
        target_level = maxi(1, get_weapon_level(clean_id))

    var weapons: Dictionary = _level_config.get("weapons", {})
    var row: Dictionary = {}
    if weapons.get(clean_id, {}) is Dictionary:
        row = weapons.get(clean_id, {})

    var levels: Dictionary = {}
    if row.get("levels", {}) is Dictionary:
        levels = row.get("levels", {})
    if levels.is_empty() and _level_config.get("default_levels", {}) is Dictionary:
        levels = _level_config.get("default_levels", {})

    var profile: Dictionary = {}
    var level_row_var: Variant = levels.get(str(target_level), {})
    if level_row_var is Dictionary:
        profile = level_row_var.duplicate(true)

    profile["weapon_id"] = clean_id
    profile["level"] = target_level
    profile["max_level"] = MAX_LEVEL
    if not profile.has("projectile_style"):
        profile["projectile_style"] = str(row.get("projectile_style", clean_id.trim_prefix("wpn_")))
    if not profile.has("style"):
        profile["style"] = str(row.get("style", profile.get("projectile_style", "")))
    if row.has("tags"):
        profile["special_tags"] = row.get("tags", [])
    return profile


func get_snapshot() -> Dictionary:
    return {
        "weapon_slots": weapon_slots.duplicate(true),
        "passive_slots": passive_slots.duplicate(true),
        "max_weapon_slots": MAX_WEAPON_SLOTS,
        "max_passive_slots": MAX_PASSIVE_SLOTS,
        "max_level": MAX_LEVEL,
    }


func _create_weapon_slot(weapon_id: String, style: String, level: int) -> Dictionary:
    var profile: Dictionary = get_weapon_level_profile(weapon_id, level)
    var resolved_style: String = style.strip_edges()
    if resolved_style == "":
        resolved_style = str(profile.get("style", profile.get("projectile_style", "")))
    return {
        "id": weapon_id,
        "level": clampi(level, 1, MAX_LEVEL),
        "style": resolved_style,
        "stats": profile,
        "evolved": false,
    }


func _find_slot_index(slots: Array[Dictionary], item_id: String) -> int:
    var clean_id: String = item_id.strip_edges()
    for i in range(slots.size()):
        if str(slots[i].get("id", "")) == clean_id:
            return i
    return -1


func _ensure_config_loaded() -> void:
    if not _level_config.is_empty():
        return
    if ConfigManager != null:
        _level_config = ConfigManager.get_config("weapon_levels", {})
    if _level_config.is_empty():
        var file: FileAccess = FileAccess.open("res://data/balance/weapon_levels.json", FileAccess.READ)
        if file != null:
            var parsed: Variant = JSON.parse_string(file.get_as_text())
            if parsed is Dictionary:
                _level_config = parsed
