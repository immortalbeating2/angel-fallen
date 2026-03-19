extends GutTest


func test_enemy_scaling_contains_enemy_type_weights() -> void:
    var raw_text: String = FileAccess.get_file_as_string("res://data/balance/enemy_scaling.json")
    assert_ne(raw_text, "", "enemy_scaling.json should be readable")

    var parsed: Variant = JSON.parse_string(raw_text)
    assert_true(parsed is Dictionary, "enemy_scaling.json should parse as Dictionary")
    if not (parsed is Dictionary):
        return

    var data: Dictionary = parsed
    var weights_var: Variant = data.get("enemy_type_weights", {})
    assert_true(weights_var is Dictionary, "enemy_type_weights should exist")
    if not (weights_var is Dictionary):
        return

    var weights: Dictionary = weights_var
    var expected_types: Array[String] = ["normal", "fast", "tank", "ranged"]
    var total: float = 0.0
    for enemy_type: String in expected_types:
        assert_true(weights.has(enemy_type), "Missing weight for %s" % enemy_type)
        var value: float = float(weights.get(enemy_type, 0.0))
        assert_gte(value, 0.0, "Weight must be >= 0 for %s" % enemy_type)
        total += value

    assert_gt(total, 0.0, "enemy_type_weights total should be > 0")


func test_enemy_scaling_contains_elite_wave_interval() -> void:
    var raw_text: String = FileAccess.get_file_as_string("res://data/balance/enemy_scaling.json")
    assert_ne(raw_text, "", "enemy_scaling.json should be readable")

    var parsed: Variant = JSON.parse_string(raw_text)
    assert_true(parsed is Dictionary, "enemy_scaling.json should parse as Dictionary")
    if not (parsed is Dictionary):
        return

    var data: Dictionary = parsed
    var elite_wave_interval: int = int(data.get("elite_wave_interval", 0))
    assert_gte(elite_wave_interval, 3, "elite_wave_interval should be >= 3")


func test_enemy_scaling_contains_chapter_archetype_map() -> void:
    var raw_text: String = FileAccess.get_file_as_string("res://data/balance/enemy_scaling.json")
    assert_ne(raw_text, "", "enemy_scaling.json should be readable")

    var parsed: Variant = JSON.parse_string(raw_text)
    assert_true(parsed is Dictionary, "enemy_scaling.json should parse as Dictionary")
    if not (parsed is Dictionary):
        return

    var data: Dictionary = parsed
    var chapter_map_var: Variant = data.get("chapter_archetype_map", {})
    assert_true(chapter_map_var is Dictionary, "chapter_archetype_map should exist")
    if not (chapter_map_var is Dictionary):
        return

    var chapter_map: Dictionary = chapter_map_var
    var expected_chapters: Array[String] = ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]
    var expected_types: Array[String] = ["normal", "fast", "tank", "ranged"]

    for chapter_id: String in expected_chapters:
        assert_true(chapter_map.has(chapter_id), "Missing archetype map for %s" % chapter_id)
        var chapter_row_var: Variant = chapter_map.get(chapter_id, {})
        assert_true(chapter_row_var is Dictionary, "%s map should be Dictionary" % chapter_id)
        if not (chapter_row_var is Dictionary):
            continue
        var chapter_row: Dictionary = chapter_row_var
        for enemy_type: String in expected_types:
            assert_true(chapter_row.has(enemy_type), "Missing %s in %s" % [enemy_type, chapter_id])
            var enemy_id: String = str(chapter_row.get(enemy_type, ""))
            assert_true(enemy_id.begins_with("enemy_"), "%s.%s should start with enemy_" % [chapter_id, enemy_type])
