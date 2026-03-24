extends SceneTree

const CONFIG_PATH: String = "res://data/balance/quality_baseline_targets.json"
const OUTPUT_JSON_PATH: String = "user://quality_baseline_latest.json"
const OUTPUT_MD_PATH: String = "user://quality_baseline_latest.md"


func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var config: Dictionary = _load_json_dict(CONFIG_PATH)
    if config.is_empty():
        push_error("quality baseline config load failed: %s" % CONFIG_PATH)
        quit(1)
        return

    var report: Dictionary = await _build_report(config)
    var save_ok: bool = _save_report(report)
    _print_report_summary(report)
    quit(0 if save_ok else 1)


func _build_report(config: Dictionary) -> Dictionary:
    var scenarios_cfg: Dictionary = config.get("scenarios", {})
    var scenario_reports: Array[Dictionary] = []

    for scenario_id_var: Variant in scenarios_cfg.keys():
        var scenario_id: String = str(scenario_id_var)
        var row_var: Variant = scenarios_cfg.get(scenario_id, {})
        if not (row_var is Dictionary):
            scenario_reports.append({
                "id": scenario_id,
                "error": "scenario config must be object"
            })
            continue

        var row: Dictionary = row_var
        var sampled: Dictionary = await _sample_scenario(scenario_id, row)
        scenario_reports.append(sampled)

    var report: Dictionary = {
        "generated_at": Time.get_datetime_string_from_system(true),
        "engine": Engine.get_version_info().get("string", "unknown"),
        "platform": OS.get_name(),
        "scenarios": scenario_reports,
        "targets": config.get("targets", {}),
        "compatibility_snapshot": _build_compatibility_snapshot(config.get("compatibility_matrix", {})),
    }
    report["alerts"] = _evaluate_alerts(report)
    return report


func _sample_scenario(scenario_id: String, row: Dictionary) -> Dictionary:
    var scene_path: String = str(row.get("scene", ""))
    var warmup_frames: int = int(row.get("warmup_frames", 20))
    var sample_frames: int = int(row.get("sample_frames", 180))
    var setup_mode: String = str(row.get("setup", "none"))

    var packed: PackedScene = load(scene_path)
    if packed == null:
        return {
            "id": scenario_id,
            "scene": scene_path,
            "error": "scene load failed"
        }

    var node: Node = packed.instantiate()
    root.add_child(node)
    await process_frame

    # 先注入压力场景，再预热若干帧，尽量避开刚进场时的瞬时波动。
    _setup_scenario(node, setup_mode)

    for _i: int in range(maxi(0, warmup_frames)):
        await process_frame

    var frame_times_ms: Array[float] = []
    var memory_samples_mb: Array[float] = []
    var enemy_peak: int = 0
    var projectile_peak: int = 0
    var pickup_peak: int = 0

    var last_tick_us: int = Time.get_ticks_usec()
    # 这里按帧采样性能和实体峰值，用于生成质量基线而不是精确 profiler 数据。
    for _f: int in range(maxi(1, sample_frames)):
        await process_frame
        var now_us: int = Time.get_ticks_usec()
        frame_times_ms.append(float(now_us - last_tick_us) / 1000.0)
        last_tick_us = now_us

        var enemy_count: int = get_nodes_in_group("enemies").size()
        var projectile_count: int = get_nodes_in_group("projectiles").size()
        var pickup_count: int = get_nodes_in_group("pickups").size()
        enemy_peak = maxi(enemy_peak, enemy_count)
        projectile_peak = maxi(projectile_peak, projectile_count)
        pickup_peak = maxi(pickup_peak, pickup_count)
        memory_samples_mb.append(float(OS.get_static_memory_usage()) / 1048576.0)

    await _teardown_scenario(node)

    var avg_ms: float = _mean(frame_times_ms)
    var p95_ms: float = _percentile(frame_times_ms, 0.95)
    var max_ms: float = _max_value(frame_times_ms)
    var peak_memory_mb: float = _max_value(memory_samples_mb)

    return {
        "id": scenario_id,
        "scene": scene_path,
        "setup": setup_mode,
        "sample_frames": sample_frames,
        "avg_frame_ms": avg_ms,
        "p95_frame_ms": p95_ms,
        "max_frame_ms": max_ms,
        "estimated_fps": 1000.0 / maxf(0.001, avg_ms),
        "peak_memory_mb": peak_memory_mb,
        "enemy_peak": enemy_peak,
        "projectile_peak": projectile_peak,
        "pickup_peak": pickup_peak,
    }


func _setup_scenario(node: Node, setup_mode: String) -> void:
    match setup_mode:
        "elite_pressure_medium":
            _configure_elite_pressure(node, 8, 24, 1.0, 1.0, 1.0)
        "elite_pressure_high":
            _configure_elite_pressure(node, 11, 30, 1.2, 1.1, 1.12)
        "elite_pressure_extreme":
            _configure_elite_pressure(node, 14, 38, 1.35, 1.2, 1.2)
        "boss_pressure_endurance":
            _configure_boss_pressure(node, 13, 40, 1.4, 1.28, 1.3)
        _:
            return


func _configure_elite_pressure(
    node: Node,
    room_index: int,
    max_alive: int,
    spawn_rate_mult: float,
    enemy_hp_mult: float,
    enemy_damage_mult: float
) -> void:
    # 复用实际房间入口来施加压力参数，避免基线脚本和正式玩法分叉。
    var spawner: Node = node.get_node_or_null("EnemySpawner")
    if spawner != null:
        if spawner.get("max_alive") != null:
            spawner.max_alive = max_alive
        if spawner.has_method("set_runtime_modifiers"):
            spawner.call("set_runtime_modifiers", spawn_rate_mult, enemy_hp_mult, enemy_damage_mult)

    if node.has_method("_enter_elite_room"):
        node.set("_room_index", room_index)
        node.set("_current_room_type", "elite")
        node.call("_enter_elite_room")


func _configure_boss_pressure(
    node: Node,
    room_index: int,
    max_alive: int,
    spawn_rate_mult: float,
    enemy_hp_mult: float,
    enemy_damage_mult: float
) -> void:
    var spawner: Node = node.get_node_or_null("EnemySpawner")
    if spawner != null:
        if spawner.get("max_alive") != null:
            spawner.max_alive = max_alive
        if spawner.has_method("set_runtime_modifiers"):
            spawner.call("set_runtime_modifiers", spawn_rate_mult, enemy_hp_mult, enemy_damage_mult)

    if node.has_method("_enter_boss_room"):
        node.set("_room_index", room_index)
        node.set("_current_room_type", "boss")
        node.call("_enter_boss_room")


func _teardown_scenario(node: Node) -> void:
    var spawner: Node = node.get_node_or_null("EnemySpawner")
    if spawner != null and spawner.has_method("stop_room_combat"):
        spawner.call("stop_room_combat")
    if spawner != null and spawner.has_method("set_runtime_modifiers"):
        spawner.call("set_runtime_modifiers", 1.0, 1.0, 1.0)

    node.queue_free()
    await process_frame
    await process_frame


func _build_compatibility_snapshot(cfg_var: Variant) -> Dictionary:
    var cfg: Dictionary = {}
    if cfg_var is Dictionary:
        cfg = cfg_var

    var required_actions: Array[String] = []
    var required_var: Variant = cfg.get("required_actions", [])
    if required_var is Array:
        for action_var: Variant in required_var:
            required_actions.append(str(action_var))

    var action_status: Dictionary = {}
    for action: String in required_actions:
        action_status[action] = {
            "exists": InputMap.has_action(action),
            "events": InputMap.action_get_events(action).size() if InputMap.has_action(action) else 0
        }

    return {
        "viewport_width": int(ProjectSettings.get_setting("display/window/size/viewport_width", 1280)),
        "viewport_height": int(ProjectSettings.get_setting("display/window/size/viewport_height", 720)),
        "window_stretch_mode": str(ProjectSettings.get_setting("display/window/stretch/mode", "canvas_items")),
        "window_stretch_aspect": str(ProjectSettings.get_setting("display/window/stretch/aspect", "keep")),
        "target_platforms": cfg.get("platforms", []),
        "target_resolutions": cfg.get("resolutions", []),
        "required_actions": action_status,
    }


func _evaluate_alerts(report: Dictionary) -> Dictionary:
    var summary: Dictionary = {
        "total": 0,
        "critical": 0,
        "warning": 0,
        "info": 0,
        "items": []
    }
    var targets: Dictionary = report.get("targets", {})
    var frame_targets: Dictionary = targets.get("frame_time_ms", {})
    var memory_targets: Dictionary = targets.get("memory_mb", {})
    var pressure_targets: Dictionary = targets.get("node_pressure", {})
    var grading_targets: Dictionary = targets.get("alert_grading", {})
    var enemy_peak_warning: int = int(pressure_targets.get("enemy_peak_warning", 500))
    var projectile_peak_warning: int = int(pressure_targets.get("projectile_peak_warning", 220))
    var pickup_peak_warning: int = int(pressure_targets.get("pickup_peak_warning", 150))
    var frame_warning_ratio: float = maxf(1.0, float(grading_targets.get("frame_time_ratio_warning", 1.0)))
    var frame_critical_ratio: float = maxf(frame_warning_ratio, float(grading_targets.get("frame_time_ratio_critical", 1.2)))
    var memory_warning_ratio: float = maxf(1.0, float(grading_targets.get("memory_ratio_warning", 1.0)))
    var memory_critical_ratio: float = maxf(memory_warning_ratio, float(grading_targets.get("memory_ratio_critical", 1.15)))
    var pressure_warning_ratio: float = maxf(1.0, float(grading_targets.get("node_pressure_ratio_warning", 1.0)))
    var pressure_critical_ratio: float = maxf(pressure_warning_ratio, float(grading_targets.get("node_pressure_ratio_critical", 1.25)))

    var rows_var: Variant = report.get("scenarios", [])
    if not (rows_var is Array):
        return summary

    var rows: Array = rows_var
    for row_var: Variant in rows:
        if not (row_var is Dictionary):
            continue
        var row: Dictionary = row_var
        var scenario_id: String = str(row.get("id", "unknown"))
        if row.get("error") != null:
            _push_alert(summary, "critical", "%s: %s" % [scenario_id, str(row.get("error"))])
            continue

        var frame_target_var: Variant = frame_targets.get(scenario_id, {})
        if frame_target_var is Dictionary:
            var frame_target: Dictionary = frame_target_var
            var avg_max: float = float(frame_target.get("avg_max", 999.0))
            var p95_max: float = float(frame_target.get("p95_max", 999.0))
            var avg_ms: float = float(row.get("avg_frame_ms", 0.0))
            var p95_ms: float = float(row.get("p95_frame_ms", 0.0))
            _evaluate_ratio_alert(summary, scenario_id, "avg_frame_ms", avg_ms, avg_max, frame_warning_ratio, frame_critical_ratio)
            _evaluate_ratio_alert(summary, scenario_id, "p95_frame_ms", p95_ms, p95_max, frame_warning_ratio, frame_critical_ratio)

        var memory_target_var: Variant = memory_targets.get(scenario_id, {})
        if memory_target_var is Dictionary:
            var memory_target: Dictionary = memory_target_var
            var peak_max: float = float(memory_target.get("peak_max", 99999.0))
            var peak_memory: float = float(row.get("peak_memory_mb", 0.0))
            _evaluate_ratio_alert(summary, scenario_id, "peak_memory_mb", peak_memory, peak_max, memory_warning_ratio, memory_critical_ratio)

        var enemy_peak: int = int(row.get("enemy_peak", 0))
        var projectile_peak: int = int(row.get("projectile_peak", 0))
        var pickup_peak: int = int(row.get("pickup_peak", 0))
        _evaluate_ratio_alert(summary, scenario_id, "enemy_peak", float(enemy_peak), float(enemy_peak_warning), pressure_warning_ratio, pressure_critical_ratio)
        _evaluate_ratio_alert(summary, scenario_id, "projectile_peak", float(projectile_peak), float(projectile_peak_warning), pressure_warning_ratio, pressure_critical_ratio)
        _evaluate_ratio_alert(summary, scenario_id, "pickup_peak", float(pickup_peak), float(pickup_peak_warning), pressure_warning_ratio, pressure_critical_ratio)

    return summary


func _evaluate_ratio_alert(
    summary: Dictionary,
    scenario_id: String,
    metric: String,
    actual: float,
    threshold: float,
    warning_ratio: float,
    critical_ratio: float
) -> void:
    if threshold <= 0.0:
        return

    var ratio: float = actual / threshold
    if ratio >= critical_ratio:
        _push_alert(summary, "critical", "%s %s %.2f > critical %.2f (base %.2f)" % [scenario_id, metric, actual, threshold * critical_ratio, threshold])
    elif ratio >= warning_ratio:
        _push_alert(summary, "warning", "%s %s %.2f > warning %.2f (base %.2f)" % [scenario_id, metric, actual, threshold * warning_ratio, threshold])


func _push_alert(summary: Dictionary, severity: String, message: String) -> void:
    var items_var: Variant = summary.get("items", [])
    var items: Array = items_var if items_var is Array else []
    items.append({
        "severity": severity,
        "message": message
    })
    summary["items"] = items
    summary["total"] = int(summary.get("total", 0)) + 1
    summary[severity] = int(summary.get(severity, 0)) + 1


func _save_report(report: Dictionary) -> bool:
    var json_file: FileAccess = FileAccess.open(OUTPUT_JSON_PATH, FileAccess.WRITE)
    if json_file == null:
        push_error("Cannot write baseline json: %s" % OUTPUT_JSON_PATH)
        return false
    json_file.store_string(JSON.stringify(report, "\t"))
    json_file.close()

    var md_lines: Array[String] = []
    md_lines.append("# Quality Baseline Snapshot")
    md_lines.append("")
    md_lines.append("- generated_at: %s" % str(report.get("generated_at", "")))
    md_lines.append("- engine: %s" % str(report.get("engine", "")))
    md_lines.append("- platform: %s" % str(report.get("platform", "")))
    md_lines.append("")
    md_lines.append("## Scenario Metrics")
    md_lines.append("")
    md_lines.append("| scenario | avg frame ms | p95 frame ms | peak memory MB | enemy peak | projectile peak | pickup peak |")
    md_lines.append("|---|---:|---:|---:|---:|---:|---:|")

    var rows_var: Variant = report.get("scenarios", [])
    if rows_var is Array:
        var rows: Array = rows_var
        for row_var: Variant in rows:
            if not (row_var is Dictionary):
                continue
            var row: Dictionary = row_var
            md_lines.append("| %s | %.2f | %.2f | %.2f | %d | %d | %d |" % [
                str(row.get("id", "unknown")),
                float(row.get("avg_frame_ms", 0.0)),
                float(row.get("p95_frame_ms", 0.0)),
                float(row.get("peak_memory_mb", 0.0)),
                int(row.get("enemy_peak", 0)),
                int(row.get("projectile_peak", 0)),
                int(row.get("pickup_peak", 0))
            ])

    var alerts_var: Variant = report.get("alerts", {})
    if alerts_var is Dictionary:
        var alerts_summary: Dictionary = alerts_var
        var alert_items_var: Variant = alerts_summary.get("items", [])
        var alert_items: Array = alert_items_var if alert_items_var is Array else []
        md_lines.append("")
        md_lines.append("## Alerts")
        md_lines.append("")
        md_lines.append("- total: %d" % int(alerts_summary.get("total", 0)))
        md_lines.append("- critical: %d" % int(alerts_summary.get("critical", 0)))
        md_lines.append("- warning: %d" % int(alerts_summary.get("warning", 0)))
        md_lines.append("- info: %d" % int(alerts_summary.get("info", 0)))
        md_lines.append("")
        if alert_items.is_empty():
            md_lines.append("- none")
        else:
            for alert_var: Variant in alert_items:
                if not (alert_var is Dictionary):
                    md_lines.append("- %s" % str(alert_var))
                    continue
                var alert: Dictionary = alert_var
                md_lines.append("- [%s] %s" % [str(alert.get("severity", "info")).to_upper(), str(alert.get("message", ""))])

    var markdown_file: FileAccess = FileAccess.open(OUTPUT_MD_PATH, FileAccess.WRITE)
    if markdown_file == null:
        push_error("Cannot write baseline markdown: %s" % OUTPUT_MD_PATH)
        return false
    markdown_file.store_string("\n".join(md_lines) + "\n")
    markdown_file.close()
    return true


func _print_report_summary(report: Dictionary) -> void:
    print("Quality baseline snapshot generated:")
    print("  json: %s" % ProjectSettings.globalize_path(OUTPUT_JSON_PATH))
    print("  md:   %s" % ProjectSettings.globalize_path(OUTPUT_MD_PATH))
    var alerts_var: Variant = report.get("alerts", {})
    if alerts_var is Dictionary:
        var alerts_summary: Dictionary = alerts_var
        print("  alerts: %d (critical %d / warning %d / info %d)" % [
            int(alerts_summary.get("total", 0)),
            int(alerts_summary.get("critical", 0)),
            int(alerts_summary.get("warning", 0)),
            int(alerts_summary.get("info", 0))
        ])


func _load_json_dict(path: String) -> Dictionary:
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        return {}
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        return parsed
    return {}


func _mean(values: Array[float]) -> float:
    if values.is_empty():
        return 0.0
    var total: float = 0.0
    for value: float in values:
        total += value
    return total / float(values.size())


func _max_value(values: Array[float]) -> float:
    if values.is_empty():
        return 0.0
    var current_max: float = values[0]
    for value: float in values:
        current_max = maxf(current_max, value)
    return current_max


func _percentile(values: Array[float], ratio: float) -> float:
    if values.is_empty():
        return 0.0
    var sorted: Array[float] = values.duplicate()
    sorted.sort()
    var index: int = int(ceil(float(sorted.size()) * clampf(ratio, 0.0, 1.0))) - 1
    index = clampi(index, 0, sorted.size() - 1)
    return sorted[index]
