class_name FlockNullAnalytics
extends RefCounted

var _client: FlockClient

func _init(client: FlockClient) -> void:
	_client = client


func initialize_async() -> Variant:
	return {}


func start_session_async() -> Variant:
	return {}


func end_session_async() -> Variant:
	return {}


func log_exception(_exception: String) -> void:
	pass


func log_error(_message: String, _error_code: String = "") -> void:
	pass


func log_event(_event_name: String, _properties: Dictionary = {}) -> void:
	pass


func flush_async() -> Variant:
	return {}


func record_transaction_async(_transaction: Dictionary) -> Variant:
	return {}


func record_screen_view(_screen_name: String) -> void:
	pass


func set_consent(_granted: bool) -> void:
	pass


func erase_local_analytics_data() -> void:
	pass


func handle_auth_cleared() -> void:
	pass


func uninstall_global_exception_hook() -> void:
	pass
