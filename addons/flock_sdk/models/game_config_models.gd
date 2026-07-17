class_name GameConfigModels

static func parse_game_config(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"game_id": data.get("game_id", ""),
		"game_version_id": data.get("game_version_id", ""),
		"schema": data.get("schema", []),
		"data": data.get("data", []),
		"tag": data.get("tag", ""),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}

static func parse_game_patch(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"game_config_id": data.get("game_config_id", ""),
		"data": data.get("data", []),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}

static func get_data_as(data_fields: Array) -> Dictionary:
	return TypedSchemaModels.to_flat_object(data_fields)
