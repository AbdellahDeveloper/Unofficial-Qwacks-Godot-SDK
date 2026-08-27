class_name FlockProviderBase
extends RefCounted

var _client: FlockClient

func _init(client: FlockClient) -> void:
	_client = client


func execute_async(operation: Callable, context: String = "", retry_ambiguous: bool = true, max_retries_override: int = -1) -> Variant:
	var retry_handler := RetryPolicy.RetryHandler.new(
		_client._init_config.retry_policy if _client._init_config.retry_policy.size() > 0 else null,
		_client._logger
	)
	var result = await retry_handler.execute_async(operation, retry_ambiguous, max_retries_override)
	return result


func require_not_empty(value: String, name: String) -> void:
	if value.is_empty():
		push_error("[Flock SDK] %s cannot be null or empty" % name)


func validate_response(response: Dictionary) -> bool:
	if response.is_empty() or not response.has("result") or response["result"] == null:
		push_error("[Flock SDK] Invalid response from server")
		return false
	return true


func get_snapshot_scope(category: String) -> String:
	return "%s/%s" % [_client.game_version_id, category]


func delete_snapshot_category(category: String) -> void:
	if _client._snapshot_store:
		_client._snapshot_store.delete_scope(get_snapshot_scope(category))


func delete_snapshot_category_except(category: String, keep_key_prefixes: Array) -> void:
	if _client._snapshot_store:
		_client._snapshot_store.delete_scope_except(get_snapshot_scope(category), keep_key_prefixes)


func try_read_snapshot(category: String, key: String) -> Variant:
	if _client._snapshot_store == null:
		return null
	return _client._snapshot_store.try_read(get_snapshot_scope(category), key)


func write_snapshot(category: String, key: String, value: Variant) -> void:
	if _client._snapshot_store:
		_client._snapshot_store.write(get_snapshot_scope(category), key, value)


func fetch_with_snapshot_async(category: String, key: String, operation: Callable, context: String) -> Variant:
	var scope := get_snapshot_scope(category)
	var cached = try_read_snapshot(category, key)

	# No connection and cached — serve from cache
	if cached != null and not _client.is_reachable():
		_client._logger.log_warning("%s: serving cached snapshot (no connectivity)" % context)
		return cached

	# Try network with limited retries if we have cache
	var retry_budget := 0 if cached != null else -1
	var result = await execute_async(operation, context, true, retry_budget)

	if result is Dictionary and result.has("error"):
		if cached != null:
			_client._logger.log_warning("%s: serving cached snapshot (couldn't reach server)" % context)
			return cached
		return result

	write_snapshot(category, key, result)
	return result


func is_server_reachable() -> bool:
	return _client.is_reachable()
