class_name GameModels

static func parse_game(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"read_me": data.get("read_me", ""),
		"stage": data.get("stage", ""),
		"studio_id": data.get("studio_id", ""),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
		"deleted_at": data.get("deleted_at", ""),
	}

static func parse_game_version(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"release_type": data.get("release_type", ""),
		"env": data.get("env", ""),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}
