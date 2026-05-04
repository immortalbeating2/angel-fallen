extends GutTest

const PICKUP_SCENE_PATH: String = "res://scenes/game/pickup.tscn"


func test_pickup_vacuum_moves_toward_target_outside_magnet_range() -> void:
    GameManager.set_state(GameManager.GameState.PLAYING)
    var scene: PackedScene = load(PICKUP_SCENE_PATH)
    var pickup: Node2D = scene.instantiate() as Node2D
    add_child_autofree(pickup)
    pickup.global_position = Vector2(0, 0)
    pickup.set("magnet_range", 1.0)

    var target := Node2D.new()
    add_child_autofree(target)
    target.global_position = Vector2(300, 0)

    pickup.activate_vacuum(target, 4.0)
    pickup._process(0.25)

    assert_gt(pickup.global_position.x, 1.0, "全屏吸附应忽略普通 magnet_range 并向目标移动")
