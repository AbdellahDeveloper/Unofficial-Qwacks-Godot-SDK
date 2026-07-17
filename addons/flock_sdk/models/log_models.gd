class_name LogModels

enum LogEventType {
	EXCEPTION,
	LOGIC_ERROR,
	DEBUG
}

static func log_event_request(message: String, event_type: String, game_version: String = "",
		error_message: String = "", error_code: String = "", error_traceback: String = "",
		extra_data: Dictionary = {}) -> Dictionary:
	var data := {
		"type": event_type,
		"game_version": game_version,
		"error_message": error_message,
		"error_code": error_code,
		"error_traceback": error_traceback,
		"extra_data": extra_data,
	}
	return {
		"message": message,
		"data": data,
		"timestamp": Time.get_datetime_string_from_system(),
	}

static func log_events_request(events: Array) -> Dictionary:
	return {"events": events}
