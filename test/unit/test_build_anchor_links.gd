extends GutTest

const LEVEL_UP_SYSTEM_SCRIPT := preload("res://scripts/systems/level_up_system.gd")
const GAME_WORLD_SCENE_PATH := "res://scenes/game/game_world.tscn"


class AnchorSpy:
    extends Node

    var shop_calls: Array[String] = []
    var forge_calls: Array[String] = []
    var direct_anchor_calls: Array[Dictionary] = []

    func register_build_anchor_from_shop(item_id: String) -> void:
        shop_calls.append(item_id)

    func register_build_anchor_from_forge(forge_type: String) -> void:
        forge_calls.append(forge_type)

    func register_build_anchor(anchor_id: String, amount: float, source: String) -> void:
        direct_anchor_calls.append({
            "anchor": anchor_id,
            "amount": amount,
            "source": source
        })


func _instantiate_world() -> Node:
    var scene: PackedScene = load(GAME_WORLD_SCENE_PATH)
    assert_not_null(scene, "game_world scene should load")
    if scene == null:
        return null

    var world: Node = scene.instantiate()
    assert_not_null(world, "game_world scene should instantiate")
    if world == null:
        return null

    add_child_autofree(world)
    await get_tree().process_frame
    return world


func test_level_up_system_tracks_shop_and_forge_build_anchors() -> void:
    var system: Node = LEVEL_UP_SYSTEM_SCRIPT.new()
    assert_not_null(system, "level up system should instantiate")
    if system == null:
        return

    system.call("register_build_anchor_from_shop", "pas_might")
    system.call("register_build_anchor_from_shop", "pas_harvest")
    system.call("register_build_anchor_from_forge", "speed")

    var snapshot_var: Variant = system.call("get_build_anchor_snapshot")
    assert_typeof(snapshot_var, TYPE_DICTIONARY, "build anchor snapshot should be Dictionary")
    if not (snapshot_var is Dictionary):
        return

    var snapshot: Dictionary = snapshot_var
    assert_gt(float(snapshot.get("offense", 0.0)), 0.0, "pas_might should add offense anchor")
    assert_gt(float(snapshot.get("economy", 0.0)), 0.0, "pas_harvest should add economy anchor")
    assert_gt(float(snapshot.get("tempo", 0.0)), 0.0, "speed forge should add tempo anchor")
    system.free()


func test_evolution_anchor_weight_prefers_matching_passive_progress() -> void:
    var system: Node = LEVEL_UP_SYSTEM_SCRIPT.new()
    assert_not_null(system, "level up system should instantiate")
    if system == null:
        return

    system.set("_passive_levels", {
        "pas_focus": 3,
        "pas_vitality": 1
    })
    system.call("register_build_anchor", "tempo", 2.0)

    var tempo_recipe: Dictionary = {
        "passive_id": "pas_focus",
        "required_passive_level": 1
    }
    var survival_recipe: Dictionary = {
        "passive_id": "pas_vitality",
        "required_passive_level": 1
    }

    var tempo_weight: float = float(system.call("get_evolution_anchor_weight", tempo_recipe))
    var survival_weight: float = float(system.call("get_evolution_anchor_weight", survival_recipe))
    assert_gt(tempo_weight, survival_weight, "tempo-biased anchors should weight focus evolution higher")
    assert_gte(tempo_weight, 1.0, "evolution anchor weight lower bound")
    system.free()


func test_game_world_shop_and_forge_notify_level_up_system_anchor_hooks() -> void:
    var world: Node = await _instantiate_world()
    if world == null:
        return

    var spy := AnchorSpy.new()
    add_child_autofree(spy)
    world.set("_level_up_system", spy)

    world.call("_apply_shop_item_effect", "pas_focus")
    assert_eq(spy.shop_calls.size(), 1, "shop effect should notify level up anchor hook")
    if spy.shop_calls.size() > 0:
        assert_eq(spy.shop_calls[0], "pas_focus", "shop anchor hook should pass item id")

    world.set("_ore", 8)
    world.call("_try_forge_speed")
    assert_eq(spy.direct_anchor_calls.size(), 1, "forge success should notify direct anchor hook")
    if spy.direct_anchor_calls.size() > 0:
        var row: Dictionary = spy.direct_anchor_calls[0]
        assert_eq(str(row.get("anchor", "")), "tempo", "forge speed recipe should notify tempo anchor")
        assert_eq(str(row.get("source", "")), "forge:speed", "forge anchor hook should include forge source id")


func test_game_world_uses_data_driven_forge_recipe_cost_and_message() -> void:
    var world: Node = await _instantiate_world()
    if world == null:
        return

    world.set("_forge_recipes", {
        "speed": {
            "ore_cost": 4,
            "damage_mult": 1.0,
            "interval_mult": 0.9,
            "crit_chance_add": 0.0,
            "crit_multiplier_add": 0.0,
            "max_hp_add": 0,
            "heal_flat": 0.0,
            "anchor": "tempo",
            "anchor_amount": 1.0,
            "success_text": "Forge complete: data-driven speed recipe"
        }
    })

    world.set("_ore", 4)
    world.call("_try_forge_speed")

    assert_eq(int(world.get("_ore")), 0, "forge should consume ore_cost from configured speed recipe")
    assert_eq(str(world.get("_camp_message")), "Forge complete: data-driven speed recipe", "forge should use configured success_text")


func test_boss_stage_accessory_grants_once_and_applies_anchor_bonus() -> void:
    var world: Node = await _instantiate_world()
    if world == null:
        return

    var spy := AnchorSpy.new()
    add_child_autofree(spy)
    world.set("_level_up_system", spy)

    world.call("_grant_boss_stage_accessory", "chapter_3")
    var accessories_after_first: Array = world.get("_equipped_accessories")
    assert_true(accessories_after_first.has("acc_zero_mark"), "chapter_3 boss should grant frost chapter accessory")

    assert_eq(spy.direct_anchor_calls.size(), 1, "boss accessory should grant one anchor bonus")
    if spy.direct_anchor_calls.size() > 0:
        var row: Dictionary = spy.direct_anchor_calls[0]
        assert_eq(str(row.get("anchor", "")), "precision", "acc_zero_mark should contribute precision anchor")
        assert_eq(str(row.get("source", "")), "accessory:boss_clear:acc_zero_mark", "accessory anchor source should include boss_clear label")

    var gold_before_second: int = int(world.get("_gold"))
    world.call("_grant_boss_stage_accessory", "chapter_3")
    assert_eq(int(world.get("_gold")), gold_before_second, "claimed chapter accessory should not be granted twice")
    assert_eq(spy.direct_anchor_calls.size(), 1, "second boss stage grant should not add duplicate anchor bonus")


func test_specific_accessory_pickup_id_routes_to_direct_grant_logic() -> void:
    var world: Node = await _instantiate_world()
    if world == null:
        return

    var spy := AnchorSpy.new()
    add_child_autofree(spy)
    world.set("_level_up_system", spy)

    world.call("_on_pickup_collected", "accessory", 1, "acc_flame_core")

    var equipped: Array = world.get("_equipped_accessories")
    assert_true(equipped.has("acc_flame_core"), "direct accessory pickup id should equip matching accessory")
    assert_eq(spy.direct_anchor_calls.size(), 1, "direct accessory pickup should apply anchor bonus")
    if spy.direct_anchor_calls.size() > 0:
        var row: Dictionary = spy.direct_anchor_calls[0]
        assert_eq(str(row.get("anchor", "")), "offense", "acc_flame_core should contribute offense anchor")
