extends GutTest

const PROBE_SCRIPT: Script = preload("res://scripts/tools/run_survivor_balance_probe.gd")


func test_probe_rows_expose_stable_schema() -> void:
    var rows: Array = PROBE_SCRIPT.build_probe_rows(60, 30)
    assert_eq(rows.size(), 3, "60 秒 / 30 秒步长应产生 3 个采样点")

    var keys: Array = PROBE_SCRIPT.get_probe_schema_keys()
    for key in keys:
        assert_true((rows[0] as Dictionary).has(key), "probe row should include %s" % key)


func test_probe_pressure_increases_sample_values() -> void:
    var rows: Array = PROBE_SCRIPT.build_probe_rows(120, 30)
    var first: Dictionary = rows[0]
    var last: Dictionary = rows[rows.size() - 1]
    assert_gt(int(last.get("active_enemies", 0)), int(first.get("active_enemies", 0)), "长局压力应提升 active enemy 估算")
    assert_gt(float(last.get("estimated_dps", 0.0)), float(first.get("estimated_dps", 0.0)), "玩家成长估算 DPS 应随采样推进")
