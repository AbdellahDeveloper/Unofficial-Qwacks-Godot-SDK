class_name FlockHttpRequest
extends RefCounted

var _timeout: float = 30.0

func _init(timeout: float = 30.0) -> void:
	_timeout = timeout


func get_async(url: String, headers: Dictionary = {}) -> Variant:
	return await _send_async("GET", url, headers, "")


func post_async(url: String, data: Dictionary = {}, headers: Dictionary = {}, force_json_body: bool = false) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ("{}" if force_json_body else "")
	return await _send_async("POST", url, headers, body)


func put_async(url: String, data: Dictionary = {}, headers: Dictionary = {}) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ""
	return await _send_async("PUT", url, headers, body)


func patch_async(url: String, data: Dictionary = {}, headers: Dictionary = {}) -> Variant:
	var body := JSON.stringify(data) if data.size() > 0 else ""
	return await _send_async("PATCH", url, headers, body)


func delete_async(url: String, headers: Dictionary = {}) -> Variant:
	return await _send_async("DELETE", url, headers, "")


# Enough field errors to spot the pattern without flooding the console line.
const MAX_FIELD_ERRORS_SHOWN := 3

# Two shapes share `detail`: the game routes' coded {code,message} object, and FastAPI's own 422 array of field errors.
func _parse_error_detail(body: String) -> Dictionary:
	var parsed = JSON.parse_string(body)
	if not parsed is Dictionary:
		return {}
	var detail = parsed.get("detail", null)
	if detail is Dictionary:
		return {"code": str(detail.get("code", "")), "message": str(detail.get("message", ""))}
	if detail is Array:
		return {"code": "", "message": _describe_field_errors(detail)}
	if detail is String and not detail.is_empty():
		return {"code": "", "message": detail}
	return {}


# "body.player_data: Input should be a valid dictionary" — names the offending field so the caller can fix the payload.
func _describe_field_errors(errors: Array) -> String:
	var parts: Array[String] = []
	var shown := 0
	for e in errors:
		if shown == MAX_FIELD_ERRORS_SHOWN:
			parts.append("(+%d more)" % (errors.size() - shown))
			break
		if not e is Dictionary:
			continue
		var why := str(e.get("msg", ""))
		if why.is_empty():
			continue
		var where := _join_location(e.get("loc", null))
		parts.append(why if where.is_empty() else "%s: %s" % [where, why])
		shown += 1
	return "; ".join(parts)


static func _join_location(location) -> String:
	if not location is Array or location.size() == 0:
		return ""
	var path := ""
	for part in location:
		if not path.is_empty():
			path += "."
		path += str(part)
	return path


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
			var detail := _parse_error_detail(body_text)
			var error_code: String = detail.get("code", "")
			var server_message: String = detail.get("message", "")
			var hint := FlockErrorHints.for_code(FlockErrorCodes.parse(error_code))

			# The server's reason beats our generic fallback whenever the body carried one.
			var fallback := "HTTP request failed"
			if response_code == 401 or response_code == 403:
				fallback = "Authentication failed"
			elif response_code == 400 or response_code == 422:
				fallback = "Validation failed"

			var error_dict := {
				"error": FlockErrorHints.compose("", server_message, error_code, response_code, hint, fallback),
				"status_code": response_code,
				"code": error_code,
				"body": body_text,
			}
			if not server_message.is_empty():
				error_dict["server_message"] = server_message
			if not hint.is_empty():
				error_dict["hint"] = hint

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
