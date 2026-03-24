extends Node

@export var player_path: NodePath = ^"../Player"
@export var panel_path: NodePath = ^"../LevelUpPanel"

var _player: CharacterBody2D
var _panel: Control
var _progression: Node
var _stats: Node
var _health: Node
var _weapon: Node
var _option_lookup: Dictionary = {}
var _passive_levels: Dictionary = {}
var _evolution_recipes: Array[Dictionary] = []
var _build_anchor_scores: Dictionary = {
    "offense": 0.0,
    "tempo": 0.0,
    "precision": 0.0,
    "survival": 0.0,
    "economy": 0.0
}

const PASSIVE_OPTION_TO_ID: Dictionary = {
    "power": "pas_might",
    "vitality": "pas_vitality",
    "agility": "pas_agility",
    "endurance": "pas_endurance",
    "focus": "pas_focus",
    "precision": "pas_precision",
    "force": "pas_force"
}

const PASSIVE_ID_TO_ANCHOR: Dictionary = {
    "pas_might": "offense",
    "pas_vitality": "survival",
    "pas_agility": "tempo",
    "pas_endurance": "survival",
    "pas_focus": "tempo",
    "pas_precision": "precision",
    "pas_force": "precision",
    "pas_armor": "survival",
    "pas_resolve": "survival",
    "pas_momentum": "tempo",
    "pas_overcharge": "offense",
    "pas_bastion": "survival",
    "pas_siphon": "offense",
    "pas_zeal": "precision",
    "pas_warding": "survival",
    "pas_harvest": "economy"
}

const SHOP_ITEM_ANCHOR_BOOSTS: Dictionary = {
    "hp_potion": {"survival": 0.35},
    "stamina_tonic": {"tempo": 0.30},
    "pas_might": {"offense": 0.80},
    "pas_armor": {"survival": 0.70},
    "pas_focus": {"tempo": 0.75},
    "pas_precision": {"precision": 0.75},
    "pas_force": {"precision": 0.70},
    "pas_fortune": {"economy": 0.85},
    "pas_resolve": {"survival": 0.70},
    "pas_momentum": {"tempo": 0.80},
    "pas_overcharge": {"offense": 0.80},
    "pas_bastion": {"survival": 0.75},
    "pas_siphon": {"offense": 0.72},
    "pas_zeal": {"precision": 0.72},
    "pas_warding": {"survival": 0.65},
    "pas_harvest": {"economy": 0.80},
    "wpn_magic_missile": {"offense": 0.62},
    "wpn_holy_cross": {"offense": 0.74, "precision": 0.30},
    "wpn_arcane_comet": {"offense": 0.60, "tempo": 0.28},
    "wpn_holy_judgment": {"offense": 0.82},
    "wpn_shadow_tempest": {"tempo": 0.90},
    "wpn_solar_supernova": {"offense": 1.00},
    "wpn_sacred_lance": {"precision": 0.80},
    "wpn_void_chain": {"offense": 0.66, "tempo": 0.24},
    "wpn_frost_orb": {"tempo": 0.74},
    "wpn_storm_bow": {"tempo": 0.70, "precision": 0.24},
    "wpn_radiant_hammer": {"offense": 0.86},
    "wpn_blood_rite": {"offense": 0.72},
    "wpn_vowblade": {"precision": 0.82},
    "wpn_nether_shard": {"offense": 0.68, "tempo": 0.24},
    "wpn_astral_disc": {"tempo": 0.68, "precision": 0.22}
}

const FORGE_ANCHOR_BOOSTS: Dictionary = {
    "damage": {"offense": 1.10},
    "speed": {"tempo": 1.10}
}


func _ready() -> void:
    _player = get_node_or_null(player_path) as CharacterBody2D
    _panel = get_node_or_null(panel_path) as Control
    if _player == null or _panel == null:
        push_warning("LevelUpSystem failed to bind player or panel")
        return

    _progression = _player.get_node_or_null("ProgressionComponent")
    _stats = _player.get_node_or_null("StatsComponent")
    _health = _player.get_node_or_null("HealthComponent")
    _weapon = _player.get_node_or_null("AutoWeapon")
    _load_evolution_recipes()

    if _progression != null and _progression.has_signal("leveled_up"):
        _progression.leveled_up.connect(_on_leveled_up)
    if _panel.has_signal("option_selected"):
        _panel.option_selected.connect(_on_option_selected)


func _on_leveled_up(new_level: int) -> void:
    if _panel.has_method("show_options"):
        var options: Array[Dictionary] = _generate_options()
        _option_lookup.clear()
        for row: Dictionary in options:
            _option_lookup[str(row.get("id", ""))] = row
        _panel.show_options(options, new_level)
        get_tree().paused = true


func _generate_options() -> Array[Dictionary]:
    var pool: Array[Dictionary] = [
        {"id": "power", "title": "Might", "desc": "+12% damage"},
        {"id": "vitality", "title": "Vitality", "desc": "+20 max HP and heal 20"},
        {"id": "agility", "title": "Agility", "desc": "+15 move speed"},
        {"id": "endurance", "title": "Endurance", "desc": "+20 stamina max"},
        {"id": "focus", "title": "Focus", "desc": "-8% weapon interval"},
        {"id": "precision", "title": "Precision", "desc": "+6% crit chance"},
        {"id": "force", "title": "Force", "desc": "+18% crit multiplier"}
    ]

    var picked: Array[Dictionary] = []
    var evolution_options: Array[Dictionary] = _collect_available_evolution_options()
    if not evolution_options.is_empty():
        picked.append(_pick_weighted_evolution_option(evolution_options))

    var bag: Array[Dictionary] = pool.duplicate()
    while picked.size() < 3 and bag.size() > 0:
        var index: int = randi_range(0, bag.size() - 1)
        picked.append(bag[index])
        bag.remove_at(index)
    return picked


func _on_option_selected(option_id: String) -> void:
    var row_var: Variant = _option_lookup.get(option_id, {})
    var row: Dictionary = {}
    if row_var is Dictionary:
        row = row_var

    if str(row.get("type", "upgrade")) == "evolution":
        _apply_evolution_option(row)
    else:
        if SaveManager != null and SaveManager.has_method("unlock_codex_entry"):
            SaveManager.unlock_codex_entry("passives", option_id, "level_up_choice", str(GameManager.current_chapter_id))
        _apply_upgrade(option_id)

    get_tree().paused = false


func _apply_upgrade(option_id: String) -> void:
    match option_id:
        "power":
            if _stats != null and _stats.get("damage_bonus_pct") != null:
                _stats.damage_bonus_pct += 0.12
        "vitality":
            if _health != null and _health.get("max_hp") != null:
                _health.max_hp += 20.0
                _health.heal(20.0)
        "agility":
            if _stats != null and _stats.get("base_move_speed") != null:
                _stats.base_move_speed += 15.0
        "endurance":
            if _stats != null and _stats.get("stamina_max") != null:
                _stats.stamina_max += 20.0
                _stats.current_stamina = minf(_stats.stamina_max, _stats.current_stamina + 20.0)
        "focus":
            var weapon: Node = _player.get_node_or_null("AutoWeapon")
            if weapon != null and weapon.get("attack_interval") != null:
                weapon.attack_interval = maxf(0.12, weapon.attack_interval * 0.92)
        "precision":
            if _stats != null and _stats.get("crit_chance") != null:
                _stats.crit_chance = minf(0.85, _stats.crit_chance + 0.06)
        "force":
            if _stats != null and _stats.get("crit_multiplier") != null:
                _stats.crit_multiplier += 0.18

    _mark_passive_progress(option_id)


func _mark_passive_progress(option_id: String) -> void:
    var passive_id: String = str(PASSIVE_OPTION_TO_ID.get(option_id, "")).strip_edges()
    if passive_id == "":
        return
    _passive_levels[passive_id] = int(_passive_levels.get(passive_id, 0)) + 1
    var anchor_id: String = _resolve_anchor_from_passive(passive_id)
    if anchor_id != "":
        register_build_anchor(anchor_id, 0.85, "level_up:%s" % option_id)


func _load_evolution_recipes() -> void:
    _evolution_recipes.clear()
    var config: Dictionary = ConfigManager.get_config("evolutions", {})
    var rows_var: Variant = config.get("evolutions", [])
    if not (rows_var is Array):
        return

    for item: Variant in rows_var:
        if item is Dictionary:
            _evolution_recipes.append((item as Dictionary).duplicate(true))


func _collect_available_evolution_options() -> Array[Dictionary]:
    var options: Array[Dictionary] = []
    if _weapon == null:
        return options

    var current_weapon_id: String = str(_weapon.get("current_weapon_id")).strip_edges()
    for recipe in _evolution_recipes:
        if not _can_trigger_evolution(recipe, current_weapon_id):
            continue

        var result_weapon_id: String = str(recipe.get("result_weapon_id", "")).strip_edges()
        if result_weapon_id == "":
            continue

        var title: String = str(recipe.get("title", _prettify_result_id(result_weapon_id)))
        var desc: String = str(recipe.get("desc", "Evolve weapon with passive synergy"))
        var passive_id: String = str(recipe.get("passive_id", ""))
        var required_passive_level: int = maxi(1, int(recipe.get("required_passive_level", 1)))
        var anchor_weight: float = get_evolution_anchor_weight(recipe)
        options.append({
            "id": "evo::%s" % result_weapon_id,
            "type": "evolution",
            "title": "Evolution: %s" % title,
            "desc": "%s (need %s Lv.%d)" % [desc, passive_id, required_passive_level],
            "recipe": recipe,
            "anchor_weight": anchor_weight
        })

    return options


func _can_trigger_evolution(recipe: Dictionary, current_weapon_id: String) -> bool:
    if _weapon == null:
        return false

    var weapon_id: String = str(recipe.get("weapon_id", "")).strip_edges()
    var passive_id: String = str(recipe.get("passive_id", "")).strip_edges()
    var result_weapon_id: String = str(recipe.get("result_weapon_id", "")).strip_edges()
    var required_passive_level: int = maxi(1, int(recipe.get("required_passive_level", 1)))

    if weapon_id == "" or passive_id == "" or result_weapon_id == "":
        return false
    if weapon_id != current_weapon_id:
        return false

    var passive_level: int = int(_passive_levels.get(passive_id, 0))
    if passive_level < required_passive_level:
        return false

    if _weapon.has_method("has_evolved_to") and _weapon.has_evolved_to(result_weapon_id):
        return false
    return true


func _apply_evolution_option(option: Dictionary) -> void:
    if _weapon == null:
        return
    var recipe_var: Variant = option.get("recipe", {})
    if not (recipe_var is Dictionary):
        return
    var recipe: Dictionary = recipe_var

    if not _weapon.has_method("apply_evolution_profile"):
        return

    var applied: bool = bool(_weapon.apply_evolution_profile(recipe))
    if not applied:
        return

    var result_weapon_id: String = str(recipe.get("result_weapon_id", "")).strip_edges()
    if result_weapon_id != "" and SaveManager != null and SaveManager.has_method("unlock_codex_entry"):
        SaveManager.unlock_codex_entry("weapons", result_weapon_id, "weapon_evolution", str(GameManager.current_chapter_id))


func _prettify_result_id(raw_id: String) -> String:
    var text: String = raw_id
    if text.begins_with("wpn_"):
        text = text.trim_prefix("wpn_")
    text = text.replace("_", " ")
    return text.capitalize()


func register_build_anchor(anchor_id: String, amount: float = 1.0, _source: String = "") -> void:
    var key: String = anchor_id.strip_edges().to_lower()
    if key == "":
        return
    if not _build_anchor_scores.has(key):
        _build_anchor_scores[key] = 0.0
    var current_value: float = float(_build_anchor_scores.get(key, 0.0))
    _build_anchor_scores[key] = clampf(current_value + amount, 0.0, 99.0)


func register_build_anchor_from_shop(item_id: String) -> void:
    _apply_anchor_boost_map(SHOP_ITEM_ANCHOR_BOOSTS.get(item_id, {}), "shop:%s" % item_id)


func register_build_anchor_from_forge(forge_type: String) -> void:
    _apply_anchor_boost_map(FORGE_ANCHOR_BOOSTS.get(forge_type, {}), "forge:%s" % forge_type)


func get_build_anchor_snapshot() -> Dictionary:
    return _build_anchor_scores.duplicate(true)


func get_evolution_anchor_weight(recipe: Dictionary) -> float:
    var passive_id: String = str(recipe.get("passive_id", "")).strip_edges()
    var required_level: int = maxi(1, int(recipe.get("required_passive_level", 1)))
    var passive_level: int = int(_passive_levels.get(passive_id, 0))
    var anchor_id: String = _resolve_anchor_from_passive(passive_id)
    var anchor_score: float = float(_build_anchor_scores.get(anchor_id, 0.0))
    var level_surplus: float = maxf(0.0, float(passive_level - required_level))
    var weight: float = 1.0 + anchor_score * 0.26 + level_surplus * 0.22
    return clampf(weight, 1.0, 4.5)


func _pick_weighted_evolution_option(options: Array[Dictionary]) -> Dictionary:
    if options.is_empty():
        return {}
    var total_weight: float = 0.0
    for row in options:
        total_weight += maxf(0.01, float(row.get("anchor_weight", 1.0)))
    var roll: float = randf() * total_weight
    var cursor: float = 0.0
    for row in options:
        cursor += maxf(0.01, float(row.get("anchor_weight", 1.0)))
        if roll <= cursor:
            return row
    return options[options.size() - 1]


func _resolve_anchor_from_passive(passive_id: String) -> String:
    return str(PASSIVE_ID_TO_ANCHOR.get(passive_id, "")).strip_edges().to_lower()


func _apply_anchor_boost_map(boost_map_var: Variant, source: String) -> void:
    if not (boost_map_var is Dictionary):
        return
    var boost_map: Dictionary = boost_map_var
    for anchor_key_var in boost_map.keys():
        var anchor_key: String = str(anchor_key_var).strip_edges().to_lower()
        var amount: float = maxf(0.0, float(boost_map.get(anchor_key, 0.0)))
        if amount <= 0.0:
            continue
        register_build_anchor(anchor_key, amount, source)
