extends GutTest

const SHOP_CONFIG_PATH := "res://data/balance/shop_items.json"


func _load_shop_config() -> Dictionary:
	var file := FileAccess.open(SHOP_CONFIG_PATH, FileAccess.READ)
	assert_not_null(file, "shop_items.json should be readable")
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	assert_typeof(parsed, TYPE_DICTIONARY, "shop_items.json should parse as Dictionary")
	if parsed is Dictionary:
		return parsed
	return {}


func test_shop_config_contains_dynamic_economy_fields() -> void:
	var cfg := _load_shop_config()

	assert_true(cfg.has("restock_growth"), "shop config should include restock_growth")
	assert_true(cfg.has("restock_cost_cap"), "shop config should include restock_cost_cap")
	assert_true(cfg.has("catchup_discount"), "shop config should include catchup_discount")
	assert_true(cfg.has("ore_exchange"), "shop config should include ore_exchange")
	assert_true(cfg.has("chapter_overrides"), "shop config should include chapter_overrides")
	assert_true(cfg.has("category_weights"), "shop config should include category_weights")

	assert_typeof(cfg.get("catchup_discount", {}), TYPE_DICTIONARY, "catchup_discount should be Dictionary")
	assert_typeof(cfg.get("ore_exchange", {}), TYPE_DICTIONARY, "ore_exchange should be Dictionary")
	assert_typeof(cfg.get("chapter_overrides", {}), TYPE_DICTIONARY, "chapter_overrides should be Dictionary")
	assert_typeof(cfg.get("category_weights", {}), TYPE_DICTIONARY, "category_weights should be Dictionary")


func test_shop_chapter_overrides_include_all_chapters_and_ranges() -> void:
	var cfg := _load_shop_config()
	var overrides: Dictionary = cfg.get("chapter_overrides", {})
	var chapters := ["chapter_1", "chapter_2", "chapter_3", "chapter_4"]

	for chapter_id in chapters:
		assert_true(overrides.has(chapter_id), "%s should exist in chapter_overrides" % chapter_id)
		var row: Dictionary = overrides.get(chapter_id, {})
		assert_typeof(row, TYPE_DICTIONARY, "%s override should be Dictionary" % chapter_id)

		assert_gte(float(row.get("price_mult", 0.0)), 0.6, "%s price_mult lower bound" % chapter_id)
		assert_lte(float(row.get("price_mult", 99.0)), 1.6, "%s price_mult upper bound" % chapter_id)
		assert_gte(float(row.get("restock_cost_mult", 0.0)), 0.6, "%s restock_cost_mult lower bound" % chapter_id)
		assert_lte(float(row.get("restock_cost_mult", 99.0)), 1.9, "%s restock_cost_mult upper bound" % chapter_id)
		assert_gte(float(row.get("target_gold_mult", 0.0)), 0.5, "%s target_gold_mult lower bound" % chapter_id)
		assert_lte(float(row.get("target_gold_mult", 99.0)), 2.0, "%s target_gold_mult upper bound" % chapter_id)

		var quality_mult: Dictionary = row.get("quality_weight_mult", {})
		assert_typeof(quality_mult, TYPE_DICTIONARY, "%s quality_weight_mult should be Dictionary" % chapter_id)
		for quality_key in ["common", "rare", "epic", "legendary"]:
			assert_true(quality_mult.has(quality_key), "%s quality_weight_mult should have %s" % [chapter_id, quality_key])
			assert_gte(float(quality_mult.get(quality_key, -1.0)), 0.0, "%s quality_weight_mult.%s should be >= 0" % [chapter_id, quality_key])

		var category_mult: Dictionary = row.get("category_weight_mult", {})
		assert_typeof(category_mult, TYPE_DICTIONARY, "%s category_weight_mult should be Dictionary" % chapter_id)
		for category_key in ["consumable", "passive", "weapon"]:
			assert_true(category_mult.has(category_key), "%s category_weight_mult should have %s" % [chapter_id, category_key])
			assert_gte(float(category_mult.get(category_key, -1.0)), 0.0, "%s category_weight_mult.%s should be >= 0" % [chapter_id, category_key])

		var pool_overrides: Dictionary = row.get("pool_overrides", {})
		assert_typeof(pool_overrides, TYPE_DICTIONARY, "%s pool_overrides should be Dictionary" % chapter_id)


func test_shop_chapter_progression_prices_scale_up_toward_chapter_4() -> void:
	var cfg := _load_shop_config()
	var overrides: Dictionary = cfg.get("chapter_overrides", {})
	var c1: Dictionary = overrides.get("chapter_1", {})
	var c4: Dictionary = overrides.get("chapter_4", {})

	var chapter_1_price_mult: float = float(c1.get("price_mult", 1.0))
	var chapter_4_price_mult: float = float(c4.get("price_mult", 1.0))
	assert_lte(chapter_1_price_mult, chapter_4_price_mult, "chapter_1 price_mult should not exceed chapter_4")

	var chapter_1_restock_mult: float = float(c1.get("restock_cost_mult", 1.0))
	var chapter_4_restock_mult: float = float(c4.get("restock_cost_mult", 1.0))
	assert_lte(chapter_1_restock_mult, chapter_4_restock_mult, "chapter_1 restock_cost_mult should not exceed chapter_4")

	var c1_quality: Dictionary = c1.get("quality_weight_mult", {})
	var c4_quality: Dictionary = c4.get("quality_weight_mult", {})
	assert_gte(float(c1_quality.get("common", 0.0)), float(c4_quality.get("common", 0.0)), "chapter_1 should favor common quality more than chapter_4")
	assert_lte(float(c1_quality.get("legendary", 0.0)), float(c4_quality.get("legendary", 99.0)), "chapter_1 legendary multiplier should not exceed chapter_4")


func test_shop_category_weights_have_valid_total() -> void:
	var cfg := _load_shop_config()
	var category_weights: Dictionary = cfg.get("category_weights", {})

	assert_typeof(category_weights, TYPE_DICTIONARY, "category_weights should be Dictionary")

	var total: float = 0.0
	for category_key in ["consumable", "passive", "weapon"]:
		assert_true(category_weights.has(category_key), "category_weights should include %s" % category_key)
		var weight: float = float(category_weights.get(category_key, -1.0))
		assert_gte(weight, 0.0, "category_weights.%s should be >= 0" % category_key)
		total += weight

	assert_gt(total, 0.0, "category_weights total should be > 0")


func test_shop_discount_parameters_are_in_expected_ranges() -> void:
	var cfg := _load_shop_config()
	var catchup: Dictionary = cfg.get("catchup_discount", {})

	var target_gold: float = float(catchup.get("target_gold_per_room", 0.0))
	var max_discount: float = float(catchup.get("max_discount", -1.0))
	var high_markup: float = float(catchup.get("high_gold_markup", -1.0))
	var high_threshold: float = float(catchup.get("high_gold_threshold_mult", 0.0))

	assert_gt(target_gold, 0.0, "target_gold_per_room should be > 0")
	assert_gte(max_discount, 0.0, "max_discount should be >= 0")
	assert_lte(max_discount, 0.75, "max_discount should be <= 0.75")
	assert_gte(high_markup, 0.0, "high_gold_markup should be >= 0")
	assert_lte(high_markup, 0.45, "high_gold_markup should be <= 0.45")
	assert_gte(high_threshold, 1.0, "high_gold_threshold_mult should be >= 1.0")


func test_shop_route_style_overrides_have_expected_profiles_and_ranges() -> void:
	var cfg := _load_shop_config()
	var style_overrides: Dictionary = cfg.get("route_style_overrides", {})
	assert_typeof(style_overrides, TYPE_DICTIONARY, "route_style_overrides should be Dictionary")

	for style_id in ["neutral", "vanguard", "raider"]:
		assert_true(style_overrides.has(style_id), "route_style_overrides should include %s" % style_id)
		var row: Dictionary = style_overrides.get(style_id, {})
		assert_typeof(row, TYPE_DICTIONARY, "%s route override should be Dictionary" % style_id)

		assert_gte(float(row.get("price_mult", 0.0)), 0.7, "%s price_mult lower bound" % style_id)
		assert_lte(float(row.get("price_mult", 99.0)), 1.5, "%s price_mult upper bound" % style_id)
		assert_gte(float(row.get("target_gold_mult", 0.0)), 0.6, "%s target_gold_mult lower bound" % style_id)
		assert_lte(float(row.get("target_gold_mult", 99.0)), 1.8, "%s target_gold_mult upper bound" % style_id)
		assert_gte(float(row.get("max_discount_add", -9.0)), -0.35, "%s max_discount_add lower bound" % style_id)
		assert_lte(float(row.get("max_discount_add", 9.0)), 0.35, "%s max_discount_add upper bound" % style_id)
		assert_gte(float(row.get("high_markup_add", -9.0)), -0.25, "%s high_markup_add lower bound" % style_id)
		assert_lte(float(row.get("high_markup_add", 9.0)), 0.35, "%s high_markup_add upper bound" % style_id)
		assert_gte(int(row.get("exchange_gold_add", -999)), -15, "%s exchange_gold_add lower bound" % style_id)
		assert_lte(int(row.get("exchange_gold_add", 999)), 25, "%s exchange_gold_add upper bound" % style_id)

		var quality_mult: Dictionary = row.get("quality_weight_mult", {})
		assert_typeof(quality_mult, TYPE_DICTIONARY, "%s quality_weight_mult should be Dictionary" % style_id)
		for quality_key in ["common", "rare", "epic", "legendary"]:
			assert_true(quality_mult.has(quality_key), "%s quality_weight_mult should have %s" % [style_id, quality_key])
			assert_gte(float(quality_mult.get(quality_key, -1.0)), 0.0, "%s quality_weight_mult.%s should be >= 0" % [style_id, quality_key])

		var category_mult: Dictionary = row.get("category_weight_mult", {})
		assert_typeof(category_mult, TYPE_DICTIONARY, "%s category_weight_mult should be Dictionary" % style_id)
		for category_key in ["consumable", "passive", "weapon"]:
			assert_true(category_mult.has(category_key), "%s category_weight_mult should have %s" % [style_id, category_key])
			assert_gte(float(category_mult.get(category_key, -1.0)), 0.0, "%s category_weight_mult.%s should be >= 0" % [style_id, category_key])


func test_shop_ore_exchange_values_are_consistent() -> void:
	var cfg := _load_shop_config()
	var exchange: Dictionary = cfg.get("ore_exchange", {})

	assert_true(bool(exchange.get("enabled", false)), "ore exchange should be enabled for economy recovery")
	assert_gte(int(exchange.get("ore_per_trade", 0)), 1, "ore_per_trade should be >= 1")
	assert_gte(int(exchange.get("gold_per_trade", 0)), 1, "gold_per_trade should be >= 1")
	assert_gte(int(exchange.get("max_trades_per_shop", 0)), 1, "max_trades_per_shop should be >= 1")

	var bonus_chance: float = float(exchange.get("bonus_trade_chance", -1.0))
	assert_gte(bonus_chance, 0.0, "bonus_trade_chance should be >= 0")
	assert_lte(bonus_chance, 1.0, "bonus_trade_chance should be <= 1")
	assert_gte(int(exchange.get("bonus_gold", -1)), 0, "bonus_gold should be >= 0")


func test_restock_growth_progression_does_not_exceed_cap_in_sample_steps() -> void:
	var cfg := _load_shop_config()
	var base_cost: int = int(cfg.get("restock_cost", 0))
	var growth: float = float(cfg.get("restock_growth", 0.0))
	var cap: int = int(cfg.get("restock_cost_cap", 0))

	assert_gt(base_cost, 0, "restock_cost should be > 0")
	assert_gte(growth, 0.0, "restock_growth should be >= 0")
	assert_gte(cap, base_cost, "restock_cost_cap should be >= restock_cost")

	for i in range(0, 6):
		var growth_factor: float = pow(1.0 + growth, float(i))
		var simulated_cost: int = int(round(float(base_cost) * growth_factor))
		var clamped_cost: int = mini(cap, maxi(base_cost, simulated_cost))
		assert_lte(clamped_cost, cap, "sample restock cost should not exceed cap")
		assert_gte(clamped_cost, base_cost, "sample restock cost should not drop below base")
