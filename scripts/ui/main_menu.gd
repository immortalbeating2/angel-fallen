extends Control

@onready var _meta_value: Label = $CenterContainer/VBoxContainer/MetaValue
@onready var _run_value: Label = $CenterContainer/VBoxContainer/RunValue
@onready var _best_value: Label = $CenterContainer/VBoxContainer/BestValue
@onready var _progress_value: Label = $CenterContainer/VBoxContainer/ProgressValue
@onready var _upgrade_1_button: Button = $CenterContainer/VBoxContainer/Upgrade1Button
@onready var _upgrade_2_button: Button = $CenterContainer/VBoxContainer/Upgrade2Button
@onready var _upgrade_3_button: Button = $CenterContainer/VBoxContainer/Upgrade3Button
@onready var _upgrade_4_button: Button = $CenterContainer/VBoxContainer/Upgrade4Button
@onready var _upgrade_5_button: Button = $CenterContainer/VBoxContainer/Upgrade5Button
@onready var _shop_message_value: Label = $CenterContainer/VBoxContainer/ShopMessageValue
@onready var _achievement_list_value: Label = $CenterContainer/VBoxContainer/AchievementListValue
@onready var _fragment_review_value: Label = $CenterContainer/VBoxContainer/FragmentReviewValue
@onready var _review_fragment_button: Button = $CenterContainer/VBoxContainer/ReviewFragmentButton
@onready var _last_run_value: Label = $CenterContainer/VBoxContainer/LastRunValue

var _shop_message: String = ""
var _fragment_cursor: int = 0


func _ready() -> void:
    GameManager.set_state(GameManager.GameState.MENU)
    _refresh_meta_text()


func _on_start_pressed() -> void:
    SceneManager.go_to_game_world()


func _on_quit_pressed() -> void:
    get_tree().quit()


func _on_reset_meta_pressed() -> void:
    SaveManager.reset_meta()
    _shop_message = "Meta data reset"
    _refresh_meta_text()


func _on_upgrade_1_pressed() -> void:
    _try_buy_upgrade(0)


func _on_upgrade_2_pressed() -> void:
    _try_buy_upgrade(1)


func _on_upgrade_3_pressed() -> void:
    _try_buy_upgrade(2)


func _on_upgrade_4_pressed() -> void:
    _try_buy_upgrade(3)


func _on_upgrade_5_pressed() -> void:
    _try_buy_upgrade(4)


func _on_review_fragment_button_pressed() -> void:
    _fragment_cursor += 1
    _refresh_fragment_review()


func _refresh_meta_text() -> void:
    var meta: Dictionary = SaveManager.get_meta()
    var last_run: Dictionary = SaveManager.get_last_run()
    var unlocked_achievements: Array[String] = SaveManager.get_unlocked_achievements()
    var unlocked_endings: Array[String] = SaveManager.get_unlocked_endings()
    var achievements_config: Dictionary = ConfigManager.get_config("achievements", {})
    var total_achievements: int = 0
    var rows: Variant = achievements_config.get("achievements", [])
    if rows is Array:
        total_achievements = (rows as Array).size()

    _meta_value.text = str(meta.get("meta_currency", 0))
    _run_value.text = "%d runs / %d kills" % [
        int(meta.get("total_runs", 0)),
        int(meta.get("total_kills", 0))
    ]
    _best_value.text = "Highest Room %d | Best Lv %d | Victories %d" % [
        int(meta.get("highest_room", 1)),
        int(meta.get("best_level", 1)),
        int(meta.get("total_victories", 0))
    ]
    _progress_value.text = "Achievements %d/%d | Endings %d/3" % [
        unlocked_achievements.size(),
        total_achievements,
        unlocked_endings.size()
    ]
    _refresh_upgrade_buttons()
    _refresh_achievement_list()
    _refresh_fragment_review()

    if last_run.is_empty():
        _last_run_value.text = "No run record yet"
        return

    var ending_text: String = str(last_run.get("ending_id", ""))
    if ending_text == "":
        ending_text = "-"
    var new_achievements_count: int = 0
    var new_achievements_var: Variant = last_run.get("new_achievements", [])
    if new_achievements_var is Array:
        new_achievements_count = (new_achievements_var as Array).size()

    _last_run_value.text = "Last: %s | Rooms %d | Kills %d | Lv %d | Meta +%d | Ending %s | NewAch %d" % [
        str(last_run.get("outcome", "death")).to_upper(),
        int(last_run.get("rooms_cleared", 0)),
        int(last_run.get("kills", 0)),
        int(last_run.get("level_reached", 1)),
        int(last_run.get("meta_reward", 0)),
        ending_text,
        new_achievements_count
    ]


func _try_buy_upgrade(index: int) -> void:
    var rows: Array[Dictionary] = _get_meta_upgrade_rows()
    if index < 0 or index >= rows.size():
        return

    var row: Dictionary = rows[index]
    var upgrade_id: String = str(row.get("id", ""))
    var title: String = str(row.get("title", upgrade_id))
    var result: Dictionary = SaveManager.purchase_upgrade(upgrade_id)

    if bool(result.get("ok", false)):
        _shop_message = "Purchased %s -> Lv.%d" % [title, int(result.get("new_level", 0))]
    else:
        var reason: String = str(result.get("reason", "failed"))
        if reason == "not_enough_currency":
            _shop_message = "Need %d meta (have %d)" % [
                int(result.get("cost", 0)),
                int(result.get("currency", 0))
            ]
        elif reason == "max_level":
            _shop_message = "%s is already maxed" % title
        else:
            _shop_message = "Upgrade purchase failed"

    _refresh_meta_text()


func _refresh_upgrade_buttons() -> void:
    var rows: Array[Dictionary] = _get_meta_upgrade_rows()
    var buttons: Array[Button] = [
        _upgrade_1_button,
        _upgrade_2_button,
        _upgrade_3_button,
        _upgrade_4_button,
        _upgrade_5_button
    ]

    for i in range(buttons.size()):
        var button: Button = buttons[i]
        if i >= rows.size():
            button.visible = false
            continue

        button.visible = true
        var row: Dictionary = rows[i]
        var upgrade_id: String = str(row.get("id", ""))
        var title: String = str(row.get("title", upgrade_id))
        var max_level: int = int(row.get("max_level", 1))
        var level: int = SaveManager.get_upgrade_level(upgrade_id)
        var cost: int = SaveManager.get_upgrade_cost(upgrade_id)

        if level >= max_level or cost < 0:
            button.text = "%d) %s Lv.%d/%d (MAX)" % [i + 1, title, level, max_level]
            button.disabled = true
        else:
            button.text = "%d) %s Lv.%d/%d  Cost:%d" % [i + 1, title, level, max_level, cost]
            button.disabled = false

    if _shop_message == "":
        _shop_message_value.text = "Meta Shop: buy permanent upgrades"
    else:
        _shop_message_value.text = _shop_message


func _refresh_achievement_list() -> void:
    var rows_var: Variant = ConfigManager.get_config("achievements", {}).get("achievements", [])
    var rows: Array = []
    if rows_var is Array:
        rows = rows_var

    var unlocked: Array[String] = SaveManager.get_unlocked_achievements()
    var lines: Array[String] = []
    lines.append("Achievements:")
    for item: Variant in rows:
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var ach_id: String = str(row.get("id", ""))
        var title: String = str(row.get("title", ach_id))
        var mark: String = "[ ]"
        if unlocked.has(ach_id):
            mark = "[x]"
        lines.append("%s %s" % [mark, title])

    var endings: Array[String] = SaveManager.get_unlocked_endings()
    lines.append("Endings:")
    lines.append("%s Redeem" % ("[x]" if endings.has("nar_ending_redeem") else "[ ]"))
    lines.append("%s Fall" % ("[x]" if endings.has("nar_ending_fall") else "[ ]"))
    lines.append("%s Balance" % ("[x]" if endings.has("nar_ending_balance") else "[ ]"))

    var unlocked_fragments: Array[String] = SaveManager.get_unlocked_fragments()
    var fragment_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("memory_fragments", {})
    var fragment_rows: Dictionary = {}
    if fragment_rows_var is Dictionary:
        fragment_rows = fragment_rows_var

    lines.append("Memory Fragments:")
    lines.append("Unlocked %d / %d" % [unlocked_fragments.size(), fragment_rows.size()])
    for item: Variant in unlocked_fragments:
        var fragment_id: String = str(item)
        var fragment_title: String = fragment_id
        var row_var: Variant = fragment_rows.get(fragment_id, {})
        if row_var is Dictionary:
            fragment_title = str((row_var as Dictionary).get("title", fragment_id))
        lines.append("[x] %s" % fragment_title)

    _achievement_list_value.text = "\n".join(PackedStringArray(lines))


func _get_meta_upgrade_rows() -> Array[Dictionary]:
    var config: Dictionary = ConfigManager.get_config("meta_upgrades", {})
    var rows_var: Variant = config.get("upgrades", [])
    var rows: Array[Dictionary] = []
    if rows_var is Array:
        for item: Variant in rows_var:
            if item is Dictionary:
                rows.append(item)
    return rows


func _refresh_fragment_review() -> void:
    var unlocked_fragments: Array[String] = SaveManager.get_unlocked_fragments()
    if unlocked_fragments.is_empty():
        _review_fragment_button.disabled = true
        _fragment_review_value.text = "Memory Archive: no fragments unlocked yet"
        _fragment_cursor = 0
        return

    _review_fragment_button.disabled = false
    _fragment_cursor = posmod(_fragment_cursor, unlocked_fragments.size())
    var fragment_id: String = unlocked_fragments[_fragment_cursor]

    var fragment_rows_var: Variant = ConfigManager.get_config("narrative_content", {}).get("memory_fragments", {})
    var row: Dictionary = {}
    if fragment_rows_var is Dictionary:
        var row_var: Variant = (fragment_rows_var as Dictionary).get(fragment_id, {})
        if row_var is Dictionary:
            row = row_var

    var title: String = str(row.get("title", fragment_id))
    var text: String = str(row.get("text", "No memory text."))
    _fragment_review_value.text = "Memory Archive (%d/%d)\n%s\n%s" % [
        _fragment_cursor + 1,
        unlocked_fragments.size(),
        title,
        text
    ]
