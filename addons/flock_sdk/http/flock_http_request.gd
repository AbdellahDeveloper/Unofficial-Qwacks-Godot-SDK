class_name FlockHttpRequest
extends RefCounted

var _timeout: float = 30.0

func _init(timeout: float = 30.0) -> void:
	_timeout = timeout


func get_async(url: String, headers: Dictionary = {}) -> Variant:
	return await _send_async("GET", url, headers, "")


func post_async(url: String, data: Dictionary = {}, headers: Dictionary = {}) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ""
	return await _send_async("POST", url, headers, body)


func put_async(url: String, data: Dictionary = {}, headers: Dictionary = {}) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ""
	return await _send_async("PUT", url, headers, body)


func patch_async(url: String, data: Dictionary = {}, headers: Dictionary = {}) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ""
	return await _send_async("PATCH", url, headers, body)


func delete_async(url: String, headers: Dictionary = {}) -> Variant:
	return await _send_async("DELETE", url, headers, "")


func _send_async(method: String, url: String, headers: Dictionary, body: String) -> Variant:
	var http_request := HTTPRequest.new()
	http_request.timeout = _timeout if _timeout > 0 else 0

	# HTTPRequest must be in the scene tree for request_completed to fire
	var tree := Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		tree.root.add_child(http_request)

	# Add custom headers
	var header_array: PackedStringArray = ["Content-Type: application/json"]
	for key in headers:
		if headers[key] != null and str(headers[key]) != "":
			header_array.append("%s: %s" % [key, str(headers[key])])

	http_request.request(url, header_array, _method_to_http(method), body if not body.is_empty() else "")

	# Wait for completion
	var result: Array = await http_request.request_completed

	# Clean up node from tree
	if http_request.get_parent():
		http_request.get_parent().remove_child(http_request)
	http_request.queue_free()

	var response_code_http: int = result[0]
	var response_code: int = result[1]
	var _response_headers: PackedStringArray = result[2]
	var response_body: PackedByteArray = result[3]

	var body_text := response_body.get_string_from_utf8()

	# Check for transport errors
	if response_code_http == HTTPRequest.RESULT_SUCCESS:
		if response_code >= 200 and response_code < 300:
			if body_text.is_empty():
				return {}
			var parsed = JSON.parse_string(body_text)
			if parsed == null:
				return {"error": "Failed to parse response JSON"}
			return parsed
		else:
			var error_code := ""
			var parsed_body = JSON.parse_string(body_text)
			if parsed_body is Dictionary and parsed_body.has("detail"):
				var detail = parsed_body["detail"]
				if detail is Dictionary:
					error_code = detail.get("code", "")

			var error_dict := {
				"error": "HTTP %d" % response_code,
				"status_code": response_code,
				"code": error_code,
				"body": body_text,
			}

			if response_code == 401 or response_code == 403:
				error_dict["error"] = "Authentication failed (HTTP %d)" % response_code
			elif response_code == 400 or response_code == 422:
				error_dict["error"] = "Validation failed (HTTP %d)" % response_code

			return error_dict
	else:
		return {"error": "Request failed with code: %d" % response_code_http}


func _method_to_http(method: String) -> int:
	match method.to_upper():
		"GET": return HTTPClient.METHOD_GET
		"POST": return HTTPClient.METHOD_POST
		"PUT": return HTTPClient.METHOD_PUT
		"PATCH": return HTTPClient.METHOD_PATCH
		"DELETE": return HTTPClient.METHOD_DELETE
		_: return HTTPClient.METHOD_GET
