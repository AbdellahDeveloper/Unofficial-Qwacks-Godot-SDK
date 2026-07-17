class_name FlockHttpClient

static var _default_timeout: float = 30.0

static func configure(timeout: float) -> void:
	_default_timeout = timeout


static func get_async(url: String, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.get_async(url, headers)


static func post_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.post_async(url, data, headers)


static func put_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.put_async(url, data, headers)


static func patch_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.patch_async(url, data, headers)


static func delete_async(url: String, headers: Dictionary = {}, timeout: float = -1.0) -> Variant:
	var http := FlockHttpRequest.new(timeout if timeout > 0 else _default_timeout)
	return await http.delete_async(url, headers)
