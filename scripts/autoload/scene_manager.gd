extends Node

const MAIN_MENU_SCENE: String = "res://scenes/main_menu/main_menu.tscn"
const GAME_WORLD_SCENE: String = "res://scenes/game/game_world.tscn"


func transition_to(scene_path: String) -> void:
    if not ResourceLoader.exists(scene_path):
        push_warning("Scene not found: %s" % scene_path)
        return

    var result: Error = get_tree().change_scene_to_file(scene_path)
    if result != OK:
        push_warning("Failed to switch scene: %s" % scene_path)


func go_to_main_menu() -> void:
    transition_to(MAIN_MENU_SCENE)


func go_to_game_world() -> void:
    transition_to(GAME_WORLD_SCENE)
