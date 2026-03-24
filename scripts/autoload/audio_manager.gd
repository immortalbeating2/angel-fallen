extends Node

const MASTER_BUS: StringName = &"Master"
const SFX_BUS: StringName = &"SFX"
const BGM_BUS: StringName = &"BGM"
const AMBIENCE_BUS: StringName = &"Ambience"

var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _test_tone_stream: AudioStreamWAV
var _tone_cache: Dictionary = {}
var _last_boss_phase_cue: Dictionary = {}
var _last_boss_support_cue: Dictionary = {}


func _ready() -> void:
    _ensure_bus(SFX_BUS)
    _ensure_bus(BGM_BUS)
    _ensure_bus(AMBIENCE_BUS)

    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = BGM_BUS
    add_child(_bgm_player)

    _ambience_player = AudioStreamPlayer.new()
    _ambience_player.bus = AMBIENCE_BUS
    add_child(_ambience_player)


func apply_runtime_settings(settings: Dictionary) -> void:
    set_bus_volume_ratio(MASTER_BUS, float(settings.get("master_volume", 1.0)))
    set_bus_volume_ratio(BGM_BUS, float(settings.get("bgm_volume", 1.0)))
    set_bus_volume_ratio(SFX_BUS, float(settings.get("sfx_volume", 1.0)))
    set_bus_volume_ratio(AMBIENCE_BUS, float(settings.get("ambience_volume", 1.0)))


func get_bus_volume_ratio(bus_name: StringName) -> float:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return 1.0
    var db_value: float = AudioServer.get_bus_volume_db(index)
    return clampf(db_to_linear(db_value), 0.0, 1.0)


func set_bus_volume_ratio(bus_name: StringName, ratio: float) -> void:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return

    var clamped: float = clampf(ratio, 0.0, 1.0)
    if clamped <= 0.0001:
        AudioServer.set_bus_volume_db(index, -80.0)
    else:
        AudioServer.set_bus_volume_db(index, linear_to_db(clamped))


func _ensure_bus(bus_name: StringName) -> void:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index >= 0:
        return

    AudioServer.add_bus()
    var new_index: int = AudioServer.get_bus_count() - 1
    AudioServer.set_bus_name(new_index, String(bus_name))


func play_bgm(stream: AudioStream) -> void:
    if stream == null:
        return
    _bgm_player.stream = stream
    _bgm_player.play()


func play_ambience(stream: AudioStream) -> void:
    if stream == null:
        return
    _ambience_player.stream = stream
    _ambience_player.play()


func play_sfx(stream: AudioStream) -> void:
    if stream == null:
        return
    var player: AudioStreamPlayer = AudioStreamPlayer.new()
    player.bus = SFX_BUS
    player.stream = stream
    player.finished.connect(player.queue_free)
    add_child(player)
    player.play()


func play_test_tone() -> void:
    if _test_tone_stream == null:
        _test_tone_stream = _build_test_tone_stream(0.16, 880.0)
    play_sfx(_test_tone_stream)


func play_boss_phase_cue(boss_id: String, phase_index: int, pulse_count: int = 2, tempo: float = 0.12) -> void:
    var family: String = "core"
    var base_frequency: float = 700.0
    if boss_id.find("frost") >= 0:
        family = "frost"
        base_frequency = 760.0
    elif boss_id.find("void") >= 0:
        family = "void"
        base_frequency = 430.0

    var frequency_step: float = 42.0
    if family == "void":
        frequency_step = 36.0

    var frequency: float = base_frequency + frequency_step * clampf(float(phase_index), 0.0, 6.0)
    var duration: float = clampf(tempo * (0.72 + 0.16 * float(maxi(1, pulse_count))), 0.05, 0.24)
    _last_boss_phase_cue = {
        "boss_id": boss_id,
        "phase_index": phase_index,
        "pulse_count": maxi(1, pulse_count),
        "tempo": tempo,
        "frequency": frequency,
        "duration": duration,
        "family": family,
    }
    play_sfx(_get_cached_tone(duration, frequency))


func play_boss_support_cue(boss_id: String, phase_index: int, spawned_count: int, includes_miniboss: bool = false) -> void:
    var base_frequency: float = 610.0
    if boss_id.find("frost") >= 0:
        base_frequency = 670.0
    elif boss_id.find("void") >= 0:
        base_frequency = 390.0

    var frequency: float = base_frequency + 26.0 * clampf(float(spawned_count), 0.0, 8.0) + 18.0 * clampf(float(phase_index), 0.0, 6.0)
    if includes_miniboss:
        frequency += 58.0
    var duration: float = 0.09
    if includes_miniboss:
        duration = 0.12
    _last_boss_support_cue = {
        "boss_id": boss_id,
        "phase_index": phase_index,
        "spawned_count": maxi(0, spawned_count),
        "includes_miniboss": includes_miniboss,
        "frequency": frequency,
        "duration": duration,
    }
    play_sfx(_get_cached_tone(duration, frequency))


func get_last_boss_phase_cue_snapshot() -> Dictionary:
    return _last_boss_phase_cue.duplicate(true)


func get_last_boss_support_cue_snapshot() -> Dictionary:
    return _last_boss_support_cue.duplicate(true)


func clear_boss_cue_snapshots() -> void:
    _last_boss_phase_cue.clear()
    _last_boss_support_cue.clear()


func get_tone_cache_size() -> int:
    return _tone_cache.size()


func get_bus_peak_ratio(bus_name: StringName) -> float:
    var index: int = AudioServer.get_bus_index(String(bus_name))
    if index < 0:
        return 0.0

    var left_db: float = AudioServer.get_bus_peak_volume_left_db(index, 0)
    var right_db: float = AudioServer.get_bus_peak_volume_right_db(index, 0)
    var left_lin: float = clampf(db_to_linear(left_db), 0.0, 1.0)
    var right_lin: float = clampf(db_to_linear(right_db), 0.0, 1.0)
    return maxf(left_lin, right_lin)


func _build_test_tone_stream(duration: float, frequency: float) -> AudioStreamWAV:
    var sample_rate: int = 44100
    var samples: int = maxi(1, int(sample_rate * maxf(duration, 0.05)))
    var bytes: PackedByteArray = PackedByteArray()
    bytes.resize(samples * 2)

    for i in range(samples):
        var t: float = float(i) / float(sample_rate)
        var fade: float = 1.0 - (float(i) / float(samples))
        var sample: float = sin(TAU * frequency * t) * 0.35 * fade
        var pcm: int = clampi(int(round(sample * 32767.0)), -32768, 32767)
        var idx: int = i * 2
        bytes[idx] = pcm & 0xFF
        bytes[idx + 1] = (pcm >> 8) & 0xFF

    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.mix_rate = sample_rate
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.stereo = false
    wav.data = bytes
    return wav


func _get_cached_tone(duration: float, frequency: float) -> AudioStreamWAV:
    var key: String = "%.3f_%.1f" % [duration, frequency]
    var cached: Variant = _tone_cache.get(key)
    if cached is AudioStreamWAV:
        return cached

    var tone: AudioStreamWAV = _build_test_tone_stream(duration, frequency)
    _tone_cache[key] = tone
    return tone
