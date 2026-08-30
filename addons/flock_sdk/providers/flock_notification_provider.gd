class_name FlockNotificationProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "notification"
const PENDING_SCHEDULES_KEY := "pending_schedules"
const WATERMARK_KEY := "seen_watermark"

# Last count the server reported; -1 until a count-bearing call succeeds.
var _last_unread_count: int = -1

# Name+locale -> template memo: scheduling resolves a name to an id first, and that shouldn't cost a round trip each time.
var _templates_by_name := {}

func _init(client: FlockClient) -> void:
	super(client)


# Drops cached inbox reads and the template memo. Pending schedules and the seen-watermark survive — neither is
# cache: one is the only handle on a cancellable reminder, the other decides what counts as newly received.
func clear_cache() -> void:
	_last_unread_count = -1
	_templates_by_name.clear()

	# Keep every player's schedules and watermarks, not just the signed-in one's: dropping another
	# player's row orphans a reminder that still fires and can no longer be cancelled.
	delete_snapshot_category_except(SNAPSHOT_CATEGORY, [PENDING_SCHEDULES_KEY, WATERMARK_KEY])


# A page of the signed-in player's inbox, newest first. Set unread_only to skip already-read entries.
func get_inbox_async(unread_only: bool = false, page: int = 1, limit: int = 50) -> Variant:
	if not _require_authenticated():
		return _auth_error()

	var query := "?page=%d&limit=%d" % [page, limit]
	if unread_only:
		query += "&unread_only=true"

	var inbox = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, _player_scoped_key("inbox_%s_p%d_l%d" % [unread_only, page, limit]), func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION]
		return await FlockHttpClient.get_async(url + query, _client.get_base_headers())
	, "Fetch notifications")

	_raise_new_notifications(inbox.get("items", []) if inbox is Dictionary else [])
	return inbox


# How many notifications the player hasn't read. Raises unread_count_changed when the value moves.
func get_unread_count_async() -> Variant:
	if not _require_authenticated():
		return _auth_error()

	var result = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, _player_scoped_key("unread_count"), func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_UNREAD_COUNT]
		var response = await FlockHttpClient.get_async(url, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		var count_data: Dictionary = GenericResponseModels.get_result(response)
		if count_data == null:
			return {"error": "Invalid response from server (missing count)"}
		return count_data
	, "Fetch unread notification count")

	if result is Dictionary:
		if not result.has("error"):
			_set_unread_count(int(result.get("count", 0)))
			return result.get("count", 0)
		return result
	return 0


# Unread count and the first limit notifications in one call — the cheapest way to refresh a mailbox badge and preview together.
func get_summary_async(limit: int = 10) -> Variant:
	if not _require_authenticated():
		return _auth_error()

	var result = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, _player_scoped_key("summary_l%d" % limit), func() -> Variant:
		var url := "%s/%s?limit=%d" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_SUMMARY, limit]
		var response = await FlockHttpClient.get_async(url, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		var summary: Dictionary = GenericResponseModels.get_result(response)
		if summary == null:
			return {"error": "Invalid response from server (missing summary)"}
		return summary
	, "Fetch notification summary")

	if result is Dictionary and not result.has("error"):
		_raise_new_notifications(result.get("items", []))
		_set_unread_count(int(result.get("unread_count", 0)))
	return result


# Marks a notification read straight from a list entry, so callers don't have to reach for the id.
func mark_read_async(notification: Variant) -> Variant:
	if notification is Dictionary:
		notification = str((notification as Dictionary).get("id", ""))
	require_not_empty(str(notification), "Notification ID")
	if not _require_authenticated():
		return _auth_error()

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.notification_read_by_id(str(notification))]
		var response = await FlockHttpClient.post_async(url, {}, _client.get_base_headers(), -1.0, true)
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	, "Mark notification read")


# Marks every unread notification read and returns how many changed. Unread is zero afterwards, so this raises unread_count_changed.
func mark_all_read_async() -> Variant:
	if not _require_authenticated():
		return _auth_error()

	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_READ_ALL]
		var response = await FlockHttpClient.post_async(url, {}, _client.get_base_headers(), -1.0, true)
		if response is Dictionary and response.has("error"):
			return response
		var data: Dictionary = GenericResponseModels.get_result(response)
		if data == null:
			return {"error": "Invalid response from server (missing result)"}
		return data
	, "Mark all notifications read")

	if result is Dictionary:
		if result.has("error"):
			return result
		_set_unread_count(0)
		return result.get("updated", 0)
	return result


# Registers this device for push. Credit the game with the token from the platform's messaging client and pass it
# here — the SDK can't obtain it itself on desktop or editor. Pass platform = -1 to detect it from the running build.
func register_device_token_async(token: String, platform: int = -1) -> Variant:
	require_not_empty(token, "Device Token")
	if not _require_authenticated():
		return _auth_error()

	if platform < 0:
		var detected = _current_device_platform()
		if detected.has("error"):
			return detected
		platform = detected["platform"]

	var request := {
		"platform": NotificationModels.platform_to_wire(platform),
		"token": token,
	}

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.DEVICE_TOKEN_REGISTER]
		var response = await FlockHttpClient.post_async(url, request, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	, "Register device token")


# Stops push going to this token. Returns whether the server deactivated one.
# Call this before logout() if the device is shared — logout is local-only by design and will not do it for you.
func unregister_device_token_async(token: String) -> Variant:
	require_not_empty(token, "Device Token")
	if not _require_authenticated():
		return _auth_error()

	var request := {"token": token}
	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.DEVICE_TOKEN_UNREGISTER]
		var response = await FlockHttpClient.post_async(url, request, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		var data: Dictionary = GenericResponseModels.get_result(response)
		if data == null:
			return {"error": "Invalid response from server (missing result)"}
		return data
	, "Unregister device token")

	if result is Dictionary:
		if result.has("error"):
			return result
		return result.get("deactivated", false)
	return false


# The API accepts android/ios/web only. Anything else is refused outright rather than mapped to a
# plausible-looking value — a token registered under the wrong platform fails silently at delivery time.
func _current_device_platform() -> Dictionary:
	match OS.get_name():
		"Android":
			return {"platform": NotificationModels.PLATFORM_ANDROID}
		"iOS":
			return {"platform": NotificationModels.PLATFORM_IOS}
		"Web":
			return {"platform": NotificationModels.PLATFORM_WEB}
		_:
			return {"error": "Push is not available on %s — the backend accepts android, ios and web only. Pass an explicit platform if you are supplying a token from elsewhere." % OS.get_name()}


# Every active template this game can schedule, name-ascending. Open to signed-out players — the catalog is game-scoped, not per-player.
func get_templates_async() -> Variant:
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "templates", func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_TEMPLATE]
		var response = await FlockHttpClient.get_async(url, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	, "Fetch notification templates")


# One active template by name. Open to signed-out players; memoized for the session after the first call.
# locale picks a specific localisation. Omitted, the server prefers English and falls back to the first locale on file.
func get_template_by_name_async(template_name: String, locale: String = "") -> Variant:
	require_not_empty(template_name, "Template Name")

	var memo_key := "%s|%s" % [template_name, locale]
	if _templates_by_name.has(memo_key):
		return _templates_by_name[memo_key]

	var template = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "template_name_%s_%s" % [template_name, locale], func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.notification_template_by_name(template_name, locale)]
		var response = await FlockHttpClient.get_async(url, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	, "Fetch notification template")

	if template is Dictionary and not str(template.get("id", "")).is_empty():
		_templates_by_name[memo_key] = template
	return template


# The template's id, for logging or a deep link. Scheduling takes the name — nothing in this provider consumes an id.
func resolve_template_id_async(template_name: String, locale: String = "") -> Variant:
	var template = await get_template_by_name_async(template_name, locale)
	if template is Dictionary:
		return template.get("id", "")
	return ""


# Schedules the template to arrive after delay_seconds — the shape most games want ("energy full in 4 hours").
func schedule_delayed_async(template_name: String, delay_seconds: float, variables: Dictionary = {}, channels: int = NotificationModels.CHANNEL_NONE, locale: String = "") -> Variant:
	return await schedule_async(template_name, _iso_utc(Time.get_unix_time_from_system() + delay_seconds), variables, channels, locale)


# Schedules a notification template to reach the signed-in player at deliver_at_utc (an ISO-8601 UTC timestamp).
# Keep the returned id to cancel; the SDK also tracks it locally, see get_pending_schedules().
func schedule_async(template_name: String, deliver_at_utc: String, variables: Dictionary = {}, channels: int = NotificationModels.CHANNEL_NONE, locale: String = "") -> Variant:
	require_not_empty(template_name, "Template Name")
	require_not_empty(deliver_at_utc, "Deliver-At")
	if not _require_authenticated():
		return _auth_error()

	# Resolved before the write, so a name this game doesn't have never leaves a schedule behind.
	var resolved = await _require_template_id_async(template_name, locale)
	if resolved is Dictionary:
		return resolved
	var template_id: String = str(resolved)

	var request := {
		"template_id": template_id,
		"deliver_at": deliver_at_utc,
	}
	if not variables.is_empty():
		request["variables"] = variables
	var wire_channels: Array = NotificationModels.channels_to_wire(channels)
	if not wire_channels.is_empty():
		request["channels"] = wire_channels

	var scheduled = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_SCHEDULE]
		var response = await FlockHttpClient.post_async(url, request, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	# Not idempotent: a re-sent schedule after an ambiguous failure creates a second reminder the game
	# can't cancel, because it only ever learns one scheduled id. Surface the failure instead.
	, "Schedule notification", false)

	if scheduled is Dictionary and not scheduled.has("error"):
		_track_pending(scheduled, template_name, template_id)
	return scheduled


# A name this game doesn't have is a caller mistake, not an empty result.
func _require_template_id_async(template_name: String, locale: String) -> Variant:
	var template_id: String = str(await resolve_template_id_async(template_name, locale))
	if template_id.is_empty():
		return {"error": "No notification template named '%s'" % template_name}
	return template_id


# Scheduled notifications this install created that haven't reached their delivery time yet.
# Local bookkeeping, not a server query: it only knows what THIS install scheduled, and it infers delivery from the
# clock. Prefer get_scheduled_async(), which asks the server and so survives a reinstall or a second device; this stays for offline reads.
func get_pending_schedules() -> Variant:
	if not _require_authenticated():
		return []
	return _load_pending_schedules()


# The player's scheduled notifications as the server knows them — unlike get_pending_schedules() this survives a
# reinstall and sees schedules made on another device. status defaults to pending.
func get_scheduled_async(status: String = NotificationModels.STATUS_PENDING, page: int = 1, limit: int = 100) -> Variant:
	if not _require_authenticated():
		return _auth_error()

	# Schedules change whenever one is created, cancelled or delivered — always read fresh, never cached.
	return await execute_async(func() -> Variant:
		var url := "%s/%s?page=%d&limit=%d" % [_client.get_versioned_api_url(), FlockEndpoints.NOTIFICATION_SCHEDULE, page, limit]
		if not status.is_empty():
			url += "&status=%s" % status.uri_encode()
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "List scheduled notifications")


# Cancels every pending schedule the player has and returns how many the server actually cancelled. Entries the
# server no longer recognises are dropped rather than failing the batch.
func cancel_all_scheduled_async() -> Variant:
	if not _require_authenticated():
		return _auth_error()

	var ids = await _resolve_cancellable_schedule_ids()
	if ids is Dictionary:
		return ids

	var cancelled := 0
	for id: String in ids:
		var result = await cancel_scheduled_async(id)
		if result is Dictionary and result.has("error"):
			# Already delivered, already cancelled, or unknown to the server — it isn't pending either way.
			if FlockException.FlockNetworkException.is_permanent_status(int(result.get("status_code", 0))):
				_untrack_pending(id)
			else:
				return result
		else:
			cancelled += 1
	return cancelled


# Server list is authoritative (it spans devices and installs); local bookkeeping is the offline fallback.
func _resolve_cancellable_schedule_ids() -> Variant:
	var pending = await get_scheduled_async(NotificationModels.STATUS_PENDING)
	if pending is Dictionary:
		if not pending.has("error") and pending.has("items"):
			var ids := []
			for entry: Dictionary in pending.get("items", []):
				var eid: String = str(entry.get("id", ""))
				if not eid.is_empty():
					ids.append(eid)
			return ids
		# Permanent client errors (auth, validation) aren't network trouble — propagate them rather than half-cancelling.
		var status := int(pending.get("status_code", 0))
		if status >= 400 and status < 500 and status != 408 and status != 429:
			return pending
	_client._logger.log_warning("Could not read scheduled notifications from the server; cancelling only what this install tracked.")

	var local_ids := []
	for entry: Dictionary in _load_pending_schedules():
		var pid: String = str(entry.get("id", ""))
		if not pid.is_empty():
			local_ids.append(pid)
	return local_ids


# Cancels the notification returned by schedule_async(), so callers can hold the object rather than its id.
func cancel_scheduled_async(scheduled: Variant) -> Variant:
	if scheduled is Dictionary:
		scheduled = str((scheduled as Dictionary).get("id", ""))
	require_not_empty(str(scheduled), "Scheduled Notification ID")
	if not _require_authenticated():
		return _auth_error()

	var cancelled = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.notification_schedule_by_id(str(scheduled))]
		var response = await FlockHttpClient.delete_async(url, _client.get_base_headers())
		if response is Dictionary and response.has("error"):
			return response
		return GenericResponseModels.get_result(response)
	, "Cancel scheduled notification", false)

	if cancelled is Dictionary and cancelled.has("error"):
		return cancelled
	_untrack_pending(str(scheduled))
	return cancelled


# --- local pending-schedule bookkeeping ---
# The id from schedule_async is the only handle on a pending reminder and /v1 has no route to list or read
# one back, so the SDK persists what it scheduled. Player-scoped: a second player on the same device must
# not see, or be able to cancel, the first player's reminders.

func _load_pending_schedules() -> Array:
	var stored = try_read_snapshot(SNAPSHOT_CATEGORY, _player_scoped_key(PENDING_SCHEDULES_KEY))
	if not stored is Array:
		return []

	# Delivery can only be inferred from the clock — nothing to query — so a passed entry stops being pending.
	var live := []
	for entry: Dictionary in stored:
		if not _has_elapsed(str(entry.get("deliver_at", ""))):
			live.append(entry)

	if live.size() != stored.size():
		_save_pending_schedules(live)
	return live


func _save_pending_schedules(pending: Array) -> void:
	write_snapshot(SNAPSHOT_CATEGORY, _player_scoped_key(PENDING_SCHEDULES_KEY), pending)


func _track_pending(scheduled: Dictionary, template_name: String, template_id: String) -> void:
	var scheduled_id: String = str(scheduled.get("id", ""))
	if scheduled_id.is_empty():
		return

	var pending := _load_pending_schedules()
	pending.append({
		"id": scheduled_id,
		"template_name": template_name,
		"template_id": template_id,
		"deliver_at": str(scheduled.get("deliver_at", "")),
	})
	_save_pending_schedules(pending)


func _untrack_pending(scheduled_id: String) -> void:
	var pending := _load_pending_schedules()
	for i in range(pending.size() - 1, -1, -1):
		if str((pending[i] as Dictionary).get("id", "")) == scheduled_id:
			pending.remove_at(i)
	_save_pending_schedules(pending)


# --- seen-watermark bookkeeping ---
# "Received" is fetch-derived: there is no realtime channel and the SDK never polls, so the watermark is
# what separates a notification the game has already been told about from a genuinely new one.

func _load_watermark() -> Dictionary:
	var stored = try_read_snapshot(SNAPSHOT_CATEGORY, _player_scoped_key(WATERMARK_KEY))
	if stored is Dictionary:
		return stored
	return {"seeded": false, "newest_created_at": ""}


func _save_watermark(mark: Dictionary) -> void:
	write_snapshot(SNAPSHOT_CATEGORY, _player_scoped_key(WATERMARK_KEY), mark)


# Raises once per notification newer than the watermark, oldest first. The first fetch for a player seeds
# silently — replaying a whole existing inbox as a burst of events is worse than not reporting its history.
func _raise_new_notifications(items: Variant) -> void:
	if not items is Array:
		return

	var mark := _load_watermark()
	var first_ever: bool = not bool(mark.get("seeded", false))

	var cutoff := -INF
	if not first_ever:
		var newest_str: String = str(mark.get("newest_created_at", ""))
		if not newest_str.is_empty():
			cutoff = _parse_utc(newest_str)

	var newest := cutoff
	var newest_raw := ""
	var fresh := []

	for entry: Variant in items:
		if not entry is Dictionary:
			continue
		var created := _parse_utc(str((entry as Dictionary).get("created_at", "")))
		# An unparseable created_at is skipped rather than announced — a duplicate is worse than a miss.
		if created == -INF:
			continue
		if created > newest:
			newest = created
			newest_raw = str((entry as Dictionary).get("created_at", ""))
		if not first_ever and created > cutoff:
			fresh.append(entry)

	# Persisted before anything is raised, so a handler that throws can't make the same one fire twice.
	if first_ever or newest > cutoff:
		mark["seeded"] = true
		if newest != -INF:
			mark["newest_created_at"] = newest_raw
		_save_watermark(mark)

	# The page arrives newest-first; walk back so handlers see them in the order they were created.
	for i in range(fresh.size() - 1, -1, -1):
		FlockEvents.get_instance().invoke_notification_received(fresh[i])


# Unparseable timestamps are kept rather than silently dropped — losing a cancellable id is the worse failure.
func _has_elapsed(deliver_at: String) -> bool:
	var parsed := _parse_utc(deliver_at)
	if parsed == -INF:
		return false
	return parsed <= Time.get_unix_time_from_system()


# Parses an ISO-8601 UTC timestamp into unix seconds; returns -INF when unparseable.
func _parse_utc(timestamp: String) -> float:
	var t := timestamp.strip_edges()
	if t.is_empty():
		return -INF

	var offset_seconds := 0.0
	if t.ends_with("Z") or t.ends_with("z"):
		t = t.substr(0, t.length() - 1)
	else:
		var t_index := t.find("T")
		var search_from := t_index + 1 if t_index != -1 else 10
		var zone_index := -1
		var zone_sign := 1.0
		for marker in ["+", "-"]:
			var idx := t.rfind(marker)
			if idx >= search_from and (zone_index == -1 or idx < zone_index):
				zone_index = idx
				zone_sign = -1.0 if marker == "-" else 1.0
		if zone_index != -1:
			var zone := t.substr(zone_index + 1)
			t = t.substr(0, zone_index)
			var parts := zone.split(":")
			var hours := float(parts[0]) if parts.size() > 0 else 0.0
			var minutes := float(parts[1]) if parts.size() > 1 else 0.0
			var seconds := float(parts[2]) if parts.size() > 2 else 0.0
			offset_seconds = (hours * 3600.0 + minutes * 60.0 + seconds) * zone_sign

	var dot := t.find(".")
	if dot != -1:
		t = t.substr(0, dot)
	t = t.replace("T", " ")
	if t.find(" ") == -1:
		t += " 00:00:00"

	var pieces := t.split(" ")
	if pieces.size() < 1:
		return -INF
	var date: PackedStringArray = pieces[0].split("-")
	if date.size() != 3:
		return -INF
	var time: PackedStringArray = pieces[1].split(":") if pieces.size() > 1 else PackedStringArray()
	if date[1].length() != 2 or date[2].length() != 2:
		return -INF

	var dict := {
		"year": int(date[0]),
		"month": int(date[1]),
		"day": int(date[2]),
		"hour": int(time[0]) if time.size() > 0 else 0,
		"minute": int(time[1]) if time.size() > 1 else 0,
		"second": int(time[2]) if time.size() > 2 else 0,
	}
	# get_unix_time_from_datetime_dict interprets the wall clock in local time; the backend timestamps are UTC,
	# so peel off the host's UTC-offset (bias, in minutes) to recover the UTC instant.
	var local_epoch: float = Time.get_unix_time_from_datetime_dict(dict)
	var bias: int = Time.get_time_zone_from_system().bias
	return local_epoch - offset_seconds - float(bias) * 60.0


# Formats unix seconds as an ISO-8601 UTC timestamp.
func _iso_utc(unix_seconds: float) -> String:
	var dict := Time.get_datetime_dict_from_unix_time(int(unix_seconds))
	return "%04d-%02d-%02dT%02d:%02d:%02d.%06dZ" % [dict.year, dict.month, dict.day, dict.hour, dict.minute, dict.second, dict.msec * 1000]


# Only fires when the number actually moves, so a repeated refresh doesn't spam a badge.
func _set_unread_count(count: int) -> void:
	if _last_unread_count == count:
		return
	_last_unread_count = count
	FlockEvents.get_instance().invoke_unread_count_changed(count)


# Bearer-only endpoints — fail fast instead of a guaranteed server 401.
func _require_authenticated() -> bool:
	if not _client.is_authenticated:
		push_error("[Flock SDK] No player is signed in")
		return false
	return true


func _auth_error() -> Dictionary:
	return {"error": "No player is signed in"}


# Player-scoped so one player's inbox can't be served to the next player on a shared device.
func _player_scoped_key(key: String) -> String:
	return "%s_%s" % [key, _client.current_player_id]