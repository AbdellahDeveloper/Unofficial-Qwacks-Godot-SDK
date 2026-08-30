extends GutTest


func test_reward_parsing() -> void:
	assert_eq(ShopModels.REWARD_TYPE_CURRENCY, "currency", "reward type const")
	var reward := ShopModels.parse_shop_item_reward({"type": "currency", "code": "COINS", "amount": 25})
	assert_eq(reward["type"], "currency", "reward type")
	assert_eq(reward["code"], "COINS", "reward code")
	assert_eq(reward["amount"], 25, "reward amount")
	var bare := ShopModels.parse_shop_item_reward({})
	assert_eq(bare["type"], "currency", "reward default type")
	assert_eq(bare["amount"], 0, "reward default amount")
	var newkind := ShopModels.parse_shop_item_reward({"type": "badge", "code": "B1"})
	assert_eq(newkind["type"], "badge", "reward unknown kind survives")


func test_shop_item_gains_type_and_rewards() -> void:
	var item := ShopModels.parse_shop_item({"id": "i1", "type": "reward", "rewards": [{"code": "COINS", "amount": 25}]})
	assert_eq(item["type"], "reward", "item type")
	assert_eq(item["rewards"].size(), 1, "item rewards len")
	assert_eq(item["rewards"][0]["amount"], 25, "item reward amount")
	var plain := ShopModels.parse_shop_item({"id": "i2"})
	assert_eq(plain["rewards"], [], "item rewards default")
	assert_eq(plain["type"], "", "item type default")


func test_purchase_result_parsing() -> void:
	var purchase := ShopModels.parse_purchase_result({
		"purchase_id": "p1",
		"item_type": "reward",
		"inventory": {"id": "inv1", "player_id": "pl", "shop_item_id": "i1", "status": "owned", "created_at": "2026-01-01T00:00:00Z", "used_at": null},
		"granted": [{"code": "COINS", "amount": 25}],
		"wallet": {"id": "w1", "player_template_id": "pt", "player_id": "pl", "data": []},
	})
	assert_eq(purchase["purchase_id"], "p1", "purchase id")
	assert_eq(purchase["item_type"], "reward", "purchase item_type")
	assert_eq(purchase["inventory"]["id"], "inv1", "purchase inventory id")
	assert_eq(purchase["granted"].size(), 1, "purchase granted len")
	assert_eq(purchase["granted"][0]["amount"], 25, "purchase granted amount")
	assert_eq(purchase["wallet"]["id"], "w1", "purchase wallet id")
	var no_rewards := ShopModels.parse_purchase_result({"purchase_id": "p2", "inventory": {"id": "inv2"}})
	assert_eq(no_rewards["granted"], [], "purchase granted default")
	assert_eq(no_rewards["wallet"]["player_id"], "", "purchase wallet default data")


func test_consume_result_parsing() -> void:
	var consume := ShopModels.parse_consume_result({"inventory": {"id": "inv9"}, "granted": [{"amount": 5}], "wallet": {}})
	assert_eq(consume["inventory"]["id"], "inv9", "consume inventory id")
	assert_eq(consume["granted"].size(), 1, "consume granted len")
	assert_eq(consume["wallet"]["id"], "", "consume wallet default")