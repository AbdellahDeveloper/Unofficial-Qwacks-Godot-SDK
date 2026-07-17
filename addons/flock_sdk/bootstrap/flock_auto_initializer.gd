class_name FlockAutoInitializer
extends Node

## Auto-initializes Flock SDK on startup
## Add this as an autoload or to the root scene

@export var game_id: String = ""
@export var game_version_id: String = ""
@export var api_url: String = "https://api-flock.qwacks.com"
@export var api_key: String = ""
@export var offline_cache_enabled: bool = true
@export var analytics_enabled: bool = true
@export var enable_debug_logs: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_initialize_sdk")


func _initialize_sdk() -> void:
	var config := FlockInitConfig.new()
	config.game_id = game_id
	config.game_version_id = game_version_id
	config.api_url = api_url
	config.api_key = api_key
	config.enable_offline_cache = offline_cache_enabled
	config.analytics_config = {
		"enabled": analytics_enabled,
		"auto_start_session": true,
	}
	config.enable_debug_logs = enable_debug_logs

	FlockClient.get_instance().create(config)
