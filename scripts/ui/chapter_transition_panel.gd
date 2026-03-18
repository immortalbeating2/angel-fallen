extends Control

signal choice_committed(chapter_id: String, choice_id: String, alignment_delta: float)
signal transition_closed

@onready var _title_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Title
@onready var _body_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Body
@onready var _option_1: Button = $CenterContainer/PanelContainer/VBoxContainer/Option1
@onready var _option_2: Button = $CenterContainer/PanelContainer/VBoxContainer/Option2
@onready var _hint_label: Label = $CenterContainer/PanelContainer/VBoxContainer/Hint

var _active: bool = false
var _has_choice: bool = false
var _chapter_id: String = ""
var _choice_1: Dictionary = {}
var _choice_2: Dictionary = {}


func _ready() -> void:
    visible = false


func show_transition(chapter_index: int, current_alignment: float) -> void:
    var data: Dictionary = _get_chapter_data(chapter_index)
    _chapter_id = str(data.get("chapter_id", "chapter_1"))
    _choice_1 = data.get("choice_1", {})
    _choice_2 = data.get("choice_2", {})

    _title_label.text = str(data.get("title", "Chapter Transition"))
    _body_label.text = "%s\n\nCurrent Alignment: %.0f" % [
        str(data.get("body", "")),
        current_alignment
    ]
    _option_1.text = "1) %s (%+.0f)" % [
        str(_choice_1.get("label", "Holy Vow")),
        float(_choice_1.get("delta", 10.0))
    ]
    _option_2.text = "2) %s (%+.0f)" % [
        str(_choice_2.get("label", "Void Oath")),
        float(_choice_2.get("delta", -10.0))
    ]

    _option_1.disabled = false
    _option_2.disabled = false
    _hint_label.text = "Press 1/2 to choose route"
    _has_choice = false
    _active = true
    visible = true


func _unhandled_input(event: InputEvent) -> void:
    if not _active:
        return

    if not _has_choice:
        if event.is_action_pressed("narrative_choice_1"):
            _commit_choice(_choice_1)
        elif event.is_action_pressed("narrative_choice_2"):
            _commit_choice(_choice_2)
        return

    if event.is_action_pressed("interact") or event.is_action_pressed("pause"):
        _close_panel()


func _on_option_1_pressed() -> void:
    _commit_choice(_choice_1)


func _on_option_2_pressed() -> void:
    _commit_choice(_choice_2)


func _on_continue_pressed() -> void:
    if _has_choice:
        _close_panel()


func _commit_choice(choice_data: Dictionary) -> void:
    if not _active or _has_choice:
        return

    var choice_id: String = str(choice_data.get("id", "neutral"))
    var delta: float = float(choice_data.get("delta", 0.0))
    _has_choice = true
    _option_1.disabled = true
    _option_2.disabled = true
    _hint_label.text = "Choice committed: %s (%+.0f). Press E/Esc to continue" % [choice_id.to_upper(), delta]
    choice_committed.emit(_chapter_id, choice_id, delta)


func _close_panel() -> void:
    if not _active:
        return
    _active = false
    visible = false
    transition_closed.emit()


func _get_chapter_data(chapter_index: int) -> Dictionary:
    var chapter_id: String = "chapter_%d" % chapter_index
    var configured: Dictionary = _get_configured_transition(chapter_id)
    if not configured.is_empty():
        return configured

    match chapter_index:
        1:
            return {
                "chapter_id": "chapter_1",
                "title": "Chapter I Complete - Ashen Echo",
                "body": "The campfire reflects on broken wings.\nYou can preserve your light, or bargain with darkness to survive the deeper floors.",
                "choice_1": {"id": "holy_vow", "label": "Keep the Oath", "delta": 10.0},
                "choice_2": {"id": "void_oath", "label": "Embrace the Abyss", "delta": -10.0}
            }
        2:
            return {
                "chapter_id": "chapter_2",
                "title": "Chapter II Complete - Furnace of Faith",
                "body": "Steel and prayer clash in your chest.\nA righteous path grants grace, a darker path grants ruthless power.",
                "choice_1": {"id": "holy_vow", "label": "Raise the Halo", "delta": 14.0},
                "choice_2": {"id": "void_oath", "label": "Feed the Void", "delta": -14.0}
            }
        3:
            return {
                "chapter_id": "chapter_3",
                "title": "Chapter III Complete - Frozen Covenant",
                "body": "Silence answers your steps before the final gate.\nOne final choice will decide the shape of your ending.",
                "choice_1": {"id": "holy_vow", "label": "Redeem the Light", "delta": 18.0},
                "choice_2": {"id": "void_oath", "label": "Crown the Fall", "delta": -18.0}
            }
        _:
            return {
                "chapter_id": "chapter_0",
                "title": "Transition",
                "body": "Your journey continues.",
                "choice_1": {"id": "holy_vow", "label": "Hold the Line", "delta": 8.0},
                "choice_2": {"id": "void_oath", "label": "Break the Seal", "delta": -8.0}
            }


func _get_configured_transition(chapter_id: String) -> Dictionary:
    var config: Dictionary = ConfigManager.get_config("narrative_content", {})
    var transition_rows: Variant = config.get("chapter_transitions", {})
    if not (transition_rows is Dictionary):
        return {}

    var row_variant: Variant = (transition_rows as Dictionary).get(chapter_id, {})
    if not (row_variant is Dictionary):
        return {}

    var row: Dictionary = row_variant
    var choices_variant: Variant = row.get("choices", [])
    if not (choices_variant is Array):
        return {}
    var choices: Array = choices_variant
    if choices.size() < 2:
        return {}

    var c1: Dictionary = choices[0] if choices[0] is Dictionary else {}
    var c2: Dictionary = choices[1] if choices[1] is Dictionary else {}
    if c1.is_empty() or c2.is_empty():
        return {}

    return {
        "chapter_id": chapter_id,
        "title": str(row.get("title", "Chapter Transition")),
        "body": str(row.get("body", "")),
        "choice_1": {
            "id": str(c1.get("id", "holy_vow")),
            "label": str(c1.get("label", "Holy Vow")),
            "delta": float(c1.get("delta", 10.0))
        },
        "choice_2": {
            "id": str(c2.get("id", "void_oath")),
            "label": str(c2.get("label", "Void Oath")),
            "delta": float(c2.get("delta", -10.0))
        }
    }
