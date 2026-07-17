class_name PlayerDataModels

static func parse_template(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"game_version_id": data.get("game_version_id", ""),
		"schema": data.get("schema", []),
		"data": data.get("data", []),
		"tag": data.get("tag", ""),
	}

static func parse_player_data(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"player_template_id": data.get("player_template_id", ""),
		"game_id": data.get("game_id", ""),
		"player_id": data.get("player_id", ""),
		"data": data.get("data", []),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}
