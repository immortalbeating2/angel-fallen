extends Node

const PRESSURE_SEGMENT_SECONDS: float = 30.0
const SPECIAL_WAVE_SECONDS: float = 60.0
const ELITE_WAVE_SECONDS: float = 300.0

var elapsed_seconds: float = 0.0
var _last_profile: Dictionary = {}


func reset() -> void:
    elapsed_seconds = 0.0
    _last_profile = get_current_wave_profile(0.0)


func advance(delta: float) -> Dictionary:
    elapsed_seconds = maxf(0.0, elapsed_seconds + maxf(0.0, delta))
    _last_profile = get_current_wave_profile(elapsed_seconds)
    return _last_profile.duplicate(true)


func get_last_profile() -> Dictionary:
    if _last_profile.is_empty():
        return get_current_wave_profile(elapsed_seconds)
    return _last_profile.duplicate(true)


func get_current_wave_profile(elapsed: float = -1.0) -> Dictionary:
    var seconds: float = elapsed_seconds if elapsed < 0.0 else maxf(0.0, elapsed)
    var pressure_stage: int = int(floor(seconds / PRESSURE_SEGMENT_SECONDS))
    var wave_archetype: String = _resolve_wave_archetype(seconds)
    var enemy_tier: String = _resolve_enemy_tier(seconds, pressure_stage, wave_archetype)
    var archetype_weights: Dictionary = _build_archetype_weights(wave_archetype, pressure_stage)

    var spawn_mult: float = clampf(1.0 + float(pressure_stage) * 0.075, 1.0, 1.75)
    var hp_mult: float = clampf(1.0 + float(pressure_stage) * 0.052, 1.0, 1.85)
    var damage_mult: float = clampf(1.0 + float(pressure_stage) * 0.032, 1.0, 1.70)
    if wave_archetype == "special_wave":
        spawn_mult *= 1.08
    elif wave_archetype == "elite_wave":
        hp_mult *= 1.12
        damage_mult *= 1.08
    elif wave_archetype == "boss_pressure" or wave_archetype == "final_pressure":
        spawn_mult *= 1.12
        hp_mult *= 1.18
        damage_mult *= 1.12

    return {
        "elapsed_seconds": seconds,
        "pressure_stage": pressure_stage,
        "wave_archetype": wave_archetype,
        "enemy_tier": enemy_tier,
        "spawn_rate_mult": clampf(spawn_mult, 1.0, 1.85),
        "enemy_hp_mult": clampf(hp_mult, 1.0, 1.9),
        "enemy_damage_mult": clampf(damage_mult, 1.0, 1.8),
        "elite_wave_interval": _resolve_elite_interval(pressure_stage, wave_archetype),
        "max_alive_bonus": mini(14, pressure_stage),
        "reward_chance": clampf(0.08 + float(pressure_stage) * 0.008, 0.08, 0.22),
        "archetype_weights": archetype_weights,
    }


func _resolve_wave_archetype(seconds: float) -> String:
    if seconds >= 1800.0:
        return "final_pressure"
    if seconds >= 1200.0:
        return "boss_pressure"
    if seconds >= ELITE_WAVE_SECONDS and fmod(seconds, ELITE_WAVE_SECONDS) < PRESSURE_SEGMENT_SECONDS:
        return "elite_wave"
    if seconds >= SPECIAL_WAVE_SECONDS and fmod(seconds, SPECIAL_WAVE_SECONDS) < PRESSURE_SEGMENT_SECONDS:
        return "special_wave"
    return "swarm"


func _resolve_enemy_tier(seconds: float, pressure_stage: int, wave_archetype: String) -> String:
    if wave_archetype == "final_pressure":
        return "final"
    if wave_archetype == "boss_pressure":
        return "boss"
    if wave_archetype == "elite_wave":
        return "elite"
    if pressure_stage >= 10:
        return "heavy"
    if seconds >= SPECIAL_WAVE_SECONDS:
        return "mixed"
    return "normal"


func _resolve_elite_interval(pressure_stage: int, wave_archetype: String) -> int:
    if wave_archetype == "elite_wave":
        return 3
    if wave_archetype == "boss_pressure" or wave_archetype == "final_pressure":
        return 4
    return clampi(8 - int(floor(float(pressure_stage) / 3.0)), 4, 8)


func _build_archetype_weights(wave_archetype: String, pressure_stage: int) -> Dictionary:
    var weights: Dictionary = {
        "normal": 42.0,
        "fast": 24.0,
        "tank": 18.0,
        "ranged": 16.0,
    }
    if wave_archetype == "special_wave":
        weights["fast"] = 30.0
        weights["ranged"] = 22.0
        weights["normal"] = 34.0
    elif wave_archetype == "elite_wave":
        weights["tank"] = 28.0
        weights["ranged"] = 22.0
        weights["normal"] = 30.0
    elif wave_archetype == "boss_pressure" or wave_archetype == "final_pressure":
        weights["tank"] = 26.0
        weights["ranged"] = 26.0
        weights["fast"] = 26.0
        weights["normal"] = 22.0

    if pressure_stage >= 6:
        weights["normal"] = maxf(20.0, float(weights.get("normal", 0.0)) - 4.0)
        weights["tank"] = float(weights.get("tank", 0.0)) + 2.0
        weights["ranged"] = float(weights.get("ranged", 0.0)) + 2.0
    return weights
