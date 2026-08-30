extends GutTest


func test_marker_error_detection() -> void:
	assert_true(FlockHttpRequest.is_marker_error({"code": null}), "code-null marker")
	assert_true(FlockHttpRequest.is_marker_error({"code": "", "message": ""}), "empty marker")
	assert_true(FlockHttpRequest.is_marker_error(null), "json null marker")
	assert_false(FlockHttpRequest.is_marker_error({"code": "player.x"}), "real code not marker")
	assert_false(FlockHttpRequest.is_marker_error({"message": "boom"}), "real message not marker")
	assert_false(FlockHttpRequest.is_marker_error("boom"), "string error not marker")
	assert_false(FlockHttpRequest.is_marker_error(42), "number error not marker")


func test_normalize_success_body_drops_marker_error_keeps_result() -> void:
	var envelope := {
		"error": {"code": null},
		"response": {"message": null, "code": null},
		"result": {"id": "01M197TNVDZWPVZDR42HX2RXM5", "name": "Lowest_Time"},
	}
	var normalized = FlockHttpRequest.normalize_success_body(envelope)
	assert_true(normalized is Dictionary, "returns dictionary")
	assert_false((normalized as Dictionary).has("error"), "marker error dropped")
	assert_eq((normalized as Dictionary).get("result", {}).get("name", ""), "Lowest_Time", "result preserved for get_result downstream")


func test_normalize_success_body_flat_passes_through() -> void:
	var flat := {"access_token": "abc", "player_id": "01P"}
	assert_eq(FlockHttpRequest.normalize_success_body(flat), flat, "flat auth body untouched")
	assert_eq(FlockHttpRequest.normalize_success_body(null), null, "null untouched")
	var real_error := {"error": "boom", "status_code": 401}
	assert_eq(FlockHttpRequest.normalize_success_body(real_error), real_error, "non-2xx style error dict untouched")