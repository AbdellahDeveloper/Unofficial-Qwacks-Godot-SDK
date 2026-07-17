class_name AnalyticsModels

static func session_start_request(player_id: String, platform: String, device_type: String,
		game_version_id: String, started_at: String) -> Dictionary:
	return {
		"player_id": player_id,
		"platform": platform,
		"device_type": device_type,
		"game_version_id": game_version_id,
		"started_at": started_at,
	}

static func session_end_request(duration_seconds: int, screens_viewed: int, is_bounce: bool, ended_at: String) -> Dictionary:
	return {
		"duration_seconds": duration_seconds,
		"screens_viewed": screens_viewed,
		"is_bounce": is_bounce,
		"ended_at": ended_at,
	}

static func analytics_event_request(player_id: String, event_name: String, event_category: String,
		session_id: String, timestamp: String, properties: Dictionary = {}) -> Dictionary:
	return {
		"player_id": player_id,
		"event_name": event_name,
		"event_category": event_category,
		"session_id": session_id,
		"timestamp": timestamp,
		"properties": properties,
	}

static func analytics_events_request(events: Array) -> Dictionary:
	return {"events": events}

static func analytics_transaction_request(player_id: String, amount: float, currency_id: String = "",
		currency_code: String = "USD", session_id: String = "", shop_item_id: String = "",
		quantity: int = 1, transaction_type: String = "purchase", status: String = "completed",
		payment_provider: String = "", external_transaction_id: String = "", created_at: String = "") -> Dictionary:
	var req := {
		"player_id": player_id,
		"amount": amount,
		"currency_code": currency_code,
		"quantity": quantity,
		"transaction_type": transaction_type,
		"status": status,
	}
	if not currency_id.is_empty(): req["currency_id"] = currency_id
	if not session_id.is_empty(): req["session_id"] = session_id
	if not shop_item_id.is_empty(): req["shop_item_id"] = shop_item_id
	if not payment_provider.is_empty(): req["payment_provider"] = payment_provider
	if not external_transaction_id.is_empty(): req["external_transaction_id"] = external_transaction_id
	if not created_at.is_empty(): req["created_at"] = created_at
	return req
