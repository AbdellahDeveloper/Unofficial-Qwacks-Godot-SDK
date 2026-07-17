class_name FlockAnalyticsConfig

var enabled: bool = true
var require_explicit_consent: bool = false
var auto_start_session: bool = true
var auto_end_session_on_quit: bool = true
var session_timeout_seconds: float = 30.0
var heartbeat_interval_seconds: float = 60.0
var bounce_threshold_seconds: float = 10.0
var persist_session_on_disk: bool = true
var track_fps: bool = true
var fps_sample_interval_seconds: float = 1.0
var cache_failed_events: bool = true
var max_cached_events: int = 1000
var cache_flush_batch_size: int = 50
var event_buffer_flush_interval_seconds: float = 10.0

static func from_dict(data: Dictionary) -> FlockAnalyticsConfig:
	var config := FlockAnalyticsConfig.new()
	config.enabled = data.get("enabled", true)
	config.require_explicit_consent = data.get("require_explicit_consent", false)
	config.auto_start_session = data.get("auto_start_session", true)
	config.auto_end_session_on_quit = data.get("auto_end_session_on_quit", true)
	config.session_timeout_seconds = data.get("session_timeout_seconds", 30.0)
	config.heartbeat_interval_seconds = data.get("heartbeat_interval_seconds", 60.0)
	config.bounce_threshold_seconds = data.get("bounce_threshold_seconds", 10.0)
	config.persist_session_on_disk = data.get("persist_session_on_disk", true)
	config.track_fps = data.get("track_fps", true)
	config.fps_sample_interval_seconds = data.get("fps_sample_interval_seconds", 1.0)
	config.cache_failed_events = data.get("cache_failed_events", true)
	config.max_cached_events = data.get("max_cached_events", 1000)
	config.cache_flush_batch_size = data.get("cache_flush_batch_size", 50)
	config.event_buffer_flush_interval_seconds = data.get("event_buffer_flush_interval_seconds", 10.0)
	return config
