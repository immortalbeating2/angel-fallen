extends Node

@export var player_path: NodePath = ^"../Player"
@export var panel_path: NodePath = ^"../LevelUpPanel"

var _player: CharacterBody2D
var _panel: Control
var _progression: Node
var _stats: Node
var _health: Node


func _ready() -> void:
    _player = get_node_or_null(player_path) as CharacterBody2D
    _panel = get_node_or_null(panel_path) as Control
    if _player == null or _panel == null:
        push_warning("LevelUpSystem failed to bind player or panel")
        return

    _progression = _player.get_node_or_null("ProgressionComponent")
    _stats = _player.get_node_or_null("StatsComponent")
    _health = _player.get_node_or_null("HealthComponent")

    if _progression != null and _progression.has_signal("leveled_up"):
        _progression.leveled_up.connect(_on_leveled_up)
    if _panel.has_signal("option_selected"):
        _panel.option_selected.connect(_on_option_selected)


func _on_leveled_up(new_level: int) -> void:
    if _panel.has_method("show_options"):
        _panel.show_options(_generate_options(), new_level)
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
    var bag: Array[Dictionary] = pool.duplicate()
    while picked.size() < 3 and bag.size() > 0:
        var index: int = randi_range(0, bag.size() - 1)
        picked.append(bag[index])
        bag.remove_at(index)
    return picked


func _on_option_selected(option_id: String) -> void:
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
