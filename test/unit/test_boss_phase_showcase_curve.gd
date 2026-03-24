extends GutTest

const ENEMY_SCENE_PATH: String = "res://scenes/game/enemy.tscn"
const ENEMY_SPAWNER_SCRIPT := preload("res://scripts/systems/enemy_spawner.gd")


class MockPlayer:
    extends CharacterBody2D

    var damage_taken: float = 0.0
    var last_knockback: Vector2 = Vector2.ZERO

    func apply_damage(amount: float) -> void:
        damage_taken += amount

    func apply_knockback(force: Vector2) -> void:
        last_knockback = force


func _spawn_enemy_node() -> CharacterBody2D:
    var scene: PackedScene = load(ENEMY_SCENE_PATH)
    assert_not_null(scene, "Enemy scene should load")
    if scene == null:
        return null

    var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
    assert_not_null(enemy, "Enemy instance should be CharacterBody2D")
    if enemy == null:
        return null

    add_child_autofree(enemy)
    await get_tree().process_frame
    return enemy


func _set_boss_phase_by_hp(boss: CharacterBody2D, hp_ratio: float) -> void:
    var health: Node = boss.get_node_or_null("HealthComponent")
    if health == null:
        return
    var max_hp: float = float(health.get("max_hp"))
    health.set("current_hp", clampf(max_hp * hp_ratio, 1.0, max_hp))
    boss.call("_update_phase_by_hp")


func _clear_active_enemies() -> void:
    for node: Node in get_tree().get_nodes_in_group("enemy"):
        if node == null or not is_instance_valid(node):
            continue
        if ObjectPool != null and node.get_parent() == ObjectPool:
            continue
        if ObjectPool != null:
            ObjectPool.release("enemy_basic", node)
        else:
            node.queue_free()


func test_boss_audio_cues_capture_phase_and_support_events() -> void:
    if AudioManager == null:
        pending("AudioManager autoload not available in test runtime")
        return
    if not AudioManager.has_method("clear_boss_cue_snapshots"):
        pending("AudioManager cue snapshot helpers are unavailable")
        return

    AudioManager.clear_boss_cue_snapshots()

    var enemy: CharacterBody2D = await _spawn_enemy_node()
    if enemy == null:
        return

    var player := MockPlayer.new()
    add_child_autofree(player)
    player.add_to_group("player")
    player.global_position = Vector2(128.0, 0.0)
    await get_tree().process_frame

    enemy.global_position = Vector2.ZERO
    enemy.apply_spawn_profile({
        "tier": "boss",
        "archetype": "boss",
        "enemy_id": "boss_frost_king",
        "scale": Vector2(2.0, 2.0)
    })
    enemy.set("_player", player)
    _set_boss_phase_by_hp(enemy, 0.62)

    var phase_cue: Dictionary = AudioManager.get_last_boss_phase_cue_snapshot()
    assert_eq(str(phase_cue.get("boss_id", "")), "boss_frost_king", "phase cue should record frost boss id")
    assert_eq(int(phase_cue.get("phase_index", -1)), 1, "phase cue should record phase 1 transition")
    assert_eq(str(phase_cue.get("family", "")), "frost", "phase cue should classify frost family")

    _clear_active_enemies()
    await get_tree().process_frame

    var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new()
    spawner.enemy_scene = load(ENEMY_SCENE_PATH)
    spawner.max_alive = 64
    add_child_autofree(spawner)

    spawner.start_room_combat(15, "boss", "boss_void_lord", {})
    spawner.call("_process", 0.2)
    var boss: CharacterBody2D = spawner.call("_find_active_boss_node") as CharacterBody2D
    assert_not_null(boss, "void boss should spawn")
    if boss == null:
        return

    _set_boss_phase_by_hp(boss, 0.2)
    spawner.call("_process_boss_support")

    var support_cue: Dictionary = AudioManager.get_last_boss_support_cue_snapshot()
    assert_eq(str(support_cue.get("boss_id", "")), "boss_void_lord", "support cue should record void boss id")
    assert_eq(int(support_cue.get("phase_index", -1)), 3, "support cue should record late void phase")
    assert_gt(int(support_cue.get("spawned_count", 0)), 0, "support cue should capture spawned support count")
    assert_true(bool(support_cue.get("includes_miniboss", false)), "late void support cue should indicate miniboss inclusion")


func test_void_miniboss_curve_is_stronger_than_frost_curve() -> void:
    var spawner: Node2D = ENEMY_SPAWNER_SCRIPT.new()
    spawner.enemy_scene = load(ENEMY_SCENE_PATH)
    add_child_autofree(spawner)

    var frost_curve: Dictionary = spawner.call("get_boss_support_curve_snapshot", "boss_frost_king", 2, true)
    var void_curve: Dictionary = spawner.call("get_boss_support_curve_snapshot", "boss_void_lord", 3, true)

    assert_eq(str(frost_curve.get("chapter_id", "")), "chapter_3", "frost support should map to chapter_3 curve")
    assert_eq(str(void_curve.get("chapter_id", "")), "chapter_4", "void support should map to chapter_4 curve")

    assert_gt(float(void_curve.get("hp_mult", 0.0)), float(frost_curve.get("hp_mult", 0.0)), "void late-phase miniboss curve should have higher hp multiplier")
    assert_gt(float(void_curve.get("damage_mult", 0.0)), float(frost_curve.get("damage_mult", 0.0)), "void late-phase miniboss curve should have higher damage multiplier")
    assert_gt(float(void_curve.get("speed_mult", 0.0)), float(frost_curve.get("speed_mult", 0.0)), "void late-phase miniboss curve should have higher speed multiplier")
    assert_lt(float(void_curve.get("attack_interval_mult", 1.0)), float(frost_curve.get("attack_interval_mult", 1.0)), "void late-phase miniboss curve should attack faster (lower attack interval multiplier)")
