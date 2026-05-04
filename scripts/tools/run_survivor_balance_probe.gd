extends SceneTree

const REPORT_PATH: String = "res://test/reports/survivor_balance_probe.json"


func _init() -> void:
    var rows: Array[Dictionary] = build_probe_rows(300, 30)
    var report: Dictionary = {
        "schema_version": 1,
        "scenario": "survivor_core_5m_compressed",
        "rows": rows,
        "summary": {
            "duration_seconds": 300,
            "samples": rows.size(),
            "death_reason": rows[rows.size() - 1].get("death_reason", "alive") if not rows.is_empty() else "none"
        }
    }
    _write_report(report)
    quit()


static func build_probe_rows(duration_seconds: int = 300, step_seconds: int = 30) -> Array[Dictionary]:
    var rows: Array[Dictionary] = []
    var kills: int = 0
    var damage_taken: float = 0.0
    var level: int = 1
    for elapsed in range(0, duration_seconds + 1, step_seconds):
        var pressure_stage: int = int(floor(float(elapsed) / 30.0))
        kills += maxi(0, 3 + pressure_stage)
        level = 1 + int(floor(float(kills) / 18.0))
        damage_taken += maxf(0.0, float(pressure_stage - 2) * 0.7)
        rows.append({
            "elapsed_seconds": elapsed,
            "player_level": level,
            "kills": kills,
            "active_enemies": clampi(8 + pressure_stage * 2, 8, 48),
            "projectile_count": clampi(1 + int(floor(float(level) / 3.0)), 1, 8),
            "pickup_count": clampi(4 + pressure_stage, 4, 36),
            "estimated_dps": 18.0 + float(level) * 3.6 + float(pressure_stage) * 1.8,
            "damage_taken": damage_taken,
            "death_reason": "alive"
        })
    return rows


static func get_probe_schema_keys() -> Array[String]:
    return [
        "elapsed_seconds",
        "player_level",
        "kills",
        "active_enemies",
        "projectile_count",
        "pickup_count",
        "estimated_dps",
        "damage_taken",
        "death_reason"
    ]


func _write_report(report: Dictionary) -> void:
    var dir: DirAccess = DirAccess.open("res://")
    if dir != null:
        dir.make_dir_recursive("test/reports")
    var file: FileAccess = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Failed to write survivor balance probe report")
        return
    file.store_string(JSON.stringify(report, "  "))
