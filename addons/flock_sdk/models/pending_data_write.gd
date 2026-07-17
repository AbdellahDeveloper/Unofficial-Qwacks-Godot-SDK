class_name PendingDataWrite
extends RefCounted

var path: String = ""
var payload_json: String = ""
var context: String = ""

func _init(p_path: String = "", p_payload: String = "", p_context: String = "") -> void:
	path = p_path
	payload_json = p_payload
	context = p_context

func serialize() -> Dictionary:
	return {
		"path": path,
		"payload_json": payload_json,
		"context": context,
	}

static func deserialize(data: Dictionary) -> PendingDataWrite:
	return PendingDataWrite.new(
		data.get("path", ""),
		data.get("payload_json", ""),
		data.get("context", "")
	)
