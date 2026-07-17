class_name FlockAnalyticsProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "analytics"
const EVENTS_FOLDER := "events"
const LOG_EVENTS_FOLDER := "log_events"

var _session: FlockSession
var _consent_store: FlockConsentStore
var _termination_tracker: FlockTerminationTracker
var _event_cache: FlockEventCache
var _log_event_cache: FlockEventCache
var _consent_granted: bool = false

func _init(client: FlockClient) -> void:
	super(client)
	_session = client.session
	_consent_store = FlockConsentStore.new()

	# Initialize caches
	var cache_dir := client._init_config.offline_cache_directory if not client._init_config.offline_cache_directory.is_empty() else FlockUtil.flock_data_dir()
	_event_cache = FlockEventCache.new(cache_dir, EVENTS_FOLDER,
		client._init_config.analytics_config.get("max_cached_events", 1000),
		client._init_config.analytics_config.get("cache_flush_batch_size", 50),
		client._logger)
	_log_event_cache = FlockEventCache.new(cache_dir, LOG_EVENTS_FOLDER,
		client._init_config.analytics_config.get("max_cached_events", 1000),
		client._init_config.analytics_config.get("cache_flush_batch_size", 50),
		client._logger)

	# Load consent
	var stored_consent = _consent_store.load_consent()
	if stored_consent != null:
		_consent_granted = stored_consent

	# Termination tracker
	var persist_enabled = client._init_config.analytics_config.get("persist_session_on_disk", true)
	_termination_tracker = FlockTerminationTracker.new(client._logger, persist_enabled)

	# Subscribe to session events
	_session.on_heartbeat.connect(_handle_heartbeat)
	_session.on_session_paused.connect(_handle_session_paused)
	_session.on_session_ended.connect(_handle_session_ended)
	_session.on_quit_flush.connect(_handle_quit_flush)
	_session.on_flush_interval.connect(_handle_flush_interval)


func initialize_async() -> Variant:
	if _session == null:
		return {}

	# Check for surviving termination marker
	var marker = _termination_tracker.read_surviving_marker()
	if marker != null:
		_termination_tracker.clear_marker()
		_send_termination_event(marker)

	# Recover orphaned session
	var recovered = _session.recover_orphaned_session()
	if recovered != null:
		_client._logger.log_warning("Recovering orphaned session: %s" % recovered.session_id)

	# Start session if auto-start
	if _client._init_config.analytics_config.get("auto_start_session", true):
		start_session_async()

	return {}


func start_session_async() -> Variant:
	if not _consent_granted:
		return {}
	if _client.current_player_id.is_empty():
		return {}

	var session_id := _session.start(_client.current_player_id)

	# Start server session
	var request := AnalyticsModels.session_start_request(
		_client.current_player_id,
		OS.get_name(),
		FlockDeviceInfo._get_device_type(),
		_client.game_version_id,
		_session.start_time_utc
	)
	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.ANALYTICS_SESSIONS]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Start session")

	if result is Dictionary and not result.has("error"):
		var server_session_id: String = result.get("result", {}).get("session_id", "")
		if not server_session_id.is_empty():
			_session.set_server_session_id(server_session_id)

	# Begin termination tracking
	_termination_tracker.begin_tracking(session_id)

	return {}


func end_session_async() -> Variant:
	if not _session.is_active:
		return {}

	# Stop termination tracking
	_termination_tracker.stop_tracking()

	var snapshot := _session.end(FlockSessionEndReason.MANUAL)
	if snapshot == null:
		return {}

	return await _send_session_end(snapshot)


func log_exception(exception: String) -> void:
	var event := LogModels.log_event_request(
		exception, "exception", "",
		exception, "", ""
	)
	_log_event_cache.enqueue(event)
	_flush_log_events_async.call_deferred()


func log_error(message: String, error_code: String = "") -> void:
	var event := LogModels.log_event_request(
		message, "logic_error", "",
		message, error_code, ""
	)
	_log_event_cache.enqueue(event)
	_flush_log_events_async.call_deferred()


func log_event(event_name: String, properties: Dictionary = {}) -> void:
	var event := AnalyticsModels.analytics_event_request(
		_client.current_player_id, event_name, "custom",
		_session.session_id if _session else "",
		Time.get_datetime_string_from_system(),
		properties
	)
	_event_cache.enqueue(event)
	_flush_events_async.call_deferred()


func flush_async() -> Variant:
	await _flush_events_async()
	await _flush_log_events_async()
	return {}


func record_transaction_async(transaction: Dictionary) -> Variant:
	if _client.current_player_id.is_empty():
		return {"error": "Player must be authenticated for analytics"}

	transaction["player_id"] = _client.current_player_id
	if transaction.get("session_id", "").is_empty():
		transaction["session_id"] = _session.session_id if _session else ""
	if transaction.get("created_at", "").is_empty():
		transaction["created_at"] = Time.get_datetime_string_from_system()

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.ANALYTICS_TRANSACTIONS]
		return await FlockHttpClient.post_async(url, transaction, _client.get_base_headers())
	, "Record transaction")


func record_screen_view(screen_name: String) -> void:
	if _session:
		_session.record_screen_view(screen_name)


func set_consent(granted: bool) -> void:
	_consent_granted = granted
	_consent_store.save_consent(granted)
	FlockEvents.get_instance().invoke_consent_changed(granted)

	if granted:
		if not _session.is_active:
			start_session_async()
	else:
		if _session.is_active:
			_session.discard()


func erase_local_analytics_data() -> void:
	_event_cache.clear()
	_log_event_cache.clear()


func handle_auth_cleared() -> void:
	_event_cache.clear()
	_log_event_cache.clear()


func uninstall_global_exception_hook() -> void:
	pass


func _handle_heartbeat() -> void:
	_termination_tracker.handle_heartbeat()


func _handle_session_paused() -> void:
	_termination_tracker.handle_app_backgrounded(true)
	_flush_events_async.call_deferred()


func _handle_session_ended(snapshot: FlockSessionSnapshot) -> void:
	_send_session_end.call_deferred(snapshot)
	_flush_events_async.call_deferred()


func _handle_quit_flush(snapshot: FlockSessionSnapshot) -> void:
	_send_session_end.call_deferred(snapshot)


func _handle_flush_interval() -> void:
	_flush_events_async.call_deferred()


func _send_session_end(snapshot: FlockSessionSnapshot) -> Variant:
	if snapshot.server_session_id.is_empty():
		return {}

	var end_request := AnalyticsModels.session_end_request(
		int(snapshot.duration_seconds),
		snapshot.screens_viewed,
		snapshot.is_bounce,
		snapshot.end_time_utc
	)

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.analytics_session_by_id(snapshot.server_session_id)]
		return await FlockHttpClient.post_async(url, end_request, _client.get_base_headers())
	, "End session")


func _send_termination_event(marker: FlockTerminationMarker) -> void:
	var classification := FlockTerminationTracker.classify(marker)
	var event := AnalyticsModels.analytics_event_request(
		_client.current_player_id, FlockTerminationTracker.EVENT_NAME, "system",
		marker.session_id, marker.last_alive_utc,
		{
			"previous_session_id": marker.session_id,
			"classification": classification,
			"last_alive_at": marker.last_alive_utc,
			"unhandled_exception_count": marker.exception_count,
			"sdk_version": FlockSdkVersion.CURRENT,
		}
	)
	_event_cache.enqueue(event)
	_flush_events_async.call_deferred()


func _flush_events_async() -> void:
	if _event_cache.pending_count == 0:
		return
	await _event_cache.flush_async(func(events: Array, _ct) -> Variant:
		if events.is_empty():
			return "ok"
		var request := AnalyticsModels.analytics_events_request(events)
		return await execute_async(func() -> Variant:
			var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.ANALYTICS_EVENTS]
			return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
		, "Flush analytics events")
	)


func _flush_log_events_async() -> void:
	if _log_event_cache.pending_count == 0:
		return
	await _log_event_cache.flush_async(func(events: Array, _ct) -> Variant:
		if events.is_empty():
			return "ok"
		var request := LogModels.log_events_request(events)
		return await execute_async(func() -> Variant:
			var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.LOG_EVENT]
			return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
		, "Flush log events")
	)
