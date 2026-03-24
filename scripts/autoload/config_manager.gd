extends Node

const CONFIG_PATHS: Dictionary = {
    "characters": "res://data/balance/characters.json",
    "map_generation": "res://data/balance/map_generation.json",
    "xp_curve": "res://data/balance/xp_curve.json",
    "enemy_scaling": "res://data/balance/enemy_scaling.json",
    "drop_tables": "res://data/balance/drop_tables.json",
    "evolutions": "res://data/balance/evolutions.json",
    "shop_items": "res://data/balance/shop_items.json",
    "environment_config": "res://data/balance/environment_config.json",
    "boss_phases": "res://data/balance/boss_phases.json",
    "narrative_index": "res://data/balance/narrative_index.json",
    "narrative_content": "res://data/balance/narrative_content.json",
    "achievements": "res://data/balance/achievements.json",
    "meta_upgrades": "res://data/balance/meta_upgrades.json"
}

var _configs: Dictionary = {}


func reload_all_configs() -> void:
    _configs.clear()
    # 启动时一次性装入常用配置，运行期统一从缓存读取，减少重复文件 IO。
    for key: String in CONFIG_PATHS.keys():
        _configs[key] = _load_json(CONFIG_PATHS[key])


func get_config(key: String, default_value: Variant = {}) -> Variant:
    return _configs.get(key, default_value)


func _load_json(path: String) -> Variant:
    if not FileAccess.file_exists(path):
        push_warning("Config file missing: %s" % path)
        return {}

    var raw_text: String = FileAccess.get_file_as_string(path)
    var parsed: Variant = JSON.parse_string(raw_text)
    if parsed == null:
        push_warning("Failed to parse JSON: %s" % path)
        return {}
    return parsed
