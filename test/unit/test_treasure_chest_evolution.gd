extends GutTest

const TREASURE_CHEST_SCRIPT: Script = preload("res://scripts/game/treasure_chest.gd")


func test_chest_prioritizes_eligible_evolution() -> void:
    var chest: Node = TREASURE_CHEST_SCRIPT.new()
    add_child_autofree(chest)
    chest.configure(
        [{"type": "gold", "amount": 20}],
        [{"weapon_id": "wpn_holy_cross", "result_weapon_id": "wpn_holy_judgment"}],
        3
    )

    var rewards: Array = chest.open()
    assert_eq(str(rewards[0].get("type", "")), "evolution", "宝箱应优先给满足条件的进化")
    assert_eq(str(rewards[0].get("id", "")), "wpn_holy_judgment", "进化奖励应包含结果武器 id")


func test_chest_returns_regular_rewards_when_no_evolution() -> void:
    var chest: Node = TREASURE_CHEST_SCRIPT.new()
    add_child_autofree(chest)
    chest.configure(
        [{"type": "gold", "amount": 20}, {"type": "ore", "amount": 1}, {"type": "food", "amount": 1}],
        [],
        3
    )

    var rewards: Array = chest.open()
    assert_eq(rewards.size(), 3, "无进化候选时宝箱应按数量返回普通奖励")
    assert_eq(str(rewards[0].get("type", "")), "gold", "普通奖励顺序应稳定")
