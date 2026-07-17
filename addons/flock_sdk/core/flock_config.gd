class_name FlockConfig
extends RefCounted

var api_url: String = "https://api-flock.qwacks.com"
var api_key: String = ""
var game_id: String = ""
var game_version: String = ""
var game_version_id: String = ""
var enable_debug_logs: bool = false
var analytics_enabled: bool = true
var analytics_auto_start_session: bool = true
var analytics_auto_end_on_quit: bool = true
var analytics_session_timeout: float = 30.0
var analytics_heartbeat_interval: float = 60.0
var analytics_bounce_threshold: float = 10.0
var analytics_persist_session: bool = true
var analytics_track_fps: bool = true
var analytics_fps_sample_interval: float = 1.0
var analytics_require_explicit_consent: bool = false
var analytics_cache_failed_events: bool = true
var analytics_max_cached_events: int = 1000
var analytics_cache_flush_batch_size: int = 50
var analytics_event_buffer_flush_interval: float = 10.0
var enable_asset_cache: bool = true
var asset_cache_directory: String = ""
var asset_cache_max_size_mb: int = 100
var asset_download_timeout_seconds: int = 0
var asset_download_retry_count: int = 3
var asset_max_concurrent_downloads: int = 4
var enable_offline_cache: bool = true
var offline_cache_directory: String = ""
var retry_max_retries: int = 3
var retry_use_jitter: bool = true
var http_timeout_seconds: float = 30.0


func to_init_config() -> FlockInitConfig:
	var analytics_config := {
		"enabled": analytics_enabled,
		"auto_start_session": analytics_auto_start_session,
		"auto_end_session_on_quit": analytics_auto_end_on_quit,
		"session_timeout_seconds": analytics_session_timeout,
		"heartbeat_interval_seconds": analytics_heartbeat_interval,
		"bounce_threshold_seconds": analytics_bounce_threshold,
		"persist_session_on_disk": analytics_persist_session,
		"track_fps": analytics_track_fps,
		"fps_sample_interval_seconds": analytics_fps_sample_interval,
		"require_explicit_consent": analytics_require_explicit_consent,
		"cache_failed_events": analytics_cache_failed_events,
		"max_cached_events": analytics_max_cached_events,
		"cache_flush_batch_size": analytics_cache_flush_batch_size,
		"event_buffer_flush_interval_seconds": analytics_event_buffer_flush_interval,
	}

	var retry_policy := {
		"max_retries": retry_max_retries,
		"use_jitter": retry_use_jitter,
	}

	var config := FlockInitConfig.new()
	config.api_url = api_url.strip_edges()
	config.api_key = api_key
	config.game_id = game_id
	config.game_version = game_version
	config.game_version_id = game_version_id
	config.enable_debug_logs = enable_debug_logs
	config.analytics_config = analytics_config
	config.retry_policy = retry_policy
	config.enable_asset_cache = enable_asset_cache
	config.asset_cache_directory = asset_cache_directory
	config.asset_cache_max_size_mb = asset_cache_max_size_mb
	config.asset_download_timeout = asset_download_timeout_seconds
	config.asset_download_retry_count = asset_download_retry_count
	config.asset_max_concurrent_downloads = asset_max_concurrent_downloads
	config.enable_offline_cache = enable_offline_cache
	config.offline_cache_directory = offline_cache_directory
	config.http_timeout = http_timeout_seconds
	return config


func is_valid() -> Dictionary:
	if api_url.is_empty():
		return {"valid": false, "error": "API URL is required"}
	if api_key.is_empty():
		return {"valid": false, "error": "API Key is required"}
	if game_id.is_empty():
		return {"valid": false, "error": "Game Name is required"}
	if game_version.is_empty():
		return {"valid": false, "error": "Game Version is required"}
	return {"valid": true, "error": ""}
