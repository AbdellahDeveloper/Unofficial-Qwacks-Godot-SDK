class_name GenericResponseModels

static func get_result(response: Dictionary) -> Variant:
	if response.has("result"):
		return response["result"]
	return null

static func has_error(response: Dictionary) -> bool:
	return response.has("error") and response["error"] != null

static func get_error_code(response: Dictionary) -> String:
	if has_error(response):
		return response.get("code", "")
	return ""

static func parse_coded_error(response_body: String) -> Dictionary:
	var parsed = JSON.parse_string(response_body)
	if parsed is Dictionary and parsed.has("detail"):
		var detail: Dictionary = parsed["detail"]
		return {"code": detail.get("code", ""), "message": detail.get("message", "")}
	return {}
