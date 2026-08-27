class_name FlockAnalyticsProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "analytics"
const EVENTS_FOLDER := "events"
const LOG_EVENTS_FOLDER := "log_events"
const SESSION_ENDS_FOLDER := "session_ends"

var _session: FlockSession
var _consent_store: FlockConsentStore
var _termination_tracker: FlockTerminationTracker
var _event_cache: FlockEventCache
var _log_event_cache: FlockEventCache
# Write-ahead spool: session ends hit disk before any network attempt and are
# retried until the server confirms them.
var _session_end_cache: FlockEventCache = null
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
	if client._init_config.analytics_config.get("persist_session_on_disk", true):
		_session_end_cache = FlockEventCache.new(cache_dir, SESSION_ENDS_FOLDER,
			client._init_config.analytics_config.get("max_cached_events", 1000),
			client._init_config.analytics_config.get("cache_flush_batch_size", 50),
			client._logger)

	# Load consent: a previously-recorded decision always wins; otherwise fall back to the
	# config's default policy (opt-out unless require_explicit_consent is on).
	var stored_consent = _consent_store.load_consent()
	if stored_consent != null:
		_consent_granted = stored_consent
	else:
		_consent_granted = not client._init_config.analytics_config.get("require_explicit_consent", false)

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
		# No consent means the data must be discarded — drop the marker instead of retrying.
		if not _consent_granted:
			_termination_tracker.clear_marker()
		else:
			var handle := _enqueue_termination_event(marker)
			if not handle.is_empty():
				# Clear only after the durable enqueue — a failed write retries next launch.
				_termination_tracker.clear_marker()
				_client._logger.log_info("Previous run terminated dirty (%s); app_termination queued for session %s" % [
					FlockTerminationTracker.classify(marker), marker.session_id])
			else:
				_client._logger.log_warning("app_termination enqueue failed; marker kept for retry next launch")

	# Recover orphaned session
	var recovered = _session.recover_orphaned_session()
	if recovered != null:
		if _session_end_cache != null:
			# Spool first, clear after — clearing first loses the session if the send fails.
			var handle := _session_end_cache.enqueue(recovered.serialize())
			if not handle.is_empty():
				_session.clear_persisted_state()
				_client._logger.log_debug("Orphaned session end spooled: %s" % recovered.session_id)
		else:
			_session.clear_persisted_state()
			await _try_send_session_end(recovered)

	# Deliver unconfirmed ends from previous runs before a new session registers.
	# When offline, the spool drains on later flush triggers instead.
	if _session_end_cache != null and _session_end_cache.pending_count > 0 and is_server_reachable():
		_client._logger.log_info("Delivering %d pending session end(s)" % _session_end_cache.pending_count)
		await _flush_session_ends()

	# Start session if auto-start
	if _client._init_config.analytics_config.get("auto_start_session", true):
		start_session_async()

	return {}


func start_session_async() -> Variant:
	if not _consent_granted:
		return {}
	if _client.current_player_id.is_empty():
		return {}

	# Deliver the previous session's end before the new one registers. The end is already
	# spooled by _handle_session_ended; the flush is the network delivery attempt.
	if _session.is_active:
		var stale := _session.end(FlockSessionEndReason.RESTARTED)
		if stale != null:
			await _deliver_session_end(stale)

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

	return await _deliver_session_end(snapshot)


func log_exception(exception: String) -> void:
	if not _consent_granted:
		return
	var event := LogModels.log_event_request(
		exception, "exception", "",
		exception, "", ""
	)
	_log_event_cache.enqueue(event)
	_client._logger.log_debug("Log event queued")
	_flush_log_events_async.call_deferred()


func log_error(message: String, error_code: String = "") -> void:
	if not _consent_granted:
		return
	var event := LogModels.log_event_request(
		message, "logic_error", "",
		message, error_code, ""
	)
	_log_event_cache.enqueue(event)
	_client._logger.log_debug("Log event queued")
	_flush_log_events_async.call_deferred()


func log_event(event_name: String, properties: Dictionary = {}) -> void:
	if not _consent_granted:
		return
	var event := AnalyticsModels.analytics_event_request(
		_client.current_player_id, event_name, "custom",
		_session.session_id if _session else "",
		Time.get_datetime_string_from_system(),
		properties
	)
	# A null handle means the event is gone, not queued - no cache (CacheFailedEvents off) or the
	# write failed. Saying "queued" there sends anyone debugging a missing event down the wrong path.
	var handle := _event_cache.enqueue(event)
	if handle.is_empty():
		_client._logger.log_warning(
			"Event '%s' was NOT queued and will never be delivered — the analytics event cache is unavailable (CacheFailedEvents off, or the disk write failed)." % event_name)
	else:
		_client._logger.log_debug("Event queued: %s" % event_name)
	_flush_events_async.call_deferred()


func flush_async() -> Variant:
	await _flush_session_ends()
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
	if not _consent_granted:
		return
	if _session:
		_session.record_screen_view(screen_name)


func set_consent(granted: bool) -> void:
	if granted == _consent_granted:
		return
	_consent_granted = granted
	_consent_store.save_consent(granted)
	FlockEvents.get_instance().invoke_consent_changed(granted)

	if granted:
		_client._logger.log_info("Analytics consent granted")
		if not _session.is_active:
			start_session_async()
	else:
		_client._logger.log_info("Analytics consent revoked")
		if _session.is_active:
			_session.discard()
		# Discard deliberately skips on_session_ended, so the tombstone needs its own stop.
		_termination_tracker.stop_tracking()


func erase_local_analytics_data() -> void:
	if _event_cache:
		_event_cache.clear()
	if _session_end_cache:
		_session_end_cache.clear()
	if _log_event_cache:
		_log_event_cache.clear()
	_client._logger.log_info("Local analytics data erased (queued events + session-end spool + log events)")


func handle_auth_cleared() -> void:
	# Queued events survive logout: they're retagged from the placeholder player id and drained on
	# the next initialize. Nothing is cleared here — a logout must not delete undelivered data.
	pass


func uninstall_global_exception_hook() -> void:
	pass


func _handle_heartbeat() -> void:
	_termination_tracker.handle_heartbeat()


func _handle_session_paused() -> void:
	_termination_tracker.handle_app_backgrounded(true)
	_flush_events_async.call_deferred()


func _handle_session_ended(snapshot: FlockSessionSnapshot) -> void:
	# Every clean end path lands here — the tombstone must go before any early return.
	_termination_tracker.stop_tracking()

	if _session_end_cache == null:
		return

	# A null handle means it never reached disk - say so, or end() clears the marker and the session is gone.
	var handle := _session_end_cache.enqueue(snapshot.serialize())
	if handle.is_empty():
		_client._logger.log_error("Session end %s was NOT spooled — recovering it on the next launch instead." % snapshot.session_id)
		_session.report_end_spool_failed()
		return

	_client._logger.log_debug("Session end spooled: %s" % snapshot.session_id)


func _handle_quit_flush(snapshot: FlockSessionSnapshot) -> void:
	# Best-effort drain within the quit budget; the next launch re-drains whatever doesn't finish.
	_flush_all_async.call_deferred()
	if _session_end_cache == null:
		_try_send_session_end.call_deferred(snapshot)


func _handle_flush_interval() -> void:
	_flush_events_async.call_deferred()


# Awaited delivery attempt for an end that _handle_session_ended already spooled.
# Falls back to a one-shot send when the spool is unavailable.
func _deliver_session_end(snapshot: FlockSessionSnapshot) -> Variant:
	if snapshot == null:
		return {}
	if _session_end_cache == null:
		return await _try_send_session_end(snapshot)
	return await _flush_session_ends()


func _flush_session_ends() -> Variant:
	# Egress is consent-gated too - withdrawal stops transmission, not just collection.
	if not _consent_granted:
		return {}
	if _session_end_cache == null or _session_end_cache.pending_count == 0:
		return {}
	await _session_end_cache.flush_async(_send_session_ends)
	return {}


# One-shot best-effort send, used only when the spool is unavailable. Never throws beyond the return dict.
func _try_send_session_end(snapshot: FlockSessionSnapshot) -> Variant:
	# Sends one end directly, bypassing the caches, so it needs its own consent gate.
	if not _consent_granted:
		return {}
	var session_id := snapshot.server_session_id if not snapshot.server_session_id.is_empty() else snapshot.session_id
	if session_id.is_empty():
		_client._logger.log_warning("Cannot end session: no session ID available")
		return {}
	return await _patch_session_end(session_id, snapshot)


# Spool sender. A record without a server id was never registered - register it first (the POST
# accepts a historical started_at). Permanent rejections are logged and skipped so the batch can
# clear; transient failures propagate so the cache defers the batch.
func _send_session_ends(events: Array, _ct) -> Variant:
	var delivered := {}
	for ev in events:
		var snapshot := FlockSessionSnapshot.deserialize(ev)
		# A quit and a crash recovery can both spool the same session. The batch is ordered
		# oldest-first and the older record is the accurate one, so later ones are skipped.
		if delivered.has(snapshot.session_id):
			_client._logger.log_debug("Skipping duplicate spooled end: %s" % snapshot.session_id)
			continue
		delivered[snapshot.session_id] = true

		var server_session_id := snapshot.server_session_id
		if server_session_id.is_empty():
			var registered = await _post_session_start(snapshot)
			if registered is Dictionary and registered.has("error"):
				if _session_end_cache._outcome_is_permanent(registered):
					_client._logger.log_warning("Session end for '%s' rejected by server (HTTP %d), dropping" % [
						snapshot.session_id, int(registered.get("status_code", 0))])
					continue
				return registered
			server_session_id = str(registered.get("result", {}).get("session_id", "") if registered is Dictionary else "")
			if server_session_id.is_empty():
				return {"error": "Session registration returned no session id"}

		var result = await _patch_session_end(server_session_id, snapshot)
		if result is Dictionary and result.has("error"):
			if _session_end_cache._outcome_is_permanent(result):
				_client._logger.log_warning("Session end for '%s' rejected by server (HTTP %d), dropping" % [
					snapshot.session_id, int(result.get("status_code", 0))])
				continue
			return result
	return "ok"


func _build_session_start_request(snapshot: FlockSessionSnapshot) -> Dictionary:
	var device := snapshot.device_info
	return AnalyticsModels.session_start_request(
		snapshot.player_id if not snapshot.player_id.is_empty() else _client.current_player_id,
		device.get("platform", OS.get_name()),
		device.get("device_type", FlockDeviceInfo._get_device_type()),
		_client.game_version_id,
		snapshot.start_time_utc if not snapshot.start_time_utc.is_empty() else Time.get_datetime_string_from_system()
	)


func _post_session_start(snapshot: FlockSessionSnapshot) -> Variant:
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.ANALYTICS_SESSIONS]
		return await FlockHttpClient.post_async(url, _build_session_start_request(snapshot), _client.get_base_headers())
	, "Start session")


# Throws on failure? No - returns the error dict; shared by the spool sender and the one-shot path.
func _patch_session_end(session_id: String, snapshot: FlockSessionSnapshot) -> Variant:
	var end_request := AnalyticsModels.session_end_request(
		int(snapshot.duration_seconds),
		snapshot.screens_viewed,
		snapshot.is_bounce,
		snapshot.end_time_utc if not snapshot.end_time_utc.is_empty() else Time.get_datetime_string_from_system()
	)

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.analytics_session_by_id(session_id)]
		return await FlockHttpClient.patch_async(url, end_request, _client.get_base_headers())
	, "End session")


func _enqueue_termination_event(marker: FlockTerminationMarker) -> String:
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
	var handle := _event_cache.enqueue(event)
	if not handle.is_empty():
		_flush_events_async.call_deferred()
	return handle


func _flush_events_async() -> void:
	# Egress is consent-gated too - withdrawal stops transmission, not just collection.
	if not _consent_granted:
		return
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
	# Egress is consent-gated too - withdrawal stops transmission, not just collection.
	if not _consent_granted:
		return
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


func _flush_all_async() -> void:
	await _flush_session_ends()
	await _flush_events_async()
	await _flush_log_events_async()
