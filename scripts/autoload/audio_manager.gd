extends Node

const SFX_BUS: StringName = &"SFX"
const BGM_BUS: StringName = &"BGM"
const AMBIENCE_BUS: StringName = &"Ambience"

var _bgm_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer


func _ready() -> void:
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = BGM_BUS
    add_child(_bgm_player)

    _ambience_player = AudioStreamPlayer.new()
    _ambience_player.bus = AMBIENCE_BUS
    add_child(_ambience_player)


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
