class_name PaginatedResponseModels

static func parse(data: Dictionary) -> Dictionary:
	return {
		"items": data.get("items", []),
		"total": data.get("total", 0),
		"page": data.get("page", 1),
		"limit": data.get("limit", 100),
	}
