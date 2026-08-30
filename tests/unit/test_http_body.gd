extends GutTest


func test_marker_error_detection() -> void:
	assert_true(FlockHttpRequest.is_marker_error({"code": null}), "code-null marker")
	assert_true(FlockHttpRequest.is_marker_error({"code": "", "message": ""}), "empty marker")
	assert_true(FlockHttpRequest.is_marker_error(null), "json null marker")
	assert_false(FlockHttpRequest.is_marker_error({"code": "player.x"}), "real code not marker")
	assert_false(FlockHttpRequest.is_marker_error({"message": "boom"}), "real message not marker")
	assert_false(FlockHttpRequest.is_marker_error("boom"), "string error not marker")
	assert_false(FlockHttpRequest.is_marker_error(42), "number error not marker")


func test_normalize_success_body_unwraps_envelope_to_result() -> void:
	var envelope := {
		"error": {"code": null},
		"response": {"message": null, "code": null},
		"result": {"id": "01M197TNVDZWPVZDR42HX2RXM5", "name": "Lowest_Time"},
	}
	var normalized = FlockHttpRequest.normalize_success_body(envelope)
	assert_true(normalized is Dictionary, "returns the result payload")
	assert_eq((normalized as Dictionary).get("name", ""), "Lowest_Time", "result member instead of the envelope wrapper")
	assert_false((normalized as Dictionary).has("error"), "no envelope error key leaked")
	assert_false((normalized as Dictionary).has("response"), "no envelope response key leaked")


func test_normalize_success_body_unwraps_array_result() -> void:
	var envelope := {"error": {"code": null}, "result": [{"tag": "achievement"}, {"tag": "currency"}]}
	var normalized = FlockHttpRequest.normalize_success_body(envelope)
	assert_true(normalized is Array, "array result unwrapped")
	assert_eq((normalized as Array).size(), 2, "payload size preserved")


func test_normalize_success_body_flat_passes_through() -> void:
	var flat := {"access_token": "abc", "player_id": "01P"}
	assert_eq(FlockHttpRequest.normalize_success_body(flat), flat, "flat auth body untouched")
	assert_eq(FlockHttpRequest.normalize_success_body(null), null, "null untouched")
	var real_error := {"error": "boom", "status_code": 401}
	assert_eq(FlockHttpRequest.normalize_success_body(real_error), real_error, "non-2xx style error dict untouched")