class_name FlockTerminationMarker

var session_id: String = ""
var last_state: String = "foreground"
var last_alive_utc: String = ""
var exception_count: int = 0

func serialize() -> Dictionary:
	return {
		"session_id": session_id,
		"last_state": last_state,
		"last_alive_utc": last_alive_utc,
		"exception_count": exception_count,
	}

static func deserialize(data: Dictionary) -> FlockTerminationMarker:
	var marker := FlockTerminationMarker.new()
	marker.session_id = data.get("session_id", "")
	marker.last_state = data.get("last_state", "foreground")
	marker.last_alive_utc = data.get("last_alive_utc", "")
	marker.exception_count = data.get("exception_count", 0)
	return marker
