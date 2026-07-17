class_name GameCommandModels

static func update_player_data_input(player_data_id: String, data: Dictionary) -> Dictionary:
	return {
		"player_data_id": player_data_id,
		"data": data,
	}

static func update_player_data_key_input(player_data_id: String, key: String, value: Variant) -> Dictionary:
	return {
		"player_data_id": player_data_id,
		"key": key,
		"value": value,
	}

static func add_game_funds_input(player_data_id: String, currency: String, amount: int) -> Dictionary:
	return {
		"player_data_id": player_data_id,
		"currency": currency,
		"amount": amount,
	}

static func unlock_achievement_input(player_data_id: String, achievement_name: String) -> Dictionary:
	return {
		"player_data_id": player_data_id,
		"achievement_name": achievement_name,
	}

static func shop_transaction_request(shop_item_id: String, player_id: String) -> Dictionary:
	return {
		"shop_item_id": shop_item_id,
		"player_id": player_id,
	}

static func parse_player_inventory(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"player_id": data.get("player_id", ""),
		"shop_item_id": data.get("shop_item_id", ""),
		"status": data.get("status", ""),
		"created_at": data.get("created_at", ""),
		"used_at": data.get("used_at", ""),
	}
