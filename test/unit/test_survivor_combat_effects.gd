extends GutTest

const GAME_WORLD_SCENE_PATH: String = "res://scenes/game/game_world.tscn"


func test_auto_weapon_enables_orbit_and_aura_layers_by_style() -> void:
	var scene := load(GAME_WORLD_SCENE_PATH) as PackedScene
	assert_not_null(scene, "game world scene should load")
	if scene == null:
		return

	var world: Node = scene.instantiate()
	add_child_autofree(world)
	await get_tree().process_frame

	var player: Node = world.get_node_or_null("Player")
	assert_not_null(player, "player should exist")
	if player == null:
		return

	var weapon: Node = player.get_node_or_null("AutoWeapon")
	assert_not_null(weapon, "AutoWeapon should exist")
	if weapon == null:
		return

	weapon.set("projectile_style", "astral_disc")
	weapon.call("_refresh_survivor_effect_layers")
	assert_not_null(player.get_node_or_null("OrbitWeapon"), "astral style should enable orbit weapon layer")

	weapon.set("projectile_style", "holy_judgment")
	weapon.call("_refresh_survivor_effect_layers")
	assert_not_null(player.get_node_or_null("AuraWeapon"), "holy judgment should enable aura weapon layer")


func test_ground_hazard_zone_ticks_enemy_damage() -> void:
	var enemy_scene := load("res://scenes/game/enemy.tscn") as PackedScene
	var zone_script := load("res://scripts/game/ground_hazard_zone.gd") as Script
	assert_not_null(enemy_scene, "enemy scene should load")
	assert_not_null(zone_script, "ground hazard script should load")
	if enemy_scene == null or zone_script == null:
		return

	var enemy := enemy_scene.instantiate() as CharacterBody2D
	var zone := zone_script.new() as Node2D
	assert_not_null(zone, "ground hazard zone should instantiate from script")
	if zone == null:
		return
	add_child_autofree(enemy)
	add_child_autofree(zone)
	enemy.global_position = Vector2(180, 180)
	zone.global_position = Vector2(180, 180)
	zone.setup({
		"radius": 64.0,
		"duration": 1.0,
		"tick_interval": 0.2,
		"damage": 6.0,
		"damage_type": int(DamageSystem.DamageType.PHYSICAL),
		"style_id": "solar_supernova"
	})
	await get_tree().process_frame

	var health: Node = enemy.get_node_or_null("HealthComponent")
	assert_not_null(health, "enemy should expose HealthComponent")
	if health == null:
		return
	var before_hp: float = float(health.get("current_hp"))

	zone.call("_apply_zone_tick")
	await get_tree().process_frame

	assert_lt(float(health.get("current_hp")), before_hp, "ground zone should damage enemies inside radius")


func test_audio_manager_gameplay_cue_snapshots() -> void:
	if AudioManager == null:
		pending("AudioManager autoload not available")
		return
	if not AudioManager.has_method("clear_gameplay_cue_snapshot"):
		pending("AudioManager gameplay cue helpers are unavailable")
		return

	AudioManager.clear_gameplay_cue_snapshot()
	AudioManager.play_pickup_cue("gold", 3)
	var pickup_cue: Dictionary = AudioManager.get_last_gameplay_cue_snapshot()
	assert_eq(str(pickup_cue.get("cue", "")), "pickup_gold", "pickup cue should record pickup type")
	assert_eq(int(pickup_cue.get("amount", 0)), 3, "pickup cue should record pickup amount")

	AudioManager.clear_gameplay_cue_snapshot()
	AudioManager.play_enemy_kill_cue("enemy_shadowling")
	var kill_cue: Dictionary = AudioManager.get_last_gameplay_cue_snapshot()
	assert_eq(str(kill_cue.get("cue", "")), "kill_enemy", "enemy kill cue should record normal kill")

	AudioManager.clear_gameplay_cue_snapshot()
	AudioManager.play_weapon_impact_cue("solar_supernova", true)
	var impact_cue: Dictionary = AudioManager.get_last_gameplay_cue_snapshot()
	assert_eq(str(impact_cue.get("cue", "")), "impact_crit", "critical impact cue should be recorded")
	assert_true(bool(impact_cue.get("is_crit", false)), "impact cue should record crit flag")
