class_name FlockBootstrap
extends Node

## Emitted when SDK initialization completes
signal sdk_initialized
## Emitted when SDK initialization fails
signal sdk_initialization_failed(error: String)
## Emitted when player authenticates
signal player_authenticated(player_id: String)
## Emitted when session expires
signal session_expired

@export var game_id: String = ""
@export var game_version_id: String = ""
@export var api_url: String = "https://api.flock.io"
@export var offline_cache_enabled: bool = true
@export var analytics_enabled: bool = true
@export var enable_debug_logs: bool = false

var _initialized := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Connect to SDK events
	FlockEvents.get_instance().initialized.connect(_on_initialized)
	FlockEvents.get_instance().initialization_failed.connect(_on_initialization_failed)
	FlockEvents.get_instance().authenticated.connect(_on_authenticated)
	FlockEvents.get_instance().auth_expired.connect(_on_session_expired)


func initialize(config: FlockInitConfig = null) -> void:
	if _initialized:
		push_warning("[Flock SDK] Already initialized")
		return

	if config == null:
		config = FlockInitConfig.new()
		config.game_id = game_id
		config.game_version_id = game_version_id
		config.api_url = api_url
		config.enable_offline_cache = offline_cache_enabled
		config.analytics_config = {
			"enabled": analytics_enabled,
			"auto_start_session": true,
		}
		config.enable_debug_logs = enable_debug_logs

	FlockClient.get_instance().create(config)


func login_with_device_async() -> Variant:
	if not FlockClient.is_initialized:
		return {"error": "SDK not initialized"}
	return await FlockClient.get_instance().auth.login_with_device("")


func login_with_email_async(email: String, password: String) -> Variant:
	if not FlockClient.is_initialized:
		return {"error": "SDK not initialized"}
	return await FlockClient.get_instance().auth.login_with_email(email, password)


func register_with_email_async(email: String, password: String, username: String = "") -> Variant:
	if not FlockClient.is_initialized:
		return {"error": "SDK not initialized"}
	return await FlockClient.get_instance().auth.register_with_email(email, password, username)


func logout() -> void:
	if FlockClient.is_initialized:
		FlockClient.get_instance().clear_tokens()


func _on_initialized() -> void:
	_initialized = true
	sdk_initialized.emit()
	print("[Flock SDK] Initialized successfully")


func _on_initialization_failed(error: String) -> void:
	sdk_initialization_failed.emit(error)
	push_error("[Flock SDK] Initialization failed: " + error)


func _on_authenticated(player_id: String) -> void:
	player_authenticated.emit(player_id)


func _on_session_expired() -> void:
	session_expired.emit()
