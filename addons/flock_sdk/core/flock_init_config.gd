class_name FlockInitConfig
extends RefCounted

var api_url: String = ""
var api_key: String = ""
var game_id: String = ""
var game_version: String = ""
var game_version_id: String = ""
var enable_debug_logs: bool = false
var enable_asset_cache: bool = true
var asset_cache_directory: String = ""
var asset_cache_max_size_mb: int = 100
var asset_download_timeout: float = 0.0
var asset_download_retry_count: int = 3
var asset_max_concurrent_downloads: int = 4
var enable_offline_cache: bool = true
var offline_cache_directory: String = ""
var http_timeout: float = 30.0
var analytics_config: Dictionary = {}
var retry_policy: Dictionary = {}
var token_store: RefCounted = null


func get_base_headers() -> Dictionary:
	var headers := {
		"X-Flock-API-Key": api_key,
		"X-Game-Version-ID": game_version_id,
	}
	return headers
