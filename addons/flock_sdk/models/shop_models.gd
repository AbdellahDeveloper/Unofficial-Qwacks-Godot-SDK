class_name ShopModels

# Reward kinds the server sends. Strings, not an enum: rewards are stored as typed entries so new kinds can ship
# without a schema migration, and an unknown value must not break deserialization.
const REWARD_TYPE_CURRENCY := "currency"

# One thing a reward-bearing shop item grants. Code is a currency code from the game version's currency config —
# the same namespace ShopItem.currency draws from.
static func parse_shop_item_reward(data: Dictionary) -> Dictionary:
	return {
		"type": data.get("type", REWARD_TYPE_CURRENCY),
		"code": data.get("code", ""),
		"amount": int(data.get("amount", 0)),
	}

static func parse_shop(data: Dictionary) -> Dictionary:
	var items := []
	var raw_items = data.get("shop_items", [])
	if raw_items is Array:
		for item in raw_items:
			if item is Dictionary:
				items.append(parse_shop_item(item))
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"status": data.get("status", ""),
		"game_id": data.get("game_id", ""),
		"game_version_id": data.get("game_version_id", ""),
		"data": data.get("data", {}),
		"shop_items": items,
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}

static func parse_shop_item(data: Dictionary) -> Dictionary:
	var rewards := []
	var raw_rewards = data.get("rewards", [])
	if raw_rewards is Array:
		for reward in raw_rewards:
			if reward is Dictionary:
				rewards.append(parse_shop_item_reward(reward))
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"status": data.get("status", ""),
		"shop_id": data.get("shop_id", ""),
		"patch_id": data.get("patch_id", ""),
		"price": data.get("price", 0),
		"currency": data.get("currency", ""),
		"type": data.get("type", ""),
		"rewards": rewards,
		"data": data.get("data", {}),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}


# Result of a shop purchase — the inventory row plus whatever the purchase granted immediately.
static func parse_purchase_result(data: Dictionary) -> Dictionary:
	var granted := []
	var raw_granted = data.get("granted", [])
	if raw_granted is Array:
		for reward in raw_granted:
			if reward is Dictionary:
				granted.append(parse_shop_item_reward(reward))
	return {
		"purchase_id": data.get("purchase_id", ""),
		"item_type": data.get("item_type", ""),
		"inventory": parse_inventory(data.get("inventory", {})),
		# Server omits this for non-reward items; default so callers never check before iterating.
		"granted": granted,
		# Wallet after the grant, when the purchase moved currency.
		"wallet": PlayerDataModels.parse_player_data(data.get("wallet", {})),
	}


# Result of consuming an inventory item — the updated row plus whatever consuming it granted.
static func parse_consume_result(data: Dictionary) -> Dictionary:
	var granted := []
	var raw_granted = data.get("granted", [])
	if raw_granted is Array:
		for reward in raw_granted:
			if reward is Dictionary:
				granted.append(parse_shop_item_reward(reward))
	return {
		"inventory": parse_inventory(data.get("inventory", {})),
		"granted": granted,
		"wallet": PlayerDataModels.parse_player_data(data.get("wallet", {})),
	}


static func parse_inventory(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"player_id": data.get("player_id", ""),
		"shop_item_id": data.get("shop_item_id", ""),
		"status": data.get("status", ""),
		"created_at": data.get("created_at", ""),
		"used_at": data.get("used_at", ""),
	}
