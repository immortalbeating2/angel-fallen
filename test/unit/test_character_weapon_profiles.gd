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
        "mage_orb"
    )

    assert_eq(projectile._remaining_hits, 3, "remaining hits should be assigned")
    assert_eq(projectile._style_id, "mage_orb", "style id should be assigned")

    projectile.free()
