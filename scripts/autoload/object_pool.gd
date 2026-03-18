extends Node

const DEFAULT_PREWARM: int = 6

var _scenes: Dictionary = {}
var _pool: Dictionary = {}


func register_scene(key: String, scene: PackedScene, prewarm_count: int = DEFAULT_PREWARM) -> void:
    if key == "" or scene == null:
        return

    _scenes[key] = scene
    if not _pool.has(key):
        _pool[key] = []

    var target_count: int = maxi(0, prewarm_count)
    var cached: Array = _pool[key]
    if cached.size() >= target_count:
        return

    for _i in range(target_count - cached.size()):
        var node: Node = scene.instantiate()
        _prepare_for_pool(node)
        add_child(node)
        cached.append(node)

    _pool[key] = cached


func acquire(key: String, parent: Node) -> Node:
    if parent == null:
        return null
    if not _pool.has(key):
        _pool[key] = []

    var cached: Array = _pool[key]
    var node: Node
    if cached.is_empty():
        var scene: PackedScene = _scenes.get(key)
        if scene == null:
            return null
        node = scene.instantiate()
    else:
        node = cached.pop_back()

    if node == null:
        return null

    if node.get_parent() != null:
        node.get_parent().remove_child(node)

    parent.add_child(node)
    _activate_node(node)
    _pool[key] = cached
    return node


func release(key: String, node: Node) -> void:
    if node == null:
        return
    if not _pool.has(key):
        _pool[key] = []

    if node.get_parent() != null:
        node.get_parent().remove_child(node)

    _prepare_for_pool(node)
    add_child(node)

    var cached: Array = _pool[key]
    cached.append(node)
    _pool[key] = cached


func _activate_node(node: Node) -> void:
    if node is CanvasItem:
        (node as CanvasItem).visible = true
    node.set_process(true)
    node.set_physics_process(true)
    if node.has_method("on_pool_acquired"):
        node.on_pool_acquired()


func _prepare_for_pool(node: Node) -> void:
    if node.has_method("on_pool_released"):
        node.on_pool_released()
    if node is CanvasItem:
        (node as CanvasItem).visible = false
    node.set_process(false)
    node.set_physics_process(false)
