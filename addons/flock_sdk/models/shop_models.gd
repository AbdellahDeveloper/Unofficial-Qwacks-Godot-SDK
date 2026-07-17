class_name ShopModels

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
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"status": data.get("status", ""),
		"shop_id": data.get("shop_id", ""),
		"patch_id": data.get("patch_id", ""),
		"price": data.get("price", 0),
		"currency": data.get("currency", ""),
		"data": data.get("data", {}),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}
