class_name FlockSessionSnapshot

var session_id: String = ""
var server_session_id: String = ""
var player_id: String = ""
var session_number: int = 0
var start_time_utc: String = ""
var end_time_utc: String = ""
var last_heartbeat_utc: String = ""
var duration_seconds: float = 0.0
var total_pause_duration_seconds: float = 0.0
var pause_count: int = 0
var screens_viewed: int = 0
var screen_names: Array = []
var average_fps: float = 0.0
var min_fps: float = 0.0
var max_fps: float = 0.0
var device_info: Dictionary = {}
var is_active: bool = false
var is_bounce: bool = false
var is_first_session: bool = false

func serialize() -> Dictionary:
	return {
		"session_id": session_id,
		"server_session_id": server_session_id,
		"player_id": player_id,
		"session_number": session_number,
		"start_time_utc": start_time_utc,
		"end_time_utc": end_time_utc,
		"last_heartbeat_utc": last_heartbeat_utc,
		"duration_seconds": duration_seconds,
		"total_pause_duration_seconds": total_pause_duration_seconds,
		"pause_count": pause_count,
		"screens_viewed": screens_viewed,
		"screen_names": screen_names,
		"average_fps": average_fps,
		"min_fps": min_fps,
		"max_fps": max_fps,
		"device_info": device_info,
		"is_active": is_active,
		"is_bounce": is_bounce,
		"is_first_session": is_first_session,
	}

static func deserialize(data: Dictionary) -> FlockSessionSnapshot:
	var snapshot := FlockSessionSnapshot.new()
	snapshot.session_id = data.get("session_id", "")
	snapshot.server_session_id = data.get("server_session_id", "")
	snapshot.player_id = data.get("player_id", "")
	snapshot.session_number = data.get("session_number", 0)
	snapshot.start_time_utc = data.get("start_time_utc", "")
	snapshot.end_time_utc = data.get("end_time_utc", "")
	snapshot.last_heartbeat_utc = data.get("last_heartbeat_utc", "")
	snapshot.duration_seconds = data.get("duration_seconds", 0.0)
	snapshot.total_pause_duration_seconds = data.get("total_pause_duration_seconds", 0.0)
	snapshot.pause_count = data.get("pause_count", 0)
	snapshot.screens_viewed = data.get("screens_viewed", 0)
	snapshot.screen_names = data.get("screen_names", [])
	snapshot.average_fps = data.get("average_fps", 0.0)
	snapshot.min_fps = data.get("min_fps", 0.0)
	snapshot.max_fps = data.get("max_fps", 0.0)
	snapshot.device_info = data.get("device_info", {})
	snapshot.is_active = data.get("is_active", false)
	snapshot.is_bounce = data.get("is_bounce", false)
	snapshot.is_first_session = data.get("is_first_session", false)
	return snapshot
