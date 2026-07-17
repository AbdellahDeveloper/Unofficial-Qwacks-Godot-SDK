class_name FlockTerminationTracker

const PREF_KEY_MARKER := "flock_termination_marker"
const STATE_FOREGROUND := "foreground"
const STATE_BACKGROUND := "background"
const CLASS_BACKGROUND_KILL := "background_kill"
const CLASS_ABNORMAL := "abnormal"
const EVENT_NAME := "app_termination"

var _logger: FlockLogger
var _enabled: bool
var _marker: FlockTerminationMarker = null
var _tracking := false

func _init(logger: FlockLogger, enabled: bool) -> void:
	_logger = logger
	_enabled = enabled


static func classify(marker: FlockTerminationMarker) -> String:
	if marker == null:
		return ""
	return CLASS_BACKGROUND_KILL if marker.last_state == STATE_BACKGROUND else CLASS_ABNORMAL


func begin_tracking(session_id: String) -> void:
	if not _enabled:
		return
	_marker = FlockTerminationMarker.new()
	_marker.session_id = session_id
	_marker.last_state = STATE_FOREGROUND
	_marker.last_alive_utc = Time.get_datetime_string_from_system()
	_marker.exception_count = 0
	_tracking = true
	_save_marker()


func stop_tracking() -> void:
	if not _tracking:
		return
	_tracking = false
	_marker = null
	clear_marker()


func handle_heartbeat() -> void:
	if not _tracking or _marker == null:
		return
	_marker.last_alive_utc = Time.get_datetime_string_from_system()
	_save_marker()


func handle_app_backgrounded(is_backgrounded: bool) -> void:
	if not _tracking or _marker == null:
		return
	_marker.last_state = STATE_BACKGROUND if is_backgrounded else STATE_FOREGROUND
	_marker.last_alive_utc = Time.get_datetime_string_from_system()
	_save_marker()


func read_surviving_marker() -> FlockTerminationMarker:
	if not _enabled:
		return null
	var config := ConfigFile.new()
	if config.load("user://flock_termination.cfg") != OK:
		return null
	var marker_dict: Dictionary = config.get_value("flock", PREF_KEY_MARKER, {})
	if marker_dict.is_empty():
		return null
	return FlockTerminationMarker.deserialize(marker_dict)


func clear_marker() -> void:
	var config := ConfigFile.new()
	config.load("user://flock_termination.cfg")
	config.erase_section("flock")
	config.save("user://flock_termination.cfg")


func _save_marker() -> void:
	if _marker == null:
		return
	var config := ConfigFile.new()
	config.load("user://flock_termination.cfg")
	config.set_value("flock", PREF_KEY_MARKER, _marker.serialize())
	config.save("user://flock_termination.cfg")
