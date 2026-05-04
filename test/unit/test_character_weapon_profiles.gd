extends GutTest


func test_characters_config_contains_weapon_profiles() -> void:
    var file := FileAccess.open("res://data/balance/characters.json", FileAccess.READ)
    assert_not_null(file, "characters.json should be readable")

    var parsed: Variant = JSON.parse_string(file.get_as_text())
    assert_true(parsed is Dictionary, "characters.json root must be Dictionary")

    var root: Dictionary = parsed
    var rows_var: Variant = root.get("characters", [])
    assert_true(rows_var is Array, "characters field must be Array")

    var rows: Array = rows_var
    assert_gt(rows.size(), 0, "characters array should not be empty")

    for item: Variant in rows:
        assert_true(item is Dictionary, "each character row must be Dictionary")
        if not (item is Dictionary):
            continue
        var row: Dictionary = item
        var profile_var: Variant = row.get("weapon_profile", {})
        assert_true(profile_var is Dictionary, "weapon_profile must be Dictionary")
        if not (profile_var is Dictionary):
            continue

        var profile: Dictionary = profile_var
        assert_ne(str(profile.get("mode", "")), "", "mode should not be empty")
        assert_gte(int(profile.get("projectile_count", 0)), 1, "projectile_count >= 1")
        assert_gte(float(profile.get("spread_angle_deg", -1)), 0.0, "spread_angle_deg >= 0")
        assert_gte(float(profile.get("spread_jitter_deg", -1)), 0.0, "spread_jitter_deg >= 0")
        assert_gte(int(profile.get("projectile_hits", 0)), 1, "projectile_hits >= 1")
        assert_ne(str(profile.get("projectile_style", "")), "", "projectile_style should not be empty")


func test_projectile_setup_accepts_hits_and_style() -> void:
    var scene := load("res://scenes/game/projectile.tscn") as PackedScene
    assert_not_null(scene, "projectile scene should load")

    var projectile := scene.instantiate()
    assert_not_null(projectile, "projectile should instantiate")

    projectile.setup(
        null,
        Vector2.RIGHT,
        12.0,
        0,
        0.0,
        0.0,
        1.5,
        false,
        90.0,
        3,
        "mage_orb",
        44.0,
        0.4
    )

    assert_eq(projectile._remaining_hits, 3, "remaining hits should be assigned")
    assert_eq(projectile._style_id, "mage_orb", "style id should be assigned")
    assert_true(is_equal_approx(projectile._impact_radius_runtime, 44.0), "impact radius should be assigned")
    assert_true(is_equal_approx(projectile._impact_damage_mult_runtime, 0.4), "impact damage multiplier should be assigned")

    projectile.free()


func test_projectile_impact_splash_damages_nearby_enemy() -> void:
    var projectile_scene := load("res://scenes/game/projectile.tscn") as PackedScene
    var enemy_scene := load("res://scenes/game/enemy.tscn") as PackedScene
    assert_not_null(projectile_scene, "projectile scene should load")
    assert_not_null(enemy_scene, "enemy scene should load")
    if projectile_scene == null or enemy_scene == null:
        return

    var projectile := projectile_scene.instantiate()
    var primary := enemy_scene.instantiate() as CharacterBody2D
    var secondary := enemy_scene.instantiate() as CharacterBody2D
    assert_not_null(projectile, "projectile should instantiate")
    assert_not_null(primary, "primary enemy should instantiate")
    assert_not_null(secondary, "secondary enemy should instantiate")
    if projectile == null or primary == null or secondary == null:
        return

    add_child_autofree(projectile)
    add_child_autofree(primary)
    add_child_autofree(secondary)
    primary.global_position = Vector2(200, 200)
    secondary.global_position = Vector2(232, 200)
    await get_tree().process_frame

    projectile.setup(
        null,
        Vector2.RIGHT,
        12.0,
        0,
        0.0,
        0.0,
        1.5,
        false,
        135.0,
        2,
        "radiant_hammer",
        58.0,
        0.45
    )

    var secondary_health: Node = secondary.get_node_or_null("HealthComponent")
    assert_not_null(secondary_health, "secondary enemy should have HealthComponent")
    if secondary_health == null:
        return

    var before_hp: float = float(secondary_health.get("current_hp"))
    projectile.call("_apply_impact_splash", primary, primary.global_position, 20.0)
    await get_tree().process_frame

    assert_lt(float(secondary_health.get("current_hp")), before_hp, "impact splash should damage nearby non-primary enemy")


func test_projectile_ground_zone_config_for_supernova() -> void:
    var scene := load("res://scenes/game/projectile.tscn") as PackedScene
    assert_not_null(scene, "projectile scene should load")
    if scene == null:
        return

    var projectile := scene.instantiate()
    add_child_autofree(projectile)
    projectile.setup(
        null,
        Vector2.RIGHT,
        12.0,
        0,
        0.0,
        0.0,
        1.5,
        false,
        135.0,
        2,
        "solar_supernova",
        66.0,
        0.48
    )

    var config: Dictionary = projectile.call("_get_ground_zone_config", 30.0)
    assert_gt(float(config.get("radius", 0.0)), 0.0, "solar supernova should create ground zone config")
    assert_gt(float(config.get("damage", 0.0)), 1.0, "ground zone config should carry tick damage")
