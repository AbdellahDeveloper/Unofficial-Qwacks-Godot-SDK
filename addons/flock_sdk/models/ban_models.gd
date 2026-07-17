class_name BanModels

static func parse_feature_ban(data: Dictionary) -> Dictionary:
	return {
		"reason": data.get("reason", ""),
		"ban_duration": data.get("ban_duration", ""),
		"effective_datetime": data.get("effective_datetime", ""),
	}

static func parse_player_ban(data: Dictionary) -> Dictionary:
	var bans := {}
	var raw_data: Dictionary = data.get("data", {})
	for key in raw_data:
		bans[key] = parse_feature_ban(raw_data[key])
	return {
		"id": data.get("id", ""),
		"player_id": data.get("player_id", ""),
		"game_id": data.get("game_id", ""),
		"data": bans,
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}
