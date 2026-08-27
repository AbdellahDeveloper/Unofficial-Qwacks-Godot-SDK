class_name FlockSession

const PREF_KEY_SESSION_DATA := "flock_session_active"
const PREF_KEY_SESSION_NUMBER := "flock_session_number"
const MAX_TRACKED_SCREEN_NAMES := 100
const CONFIG_PATH := "user://flock_session.cfg"

var _config: FlockAnalyticsConfig
var _logger: FlockLogger

var _active := false
var _total_pause_duration: float = 0.0
var _pause_count: int = 0
var _last_heartbeat_time: float = 0.0
var _last_flush_time: float = 0.0

var _frame_count: int = 0
var _fps_accumulator: float = 0.0
var _fps_sample_timer: float = 0.0
var _fps_min: float = 0.0
var _fps_max: float = 0.0
var _fps_sum: float = 0.0
var _fps_sample_count: int = 0

var _screens_viewed: int = 0
var _screen_names: Array = []

var _is_paused := false
var _paused_at_realtime: float = 0.0
var _player_id: String = ""

var session_id: String = ""
var server_session_id: String = ""
var start_time_utc: String = ""
var end_time_utc: String = ""
var start_realtime: float = 0.0
var end_realtime: float = 0.0
var session_number: int = 0
var device_info: Dictionary = {}

# Signals
signal on_heartbeat
signal on_flush_interval
signal on_session_paused
signal on_session_ended(snapshot: FlockSessionSnapshot)
signal on_session_timed_out(snapshot: FlockSessionSnapshot)
signal on_quit_flush(snapshot: FlockSessionSnapshot)

func _init(config: FlockAnalyticsConfig, logger: FlockLogger) -> void:
	_config = config
	_logger = logger


var is_active: bool:
	get:
		return _active

# Set from inside on_session_ended when the handler could not persist the end durably.
var _end_spool_failed := false


# Called by the end handler when spooling failed, so end() keeps the live marker.
func report_end_spool_failed() -> void:
	_end_spool_failed = true

var elapsed_seconds: float:
	get:
		var raw := 0.0
		if _active:
			raw = (Time.get_ticks_msec() / 1000.0) - start_realtime
		else:
			raw = end_realtime - start_realtime
		return raw - _finalized_pause_duration


var _finalized_pause_duration: float:
	get:
		if _is_paused:
			return _total_pause_duration + (Time.get_ticks_msec() / 1000.0) - _paused_at_realtime
		return _total_pause_duration


var average_fps: float:
	get:
		return _fps_sum / _fps_sample_count if _fps_sample_count > 0 else 0.0

var min_fps: float:
	get:
		return _fps_min if _fps_sample_count > 0 else 0.0

var max_fps: float:
	get:
		return _fps_max if _fps_sample_count > 0 else 0.0

var pause_count: int:
	get:
		return _pause_count

var screens_viewed: int:
	get:
		return _screens_viewed


func start(player_id: String) -> String:
	if _active:
		_end(FlockSessionEndReason.RESTARTED)

	_player_id = player_id
	session_id = str(FlockUUID.v4())
	server_session_id = ""
	start_time_utc = Time.get_datetime_string_from_system()
	end_time_utc = ""
	start_realtime = Time.get_ticks_msec() / 1000.0
	end_realtime = 0.0

	_active = true
	_is_paused = false
	_paused_at_realtime = 0.0
	_total_pause_duration = 0.0
	_pause_count = 0
	_last_heartbeat_time = Time.get_ticks_msec() / 1000.0
	_last_flush_time = Time.get_ticks_msec() / 1000.0

	_frame_count = 0
	_fps_accumulator = 0.0
	_fps_sample_timer = 0.0
	_fps_min = 0.0
	_fps_max = 0.0
	_fps_sum = 0.0
	_fps_sample_count = 0

	_screens_viewed = 0
	_screen_names.clear()

	# Increment session number
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	session_number = config.get_value("flock", PREF_KEY_SESSION_NUMBER, 0) + 1
	config.set_value("flock", PREF_KEY_SESSION_NUMBER, session_number)
	config.save(CONFIG_PATH)

	device_info = FlockDeviceInfo.capture()
	_save_state()

	_logger.log_info("Session started: %s (#%d)" % [session_id, session_number])
	FlockEvents.get_instance().invoke_session_started(session_id)
	return session_id


func set_server_session_id(id: String) -> void:
	server_session_id = id
	_save_state()


func end(reason: String) -> FlockSessionSnapshot:
	if not _active:
		return null

	_active = false
	end_time_utc = Time.get_datetime_string_from_system()
	end_realtime = Time.get_ticks_msec() / 1000.0
	_finalize_pause()

	var snapshot := take_snapshot()
	snapshot.is_bounce = snapshot.duration_seconds < _config.bounce_threshold_seconds

	# Spool-before-clear: only drop the live marker once the handler says it persisted the end.
	_end_spool_failed = false
	on_session_ended.emit(snapshot)

	if _end_spool_failed:
		_logger.log_error("Session end %s was not spooled — keeping the live marker for next-launch recovery." % session_id)
	else:
		_clear_persisted_state()

	_logger.log_info("Session ended: %s | Duration: %.1fs | Screens: %d | Pauses: %d | AvgFPS: %.0f%s" % [
		session_id, snapshot.duration_seconds, snapshot.screens_viewed,
		snapshot.pause_count, snapshot.average_fps,
		" [BOUNCE]" if snapshot.is_bounce else ""
	])
	FlockEvents.get_instance().invoke_session_ended({
		"snapshot": snapshot,
		"reason": reason,
	})

	return snapshot


func discard() -> void:
	if not _active:
		return
	_active = false
	end_time_utc = Time.get_datetime_string_from_system()
	end_realtime = Time.get_ticks_msec() / 1000.0
	_finalize_pause()
	_clear_persisted_state()
	_logger.log_info("Session discarded (consent revoked): %s" % session_id)


func reset(reason: String) -> void:
	if _active:
		end(reason)


func record_screen_view(screen_name: String) -> void:
	if not _active:
		return
	_screens_viewed += 1
	if not screen_name.is_empty() and _screen_names.size() < MAX_TRACKED_SCREEN_NAMES:
		_screen_names.append(screen_name)


func take_snapshot() -> FlockSessionSnapshot:
	var snapshot := FlockSessionSnapshot.new()
	snapshot.session_id = session_id
	snapshot.server_session_id = server_session_id
	snapshot.player_id = _player_id
	snapshot.session_number = session_number
	snapshot.start_time_utc = start_time_utc
	snapshot.end_time_utc = end_time_utc
	snapshot.last_heartbeat_utc = Time.get_datetime_string_from_system()
	snapshot.duration_seconds = elapsed_seconds
	snapshot.total_pause_duration_seconds = _finalized_pause_duration
	snapshot.pause_count = _pause_count
	snapshot.screens_viewed = _screens_viewed
	snapshot.screen_names = _screen_names.duplicate()
	snapshot.average_fps = average_fps
	snapshot.min_fps = min_fps
	snapshot.max_fps = max_fps
	snapshot.device_info = device_info.duplicate()
	snapshot.is_active = _active
	snapshot.is_bounce = false
	snapshot.is_first_session = session_number == 1
	return snapshot


func handle_tick(delta: float) -> void:
	if not _active or _is_paused:
		return

	if _config.track_fps:
		_frame_count += 1
		_fps_accumulator += delta
		_fps_sample_timer += delta

		if _fps_sample_timer >= _config.fps_sample_interval_seconds and _fps_accumulator > 0.0:
			var current_fps := _frame_count / _fps_accumulator
			_fps_sum += current_fps
			_fps_sample_count += 1
			if current_fps < _fps_min or _fps_min == 0.0:
				_fps_min = current_fps
			if current_fps > _fps_max:
				_fps_max = current_fps
			_frame_count = 0
			_fps_accumulator = 0.0
			_fps_sample_timer = 0.0

	if _config.heartbeat_interval_seconds > 0.0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_heartbeat_time >= _config.heartbeat_interval_seconds:
			_last_heartbeat_time = now
			_save_state()
			on_heartbeat.emit()

	if _config.event_buffer_flush_interval_seconds > 0.0:
		var now := Time.get_ticks_msec() / 1000.0
		if now - _last_flush_time >= _config.event_buffer_flush_interval_seconds:
			_last_flush_time = now
			on_flush_interval.emit()


func handle_app_backgrounded(is_backgrounded: bool) -> void:
	if not _active:
		return
	if is_backgrounded:
		_pause_count += 1
		_is_paused = true
		_paused_at_realtime = Time.get_ticks_msec() / 1000.0
		_save_state()
		on_session_paused.emit()
		FlockEvents.get_instance().invoke_session_paused()
	else:
		if not _is_paused:
			return
		var paused_duration := Time.get_ticks_msec() / 1000.0 - _paused_at_realtime
		if paused_duration > _config.session_timeout_seconds:
			var snapshot := _end(FlockSessionEndReason.TIMEOUT)
			if snapshot:
				on_session_timed_out.emit(snapshot)
		else:
			_finalize_pause()
			_is_paused = false
			FlockEvents.get_instance().invoke_session_resumed()


func _end(reason: String) -> FlockSessionSnapshot:
	if not _active:
		return null
	_active = false
	end_time_utc = Time.get_datetime_string_from_system()
	end_realtime = Time.get_ticks_msec() / 1000.0
	_finalize_pause()

	var snapshot := take_snapshot()
	snapshot.is_bounce = snapshot.duration_seconds < _config.bounce_threshold_seconds

	# Spool-before-clear: only drop the live marker once the handler says it persisted the end.
	_end_spool_failed = false
	on_session_ended.emit(snapshot)

	if _end_spool_failed:
		_logger.log_error("Session end %s was not spooled — keeping the live marker for next-launch recovery." % session_id)
	else:
		_clear_persisted_state()

	_logger.log_info("Session ended: %s | Duration: %.1fs | Screens: %d | Pauses: %d | AvgFPS: %.0f%s" % [
		session_id, snapshot.duration_seconds, snapshot.screens_viewed,
		snapshot.pause_count, snapshot.average_fps,
		" [BOUNCE]" if snapshot.is_bounce else ""
	])
	FlockEvents.get_instance().invoke_session_ended({
		"snapshot": snapshot,
		"reason": reason,
	})

	return snapshot


func _finalize_pause() -> void:
	if _is_paused:
		_total_pause_duration += Time.get_ticks_msec() / 1000.0 - _paused_at_realtime
		_is_paused = false
		_paused_at_realtime = 0.0


func _save_state() -> void:
	if not _config.persist_session_on_disk or not _active:
		return
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("flock", PREF_KEY_SESSION_DATA, take_snapshot().serialize())
	config.save(CONFIG_PATH)


func _clear_persisted_state() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) == OK:
		config.erase_section("flock")
		config.save(CONFIG_PATH)


func recover_orphaned_session() -> FlockSessionSnapshot:
	if not _config.persist_session_on_disk:
		return null

	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return null

	var snapshot_data = config.get_value("flock", PREF_KEY_SESSION_DATA, null)
	if snapshot_data == null or not snapshot_data is Dictionary:
		return null

	var snapshot := FlockSessionSnapshot.deserialize(snapshot_data)
	if snapshot.session_id.is_empty():
		return null

	_logger.log_info("Found orphaned session: %s" % snapshot.session_id)
	return snapshot
