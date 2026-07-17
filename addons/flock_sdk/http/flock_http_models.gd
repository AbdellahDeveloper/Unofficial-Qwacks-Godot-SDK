class_name FlockHttpModels


class FlockHttpRequestParams:
	var method: String = "GET"
	var url: String = ""
	var headers: Dictionary = {}
	var body: Variant = null
	var timeout: float = 30.0

	func _init(p_method: String = "GET", p_url: String = "", p_headers: Dictionary = {}, p_body: Variant = null, p_timeout: float = 30.0) -> void:
		method = p_method
		url = p_url
		headers = p_headers
		body = p_body
		timeout = p_timeout


class FlockHttpResponse:
	var success: bool = false
	var status_code: int = 0
	var body: String = ""
	var parsed: Variant = null
	var error: String = ""

	func is_ok() -> bool:
		return success and status_code >= 200 and status_code < 300

	func has_http_error() -> bool:
		return not error.is_empty()

	static func ok(p_status_code: int, p_parsed: Variant = null) -> FlockHttpResponse:
		var resp := FlockHttpResponse.new()
		resp.success = true
		resp.status_code = p_status_code
		resp.parsed = p_parsed
		return resp

	static func fail(p_status_code: int, p_error: String, p_body: String = "") -> FlockHttpResponse:
		var resp := FlockHttpResponse.new()
		resp.success = false
		resp.status_code = p_status_code
		resp.error = p_error
		resp.body = p_body
		return resp

	static func network_error(p_error: String) -> FlockHttpResponse:
		var resp := FlockHttpResponse.new()
		resp.success = false
		resp.error = p_error
		return resp


class FlockApiError:
	var code: String = ""
	var message: String = ""
	var status_code: int = 0

	func _init(p_code: String = "", p_message: String = "", p_status_code: int = 0) -> void:
		code = p_code
		message = p_message
		status_code = p_status_code

	func is_permanent() -> bool:
		if status_code == 408 or status_code == 429:
			return false
		return status_code >= 400 and status_code < 500

	static func from_response(response_body: String, p_status_code: int) -> FlockApiError:
		var parsed = JSON.parse_string(response_body)
		if parsed is Dictionary and parsed.has("detail"):
			var detail: Dictionary = parsed["detail"]
			return FlockApiError.new(detail.get("code", ""), detail.get("message", ""), p_status_code)
		return FlockApiError.new("", "HTTP %d" % p_status_code, p_status_code)
