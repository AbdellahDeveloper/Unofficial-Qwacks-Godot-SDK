class_name FlockCommandProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "command"
const PENDING_WRITES_KEY := "pending_writes"

var _pending_writes: Array = []
var _queue_loaded := false
var _queue_player_id: String = ""
var _flush_triggers_hooked := false
var _was_reachable := true
var _flush_in_flight := false
var _flush_timer: Timer = null

func _init(client: FlockClient) -> void:
	super(client)


func subscribe_flush_triggers() -> void:
	if _flush_triggers_hooked:
		return
	_flush_triggers_hooked = true
	_was_reachable = is_server_reachable()
	# Start periodic flush timer — checks every 30s for pending writes
	_flush_timer = Timer.new()
	_flush_timer.wait_time = 30.0
	_flush_timer.autostart = true
	_flush_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_flush_timer.timeout.connect(_on_flush_timer)
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(_flush_timer)


func unsubscribe_flush_triggers() -> void:
	_flush_triggers_hooked = false
	if _flush_timer:
		_flush_timer.stop()
		if _flush_timer.get_parent():
			_flush_timer.get_parent().remove_child(_flush_timer)
		_flush_timer.queue_free()
		_flush_timer = null


func _on_flush_timer() -> void:
	if _pending_writes.is_empty():
		return
	var now_reachable := is_server_reachable()
	if now_reachable and not _was_reachable:
		# Just came back online — flush
		flush_pending_writes_async()
	_was_reachable = now_reachable


func flush_on_quit() -> void:
	if _pending_writes.is_empty() or not is_server_reachable():
		return
	# Synchronous-ish: queue flush and let the caller await it
	flush_pending_writes_async()


func flush_pending_writes_async() -> void:
	if _flush_in_flight:
		return
	_flush_in_flight = true

	_ensure_queue_loaded()
	if _pending_writes.is_empty() or not is_server_reachable():
		_flush_in_flight = false
		return

	while not _pending_writes.is_empty():
		var write: PendingDataWrite = _pending_writes[0]
		var payload = JSON.parse_string(write.payload_json) if not write.payload_json.is_empty() else {}
		var result = await execute_async(func() -> Variant:
			var url := "%s/%s" % [_client.get_versioned_api_url(), write.path]
			return await FlockHttpClient.post_async(url, payload, _client.get_base_headers())
		, write.context)

		if result is Dictionary and result.has("error"):
			_flush_in_flight = false
			return

		_pending_writes.pop_front()
		_persist_queue()
		_apply_to_player_cache(result)

	_flush_in_flight = false


func update_player_data_async(player_data_id: String, data: Array) -> Variant:
	require_not_empty(player_data_id, "Player Data ID")
	var flat_data := TypedSchemaModels.to_flat_object(data)
	var request := GameCommandModels.update_player_data_input(player_data_id, flat_data)

	if not is_server_reachable():
		return _enqueue_offline(FlockEndpoints.COMMAND_UPDATE_PLAYER_DATA, request, "Update player data")

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.COMMAND_UPDATE_PLAYER_DATA]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Update player data")


func update_player_data_field_async(player_data_id: String, key: String, value: Variant) -> Variant:
	require_not_empty(player_data_id, "Player Data ID")
	require_not_empty(key, "Key")
	var request := GameCommandModels.update_player_data_key_input(player_data_id, key, value)

	if not is_server_reachable():
		return _enqueue_offline(FlockEndpoints.COMMAND_UPDATE_PLAYER_DATA_KEY, request, "Update player data field")

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.COMMAND_UPDATE_PLAYER_DATA_KEY]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Update player data field")


func add_game_funds_async(currency: String, amount: int) -> Variant:
	require_not_empty(currency, "Currency")
	var template = await _client.player.get_template_by_tag_async("currency")
	if template.is_empty():
		return {"error": "No currency template found"}
	return await _add_game_funds_with_template(currency, amount, template.get("id", ""))


func _add_game_funds_with_template(currency: String, amount: int, template_id: String) -> Variant:
	require_not_empty(template_id, "Currency Template ID")
	var wallet = await _client.player.get_my_data_by_template_async(template_id)
	if wallet == null or wallet.is_empty():
		return {"error": "No currency wallet found for the current player"}

	if not is_server_reachable():
		return {"error": "Add game funds requires a network connection"}

	var request := GameCommandModels.add_game_funds_input(wallet.get("id", ""), currency, amount)
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.COMMAND_ADD_GAME_FUNDS]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Add game funds", false)


func unlock_achievement_async(achievement_name: String) -> Variant:
	require_not_empty(achievement_name, "Achievement Name")
	var row = await _client.player.get_my_data_by_tag_async("achievement")
	if row == null or (row is Dictionary and row.is_empty()):
		return {"error": "No achievements data found for the current player"}

	var request := GameCommandModels.unlock_achievement_input(row.get("id", ""), achievement_name)

	if not is_server_reachable():
		return _enqueue_offline(FlockEndpoints.COMMAND_UNLOCK_ACHIEVEMENT, request, "Unlock achievement")

	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.COMMAND_UNLOCK_ACHIEVEMENT]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Unlock achievement")


func _enqueue_offline(path: String, payload: Dictionary, context: String) -> Dictionary:
	_ensure_queue_loaded()
	var write := PendingDataWrite.new(path, JSON.stringify(payload), context)
	_pending_writes.append(write)
	_persist_queue()
	_client._logger.log_warning("%s: offline — queued for sync on reconnect" % context)
	return {"offline": true, "queued": true}


func _ensure_queue_loaded() -> void:
	var player_id := _client.current_player_id
	if _queue_loaded and _queue_player_id == player_id:
		return
	_queue_loaded = true
	_queue_player_id = player_id
	_pending_writes = []
	if _client._snapshot_store:
		var saved = _client._snapshot_store.try_read(_get_queue_scope(), PENDING_WRITES_KEY)
		if saved is Array:
			for item in saved:
				_pending_writes.append(PendingDataWrite.deserialize(item))


func _persist_queue() -> void:
	if _client._snapshot_store:
		var serialized := []
		for write: PendingDataWrite in _pending_writes:
			serialized.append(write.serialize())
		_client._snapshot_store.write(_get_queue_scope(), PENDING_WRITES_KEY, serialized)


func _get_queue_scope() -> String:
	return "%s/%s/%s" % [_client.game_version_id, SNAPSHOT_CATEGORY, _queue_player_id]


func _apply_to_player_cache(data: Variant) -> Variant:
	if data is Dictionary and _client.player:
		_client.player.apply_server_player_data(data)
	return data
