class_name FlockEvents
extends Node

static var _instance: FlockEvents = null

func _init() -> void:
	_instance = self

static func get_instance() -> FlockEvents:
	return _instance

signal initialized
signal initialization_failed(error: String)
signal shutdown
signal authenticated(info: Dictionary)
signal token_refreshed
signal auth_expired
signal logged_out
signal session_restored(restored: bool)
signal session_started(session_id: String)
signal session_ended(args: Dictionary)
signal session_paused
signal session_resumed
signal consent_changed(granted: bool)

var _logger: RefCounted = null
var _late_initialized: bool = false
var _late_init_error: String = ""

# Track internal SDK connections so clear_all() doesn't destroy user connections
var _internal_connections: Array[Dictionary] = []


func track_internal_connection(sig_name: String, callable: Callable) -> void:
	if not has_signal(sig_name):
		return
	connect(sig_name, callable)
	_internal_connections.append({"signal": sig_name, "callable": callable})


func invoke_initialized() -> void:
	_late_initialized = true
	_late_init_error = ""
	initialized.emit()
	if _logger:
		_logger.log_debug("OnInitialized fired")


func invoke_initialization_failed(error: String) -> void:
	_late_init_error = error
	initialization_failed.emit(error)
	if _logger:
		_logger.log_debug("OnInitializationFailed fired")


func invoke_shutdown() -> void:
	shutdown.emit()
	if _logger:
		_logger.log_debug("OnShutdown fired")


func invoke_authenticated(info: Dictionary) -> void:
	authenticated.emit(info)
	if _logger:
		_logger.log_debug("OnAuthenticated fired -> %s" % str(info))


func invoke_token_refreshed() -> void:
	token_refreshed.emit()
	if _logger:
		_logger.log_debug("OnTokenRefreshed fired")


func invoke_auth_expired() -> void:
	auth_expired.emit()
	if _logger:
		_logger.log_debug("OnAuthExpired fired")


func invoke_logged_out() -> void:
	logged_out.emit()
	if _logger:
		_logger.log_debug("OnLoggedOut fired")


func invoke_session_restored(restored: bool) -> void:
	session_restored.emit(restored)
	if _logger:
		_logger.log_debug("OnSessionRestored fired -> %s" % str(restored))


func invoke_session_started(session_id: String) -> void:
	session_started.emit(session_id)
	if _logger:
		_logger.log_debug("OnSessionStarted fired -> %s" % session_id)


func invoke_session_ended(args: Dictionary) -> void:
	session_ended.emit(args)
	if _logger:
		_logger.log_debug("OnSessionEnded fired")


func invoke_session_paused() -> void:
	session_paused.emit()
	if _logger:
		_logger.log_debug("OnSessionPaused fired")


func invoke_session_resumed() -> void:
	session_resumed.emit()
	if _logger:
		_logger.log_debug("OnSessionResumed fired")


func invoke_consent_changed(granted: bool) -> void:
	consent_changed.emit(granted)
	if _logger:
		_logger.log_debug("OnConsentChanged fired -> %s" % str(granted))


func clear_all() -> void:
	_late_initialized = false
	_late_init_error = ""
	# Only disconnect connections the SDK tracked internally
	for conn: Dictionary in _internal_connections:
		var sig_name: String = conn["signal"]
		var callable: Callable = conn["callable"]
		if has_signal(sig_name) and callable.is_valid() and is_connected(sig_name, callable):
			disconnect(sig_name, callable)
	_internal_connections.clear()
