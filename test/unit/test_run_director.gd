extends GutTest

const RUN_DIRECTOR_SCRIPT: Script = preload("res://scripts/systems/run_director.gd")


func test_wave_profile_milestones() -> void:
    var director: Node = RUN_DIRECTOR_SCRIPT.new()
    add_child_autofree(director)

    var start_profile: Dictionary = director.get_current_wave_profile(0.0)
    assert_eq(int(start_profile.get("pressure_stage", -1)), 0, "0 秒应处于首个压力段")
    assert_eq(str(start_profile.get("wave_archetype", "")), "swarm", "0 秒应是基础敌潮")

    var thirty_profile: Dictionary = director.get_current_wave_profile(30.0)
    assert_eq(int(thirty_profile.get("pressure_stage", -1)), 1, "30 秒应切换到第二个压力段")
    assert_gt(float(thirty_profile.get("spawn_rate_mult", 0.0)), float(start_profile.get("spawn_rate_mult", 0.0)), "30 秒刷怪压力应高于开局")

    var sixty_profile: Dictionary = director.get_current_wave_profile(60.0)
    assert_eq(str(sixty_profile.get("wave_archetype", "")), "special_wave", "60 秒应进入特殊 wave")
    assert_eq(str(sixty_profile.get("enemy_tier", "")), "mixed", "特殊 wave 应混合敌人类型")

    var elite_profile: Dictionary = director.get_current_wave_profile(300.0)
    assert_eq(str(elite_profile.get("wave_archetype", "")), "elite_wave", "5 分钟应进入精英 wave")
    assert_eq(str(elite_profile.get("enemy_tier", "")), "elite", "5 分钟 wave 应标记精英 tier")


func test_two_minutes_pressure_changes_at_least_four_times() -> void:
    var director: Node = RUN_DIRECTOR_SCRIPT.new()
    add_child_autofree(director)

    var seen: Dictionary = {}
    for seconds in [0.0, 30.0, 60.0, 90.0, 120.0]:
        var profile: Dictionary = director.get_current_wave_profile(seconds)
        var signature: String = "%s:%s" % [profile.get("pressure_stage", -1), profile.get("wave_archetype", "")]
        seen[signature] = true

    assert_gte(seen.size(), 4, "战斗房持续 120 秒时应至少出现 4 种压力 profile")


func test_enemy_spawner_accepts_director_profile_without_compounding() -> void:
    var spawner_script: Script = load("res://scripts/systems/enemy_spawner.gd")
    var spawner: Node = spawner_script.new()
    add_child_autofree(spawner)

    var director: Node = RUN_DIRECTOR_SCRIPT.new()
    add_child_autofree(director)
    var profile: Dictionary = director.get_current_wave_profile(300.0)
    spawner.apply_director_wave(profile)
    spawner.apply_director_wave(profile)

    var snapshot: Dictionary = spawner.get_director_wave_snapshot()
    assert_true(is_equal_approx(float(snapshot.get("director_spawn_rate_mult", 0.0)), float(profile.get("spawn_rate_mult", 0.0))), "重复应用同一 profile 不应继续叠乘")
    assert_eq(int(snapshot.get("director_max_alive_bonus", -1)), int(profile.get("max_alive_bonus", -2)), "刷怪器应保留 director 的 alive bonus")
