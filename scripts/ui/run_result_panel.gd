extends Control

signal back_to_menu_requested

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _summary_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Summary
@onready var _ending_label: Label = $CenterContainer/PanelContainer/VBoxContainer/EndingStory
@onready var _choices_label: Label = $CenterContainer/PanelContainer/VBoxContainer/NarrativeChoices
@onready var _unlock_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Unlocks

var _active: bool = false


func _ready() -> void:
    visible = false


func show_result(run_result: Dictionary) -> void:
    var outcome: String = str(run_result.get("outcome", "death")).to_upper()
    _title_label.text = "Run %s" % outcome

    _summary_label.text = "Rooms %d | Kills %d | Lv %d | Meta +%d" % [
        int(run_result.get("rooms_cleared", 0)),
        int(run_result.get("kills", 0)),
        int(run_result.get("level_reached", 1)),
        int(run_result.get("meta_reward", 0))
    ]

    var lines: Array[String] = []
    _choices_label.text = _build_choices_summary(run_result.get("narrative_choices", []))

    var ending_id: String = str(run_result.get("ending_id", ""))
    if ending_id != "":
        _ending_label.text = "%s\n%s" % [_get_ending_title(ending_id), _get_ending_story(ending_id)]
    else:
        _ending_label.text = "No ending unlocked in this run"

    var new_achievements_var: Variant = run_result.get("new_achievements", [])
    if new_achievements_var is Array and not (new_achievements_var as Array).is_empty():
        var ids: PackedStringArray = PackedStringArray()
        for ach_id: Variant in new_achievements_var:
            ids.append(str(ach_id))
        lines.append("New Achievements: %s" % ", ".join(ids))

    if lines.is_empty():
        lines.append("No new unlocks this run")
    _unlock_label.text = "\n".join(PackedStringArray(lines))

    visible = true
    _active = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return
    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _request_back()


func _on_back_button_pressed() -> void:
    _request_back()


func _request_back() -> void:
    if not _active:
        return
    _active = false
    visible = false
    back_to_menu_requested.emit()


func _get_ending_title(ending_id: String) -> String:
    var configured: Dictionary = _get_ending_row(ending_id)
    if not configured.is_empty():
        return str(configured.get("title", "Ending"))

    match ending_id:
        "nar_ending_redeem":
            return "Ending: REDEEM"
        "nar_ending_fall":
            return "Ending: FALL"
        "nar_ending_balance":
            return "Ending: BALANCE"
        _:
            return "Ending: %s" % ending_id


func _get_ending_story(ending_id: String) -> String:
    var configured: Dictionary = _get_ending_row(ending_id)
    if not configured.is_empty():
        return str(configured.get("story", "A new fate is recorded."))

    match ending_id:
        "nar_ending_redeem":
            return "You rise with broken wings healed by grace. The abyss closes, but your oath remains."
        "nar_ending_fall":
            return "You wear the void as a crown. Salvation is denied, and power becomes your final prayer."
        "nar_ending_balance":
            return "Neither halo nor abyss claims you. You walk the narrow dusk, guarding both worlds."
        _:
            return "A new fate is recorded."


func _get_ending_row(ending_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var ending_rows: Variant = config.get("endings", {})
    if ending_rows is Dictionary:
        var row: Variant = (ending_rows as Dictionary).get(ending_id, {})
        if row is Dictionary:
            return row
    return {}


func _build_choices_summary(raw_choices: Variant) -> String:
    if not (raw_choices is Array):
        return "Narrative Choices: none"

    var choices: Array = raw_choices
    if choices.is_empty():
        return "Narrative Choices: none"

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
