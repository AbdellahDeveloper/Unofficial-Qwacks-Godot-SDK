class_name FlockHttpClient

static var _default_timeout: float = 30.0
# Single static listener: the transport reports whether a request actually reached the server so
# desktop builds (where OS.has_feature("online") is meaningless) don't treat every write as offline.
static var _outcome_listener: Callable = Callable()

static func configure(timeout: float) -> void:
	_default_timeout = timeout

static func set_outcome_listener(callable: Callable) -> void:
	_outcome_listener = callable

static func _report_outcome(reachable: bool) -> void:
	if _outcome_listener.is_valid():
		_outcome_listener.call(reachable)


static func get_async(url: String, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.get_async(url, headers)


static func post_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0, force_json_body: bool = false) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.post_async(url, data, headers, force_json_body)


static func put_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.put_async(url, data, headers)


static func patch_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.patch_async(url, data, headers)


static func delete_async(url: String, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.delete_async(url, headers)
