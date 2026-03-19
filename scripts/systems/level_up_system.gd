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

const PASSIVE_OPTION_TO_ID: Dictionary = {
    "power": "pas_might",
    "vitality": "pas_vitality",
    "agility": "pas_agility",
    "endurance": "pas_endurance",
    "focus": "pas_focus",
    "precision": "pas_precision",
    "force": "pas_force"
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
        picked.append(evolution_options[randi_range(0, evolution_options.size() - 1)])

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

    var current_weapon_id: String = str(_weapon.get("current_weapon_id", "")).strip_edges()
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
        options.append({
            "id": "evo::%s" % result_weapon_id,
            "type": "evolution",
            "title": "Evolution: %s" % title,
            "desc": "%s (need %s Lv.%d)" % [desc, passive_id, required_passive_level],
            "recipe": recipe
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
