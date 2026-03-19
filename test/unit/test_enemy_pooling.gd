extends GutTest

const ENEMY_SCENE_PATH: String = "res://scenes/game/enemy.tscn"


func _spawn_enemy_node() -> CharacterBody2D:
    var scene: PackedScene = load(ENEMY_SCENE_PATH)
    assert_not_null(scene, "Enemy scene should load")

    var enemy: CharacterBody2D = scene.instantiate() as CharacterBody2D
    assert_not_null(enemy, "Enemy instance should be CharacterBody2D")
    add_child_autofree(enemy)
    await get_tree().process_frame
    return enemy


func test_enemy_pool_lifecycle_resets_runtime_state() -> void:
    var enemy: CharacterBody2D = await _spawn_enemy_node()
    var health: Node = enemy.get_node_or_null("HealthComponent")
    assert_not_null(health, "Enemy should have HealthComponent")

    var base_id: String = enemy.enemy_id
    var base_speed: float = enemy.move_speed
    var base_damage: float = enemy.touch_damage
    var base_attack_interval: float = enemy.attack_interval
    var base_scale: Vector2 = enemy.scale
    var base_hp: float = float(health.get("max_hp"))

    enemy.move_speed = base_speed * 3.0
    enemy.touch_damage = base_damage * 2.0
    enemy.attack_interval = maxf(0.1, base_attack_interval * 0.5)
    enemy.scale = base_scale * 1.8
    health.set("max_hp", base_hp * 4.0)
    health.set("current_hp", 1.0)

    enemy.apply_spawn_profile({
        "tier": "boss",
        "archetype": "boss",
        "enemy_id": "boss_void_lord",
        "base_color": Color(1.0, 0.1, 0.1, 1.0),
        "scale": Vector2(2.4, 2.4)
    })

    enemy.on_pool_released()
    assert_false(enemy.is_pool_active(), "Enemy should be inactive after pool release")
    assert_false(enemy.is_in_group("enemy"), "Enemy should leave active enemy group after release")

    enemy.on_pool_acquired()
    assert_true(enemy.is_pool_active(), "Enemy should become active after pool acquire")
    assert_true(enemy.is_in_group("enemy"), "Enemy should rejoin active enemy group after acquire")

    assert_eq(enemy.enemy_id, base_id, "Enemy id should reset to template id")
    assert_true(is_equal_approx(enemy.move_speed, base_speed), "Move speed should reset to template")
    assert_true(is_equal_approx(enemy.touch_damage, base_damage), "Touch damage should reset to template")
    assert_true(is_equal_approx(enemy.attack_interval, base_attack_interval), "Attack interval should reset to template")
    assert_true(enemy.scale.is_equal_approx(base_scale), "Scale should reset to template")
    assert_true(is_equal_approx(float(health.get("max_hp")), base_hp), "Max HP should reset to template")
    assert_true(is_equal_approx(float(health.get("current_hp")), base_hp), "Current HP should refill to template")


func test_enemy_died_releases_to_object_pool() -> void:
    var enemy: CharacterBody2D = await _spawn_enemy_node()
    enemy._on_health_died(enemy)
    await get_tree().process_frame

    assert_eq(enemy.get_parent(), ObjectPool, "Dead enemy should be released to ObjectPool")
    assert_false(enemy.is_pool_active(), "Enemy should be inactive after death release")
