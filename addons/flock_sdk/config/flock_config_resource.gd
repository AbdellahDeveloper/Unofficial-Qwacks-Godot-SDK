@tool
class_name FlockConfigResource
extends Resource

@export var api_url: String = "https://api-flock.qwacks.com"
@export var api_key: String = ""
@export var game_id: String = ""
@export var game_version: String = ""
@export var game_version_id: String = ""
@export var enable_debug_logs: bool = false

@export_group("Analytics")
@export var analytics_enabled: bool = true
@export var analytics_auto_start_session: bool = true
@export var analytics_auto_end_on_quit: bool = true
@export var analytics_session_timeout: float = 30.0
@export var analytics_heartbeat_interval: float = 60.0
@export var analytics_bounce_threshold: float = 10.0
@export var analytics_persist_session: bool = true
@export var analytics_track_fps: bool = true
@export var analytics_fps_sample_interval: float = 1.0
@export var analytics_require_explicit_consent: bool = false
@export var analytics_cache_failed_events: bool = true
@export var analytics_max_cached_events: int = 1000
@export var analytics_cache_flush_batch_size: int = 50
@export var analytics_event_buffer_flush_interval: float = 10.0

@export_group("Asset Cache")
@export var enable_asset_cache: bool = true
@export var asset_cache_directory: String = ""
@export var asset_cache_max_size_mb: int = 100
@export var asset_download_timeout_seconds: int = 0
@export var asset_download_retry_count: int = 3
@export var asset_max_concurrent_downloads: int = 4

@export_group("Offline Cache")
@export var enable_offline_cache: bool = true
@export var offline_cache_directory: String = ""

@export_group("Network")
@export var retry_max_retries: int = 3
@export var retry_use_jitter: bool = true
@export var http_timeout_seconds: float = 30.0


func to_config() -> FlockConfig:
	var config := FlockConfig.new()
	config.api_url = api_url
	config.api_key = api_key
	config.game_id = game_id
	config.game_version = game_version
	config.game_version_id = game_version_id
	config.enable_debug_logs = enable_debug_logs
	config.analytics_enabled = analytics_enabled
	config.analytics_auto_start_session = analytics_auto_start_session
	config.analytics_auto_end_on_quit = analytics_auto_end_on_quit
	config.analytics_session_timeout = analytics_session_timeout
	config.analytics_heartbeat_interval = analytics_heartbeat_interval
	config.analytics_bounce_threshold = analytics_bounce_threshold
	config.analytics_persist_session = analytics_persist_session
	config.analytics_track_fps = analytics_track_fps
	config.analytics_fps_sample_interval = analytics_fps_sample_interval
	config.analytics_require_explicit_consent = analytics_require_explicit_consent
	config.analytics_cache_failed_events = analytics_cache_failed_events
	config.analytics_max_cached_events = analytics_max_cached_events
	config.analytics_cache_flush_batch_size = analytics_cache_flush_batch_size
	config.analytics_event_buffer_flush_interval = analytics_event_buffer_flush_interval
	config.enable_asset_cache = enable_asset_cache
	config.asset_cache_directory = asset_cache_directory
	config.asset_cache_max_size_mb = asset_cache_max_size_mb
	config.asset_download_timeout_seconds = asset_download_timeout_seconds
	config.asset_download_retry_count = asset_download_retry_count
	config.asset_max_concurrent_downloads = asset_max_concurrent_downloads
	config.enable_offline_cache = enable_offline_cache
	config.offline_cache_directory = offline_cache_directory
	config.retry_max_retries = retry_max_retries
	config.retry_use_jitter = retry_use_jitter
	config.http_timeout_seconds = http_timeout_seconds
	return config


static func from_config(config: FlockConfig) -> FlockConfigResource:
	var res := FlockConfigResource.new()
	res.api_url = config.api_url
	res.api_key = config.api_key
	res.game_id = config.game_id
	res.game_version = config.game_version
	res.game_version_id = config.game_version_id
	res.enable_debug_logs = config.enable_debug_logs
	res.analytics_enabled = config.analytics_enabled
	res.analytics_auto_start_session = config.analytics_auto_start_session
	res.analytics_auto_end_on_quit = config.analytics_auto_end_on_quit
	res.analytics_session_timeout = config.analytics_session_timeout
	res.analytics_heartbeat_interval = config.analytics_heartbeat_interval
	res.analytics_bounce_threshold = config.analytics_bounce_threshold
	res.analytics_persist_session = config.analytics_persist_session
	res.analytics_track_fps = config.analytics_track_fps
	res.analytics_fps_sample_interval = config.analytics_fps_sample_interval
	res.analytics_require_explicit_consent = config.analytics_require_explicit_consent
	res.analytics_cache_failed_events = config.analytics_cache_failed_events
	res.analytics_max_cached_events = config.analytics_max_cached_events
	res.analytics_cache_flush_batch_size = config.analytics_cache_flush_batch_size
	res.analytics_event_buffer_flush_interval = config.analytics_event_buffer_flush_interval
	res.enable_asset_cache = config.enable_asset_cache
	res.asset_cache_directory = config.asset_cache_directory
	res.asset_cache_max_size_mb = config.asset_cache_max_size_mb
	res.asset_download_timeout_seconds = config.asset_download_timeout_seconds
	res.asset_download_retry_count = config.asset_download_retry_count
	res.asset_max_concurrent_downloads = config.asset_max_concurrent_downloads
	res.enable_offline_cache = config.enable_offline_cache
	res.offline_cache_directory = config.offline_cache_directory
	res.retry_max_retries = config.retry_max_retries
	res.retry_use_jitter = config.retry_use_jitter
	res.http_timeout_seconds = config.http_timeout_seconds
	return res


func is_valid() -> Dictionary:
	return to_config().is_valid()
