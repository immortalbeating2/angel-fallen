extends Control

@onready var _title: Label = $Panel/MarginContainer/VBoxContainer/Title
@onready var _summary: Label = $Panel/MarginContainer/VBoxContainer/Summary
@onready var _weapons: Label = $Panel/MarginContainer/VBoxContainer/Weapons
@onready var _passives: Label = $Panel/MarginContainer/VBoxContainer/Passives
@onready var _stats: Label = $Panel/MarginContainer/VBoxContainer/Stats


func _ready() -> void:
    visible = false


func open_panel(snapshot: Dictionary, run_stats: Dictionary = {}) -> void:
    _populate(snapshot, run_stats)
    visible = true


func close_panel() -> void:
    visible = false


func show_build(snapshot: Dictionary, run_stats: Dictionary = {}) -> void:
    open_panel(snapshot, run_stats)


func _populate(snapshot: Dictionary, run_stats: Dictionary) -> void:
    if _title != null:
        _title.text = "Build"

    var trait_text: String = str(run_stats.get("trait", "-"))
    var tags: Array[String] = []
    var weapon_lines: Array[String] = []
    var weapons: Array = snapshot.get("weapon_slots", [])
    for i in range(6):
        if i < weapons.size() and weapons[i] is Dictionary:
            var row: Dictionary = weapons[i]
            var weapon_stats: Dictionary = row.get("stats", {})
            var row_tags: Variant = weapon_stats.get("special_tags", [])
            if row_tags is Array:
                for tag in row_tags:
                    var tag_text: String = str(tag)
                    if not tags.has(tag_text):
                        tags.append(tag_text)
            var full_tag: String = " MAX" if int(row.get("level", 0)) >= int(snapshot.get("max_level", 8)) else ""
            var evo_tag: String = " EVO" if bool(row.get("evolved", false)) else ""
            weapon_lines.append("%d. %s Lv.%d%s%s" % [i + 1, row.get("id", "-"), row.get("level", 0), full_tag, evo_tag])
        else:
            weapon_lines.append("%d. -" % [i + 1])

    var passive_lines: Array[String] = []
    var passives: Array = snapshot.get("passive_slots", [])
    for i in range(6):
        if i < passives.size() and passives[i] is Dictionary:
            var passive: Dictionary = passives[i]
            passive_lines.append("%d. %s Lv.%d" % [i + 1, passive.get("id", "-"), passive.get("level", 0)])
        else:
            passive_lines.append("%d. -" % [i + 1])

    if _summary != null:
        _summary.text = "Trait: %s | Tags: %s" % [trait_text, ", ".join(tags) if not tags.is_empty() else "-"]
    if _weapons != null:
        _weapons.text = "Weapons\n%s" % "\n".join(weapon_lines)
    if _passives != null:
        _passives.text = "Passives\n%s" % "\n".join(passive_lines)
    if _stats != null:
        _stats.text = "Kills %d | DPS %.1f | Damage Taken %.1f" % [
            int(run_stats.get("kills", 0)),
            float(run_stats.get("estimated_dps", 0.0)),
            float(run_stats.get("damage_taken", 0.0))
        ]
