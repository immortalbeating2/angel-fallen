extends Node2D

signal opened(rewards: Array[Dictionary])

@export var reward_count: int = 1

var _rewards: Array[Dictionary] = []
var _eligible_evolutions: Array[Dictionary] = []
var _opened: bool = false


func configure(rewards: Array, eligible_evolutions: Array = [], count: int = 1) -> void:
    _rewards.clear()
    for row in rewards:
        if row is Dictionary:
            _rewards.append((row as Dictionary).duplicate(true))
    _eligible_evolutions.clear()
    for row in eligible_evolutions:
        if row is Dictionary:
            _eligible_evolutions.append((row as Dictionary).duplicate(true))
    reward_count = clampi(count, 1, 5)
    _opened = false


func open() -> Array[Dictionary]:
    if _opened:
        return []
    _opened = true

    var result: Array[Dictionary] = []
    if not _eligible_evolutions.is_empty():
        var recipe: Dictionary = _eligible_evolutions[0].duplicate(true)
        result.append({
            "type": "evolution",
            "id": str(recipe.get("result_weapon_id", "")),
            "recipe": recipe,
        })
    else:
        var target_count: int = mini(reward_count, _rewards.size())
        for i in range(target_count):
            result.append((_rewards[i] as Dictionary).duplicate(true))

    opened.emit(result)
    return result


func is_opened() -> bool:
    return _opened
