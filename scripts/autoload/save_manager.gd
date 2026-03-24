extends Node

const SAVE_PATH: String = "user://meta_save.json"
const ENDING_REDEEM: String = "nar_ending_redeem"
const ENDING_FALL: String = "nar_ending_fall"
const ENDING_BALANCE: String = "nar_ending_balance"
const HIDDEN_LAYER_FS1: String = "FS1"
const HIDDEN_LAYER_FS2: String = "FS2"
const FS1_REQUIRED_FLAWLESS_CHAPTERS: Array[String] = ["chapter_1", "chapter_2", "chapter_3"]
const FS2_REQUIRED_BOSS_ACCESSORIES: Array[String] = ["acc_heart_of_mine", "acc_flame_core", "acc_zero_mark", "acc_void_eye"]
const FS1_ARCHIVE_BOSS_ECHOES: Array[String] = ["boss_rock_colossus", "boss_flame_lord", "boss_frost_king", "boss_void_lord"]
const FS2_TRIAL_ARCHIVE_TOTAL: int = 5
const FS1_MASTERY_BONUS_FRAGMENTS: int = 2
const FS1_MASTERY_BONUS_REWINDS: int = 1
const FS2_MASTERY_BONUS_DRAFTS: int = 1
const FS2_MASTERY_BONUS_MERGES: int = 1
const META_UPGRADE_BASE_CAP: int = 3
const META_UPGRADE_HARD_CAP: int = 4
const META_UPGRADE_NIGHTMARE_CAP: int = 5
const META_UPGRADE_NIGHTMARE_HIDDEN_CAP: int = 6
const CHALLENGE_LAYER_CL1: String = "CL1"

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


func get_achievement_meta() -> Dictionary:
    var meta_var: Variant = _meta.get("achievement_meta", {})
    return _sanitize_achievement_meta(meta_var)


func get_achievement_recent_unlocks(limit: int = 5) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var achievement_meta: Dictionary = get_achievement_meta()
    for key_var: Variant in achievement_meta.keys():
        var key: String = str(key_var)
        var row_var: Variant = achievement_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = (row_var as Dictionary).duplicate(true)
        row["meta_key"] = key
        rows.append(row)

    rows.sort_custom(Callable(self, "_sort_achievement_recent_desc"))
    var safe_limit: int = maxi(0, limit)
    if rows.size() > safe_limit:
        rows.resize(safe_limit)
    return rows


func get_unlocked_endings() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_endings", []))


func get_ending_meta() -> Dictionary:
    var meta_var: Variant = _meta.get("ending_meta", {})
    return _sanitize_ending_meta(meta_var)


func get_ending_recent_unlocks(limit: int = 5) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var ending_meta: Dictionary = get_ending_meta()
    for key_var: Variant in ending_meta.keys():
        var key: String = str(key_var)
        var row_var: Variant = ending_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = (row_var as Dictionary).duplicate(true)
        row["meta_key"] = key
        rows.append(row)

    rows.sort_custom(Callable(self, "_sort_ending_recent_desc"))
    var safe_limit: int = maxi(0, limit)
    if rows.size() > safe_limit:
        rows.resize(safe_limit)
    return rows


func get_ordered_unlocked_endings() -> Array[String]:
    var unlocked: Array[String] = get_unlocked_endings()
    var ending_meta: Dictionary = get_ending_meta()
    var rows: Array[Dictionary] = []
    var ordered: Array[String] = []
    for key_var: Variant in ending_meta.keys():
        var row_var: Variant = ending_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        rows.append((row_var as Dictionary).duplicate(true))

    rows.sort_custom(Callable(self, "_sort_ending_recent_asc"))
    for row: Dictionary in rows:
        var ending_id: String = str(row.get("ending_id", "")).strip_edges()
        if ending_id == "" or not unlocked.has(ending_id) or ordered.has(ending_id):
            continue
        ordered.append(ending_id)

    for ending_id: String in unlocked:
        if ending_id == "" or ordered.has(ending_id):
            continue
        ordered.append(ending_id)
    return ordered


func get_unlocked_fragments() -> Array[String]:
    return _as_string_array(_meta.get("unlocked_fragments", []))


func get_fragment_meta() -> Dictionary:
    var meta_var: Variant = _meta.get("fragment_meta", {})
    return _sanitize_fragment_meta(meta_var)


func get_fragment_recent_unlocks(limit: int = 5) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var fragment_meta: Dictionary = get_fragment_meta()
    for key_var: Variant in fragment_meta.keys():
        var key: String = str(key_var)
        var row_var: Variant = fragment_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = (row_var as Dictionary).duplicate(true)
        row["meta_key"] = key
        rows.append(row)

    rows.sort_custom(Callable(self, "_sort_fragment_recent_desc"))
    var safe_limit: int = maxi(0, limit)
    if rows.size() > safe_limit:
        rows.resize(safe_limit)
    return rows


func get_ordered_unlocked_fragments() -> Array[String]:
    var unlocked: Array[String] = get_unlocked_fragments()
    var fragment_meta: Dictionary = get_fragment_meta()
    var rows: Array[Dictionary] = []
    var ordered: Array[String] = []
    for key_var: Variant in fragment_meta.keys():
        var row_var: Variant = fragment_meta.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        rows.append((row_var as Dictionary).duplicate(true))

    rows.sort_custom(Callable(self, "_sort_fragment_recent_asc"))
    for row: Dictionary in rows:
        var fragment_id: String = str(row.get("fragment_id", "")).strip_edges()
        if fragment_id == "" or not unlocked.has(fragment_id) or ordered.has(fragment_id):
            continue
        ordered.append(fragment_id)

    for fragment_id: String in unlocked:
        if fragment_id == "" or ordered.has(fragment_id):
            continue
        ordered.append(fragment_id)
    return ordered


func get_hidden_layer_statuses() -> Dictionary:
    var rows: Dictionary = {}
    rows[HIDDEN_LAYER_FS1] = _build_hidden_layer_status(HIDDEN_LAYER_FS1)
    rows[HIDDEN_LAYER_FS2] = _build_hidden_layer_status(HIDDEN_LAYER_FS2)
    return rows


func get_hidden_layer_status(layer_id: String) -> Dictionary:
    return _build_hidden_layer_status(layer_id)


func get_challenge_layer_records() -> Dictionary:
    return _sanitize_challenge_layer_records(_meta.get("challenge_layer_records", {}))


func get_challenge_layer_record(layer_id: String) -> Dictionary:
    return _as_dictionary(get_challenge_layer_records().get(layer_id.strip_edges().to_upper(), {}))


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


func get_difficulty_profile(tier: int = -1) -> Dictionary:
    var resolved_tier: int = tier
    if resolved_tier < 0:
        resolved_tier = int(get_runtime_settings().get("difficulty_tier", 0))
    resolved_tier = clampi(resolved_tier, 0, 2)

    var profiles: Array[Dictionary] = [
        {
            "tier": 0,
            "label": "Normal",
            "spawn_rate_mult": 1.0,
            "enemy_hp_mult": 1.0,
            "enemy_damage_mult": 1.0,
            "hazard_intensity_mult": 1.0,
            "xp_reward_mult": 1.0,
            "gold_reward_mult": 1.0,
            "ore_reward_mult": 1.0,
            "treasure_reward_mult": 1.0,
            "meta_reward_mult": 1.0
        },
        {
            "tier": 1,
            "label": "Hard",
            "spawn_rate_mult": 1.08,
            "enemy_hp_mult": 1.12,
            "enemy_damage_mult": 1.1,
            "hazard_intensity_mult": 1.1,
            "xp_reward_mult": 1.05,
            "gold_reward_mult": 1.08,
            "ore_reward_mult": 1.1,
            "treasure_reward_mult": 1.12,
            "meta_reward_mult": 1.15
        },
        {
            "tier": 2,
            "label": "Nightmare",
            "spawn_rate_mult": 1.16,
            "enemy_hp_mult": 1.22,
            "enemy_damage_mult": 1.18,
            "hazard_intensity_mult": 1.22,
            "xp_reward_mult": 1.1,
            "gold_reward_mult": 1.16,
            "ore_reward_mult": 1.22,
            "treasure_reward_mult": 1.28,
            "meta_reward_mult": 1.3
        }
    ]
    return profiles[resolved_tier].duplicate(true)


func get_difficulty_label(tier: int = -1) -> String:
    return str(get_difficulty_profile(tier).get("label", "Normal"))


func get_difficulty_summary(tier: int = -1) -> String:
    var profile: Dictionary = get_difficulty_profile(tier)
    return "Haz x%.2f | G x%.2f | O x%.2f | T x%.2f" % [
        float(profile.get("hazard_intensity_mult", 1.0)),
        float(profile.get("gold_reward_mult", 1.0)),
        float(profile.get("ore_reward_mult", 1.0)),
        float(profile.get("treasure_reward_mult", 1.0))
    ]


func get_max_unlocked_difficulty_tier() -> int:
    var max_tier: int = 0
    if not get_unlocked_endings().is_empty():
        max_tier = 1

    var records: Dictionary = _sanitize_hidden_layer_records(_meta.get("hidden_layer_records", {}))
    var fs1_record: Dictionary = _as_dictionary(records.get(HIDDEN_LAYER_FS1, {}))
    var fs2_record: Dictionary = _as_dictionary(records.get(HIDDEN_LAYER_FS2, {}))
    if bool(fs1_record.get("collection_mastered", false)) or bool(fs2_record.get("collection_mastered", false)):
        max_tier = 2
    return max_tier


func get_next_difficulty_unlock_hint() -> String:
    match get_max_unlocked_difficulty_tier():
        0:
            return "Unlock Hard: clear any ending once"
        1:
            return "Unlock Nightmare: master any hidden-layer archive"
        _:
            return "All difficulty tiers unlocked"


func get_difficulty_records() -> Dictionary:
    return _sanitize_difficulty_records(_meta.get("difficulty_records", {}))


func get_difficulty_record(tier: int) -> Dictionary:
    var key: String = _get_difficulty_record_key(tier)
    return _as_dictionary(get_difficulty_records().get(key, {}))


func get_meta_return_profile() -> Dictionary:
    var records: Dictionary = get_difficulty_records()
    var milestones: Array[Dictionary] = _get_meta_return_milestones()
    var unlocked_rows: Array[Dictionary] = []
    var unlocked_ids: Array[String] = []
    var multiplier: float = 1.0
    var next_hint: String = "All meta returns unlocked"

    for row: Dictionary in milestones:
        if _is_meta_return_milestone_unlocked(row, records):
            unlocked_rows.append(row.duplicate(true))
            unlocked_ids.append(str(row.get("id", "")).strip_edges())
            multiplier += float(row.get("bonus_mult", 0.0))
        elif next_hint == "All meta returns unlocked":
            next_hint = str(row.get("hint", "")).strip_edges()

    return {
        "multiplier": multiplier,
        "summary": "Return x%.2f" % multiplier,
        "next_hint": next_hint,
        "unlocked_ids": unlocked_ids,
        "unlocked_rows": unlocked_rows
    }


func get_meta_upgrade_level_cap(upgrade_id: String = "") -> int:
    var max_level: int = _get_meta_upgrade_config_max_level(upgrade_id)
    if max_level <= 0:
        return 0

    var cap: int = mini(max_level, META_UPGRADE_BASE_CAP)
    var unlocked_ids: Array[String] = _sanitize_nonempty_string_array(get_meta_return_profile().get("unlocked_ids", []))
    if unlocked_ids.has("hard_meta_return"):
        cap = mini(max_level, maxi(cap, META_UPGRADE_HARD_CAP))
    if unlocked_ids.has("nightmare_meta_return"):
        cap = mini(max_level, maxi(cap, META_UPGRADE_NIGHTMARE_CAP))
    if unlocked_ids.has("nightmare_hidden_meta_return"):
        cap = mini(max_level, maxi(cap, META_UPGRADE_NIGHTMARE_HIDDEN_CAP))
    return maxi(1, cap)


func get_meta_upgrade_next_hint(upgrade_id: String = "") -> String:
    var max_level: int = _get_meta_upgrade_config_max_level(upgrade_id)
    if max_level <= 0:
        return ""

    var current_cap: int = get_meta_upgrade_level_cap(upgrade_id)
    if current_cap >= max_level:
        return "All meta shop levels unlocked"

    var unlocked_ids: Array[String] = _sanitize_nonempty_string_array(get_meta_return_profile().get("unlocked_ids", []))
    if not unlocked_ids.has("hard_meta_return") and current_cap < mini(max_level, META_UPGRADE_HARD_CAP):
        return "Unlock Hard Return for Lv.%d" % mini(max_level, META_UPGRADE_HARD_CAP)
    if not unlocked_ids.has("nightmare_meta_return") and current_cap < mini(max_level, META_UPGRADE_NIGHTMARE_CAP):
        return "Unlock Nightmare Return for Lv.%d" % mini(max_level, META_UPGRADE_NIGHTMARE_CAP)
    if not unlocked_ids.has("nightmare_hidden_meta_return") and current_cap < mini(max_level, META_UPGRADE_NIGHTMARE_HIDDEN_CAP):
        return "Unlock Nightmare Hidden Return for Lv.%d" % mini(max_level, META_UPGRADE_NIGHTMARE_HIDDEN_CAP)
    return "All meta shop levels unlocked"


func get_meta_upgrade_progression_summary() -> Dictionary:
    var max_level: int = _get_meta_upgrade_config_max_level("")
    var current_cap: int = get_meta_upgrade_level_cap("")
    if max_level <= 0:
        return {
            "current_cap": 0,
            "max_cap": 0,
            "summary": "",
            "next_hint": ""
        }
    return {
        "current_cap": current_cap,
        "max_cap": max_level,
        "summary": "Upgrade Cap %d/%d" % [current_cap, max_level],
        "next_hint": get_meta_upgrade_next_hint("")
    }


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
    var cap: int = get_meta_upgrade_level_cap(upgrade_id)
    if cap <= 0 or level >= cap:
        return -1

    var base_cost: int = int(row.get("base_cost", 50))
    var step_cost: int = int(row.get("cost_step", 25))
    return max(1, base_cost + step_cost * level)


func purchase_upgrade(upgrade_id: String) -> Dictionary:
    var row: Dictionary = _find_upgrade_row(upgrade_id)
    if row.is_empty():
        return {"ok": false, "reason": "missing_upgrade"}

    var level: int = get_upgrade_level(upgrade_id)
    var max_level: int = int(row.get("max_level", 1))
    var cap: int = get_meta_upgrade_level_cap(upgrade_id)
    if level >= max_level:
        return {"ok": false, "reason": "max_level"}
    if level >= cap:
        return {
            "ok": false,
            "reason": "meta_return_locked",
            "cap": cap,
            "max_level": max_level,
            "next_hint": get_meta_upgrade_next_hint(upgrade_id)
        }

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
    var fragment_meta: Dictionary = get_fragment_meta()
    fragment_meta[fragment_id] = _build_fragment_meta_row(fragment_id)
    _meta["fragment_meta"] = fragment_meta
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

    # 存档读取后逐字段走 sanitize，避免旧版本或坏数据直接污染运行时状态。
    var data: Dictionary = parsed
    _meta["meta_currency"] = int(data.get("meta_currency", 0))
    _meta["total_runs"] = int(data.get("total_runs", 0))
    _meta["total_kills"] = int(data.get("total_kills", 0))
    _meta["highest_room"] = int(data.get("highest_room", 1))
    _meta["best_level"] = int(data.get("best_level", 1))
    _meta["best_alignment"] = float(data.get("best_alignment", 0.0))
    _meta["total_victories"] = int(data.get("total_victories", 0))
    _meta["unlocked_achievements"] = _as_string_array(data.get("unlocked_achievements", []))
    _meta["achievement_meta"] = _sanitize_achievement_meta(data.get("achievement_meta", {}))
    _meta["unlocked_endings"] = _as_string_array(data.get("unlocked_endings", []))
    _meta["ending_meta"] = _sanitize_ending_meta(data.get("ending_meta", {}))
    _meta["unlocked_fragments"] = _as_string_array(data.get("unlocked_fragments", []))
    _meta["fragment_meta"] = _sanitize_fragment_meta(data.get("fragment_meta", {}))
    _meta["selected_character_id"] = str(data.get("selected_character_id", "char_knight"))
    _meta["upgrade_levels"] = _as_int_dictionary(data.get("upgrade_levels", {}))
    _meta["input_bindings"] = _sanitize_input_bindings(data.get("input_bindings", {}))
    _meta["runtime_settings"] = _sanitize_runtime_settings(data.get("runtime_settings", {}))
    _meta["hidden_layer_progress"] = _sanitize_hidden_layer_progress(data.get("hidden_layer_progress", {}))
    _meta["hidden_layer_unlocks"] = _sanitize_hidden_layer_unlocks(data.get("hidden_layer_unlocks", {}))
    _meta["hidden_layer_records"] = _sanitize_hidden_layer_records(data.get("hidden_layer_records", {}))
    _meta["challenge_layer_records"] = _sanitize_challenge_layer_records(data.get("challenge_layer_records", {}))
    _meta["difficulty_records"] = _sanitize_difficulty_records(data.get("difficulty_records", {}))
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

    # 某些隐藏层解锁依赖图鉴状态，读档后要补一次同步，保证老存档也能升级到新规则。
    _sync_hidden_layer_progress_from_codex()


func save_meta() -> void:
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_warning("Cannot write save file: %s" % SAVE_PATH)
        return

    # last_run 不直接塞进 _meta，写盘时再拼回 payload，避免常驻元数据和本局结算记录相互污染。
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
    var route_style_id: String = _resolve_last_route_style(result)
    var ending_payoff: Dictionary = {}
    var ending_epilogue_chain: Array[String] = []
    var fragment_triggers: Array[Dictionary] = _sanitize_fragment_trigger_log(result.get("fragment_triggers", []))
    var epilogue_branch: Dictionary = {}
    var fragment_recap: Dictionary = _get_fragment_recap_payload(fragment_triggers, alignment, route_style_id)
    var hidden_layer_hook: Dictionary = _get_hidden_layer_hook_payload(alignment, route_style_id)
    var boss_flawless_chapters: Array[String] = _sanitize_allowed_string_array(result.get("boss_flawless_chapters", []), FS1_REQUIRED_FLAWLESS_CHAPTERS)
    var hidden_layer_id: String = str(result.get("hidden_layer_id", "")).strip_edges().to_upper()
    var hidden_layer_rooms_cleared: int = maxi(0, int(result.get("hidden_layer_rooms_cleared", 0)))
    var hidden_layer_kills: int = maxi(0, int(result.get("hidden_layer_kills", 0)))
    var hidden_layer_reward_payload: Dictionary = _as_dictionary(result.get("hidden_layer_reward_payload", {}))
    var hidden_layer_reward_summary: String = str(result.get("hidden_layer_reward_summary", hidden_layer_reward_payload.get("summary", ""))).strip_edges()
    var hidden_layer_story: Dictionary = _sanitize_hidden_layer_story_payload(result.get("hidden_layer_story", {}))
    var hidden_layer_gameplay: Dictionary = _sanitize_hidden_layer_gameplay_payload(result.get("hidden_layer_gameplay", {}))
    var hidden_layer_record: Dictionary = {}
    var challenge_layer_id: String = str(result.get("challenge_layer_id", "")).strip_edges().to_upper()
    var challenge_layer_title: String = str(result.get("challenge_layer_title", "Challenge Layer")).strip_edges()
    var challenge_layer_phase: String = str(result.get("challenge_layer_phase", "")).strip_edges().to_lower()
    var challenge_layer_reward_id: String = str(result.get("challenge_layer_reward_id", "")).strip_edges().to_lower()
    var challenge_layer_reward_title: String = str(result.get("challenge_layer_reward_title", "")).strip_edges()
    var challenge_layer_reward_payload: Dictionary = _as_dictionary(result.get("challenge_layer_reward_payload", {}))
    var challenge_layer_reward_summary: String = str(result.get("challenge_layer_reward_summary", "")).strip_edges()
    var challenge_layer_rooms_cleared: int = maxi(0, int(result.get("challenge_layer_rooms_cleared", 0)))
    var challenge_layer_kills: int = maxi(0, int(result.get("challenge_layer_kills", 0)))
    var challenge_layer_record: Dictionary = {}
    var new_codex_unlocks: Array[Dictionary] = []
    var previous_meta_return_ids: Array[String] = _sanitize_nonempty_string_array(get_meta_return_profile().get("unlocked_ids", []))
    var previous_max_difficulty_tier: int = get_max_unlocked_difficulty_tier()
    var difficulty_tier: int = clampi(int(result.get("difficulty_tier", get_runtime_settings().get("difficulty_tier", 0))), 0, previous_max_difficulty_tier)
    var difficulty_profile: Dictionary = get_difficulty_profile(difficulty_tier)
    var difficulty_label: String = str(result.get("difficulty_label", difficulty_profile.get("label", "Normal"))).strip_edges()
    var difficulty_summary: String = str(result.get("difficulty_summary", get_difficulty_summary(difficulty_tier))).strip_edges()
    if difficulty_label == "":
        difficulty_label = str(difficulty_profile.get("label", "Normal"))
    if difficulty_summary == "":
        difficulty_summary = get_difficulty_summary(difficulty_tier)

    var achievement_result: Dictionary = result.duplicate(true)
    achievement_result["difficulty_tier"] = difficulty_tier
    achievement_result["difficulty_label"] = difficulty_label
    achievement_result["difficulty_summary"] = difficulty_summary
    achievement_result["hidden_layer_id"] = hidden_layer_id
    achievement_result["hidden_layer_gameplay"] = hidden_layer_gameplay

    var reward: int = _calc_meta_reward(result) + maxi(0, int(challenge_layer_reward_payload.get("meta_bonus", 0)))

    _meta["meta_currency"] = int(_meta.get("meta_currency", 0)) + reward
    _meta["total_runs"] = int(_meta.get("total_runs", 0)) + 1
    _meta["total_kills"] = int(_meta.get("total_kills", 0)) + kills
    _meta["highest_room"] = maxi(int(_meta.get("highest_room", 1)), rooms_cleared + 1)
    _meta["best_level"] = maxi(int(_meta.get("best_level", 1)), level_reached)
    if outcome == "victory":
        _meta["total_victories"] = int(_meta.get("total_victories", 0)) + 1
        ending_id = _resolve_ending(alignment)
        ending_new_unlock = _unlock_ending(ending_id)
        ending_payoff = _get_ending_payoff_payload(ending_id, alignment, route_style_id)
        ending_epilogue_chain = _get_ending_epilogue_chain(ending_id)
        epilogue_branch = _get_epilogue_branch_payload(ending_id, ending_new_unlock, route_style_id)
        hidden_layer_hook = _get_hidden_layer_hook_payload(alignment, route_style_id)
    if absf(alignment) > absf(float(_meta.get("best_alignment", 0.0))):
        _meta["best_alignment"] = alignment

    var unlocked_in_run: Array[String] = _process_achievements(achievement_result)
    var difficulty_record: Dictionary = _apply_difficulty_run_result(
        difficulty_tier,
        outcome,
        rooms_cleared,
        kills,
        hidden_layer_id
    )
    var hidden_layer_update: Dictionary = _update_hidden_layer_progress(outcome, boss_flawless_chapters)
    var hidden_layer_statuses: Dictionary = hidden_layer_update.get("statuses", get_hidden_layer_statuses())
    var new_hidden_layers: Array[String] = _as_string_array(hidden_layer_update.get("new_hidden_layers", []))
    if hidden_layer_id != "":
        var hidden_run_update: Dictionary = _apply_hidden_layer_run_result(
            hidden_layer_id,
            outcome,
            hidden_layer_rooms_cleared,
            hidden_layer_kills,
            hidden_layer_reward_payload,
            hidden_layer_story,
            hidden_layer_gameplay
        )
        hidden_layer_statuses = hidden_run_update.get("statuses", hidden_layer_statuses)
        hidden_layer_record = hidden_run_update.get("record", {})
        new_codex_unlocks = hidden_run_update.get("new_codex_unlocks", [])
        if hidden_layer_reward_summary == "":
            hidden_layer_reward_summary = str(hidden_layer_reward_payload.get("summary", "")).strip_edges()

    if challenge_layer_id != "":
        challenge_layer_record = _apply_challenge_layer_run_result(
            challenge_layer_id,
            challenge_layer_title,
            outcome,
            challenge_layer_rooms_cleared,
            challenge_layer_kills,
            challenge_layer_reward_id,
            challenge_layer_reward_title,
            challenge_layer_reward_payload
        )

    new_codex_unlocks.append_array(_unlock_difficulty_codex_entries(difficulty_tier, outcome, hidden_layer_id))

    var new_difficulty_unlocks: Array[Dictionary] = _build_new_difficulty_unlock_rows(previous_max_difficulty_tier)
    var meta_return_profile: Dictionary = get_meta_return_profile()
    var new_meta_return_unlocks: Array[Dictionary] = _build_new_meta_return_unlock_rows(previous_meta_return_ids)

    _last_run = {
        "outcome": outcome,
        "rooms_cleared": rooms_cleared,
        "kills": kills,
        "level_reached": level_reached,
        "gold": int(result.get("gold", 0)),
        "ore": int(result.get("ore", 0)),
        "alignment": alignment,
        "meta_reward": reward,
        "difficulty_tier": difficulty_tier,
        "difficulty_label": difficulty_label,
        "difficulty_summary": difficulty_summary,
        "difficulty_record": difficulty_record,
        "meta_return_multiplier": float(meta_return_profile.get("multiplier", 1.0)),
        "meta_return_summary": str(meta_return_profile.get("summary", "")).strip_edges(),
        "meta_return_next_hint": str(meta_return_profile.get("next_hint", "")).strip_edges(),
        "ending_id": ending_id,
        "ending_new_unlock": ending_new_unlock,
        "ending_epilogue": _get_ending_epilogue(ending_id, ending_new_unlock),
        "ending_payoff": ending_payoff,
        "ending_epilogue_chain": ending_epilogue_chain,
        "epilogue_branch": epilogue_branch,
        "fragment_recap": fragment_recap,
        "hidden_layer_hook": hidden_layer_hook,
        "boss_flawless_chapters": boss_flawless_chapters,
        "hidden_layer_id": hidden_layer_id,
        "hidden_layer_rooms_cleared": hidden_layer_rooms_cleared,
        "hidden_layer_kills": hidden_layer_kills,
        "hidden_layer_reward_payload": hidden_layer_reward_payload,
        "hidden_layer_reward_summary": hidden_layer_reward_summary,
        "hidden_layer_story": hidden_layer_story,
        "hidden_layer_gameplay": hidden_layer_gameplay,
        "hidden_layer_record": hidden_layer_record,
        "challenge_layer_id": challenge_layer_id,
        "challenge_layer_title": challenge_layer_title,
        "challenge_layer_phase": challenge_layer_phase,
        "challenge_layer_reward_id": challenge_layer_reward_id,
        "challenge_layer_reward_title": challenge_layer_reward_title,
        "challenge_layer_reward_payload": challenge_layer_reward_payload,
        "challenge_layer_reward_summary": challenge_layer_reward_summary,
        "challenge_layer_settlement_summary": str(result.get("challenge_layer_settlement_summary", "")).strip_edges(),
        "challenge_layer_rooms_cleared": challenge_layer_rooms_cleared,
        "challenge_layer_kills": challenge_layer_kills,
        "challenge_layer_record": challenge_layer_record,
        "hidden_layer_statuses": hidden_layer_statuses,
        "new_hidden_layers": new_hidden_layers,
        "new_codex_unlocks": new_codex_unlocks,
        "new_difficulty_unlocks": new_difficulty_unlocks,
        "new_meta_return_unlocks": new_meta_return_unlocks,
        "fragment_triggers": fragment_triggers,
        "route_style": route_style_id,
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

    var difficulty_tier: int = clampi(int(result.get("difficulty_tier", get_runtime_settings().get("difficulty_tier", 0))), 0, get_max_unlocked_difficulty_tier())
    var reward_mult: float = float(get_difficulty_profile(difficulty_tier).get("meta_reward_mult", 1.0))
    var meta_return_mult: float = float(get_meta_return_profile().get("multiplier", 1.0))
    reward = int(round(float(reward) * reward_mult * meta_return_mult))

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
        "achievement_meta": {},
        "unlocked_endings": [],
        "ending_meta": {},
        "unlocked_fragments": [],
        "fragment_meta": {},
        "selected_character_id": "char_knight",
        "upgrade_levels": {},
        "input_bindings": _default_input_bindings(),
        "hidden_layer_progress": {
            "fs1_best_flawless_chapters": [],
            "fs1_last_flawless_chapters": [],
            "fs2_boss_accessories": []
        },
        "hidden_layer_unlocks": _sanitize_hidden_layer_unlocks({}),
        "hidden_layer_records": _sanitize_hidden_layer_records({}),
        "challenge_layer_records": _sanitize_challenge_layer_records({}),
        "difficulty_records": _sanitize_difficulty_records({}),
        "codex": {
            "characters": ["char_knight"],
            "weapons": [],
            "passives": [],
            "enemies": [],
            "accessories": [],
            "archives": []
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
        "ui_scale": 1.0,
        "difficulty_tier": 0
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
        "pause": {"keys": [KEY_ESCAPE], "joypad_buttons": [JOY_BUTTON_START]},
        "camp_hidden_fs1": {"keys": [KEY_R], "joypad_buttons": []},
        "camp_hidden_fs2": {"keys": [KEY_Y], "joypad_buttons": []},
        "camp_challenge_layer": {"keys": [KEY_U], "joypad_buttons": []}
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
    out["difficulty_tier"] = clampi(int(source.get("difficulty_tier", out["difficulty_tier"])), 0, get_max_unlocked_difficulty_tier())
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
    _sync_hidden_layer_progress_from_codex(true)


func _process_achievements(result: Dictionary) -> Array[String]:
    var unlocked: Array[String] = _as_string_array(_meta.get("unlocked_achievements", []))
    var achievement_meta: Dictionary = get_achievement_meta()
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
        achievement_meta[ach_id] = _build_achievement_meta_row(ach_id, condition)
        EventBus.achievement_unlocked.emit(ach_id, str(row.get("title", ach_id)))

    _meta["unlocked_achievements"] = unlocked
    _meta["achievement_meta"] = achievement_meta
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

    if condition == "hidden_layer_clear_fs1":
        return str(result.get("hidden_layer_id", "")).strip_edges().to_upper() == HIDDEN_LAYER_FS1 and str(result.get("outcome", "")) == "victory"

    if condition == "hidden_layer_mastery_fs1":
        if str(result.get("hidden_layer_id", "")).strip_edges().to_upper() != HIDDEN_LAYER_FS1:
            return false
        var fs1_gameplay: Variant = result.get("hidden_layer_gameplay", {})
        return fs1_gameplay is Dictionary and bool((fs1_gameplay as Dictionary).get("collection_complete", false))

    if condition == "hidden_layer_clear_fs2":
        return str(result.get("hidden_layer_id", "")).strip_edges().to_upper() == HIDDEN_LAYER_FS2 and str(result.get("outcome", "")) == "victory"

    if condition == "hidden_layer_mastery_fs2":
        if str(result.get("hidden_layer_id", "")).strip_edges().to_upper() != HIDDEN_LAYER_FS2:
            return false
        var fs2_gameplay: Variant = result.get("hidden_layer_gameplay", {})
        return fs2_gameplay is Dictionary and bool((fs2_gameplay as Dictionary).get("collection_complete", false))

    if condition == "difficulty_clear_hard":
        return str(result.get("outcome", "")) == "victory" and int(result.get("difficulty_tier", 0)) >= 1

    if condition == "difficulty_clear_nightmare":
        return str(result.get("outcome", "")) == "victory" and int(result.get("difficulty_tier", 0)) >= 2

    if condition == "difficulty_hidden_clear_nightmare":
        return str(result.get("outcome", "")) == "victory" and int(result.get("difficulty_tier", 0)) >= 2 and str(result.get("hidden_layer_id", "")).strip_edges() != ""

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
    var ending_meta: Dictionary = get_ending_meta()
    ending_meta[ending_id] = _build_ending_meta_row(ending_id)
    _meta["ending_meta"] = ending_meta
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


func _get_ending_payoff_payload(ending_id: String, alignment: float, route_style: String) -> Dictionary:
    if ending_id == "":
        return {}

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("ending_payoff_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var row_var: Variant = (rows_var as Dictionary).get(ending_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["ending_id"] = ending_id
    row["arc_id"] = _resolve_route_arc_id(alignment)
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    return row


func _get_ending_epilogue_chain(ending_id: String) -> Array[String]:
    if ending_id == "":
        return []

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("epilogue_chains", {})
    if not (rows_var is Dictionary):
        return []

    var chain_var: Variant = (rows_var as Dictionary).get(ending_id, [])
    var rows: Array[String] = []
    if chain_var is Array:
        for item: Variant in chain_var:
            var text: String = str(item).strip_edges()
            if text != "":
                rows.append(text)
    return rows


func _get_epilogue_branch_payload(ending_id: String, newly_unlocked: bool, route_style: String) -> Dictionary:
    if ending_id == "":
        return {}

    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("epilogue_branch_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var ending_row_var: Variant = (rows_var as Dictionary).get(ending_id, {})
    if not (ending_row_var is Dictionary):
        return {}

    var branch_key: String = "first_unlock" if newly_unlocked else "repeat_unlock"
    var branch_row_var: Variant = (ending_row_var as Dictionary).get(branch_key, {})
    if not (branch_row_var is Dictionary):
        return {}

    var row: Dictionary = (branch_row_var as Dictionary).duplicate(true)
    row["ending_id"] = ending_id
    row["branch_key"] = branch_key
    row["archive_hook"] = str((ending_row_var as Dictionary).get("archive_hook", ""))
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    return row


func _get_fragment_recap_payload(fragment_triggers: Array[Dictionary], alignment: float, route_style: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("fragment_recap_profiles", {})
    if not (rows_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (rows_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var trigger_count: int = fragment_triggers.size()
    var newly_unlocked_count: int = 0
    var trigger_types: Array[String] = []
    for row: Dictionary in fragment_triggers:
        if bool(row.get("newly_unlocked", false)):
            newly_unlocked_count += 1
        var trigger_type: String = str(row.get("trigger_type", "")).strip_edges()
        if trigger_type != "" and not trigger_types.has(trigger_type):
            trigger_types.append(trigger_type)

    var recap: Dictionary = (row_var as Dictionary).duplicate(true)
    recap["arc_id"] = arc_id
    recap["style"] = route_style
    recap["style_echo"] = _get_route_style_echo(route_style)
    recap["trigger_count"] = trigger_count
    recap["new_unlock_count"] = newly_unlocked_count
    recap["trigger_types"] = trigger_types
    return recap


func _get_hidden_layer_hook_payload(alignment: float, route_style: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var rows_var: Variant = config.get("hidden_layer_hooks", {})
    if not (rows_var is Dictionary):
        return {}

    var arc_id: String = _resolve_route_arc_id(alignment)
    var row_var: Variant = (rows_var as Dictionary).get(arc_id, {})
    if not (row_var is Dictionary):
        return {}

    var row: Dictionary = (row_var as Dictionary).duplicate(true)
    row["arc_id"] = arc_id
    row["style"] = route_style
    row["style_echo"] = _get_route_style_echo(route_style)
    row["ready"] = _as_string_array(_meta.get("unlocked_endings", [])).has("nar_ending_%s" % arc_id)
    return row


func _update_hidden_layer_progress(outcome: String, boss_flawless_chapters: Array[String]) -> Dictionary:
    var progress: Dictionary = _sanitize_hidden_layer_progress(_meta.get("hidden_layer_progress", {}))
    var unlocks: Dictionary = _sanitize_hidden_layer_unlocks(_meta.get("hidden_layer_unlocks", {}))
    var new_hidden_layers: Array[String] = []

    progress["fs1_last_flawless_chapters"] = boss_flawless_chapters.duplicate()
    var best_flawless: Array[String] = _as_string_array(progress.get("fs1_best_flawless_chapters", []))
    if boss_flawless_chapters.size() > best_flawless.size():
        progress["fs1_best_flawless_chapters"] = boss_flawless_chapters.duplicate()

    progress["fs2_boss_accessories"] = _get_owned_boss_accessories()

    if outcome == "victory" and _covers_required_items(boss_flawless_chapters, FS1_REQUIRED_FLAWLESS_CHAPTERS):
        if _set_hidden_layer_unlocked_in_rows(unlocks, HIDDEN_LAYER_FS1):
            new_hidden_layers.append(HIDDEN_LAYER_FS1)
    if _covers_required_items(_as_string_array(progress.get("fs2_boss_accessories", [])), FS2_REQUIRED_BOSS_ACCESSORIES):
        if _set_hidden_layer_unlocked_in_rows(unlocks, HIDDEN_LAYER_FS2):
            new_hidden_layers.append(HIDDEN_LAYER_FS2)

    _meta["hidden_layer_progress"] = progress
    _meta["hidden_layer_unlocks"] = unlocks

    return {
        "statuses": _build_hidden_layer_status_rows(progress, unlocks),
        "new_hidden_layers": new_hidden_layers
    }


func _apply_hidden_layer_run_result(layer_id: String, outcome: String, rooms_cleared: int, kills: int, reward_payload: Dictionary, story_payload: Dictionary = {}, gameplay_payload: Dictionary = {}) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    var unlocks: Dictionary = _sanitize_hidden_layer_unlocks(_meta.get("hidden_layer_unlocks", {}))
    var records: Dictionary = _sanitize_hidden_layer_records(_meta.get("hidden_layer_records", {}))
    var record_row: Dictionary = _as_dictionary(records.get(layer_key, {}))
    if record_row.is_empty():
        record_row = _default_hidden_layer_record(layer_key)

    record_row["attempts"] = int(record_row.get("attempts", 0)) + 1
    record_row["best_rooms_cleared"] = maxi(int(record_row.get("best_rooms_cleared", 0)), rooms_cleared)
    record_row["best_kills"] = maxi(int(record_row.get("best_kills", 0)), kills)

    if outcome == "victory":
        var unlock_row: Dictionary = _as_dictionary(unlocks.get(layer_key, {}))
        unlock_row["unlocked"] = true
        unlock_row["completed"] = true
        unlocks[layer_key] = unlock_row
        record_row["clears"] = int(record_row.get("clears", 0)) + 1
        match layer_key:
            HIDDEN_LAYER_FS1:
                record_row["total_time_fragments"] = int(record_row.get("total_time_fragments", 0)) + int(reward_payload.get("time_fragments", 0))
                record_row["rewind_charges"] = int(record_row.get("rewind_charges", 0)) + int(reward_payload.get("rewind_charges", 0))
            HIDDEN_LAYER_FS2:
                record_row["recipe_drafts"] = int(record_row.get("recipe_drafts", 0)) + int(reward_payload.get("recipe_drafts", 0))
                record_row["relic_merges"] = int(record_row.get("relic_merges", 0)) + int(reward_payload.get("relic_merges", 0))

    if not story_payload.is_empty():
        record_row["last_arc_id"] = str(story_payload.get("arc_id", "")).strip_edges()
        record_row["last_route_style"] = str(story_payload.get("style", "")).strip_edges()
        record_row["last_fragment_id"] = str(story_payload.get("fragment_id", "")).strip_edges()
        record_row["last_fragment_title"] = str(story_payload.get("fragment_title", "")).strip_edges()
        record_row["last_story_title"] = str(story_payload.get("title", "")).strip_edges()
        record_row["last_ending_id"] = str(story_payload.get("ending_id", story_payload.get("ending_link", ""))).strip_edges()
        record_row["last_archive_echo"] = str(story_payload.get("archive_echo", "")).strip_edges()

    if not gameplay_payload.is_empty():
        record_row["best_pressure_stage"] = maxi(int(record_row.get("best_pressure_stage", 0)), int(gameplay_payload.get("pressure_stage", 0)))
        record_row["best_survival_seconds"] = maxf(float(record_row.get("best_survival_seconds", 0.0)), float(gameplay_payload.get("survival_seconds", 0.0)))
        record_row["last_boss_echo_id"] = str(gameplay_payload.get("boss_echo_id", record_row.get("last_boss_echo_id", ""))).strip_edges()
        record_row["max_trial_depth"] = maxi(int(record_row.get("max_trial_depth", 0)), int(gameplay_payload.get("trial_depth", 0)))
        record_row["boss_echo_collection"] = _merge_unique_string_arrays(
            _sanitize_allowed_string_array(record_row.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES),
            _sanitize_allowed_string_array(gameplay_payload.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES)
        )
        if str(record_row.get("last_boss_echo_id", "")).strip_edges() != "":
            record_row["boss_echo_collection"] = _merge_unique_string_arrays(
                _sanitize_allowed_string_array(record_row.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES),
                [str(record_row.get("last_boss_echo_id", "")).strip_edges()]
            )
        record_row["trial_label_collection"] = _merge_unique_string_arrays(
            _sanitize_nonempty_string_array(record_row.get("trial_label_collection", [])),
            _sanitize_nonempty_string_array(gameplay_payload.get("trial_labels", []))
        )
        var deepest_trial_label: String = str(gameplay_payload.get("deepest_trial_label", gameplay_payload.get("trial_label", ""))).strip_edges()
        if deepest_trial_label != "":
            record_row["trial_label_collection"] = _merge_unique_string_arrays(
                _sanitize_nonempty_string_array(record_row.get("trial_label_collection", [])),
                [deepest_trial_label]
            )
            record_row["deepest_trial_label"] = deepest_trial_label

    var collection_mastered: bool = false
    match layer_key:
        HIDDEN_LAYER_FS1:
            collection_mastered = _sanitize_allowed_string_array(record_row.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES).size() >= FS1_ARCHIVE_BOSS_ECHOES.size()
        HIDDEN_LAYER_FS2:
            collection_mastered = _sanitize_nonempty_string_array(record_row.get("trial_label_collection", [])).size() >= FS2_TRIAL_ARCHIVE_TOTAL
    record_row["collection_mastered"] = collection_mastered
    if bool(reward_payload.get("collection_bonus_awarded", false)):
        record_row["collection_bonus_claimed"] = true
    record_row["last_collection_bonus_label"] = str(reward_payload.get("collection_bonus_label", record_row.get("last_collection_bonus_label", ""))).strip_edges()

    records[layer_key] = record_row
    _meta["hidden_layer_unlocks"] = unlocks
    _meta["hidden_layer_records"] = records
    var new_codex_unlocks: Array[Dictionary] = _unlock_hidden_layer_codex_entries(layer_key, outcome, record_row)
    return {
        "record": record_row,
        "new_codex_unlocks": new_codex_unlocks,
        "statuses": _build_hidden_layer_status_rows(
            _sanitize_hidden_layer_progress(_meta.get("hidden_layer_progress", {})),
            unlocks
        )
    }


func _sync_hidden_layer_progress_from_codex(save_after: bool = false) -> void:
    var progress: Dictionary = _sanitize_hidden_layer_progress(_meta.get("hidden_layer_progress", {}))
    var unlocks: Dictionary = _sanitize_hidden_layer_unlocks(_meta.get("hidden_layer_unlocks", {}))
    var changed: bool = false

    var owned_accessories: Array[String] = _get_owned_boss_accessories()
    if _as_string_array(progress.get("fs2_boss_accessories", [])) != owned_accessories:
        progress["fs2_boss_accessories"] = owned_accessories
        changed = true

    if _covers_required_items(owned_accessories, FS2_REQUIRED_BOSS_ACCESSORIES):
        if _set_hidden_layer_unlocked_in_rows(unlocks, HIDDEN_LAYER_FS2):
            changed = true

    if changed:
        _meta["hidden_layer_progress"] = progress
        _meta["hidden_layer_unlocks"] = unlocks
        if save_after:
            save_meta()


func _get_hidden_layer_interface_profile(layer_id: String) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    var config: Dictionary = ConfigManager.get_config("map_generation", {})
    var rows_var: Variant = config.get("hidden_layers", {})
    if not (rows_var is Dictionary):
        return {}
    var row_var: Variant = (rows_var as Dictionary).get(layer_key, {})
    if row_var is Dictionary:
        return (row_var as Dictionary).duplicate(true)
    return {}


func _get_hidden_layer_room_count_label(map_profile: Dictionary, fallback: String) -> String:
    var label: String = str(map_profile.get("room_count_label", fallback)).strip_edges()
    if label != "":
        return label
    var room_count: int = int(map_profile.get("room_count", 0))
    if room_count < 0:
        return "Infinite"
    if room_count > 0:
        return "%d rooms" % room_count
    return fallback


func _build_hidden_layer_status(layer_id: String, progress_override: Dictionary = {}, unlocks_override: Dictionary = {}) -> Dictionary:
    var layer_key: String = layer_id.strip_edges().to_upper()
    var progress: Dictionary = progress_override if not progress_override.is_empty() else _sanitize_hidden_layer_progress(_meta.get("hidden_layer_progress", {}))
    var unlocks: Dictionary = unlocks_override if not unlocks_override.is_empty() else _sanitize_hidden_layer_unlocks(_meta.get("hidden_layer_unlocks", {}))
    var unlock_row: Dictionary = unlocks.get(layer_key, {"unlocked": false, "completed": false})
    var records: Dictionary = _sanitize_hidden_layer_records(_meta.get("hidden_layer_records", {}))
    var record_row: Dictionary = _as_dictionary(records.get(layer_key, {}))
    var interface_profile: Dictionary = _get_hidden_layer_interface_profile(layer_key)
    var map_profile: Dictionary = _as_dictionary(interface_profile.get("map_profile", {}))
    var reward_profile: Dictionary = _as_dictionary(interface_profile.get("reward_profile", {}))
    var settlement_profile: Dictionary = _as_dictionary(interface_profile.get("settlement_profile", {}))

    # 这里把进度、解锁、历史纪录和界面文案揉成统一状态对象，供 UI 直接展示而不用再拼装。
    match layer_key:
        HIDDEN_LAYER_FS1:
            var best_flawless: Array[String] = _as_string_array(progress.get("fs1_best_flawless_chapters", []))
            return {
                "layer_id": HIDDEN_LAYER_FS1,
                "title": str(interface_profile.get("title", "Time Rift")),
                "unlocked": bool(unlock_row.get("unlocked", false)),
                "completed": bool(unlock_row.get("completed", false)),
                "progress_current": best_flawless.size(),
                "progress_required": FS1_REQUIRED_FLAWLESS_CHAPTERS.size(),
                "progress_label": "Flawless Boss Route %d/%d" % [best_flawless.size(), FS1_REQUIRED_FLAWLESS_CHAPTERS.size()],
                "detail": str(interface_profile.get("unlock_rule", "Clear chapter bosses 1-3 in one victorious run without losing HP.")),
                "theme": str(interface_profile.get("theme", "")),
                "entry_hint": str(interface_profile.get("entrance_hint", "")),
                "map_mode": str(map_profile.get("mode", "survival")),
                "room_count_label": _get_hidden_layer_room_count_label(map_profile, "Infinite survival loop"),
                "reward_track": str(reward_profile.get("track", "time_fragments")),
                "reward_summary": str(reward_profile.get("summary", "")),
                "repeat_motivation": str(reward_profile.get("repeat_motivation", "")),
                "settlement_mode": str(settlement_profile.get("mode", "survival_cashout")),
                "settlement_summary": str(settlement_profile.get("summary", "")),
                "attempts": int(record_row.get("attempts", 0)),
                "clears": int(record_row.get("clears", 0)),
                "best_rooms_cleared": int(record_row.get("best_rooms_cleared", 0)),
                "best_kills": int(record_row.get("best_kills", 0)),
                "best_pressure_stage": int(record_row.get("best_pressure_stage", 0)),
                "best_survival_seconds": float(record_row.get("best_survival_seconds", 0.0)),
                "last_boss_echo_id": str(record_row.get("last_boss_echo_id", "")),
                "story_label": _build_hidden_layer_story_label(record_row),
                "gameplay_label": _build_hidden_layer_gameplay_label(HIDDEN_LAYER_FS1, record_row),
                "collection_label": _build_hidden_layer_collection_label(HIDDEN_LAYER_FS1, record_row),
                "mastery_label": _build_hidden_layer_mastery_label(HIDDEN_LAYER_FS1, record_row),
                "collection_items": _sanitize_allowed_string_array(record_row.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES),
                "collection_mastered": bool(record_row.get("collection_mastered", false)),
                "collection_bonus_claimed": bool(record_row.get("collection_bonus_claimed", false)),
                "record_label": "Clears %d | Best Rooms %d | Time Fragments %d | Rewind %d" % [
                    int(record_row.get("clears", 0)),
                    int(record_row.get("best_rooms_cleared", 0)),
                    int(record_row.get("total_time_fragments", 0)),
                    int(record_row.get("rewind_charges", 0))
                ],
                "progress_items": best_flawless,
                "target_bosses": FS1_REQUIRED_FLAWLESS_CHAPTERS.duplicate()
            }
        HIDDEN_LAYER_FS2:
            var owned_accessories: Array[String] = _as_string_array(progress.get("fs2_boss_accessories", []))
            return {
                "layer_id": HIDDEN_LAYER_FS2,
                "title": str(interface_profile.get("title", "Genesis Forge")),
                "unlocked": bool(unlock_row.get("unlocked", false)),
                "completed": bool(unlock_row.get("completed", false)),
                "progress_current": owned_accessories.size(),
                "progress_required": FS2_REQUIRED_BOSS_ACCESSORIES.size(),
                "progress_label": "Boss Relics %d/%d" % [owned_accessories.size(), FS2_REQUIRED_BOSS_ACCESSORIES.size()],
                "detail": str(interface_profile.get("unlock_rule", "Collect the four chapter boss relic accessories to stabilize the forge entrance.")),
                "theme": str(interface_profile.get("theme", "")),
                "entry_hint": str(interface_profile.get("entrance_hint", "")),
                "map_mode": str(map_profile.get("mode", "trial_chain")),
                "room_count_label": _get_hidden_layer_room_count_label(map_profile, "5 fixed forge trials"),
                "reward_track": str(reward_profile.get("track", "legendary_forge")),
                "reward_summary": str(reward_profile.get("summary", "")),
                "repeat_motivation": str(reward_profile.get("repeat_motivation", "")),
                "settlement_mode": str(settlement_profile.get("mode", "forge_resolution")),
                "settlement_summary": str(settlement_profile.get("summary", "")),
                "attempts": int(record_row.get("attempts", 0)),
                "clears": int(record_row.get("clears", 0)),
                "best_rooms_cleared": int(record_row.get("best_rooms_cleared", 0)),
                "best_kills": int(record_row.get("best_kills", 0)),
                "max_trial_depth": int(record_row.get("max_trial_depth", 0)),
                "story_label": _build_hidden_layer_story_label(record_row),
                "gameplay_label": _build_hidden_layer_gameplay_label(HIDDEN_LAYER_FS2, record_row),
                "collection_label": _build_hidden_layer_collection_label(HIDDEN_LAYER_FS2, record_row),
                "mastery_label": _build_hidden_layer_mastery_label(HIDDEN_LAYER_FS2, record_row),
                "collection_items": _sanitize_nonempty_string_array(record_row.get("trial_label_collection", [])),
                "collection_mastered": bool(record_row.get("collection_mastered", false)),
                "collection_bonus_claimed": bool(record_row.get("collection_bonus_claimed", false)),
                "record_label": "Clears %d | Best Rooms %d | Drafts %d | Merges %d" % [
                    int(record_row.get("clears", 0)),
                    int(record_row.get("best_rooms_cleared", 0)),
                    int(record_row.get("recipe_drafts", 0)),
                    int(record_row.get("relic_merges", 0))
                ],
                "progress_items": owned_accessories,
                "target_accessories": FS2_REQUIRED_BOSS_ACCESSORIES.duplicate()
            }
        _:
            return {}


func _build_hidden_layer_status_rows(progress: Dictionary, unlocks: Dictionary) -> Dictionary:
    var rows: Dictionary = {}
    # 固定输出全部隐藏层状态，保证界面顺序和缺省占位稳定。
    rows[HIDDEN_LAYER_FS1] = _build_hidden_layer_status(HIDDEN_LAYER_FS1, progress, unlocks)
    rows[HIDDEN_LAYER_FS2] = _build_hidden_layer_status(HIDDEN_LAYER_FS2, progress, unlocks)
    return rows


func _get_owned_boss_accessories() -> Array[String]:
    var codex: Dictionary = get_codex()
    var unlocked_accessories: Array[String] = _as_string_array(codex.get("accessories", []))
    var owned: Array[String] = []
    for accessory_id: String in FS2_REQUIRED_BOSS_ACCESSORIES:
        if unlocked_accessories.has(accessory_id):
            owned.append(accessory_id)
    return owned


func _set_hidden_layer_unlocked_in_rows(unlocks: Dictionary, layer_id: String) -> bool:
    var layer_key: String = layer_id.strip_edges().to_upper()
    var row_var: Variant = unlocks.get(layer_key, {"unlocked": false, "completed": false})
    var row: Dictionary = {}
    if row_var is Dictionary:
        row = (row_var as Dictionary).duplicate(true)
    if bool(row.get("unlocked", false)):
        unlocks[layer_key] = row
        return false
    row["unlocked"] = true
    unlocks[layer_key] = row
    return true


func _covers_required_items(collected: Array[String], required: Array[String]) -> bool:
    for item_id: String in required:
        if not collected.has(item_id):
            return false
    return true


func _resolve_last_route_style(result: Dictionary) -> String:
    var direct_style: String = str(result.get("route_style", "")).strip_edges().to_lower()
    if direct_style != "":
        return direct_style

    var timeline_var: Variant = result.get("route_style_timeline", [])
    if timeline_var is Array and not (timeline_var as Array).is_empty():
        var timeline: Array = timeline_var
        for i in range(timeline.size() - 1, -1, -1):
            var row_var: Variant = timeline[i]
            if not (row_var is Dictionary):
                continue
            var style_id: String = str((row_var as Dictionary).get("style_id", "")).strip_edges().to_lower()
            if style_id != "":
                return style_id

    var chapter_styles_var: Variant = result.get("chapter_route_styles", {})
    if chapter_styles_var is Dictionary:
        var chapter_styles: Dictionary = chapter_styles_var
        for chapter_key in ["chapter_4", "chapter_3", "chapter_2", "chapter_1"]:
            var style_id: String = str(chapter_styles.get(chapter_key, "")).strip_edges().to_lower()
            if style_id != "":
                return style_id

    return "neutral"


func _resolve_route_arc_id(alignment: float) -> String:
    if alignment >= 60.0:
        return ENDING_REDEEM.trim_prefix("nar_ending_")
    if alignment <= -60.0:
        return ENDING_FALL.trim_prefix("nar_ending_")
    return ENDING_BALANCE.trim_prefix("nar_ending_")


func _get_route_style_echo(route_style: String) -> String:
    match route_style:
        "vanguard":
            return "Vanguard routes favor safer pressure and disciplined pacing."
        "raider":
            return "Raider routes trade stability for burst rewards and sharper pressure."
        _:
            return "Neutral routes keep both ending paths open while you shape the run."


func _sanitize_fragment_trigger_log(value: Variant) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    if not (value is Array):
        return rows

    for item: Variant in value:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var fragment_id: String = str(row.get("fragment_id", "")).strip_edges()
        if fragment_id == "":
            continue
        rows.append({
            "chapter_id": str(row.get("chapter_id", "")).strip_edges(),
            "trigger_type": str(row.get("trigger_type", "")).strip_edges(),
            "arc_id": str(row.get("arc_id", "")).strip_edges(),
            "style": str(row.get("style", "")).strip_edges(),
            "fragment_id": fragment_id,
            "fragment_title": str(row.get("fragment_title", fragment_id)).strip_edges(),
            "fragment_text": str(row.get("fragment_text", "")).strip_edges(),
            "newly_unlocked": bool(row.get("newly_unlocked", false)),
            "room_index": int(row.get("room_index", 0))
        })
    return rows


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


func _sanitize_nonempty_string_array(value: Variant) -> Array[String]:
    var rows: Array[String] = []
    if not (value is Array):
        return rows
    for item: Variant in value:
        var text: String = str(item).strip_edges()
        if text == "" or rows.has(text):
            continue
        rows.append(text)
    return rows


func _as_int_dictionary(value: Variant) -> Dictionary:
    var result: Dictionary = {}
    if value is Dictionary:
        var source: Dictionary = value
        for key: Variant in source.keys():
            result[str(key)] = int(source.get(key, 0))
    return result


func _as_dictionary(value: Variant) -> Dictionary:
    if value is Dictionary:
        return (value as Dictionary).duplicate(true)
    return {}


func _sanitize_allowed_string_array(value: Variant, allowed: Array[String]) -> Array[String]:
    var result: Array[String] = []
    if not (value is Array):
        return result
    for item: Variant in value:
        var text: String = str(item).strip_edges()
        if text == "" or not allowed.has(text) or result.has(text):
            continue
        result.append(text)
    return result


func _sanitize_codex(value: Variant) -> Dictionary:
    var template: Dictionary = {
        "characters": [],
        "weapons": [],
        "passives": [],
        "enemies": [],
        "accessories": [],
        "archives": []
    }

    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    var out: Dictionary = template.duplicate(true)
    for key: Variant in out.keys():
        var key_name: String = str(key)
        out[key_name] = _as_string_array(source.get(key_name, []))
    return out


func _sanitize_difficulty_records(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        "0": _sanitize_difficulty_record_row(source.get("0", {}), 0),
        "1": _sanitize_difficulty_record_row(source.get("1", {}), 1),
        "2": _sanitize_difficulty_record_row(source.get("2", {}), 2)
    }


func _sanitize_challenge_layer_records(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        CHALLENGE_LAYER_CL1: _sanitize_challenge_layer_record_row(source.get(CHALLENGE_LAYER_CL1, {}), CHALLENGE_LAYER_CL1)
    }


func _sanitize_challenge_layer_record_row(value: Variant, layer_id: String) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        "id": layer_id,
        "title": str(source.get("title", "Challenge Layer")).strip_edges(),
        "attempts": maxi(0, int(source.get("attempts", 0))),
        "clears": maxi(0, int(source.get("clears", 0))),
        "best_rooms": maxi(0, int(source.get("best_rooms", 0))),
        "best_kills": maxi(0, int(source.get("best_kills", 0))),
        "last_reward_id": str(source.get("last_reward_id", "")).strip_edges().to_lower(),
        "last_reward_title": str(source.get("last_reward_title", "")).strip_edges(),
        "total_meta_bonus": maxi(0, int(source.get("total_meta_bonus", 0))),
        "total_sigils": maxi(0, int(source.get("total_sigils", 0))),
        "total_insight": maxi(0, int(source.get("total_insight", 0)))
    }


func _apply_challenge_layer_run_result(layer_id: String, title: String, outcome: String, rooms_cleared: int, kills: int, reward_id: String = "", reward_title: String = "", reward_payload: Dictionary = {}) -> Dictionary:
    var records: Dictionary = _sanitize_challenge_layer_records(_meta.get("challenge_layer_records", {}))
    var key: String = layer_id.strip_edges().to_upper()
    var row: Dictionary = _as_dictionary(records.get(key, {}))
    if row.is_empty():
        row = _sanitize_challenge_layer_record_row({}, key)
    if title.strip_edges() != "":
        row["title"] = title.strip_edges()
    row["attempts"] = int(row.get("attempts", 0)) + 1
    if outcome == "victory":
        row["clears"] = int(row.get("clears", 0)) + 1
        row["best_rooms"] = maxi(int(row.get("best_rooms", 0)), rooms_cleared)
        row["best_kills"] = maxi(int(row.get("best_kills", 0)), kills)
        if reward_id != "":
            row["last_reward_id"] = reward_id
        if reward_title != "":
            row["last_reward_title"] = reward_title
        row["total_meta_bonus"] = int(row.get("total_meta_bonus", 0)) + maxi(0, int(reward_payload.get("meta_bonus", 0)))
        row["total_sigils"] = int(row.get("total_sigils", 0)) + maxi(0, int(reward_payload.get("sigils", 0)))
        row["total_insight"] = int(row.get("total_insight", 0)) + maxi(0, int(reward_payload.get("insight", 0)))
    records[key] = row
    _meta["challenge_layer_records"] = records
    return row.duplicate(true)


func _sanitize_difficulty_record_row(value: Variant, tier: int) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        "tier": tier,
        "label": get_difficulty_label(tier),
        "clears": maxi(0, int(source.get("clears", 0))),
        "best_rooms": maxi(0, int(source.get("best_rooms", 0))),
        "best_kills": maxi(0, int(source.get("best_kills", 0))),
        "hidden_layer_clears": maxi(0, int(source.get("hidden_layer_clears", 0)))
    }


func _get_difficulty_record_key(tier: int) -> String:
    return str(clampi(tier, 0, 2))


func _get_meta_return_milestones() -> Array[Dictionary]:
    return [
        {
            "id": "hard_meta_return",
            "label": "Hard Return",
            "bonus_mult": 0.10,
            "bonus_text": "+10% Meta",
            "hint": "Next Return: clear any Hard run"
        },
        {
            "id": "nightmare_meta_return",
            "label": "Nightmare Return",
            "bonus_mult": 0.15,
            "bonus_text": "+15% Meta",
            "hint": "Next Return: clear any Nightmare run"
        },
        {
            "id": "nightmare_hidden_meta_return",
            "label": "Nightmare Hidden Return",
            "bonus_mult": 0.15,
            "bonus_text": "+15% Meta",
            "hint": "Next Return: clear any hidden layer on Nightmare"
        }
    ]


func _is_meta_return_milestone_unlocked(row: Dictionary, records: Dictionary) -> bool:
    var milestone_id: String = str(row.get("id", "")).strip_edges()
    var hard_record: Dictionary = _as_dictionary(records.get("1", {}))
    var nightmare_record: Dictionary = _as_dictionary(records.get("2", {}))
    match milestone_id:
        "hard_meta_return":
            return int(hard_record.get("clears", 0)) + int(nightmare_record.get("clears", 0)) > 0
        "nightmare_meta_return":
            return int(nightmare_record.get("clears", 0)) > 0
        "nightmare_hidden_meta_return":
            return int(nightmare_record.get("hidden_layer_clears", 0)) > 0
        _:
            return false


func _build_new_meta_return_unlock_rows(previous_ids: Array[String]) -> Array[Dictionary]:
    var previous_lookup: Dictionary = {}
    for milestone_id: String in previous_ids:
        previous_lookup[milestone_id] = true

    var rows: Array[Dictionary] = []
    var unlocked_rows_var: Variant = get_meta_return_profile().get("unlocked_rows", [])
    if not (unlocked_rows_var is Array):
        return rows
    for item: Variant in unlocked_rows_var:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var milestone_id: String = str(row.get("id", "")).strip_edges()
        if milestone_id == "" or previous_lookup.has(milestone_id):
            continue
        var unlock_row: Dictionary = {
            "id": milestone_id,
            "label": str(row.get("label", milestone_id)).strip_edges(),
            "bonus_text": str(row.get("bonus_text", "")).strip_edges()
        }
        rows.append(unlock_row)
        if EventBus != null and EventBus.has_signal("meta_return_unlocked"):
            EventBus.meta_return_unlocked.emit(
                milestone_id,
                str(unlock_row.get("label", "")).strip_edges(),
                str(unlock_row.get("bonus_text", "")).strip_edges()
            )
    return rows


func _apply_difficulty_run_result(difficulty_tier: int, outcome: String, rooms_cleared: int, kills: int, hidden_layer_id: String) -> Dictionary:
    var records: Dictionary = _sanitize_difficulty_records(_meta.get("difficulty_records", {}))
    var key: String = _get_difficulty_record_key(difficulty_tier)
    var row: Dictionary = _as_dictionary(records.get(key, {}))
    if row.is_empty():
        row = _sanitize_difficulty_record_row({}, difficulty_tier)
    if outcome == "victory":
        row["clears"] = int(row.get("clears", 0)) + 1
        row["best_rooms"] = maxi(int(row.get("best_rooms", 0)), rooms_cleared)
        row["best_kills"] = maxi(int(row.get("best_kills", 0)), kills)
        if hidden_layer_id.strip_edges() != "":
            row["hidden_layer_clears"] = int(row.get("hidden_layer_clears", 0)) + 1
    records[key] = row
    _meta["difficulty_records"] = records
    return row.duplicate(true)


func _sanitize_hidden_layer_progress(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        "fs1_best_flawless_chapters": _sanitize_allowed_string_array(source.get("fs1_best_flawless_chapters", []), FS1_REQUIRED_FLAWLESS_CHAPTERS),
        "fs1_last_flawless_chapters": _sanitize_allowed_string_array(source.get("fs1_last_flawless_chapters", []), FS1_REQUIRED_FLAWLESS_CHAPTERS),
        "fs2_boss_accessories": _sanitize_allowed_string_array(source.get("fs2_boss_accessories", []), FS2_REQUIRED_BOSS_ACCESSORIES)
    }


func _sanitize_hidden_layer_records(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    return {
        HIDDEN_LAYER_FS1: _sanitize_hidden_layer_record_row(HIDDEN_LAYER_FS1, source.get(HIDDEN_LAYER_FS1, {})),
        HIDDEN_LAYER_FS2: _sanitize_hidden_layer_record_row(HIDDEN_LAYER_FS2, source.get(HIDDEN_LAYER_FS2, {}))
    }


func _sanitize_hidden_layer_record_row(layer_id: String, value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value
    var row: Dictionary = _default_hidden_layer_record(layer_id)
    row["attempts"] = maxi(0, int(source.get("attempts", row.get("attempts", 0))))
    row["clears"] = maxi(0, int(source.get("clears", row.get("clears", 0))))
    row["best_rooms_cleared"] = maxi(0, int(source.get("best_rooms_cleared", row.get("best_rooms_cleared", 0))))
    row["best_kills"] = maxi(0, int(source.get("best_kills", row.get("best_kills", 0))))
    row["last_arc_id"] = str(source.get("last_arc_id", row.get("last_arc_id", ""))).strip_edges()
    row["last_route_style"] = str(source.get("last_route_style", row.get("last_route_style", ""))).strip_edges()
    row["last_fragment_id"] = str(source.get("last_fragment_id", row.get("last_fragment_id", ""))).strip_edges()
    row["last_fragment_title"] = str(source.get("last_fragment_title", row.get("last_fragment_title", ""))).strip_edges()
    row["last_story_title"] = str(source.get("last_story_title", row.get("last_story_title", ""))).strip_edges()
    row["last_ending_id"] = str(source.get("last_ending_id", row.get("last_ending_id", ""))).strip_edges()
    row["last_archive_echo"] = str(source.get("last_archive_echo", row.get("last_archive_echo", ""))).strip_edges()
    row["best_pressure_stage"] = maxi(0, int(source.get("best_pressure_stage", row.get("best_pressure_stage", 0))))
    row["best_survival_seconds"] = maxf(0.0, float(source.get("best_survival_seconds", row.get("best_survival_seconds", 0.0))))
    row["last_boss_echo_id"] = str(source.get("last_boss_echo_id", row.get("last_boss_echo_id", ""))).strip_edges()
    row["max_trial_depth"] = maxi(0, int(source.get("max_trial_depth", row.get("max_trial_depth", 0))))
    row["boss_echo_collection"] = _sanitize_allowed_string_array(source.get("boss_echo_collection", row.get("boss_echo_collection", [])), FS1_ARCHIVE_BOSS_ECHOES)
    row["trial_label_collection"] = _sanitize_nonempty_string_array(source.get("trial_label_collection", row.get("trial_label_collection", [])))
    row["deepest_trial_label"] = str(source.get("deepest_trial_label", row.get("deepest_trial_label", ""))).strip_edges()
    var computed_mastery: bool = false
    match layer_id.strip_edges().to_upper():
        HIDDEN_LAYER_FS1:
            computed_mastery = row["boss_echo_collection"].size() >= FS1_ARCHIVE_BOSS_ECHOES.size()
        HIDDEN_LAYER_FS2:
            computed_mastery = row["trial_label_collection"].size() >= FS2_TRIAL_ARCHIVE_TOTAL
    row["collection_mastered"] = bool(source.get("collection_mastered", row.get("collection_mastered", false))) or computed_mastery
    row["collection_bonus_claimed"] = bool(source.get("collection_bonus_claimed", row.get("collection_bonus_claimed", false)))
    row["last_collection_bonus_label"] = str(source.get("last_collection_bonus_label", row.get("last_collection_bonus_label", ""))).strip_edges()
    match layer_id.strip_edges().to_upper():
        HIDDEN_LAYER_FS1:
            row["total_time_fragments"] = maxi(0, int(source.get("total_time_fragments", row.get("total_time_fragments", 0))))
            row["rewind_charges"] = maxi(0, int(source.get("rewind_charges", row.get("rewind_charges", 0))))
        HIDDEN_LAYER_FS2:
            row["recipe_drafts"] = maxi(0, int(source.get("recipe_drafts", row.get("recipe_drafts", 0))))
            row["relic_merges"] = maxi(0, int(source.get("relic_merges", row.get("relic_merges", 0))))
    return row


func _default_hidden_layer_record(layer_id: String) -> Dictionary:
    match layer_id.strip_edges().to_upper():
        HIDDEN_LAYER_FS1:
            return {
                "attempts": 0,
                "clears": 0,
                "best_rooms_cleared": 0,
                "best_kills": 0,
                "last_arc_id": "",
                "last_route_style": "",
                "last_fragment_id": "",
                "last_fragment_title": "",
                "last_story_title": "",
                "last_ending_id": "",
                "last_archive_echo": "",
                "best_pressure_stage": 0,
                "best_survival_seconds": 0.0,
                "last_boss_echo_id": "",
                "max_trial_depth": 0,
                "boss_echo_collection": [],
                "trial_label_collection": [],
                "deepest_trial_label": "",
                "collection_mastered": false,
                "collection_bonus_claimed": false,
                "last_collection_bonus_label": "",
                "total_time_fragments": 0,
                "rewind_charges": 0
            }
        HIDDEN_LAYER_FS2:
            return {
                "attempts": 0,
                "clears": 0,
                "best_rooms_cleared": 0,
                "best_kills": 0,
                "last_arc_id": "",
                "last_route_style": "",
                "last_fragment_id": "",
                "last_fragment_title": "",
                "last_story_title": "",
                "last_ending_id": "",
                "last_archive_echo": "",
                "best_pressure_stage": 0,
                "best_survival_seconds": 0.0,
                "last_boss_echo_id": "",
                "max_trial_depth": 0,
                "boss_echo_collection": [],
                "trial_label_collection": [],
                "deepest_trial_label": "",
                "collection_mastered": false,
                "collection_bonus_claimed": false,
                "last_collection_bonus_label": "",
                "recipe_drafts": 0,
                "relic_merges": 0
            }
        _:
            return {
                "attempts": 0,
                "clears": 0,
                "best_rooms_cleared": 0,
                "best_kills": 0,
                "last_arc_id": "",
                "last_route_style": "",
                "last_fragment_id": "",
                "last_fragment_title": "",
                "last_story_title": "",
                "last_ending_id": "",
                "last_archive_echo": "",
                "best_pressure_stage": 0,
                "best_survival_seconds": 0.0,
                "last_boss_echo_id": "",
                "max_trial_depth": 0,
                "boss_echo_collection": [],
                "trial_label_collection": [],
                "deepest_trial_label": "",
                "collection_mastered": false,
                "collection_bonus_claimed": false,
                "last_collection_bonus_label": ""
            }


func _sanitize_hidden_layer_gameplay_payload(value: Variant) -> Dictionary:
    if not (value is Dictionary):
        return {}
    var source: Dictionary = value
    return {
        "pressure_label": str(source.get("pressure_label", "")).strip_edges(),
        "pressure_stage": maxi(0, int(source.get("pressure_stage", 0))),
        "required_pressure_stage": maxi(0, int(source.get("required_pressure_stage", 0))),
        "survival_seconds": maxf(0.0, float(source.get("survival_seconds", 0.0))),
        "minimum_clear_seconds": maxf(0.0, float(source.get("minimum_clear_seconds", 0.0))),
        "boss_echo_id": str(source.get("boss_echo_id", "")).strip_edges(),
        "boss_echo_title": str(source.get("boss_echo_title", "")).strip_edges(),
        "boss_echo_collection": _sanitize_allowed_string_array(source.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES),
        "collection_count": maxi(0, int(source.get("collection_count", 0))),
        "collection_required": maxi(0, int(source.get("collection_required", 0))),
        "collection_complete": bool(source.get("collection_complete", false)),
        "collection_bonus_label": str(source.get("collection_bonus_label", "")).strip_edges(),
        "mastery_label": str(source.get("mastery_label", "")).strip_edges(),
        "trial_depth": maxi(0, int(source.get("trial_depth", 0))),
        "trial_depth_max": maxi(0, int(source.get("trial_depth_max", 0))),
        "trial_label": str(source.get("trial_label", "")).strip_edges(),
        "trial_labels": _sanitize_nonempty_string_array(source.get("trial_labels", [])),
        "deepest_trial_label": str(source.get("deepest_trial_label", "")).strip_edges()
    }


func _sanitize_hidden_layer_story_payload(value: Variant) -> Dictionary:
    if not (value is Dictionary):
        return {}
    var source: Dictionary = value
    var out: Dictionary = {
        "layer_id": str(source.get("layer_id", "")).strip_edges().to_upper(),
        "arc_id": str(source.get("arc_id", "")).strip_edges(),
        "style": str(source.get("style", "")).strip_edges(),
        "style_echo": str(source.get("style_echo", "")).strip_edges(),
        "title": str(source.get("title", "")).strip_edges(),
        "body": str(source.get("body", "")).strip_edges(),
        "archive_echo": str(source.get("archive_echo", "")).strip_edges(),
        "ending_id": str(source.get("ending_id", source.get("ending_link", ""))).strip_edges(),
        "ending_link": str(source.get("ending_link", source.get("ending_id", ""))).strip_edges(),
        "ending_ready": bool(source.get("ending_ready", false)),
        "fragment_id": str(source.get("fragment_id", "")).strip_edges(),
        "fragment_title": str(source.get("fragment_title", "")).strip_edges(),
        "fragment_text": str(source.get("fragment_text", "")).strip_edges(),
        "fragment_newly_unlocked": bool(source.get("fragment_newly_unlocked", false))
    }
    if out["title"] == "" and out["fragment_id"] == "":
        return {}
    return out


func _build_hidden_layer_story_label(record_row: Dictionary) -> String:
    var story_title: String = str(record_row.get("last_story_title", "")).strip_edges()
    if story_title == "":
        return ""
    var parts: Array[String] = [story_title]
    var fragment_title: String = str(record_row.get("last_fragment_title", record_row.get("last_fragment_id", ""))).strip_edges()
    if fragment_title != "":
        parts.append(fragment_title)
    var ending_id: String = str(record_row.get("last_ending_id", "")).strip_edges()
    if ending_id != "":
        parts.append(ending_id.trim_prefix("nar_ending_").to_upper())
    return " | ".join(PackedStringArray(parts))


func _build_hidden_layer_gameplay_label(layer_id: String, record_row: Dictionary) -> String:
    match layer_id:
        HIDDEN_LAYER_FS1:
            var parts: Array[String] = []
            var best_pressure_stage: int = int(record_row.get("best_pressure_stage", 0))
            if best_pressure_stage > 0:
                parts.append("Pressure %d" % best_pressure_stage)
            var best_survival_seconds: float = float(record_row.get("best_survival_seconds", 0.0))
            if best_survival_seconds > 0.0:
                parts.append("Hold %.1fs" % best_survival_seconds)
            var echo_title: String = _get_hidden_layer_boss_echo_title(str(record_row.get("last_boss_echo_id", "")))
            if echo_title != "":
                parts.append("Echo %s" % echo_title)
            return " | ".join(PackedStringArray(parts))
        HIDDEN_LAYER_FS2:
            var max_trial_depth: int = int(record_row.get("max_trial_depth", 0))
            if max_trial_depth > 0:
                return "Deepest Trial %d/5" % max_trial_depth
            return ""
        _:
            return ""


func _build_hidden_layer_collection_label(layer_id: String, record_row: Dictionary) -> String:
    match layer_id:
        HIDDEN_LAYER_FS1:
            var echo_rows: Array[String] = _sanitize_allowed_string_array(record_row.get("boss_echo_collection", []), FS1_ARCHIVE_BOSS_ECHOES)
            if echo_rows.is_empty():
                return ""
            var titles: Array[String] = []
            for boss_id: String in echo_rows:
                var boss_title: String = _get_hidden_layer_boss_echo_title(boss_id)
                if boss_title != "":
                    titles.append(boss_title)
            var label: String = "Echoes %d/%d" % [echo_rows.size(), FS1_ARCHIVE_BOSS_ECHOES.size()]
            if not titles.is_empty():
                label += " | %s" % ", ".join(PackedStringArray(titles))
            return label
        HIDDEN_LAYER_FS2:
            var trial_rows: Array[String] = _sanitize_nonempty_string_array(record_row.get("trial_label_collection", []))
            if trial_rows.is_empty():
                return ""
            var latest_label: String = str(record_row.get("deepest_trial_label", trial_rows[trial_rows.size() - 1])).strip_edges()
            var label: String = "Trials %d/%d" % [trial_rows.size(), FS2_TRIAL_ARCHIVE_TOTAL]
            if latest_label != "":
                label += " | %s" % latest_label
            return label
        _:
            return ""


func _unlock_hidden_layer_codex_entries(layer_id: String, outcome: String, record_row: Dictionary) -> Array[Dictionary]:
    var unlocked_rows: Array[Dictionary] = []
    var layer_key: String = layer_id.strip_edges().to_upper()
    if layer_key == "":
        return unlocked_rows
    if outcome == "victory":
        match layer_key:
            HIDDEN_LAYER_FS1:
                if unlock_codex_entry("archives", "fs1_echo_archive", "hidden_layer_clear", "global"):
                    unlocked_rows.append(_build_run_codex_unlock_row("archives", "fs1_echo_archive", "hidden_layer_clear", "global"))
            HIDDEN_LAYER_FS2:
                if unlock_codex_entry("archives", "fs2_trial_archive", "hidden_layer_clear", "global"):
                    unlocked_rows.append(_build_run_codex_unlock_row("archives", "fs2_trial_archive", "hidden_layer_clear", "global"))
    if not bool(record_row.get("collection_mastered", false)):
        return unlocked_rows
    match layer_key:
        HIDDEN_LAYER_FS1:
            if unlock_codex_entry("archives", "fs1_echo_mastery", "hidden_layer_mastery", "global"):
                unlocked_rows.append(_build_run_codex_unlock_row("archives", "fs1_echo_mastery", "hidden_layer_mastery", "global"))
        HIDDEN_LAYER_FS2:
            if unlock_codex_entry("archives", "fs2_trial_mastery", "hidden_layer_mastery", "global"):
                unlocked_rows.append(_build_run_codex_unlock_row("archives", "fs2_trial_mastery", "hidden_layer_mastery", "global"))
        _:
            return unlocked_rows
    return unlocked_rows


func _unlock_difficulty_codex_entries(difficulty_tier: int, outcome: String, hidden_layer_id: String) -> Array[Dictionary]:
    var unlocked_rows: Array[Dictionary] = []
    if outcome != "victory":
        return unlocked_rows

    if difficulty_tier >= 1:
        if unlock_codex_entry("archives", "hard_clear_archive", "difficulty_clear", "global"):
            unlocked_rows.append(_build_run_codex_unlock_row("archives", "hard_clear_archive", "difficulty_clear", "global"))

    if difficulty_tier >= 2:
        if unlock_codex_entry("archives", "nightmare_clear_archive", "difficulty_clear", "global"):
            unlocked_rows.append(_build_run_codex_unlock_row("archives", "nightmare_clear_archive", "difficulty_clear", "global"))
        if hidden_layer_id.strip_edges() != "":
            if unlock_codex_entry("archives", "nightmare_hidden_archive", "difficulty_hidden_clear", "global"):
                unlocked_rows.append(_build_run_codex_unlock_row("archives", "nightmare_hidden_archive", "difficulty_hidden_clear", "global"))

    return unlocked_rows


func _build_new_difficulty_unlock_rows(previous_max_tier: int) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var current_max_tier: int = get_max_unlocked_difficulty_tier()
    for tier: int in range(previous_max_tier + 1, current_max_tier + 1):
        var label: String = get_difficulty_label(tier)
        var row: Dictionary = {
            "tier": tier,
            "label": label
        }
        rows.append(row)
        if EventBus != null and EventBus.has_signal("difficulty_unlocked"):
            EventBus.difficulty_unlocked.emit(tier, label)
    return rows


func _build_run_codex_unlock_row(category: String, entry_id: String, source: String, chapter_id: String) -> Dictionary:
    return {
        "category": category.strip_edges().to_lower(),
        "entry_id": entry_id.strip_edges(),
        "source": source.strip_edges(),
        "chapter_id": _resolve_codex_chapter_id(chapter_id)
    }


func _build_hidden_layer_mastery_label(layer_id: String, record_row: Dictionary) -> String:
    var bonus_label: String = str(record_row.get("last_collection_bonus_label", "")).strip_edges()
    var bonus_claimed: bool = bool(record_row.get("collection_bonus_claimed", false))
    var collection_mastered: bool = bool(record_row.get("collection_mastered", false))
    match layer_id:
        HIDDEN_LAYER_FS1:
            if not collection_mastered:
                return ""
            if bonus_label == "":
                bonus_label = "Rewind +%d | Time Fragments +%d" % [FS1_MASTERY_BONUS_REWINDS, FS1_MASTERY_BONUS_FRAGMENTS]
            return "Echo Archive Mastered | %s %s" % [bonus_label, "claimed" if bonus_claimed else "pending"]
        HIDDEN_LAYER_FS2:
            if not collection_mastered:
                return ""
            if bonus_label == "":
                bonus_label = "Draft +%d | Merge +%d" % [FS2_MASTERY_BONUS_DRAFTS, FS2_MASTERY_BONUS_MERGES]
            return "Forge Archive Mastered | %s %s" % [bonus_label, "claimed" if bonus_claimed else "pending"]
        _:
            return ""


func _get_hidden_layer_boss_echo_title(boss_id: String) -> String:
    match boss_id.strip_edges():
        "boss_rock_colossus":
            return "Rock Colossus"
        "boss_flame_lord":
            return "Flame Lord"
        "boss_frost_king":
            return "Frost King"
        "boss_void_lord":
            return "Void Lord"
        _:
            return ""


func _merge_unique_string_arrays(existing: Array[String], incoming: Array[String]) -> Array[String]:
    var merged: Array[String] = existing.duplicate()
    for value: String in incoming:
        if value == "" or merged.has(value):
            continue
        merged.append(value)
    return merged


func _sanitize_hidden_layer_unlocks(value: Variant) -> Dictionary:
    var source: Dictionary = {}
    if value is Dictionary:
        source = value

    var out: Dictionary = {}
    out[HIDDEN_LAYER_FS1] = {
        "unlocked": false,
        "completed": false
    }
    out[HIDDEN_LAYER_FS2] = {
        "unlocked": false,
        "completed": false
    }

    for layer_id: String in [HIDDEN_LAYER_FS1, HIDDEN_LAYER_FS2]:
        var row_var: Variant = source.get(layer_id, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        out[layer_id] = {
            "unlocked": bool(row.get("unlocked", false)),
            "completed": bool(row.get("completed", false))
        }
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


func _sanitize_achievement_meta(value: Variant) -> Dictionary:
    var out: Dictionary = {}
    if not (value is Dictionary):
        return out

    var source: Dictionary = value
    for key_var: Variant in source.keys():
        var key: String = str(key_var).strip_edges()
        if key == "":
            continue
        var row_var: Variant = source.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        out[key] = {
            "achievement_id": str(row.get("achievement_id", key)).strip_edges(),
            "condition": str(row.get("condition", "")).strip_edges(),
            "discovered_at": str(row.get("discovered_at", "")).strip_edges(),
            "run_index": maxi(0, int(row.get("run_index", 0)))
        }
    return out


func _sanitize_ending_meta(value: Variant) -> Dictionary:
    var out: Dictionary = {}
    if not (value is Dictionary):
        return out

    var source: Dictionary = value
    for key_var: Variant in source.keys():
        var key: String = str(key_var).strip_edges()
        if key == "":
            continue
        var row_var: Variant = source.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        out[key] = {
            "ending_id": str(row.get("ending_id", key)).strip_edges(),
            "discovered_at": str(row.get("discovered_at", "")).strip_edges(),
            "run_index": maxi(0, int(row.get("run_index", 0)))
        }
    return out


func _sanitize_fragment_meta(value: Variant) -> Dictionary:
    var out: Dictionary = {}
    if not (value is Dictionary):
        return out

    var source: Dictionary = value
    for key_var: Variant in source.keys():
        var key: String = str(key_var).strip_edges()
        if key == "":
            continue
        var row_var: Variant = source.get(key_var, {})
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        out[key] = {
            "fragment_id": str(row.get("fragment_id", key)).strip_edges(),
            "discovered_at": str(row.get("discovered_at", "")).strip_edges(),
            "run_index": maxi(0, int(row.get("run_index", 0)))
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


func _build_achievement_meta_row(achievement_id: String, condition: String) -> Dictionary:
    var now_text: String = Time.get_datetime_string_from_system(true, true)
    var run_index: int = int(_meta.get("total_runs", 0)) + 1
    return {
        "achievement_id": achievement_id.strip_edges(),
        "condition": condition.strip_edges(),
        "discovered_at": now_text,
        "run_index": run_index
    }


func _build_ending_meta_row(ending_id: String) -> Dictionary:
    var now_text: String = Time.get_datetime_string_from_system(true, true)
    var run_index: int = int(_meta.get("total_runs", 0)) + 1
    return {
        "ending_id": ending_id.strip_edges(),
        "discovered_at": now_text,
        "run_index": run_index
    }


func _build_fragment_meta_row(fragment_id: String) -> Dictionary:
    var now_text: String = Time.get_datetime_string_from_system(true, true)
    var run_index: int = int(_meta.get("total_runs", 0)) + 1
    return {
        "fragment_id": fragment_id.strip_edges(),
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


func _sort_achievement_recent_desc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a > run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a > time_b

    var entry_a: String = str(a.get("achievement_id", ""))
    var entry_b: String = str(b.get("achievement_id", ""))
    return entry_a < entry_b


func _sort_ending_recent_desc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a > run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a > time_b

    var entry_a: String = str(a.get("ending_id", ""))
    var entry_b: String = str(b.get("ending_id", ""))
    return entry_a < entry_b


func _sort_ending_recent_asc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a < run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a < time_b

    var entry_a: String = str(a.get("ending_id", ""))
    var entry_b: String = str(b.get("ending_id", ""))
    return entry_a < entry_b


func _sort_fragment_recent_desc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a > run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a > time_b

    var entry_a: String = str(a.get("fragment_id", ""))
    var entry_b: String = str(b.get("fragment_id", ""))
    return entry_a < entry_b


func _sort_fragment_recent_asc(a: Dictionary, b: Dictionary) -> bool:
    var run_a: int = int(a.get("run_index", 0))
    var run_b: int = int(b.get("run_index", 0))
    if run_a != run_b:
        return run_a < run_b

    var time_a: String = str(a.get("discovered_at", ""))
    var time_b: String = str(b.get("discovered_at", ""))
    if time_a != time_b:
        return time_a < time_b

    var entry_a: String = str(a.get("fragment_id", ""))
    var entry_b: String = str(b.get("fragment_id", ""))
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


func _get_meta_upgrade_config_max_level(upgrade_id: String = "") -> int:
    if upgrade_id != "":
        var row: Dictionary = _find_upgrade_row(upgrade_id)
        if row.is_empty():
            return 0
        return maxi(1, int(row.get("max_level", 1)))

    var config: Dictionary = ConfigManager.get_config("meta_upgrades", {})
    var rows_var: Variant = config.get("upgrades", [])
    if not (rows_var is Array):
        return 0

    var max_level: int = 0
    for item: Variant in rows_var:
        if not (item is Dictionary):
            continue
        max_level = maxi(max_level, int((item as Dictionary).get("max_level", 1)))
    return max_level
