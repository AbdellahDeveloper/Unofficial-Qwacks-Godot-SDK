class_name AssetModels

static func parse_asset_schema(data: Dictionary) -> Dictionary:
	return {
		"id": data.get("id", ""),
		"name": data.get("name", ""),
		"extension_type": data.get("extension_type", ""),
		"size_bytes": data.get("size_bytes", 0),
		"s3_download_url": data.get("s3_download_url", ""),
		"game_id": data.get("game_id", ""),
		"created_at": data.get("created_at", ""),
		"updated_at": data.get("updated_at", ""),
	}
