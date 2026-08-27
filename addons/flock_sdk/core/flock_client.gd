class_name FlockClient
extends Node

const API_VERSION := "v1"

static var _instance: FlockClient = null

static var is_initialized: bool:
	get:
		return _instance != null

static var is_restoring_session: bool = false
static var initialization_error: String = ""

var _init_config: FlockInitConfig
var _logger: FlockLogger
var _access_token: String = ""
var _refresh_token: String = ""
var _token_claims: Dictionary = {}
var _refresh_mutex: Mutex = Mutex.new()
var _refresh_generation: int = 0
var _snapshot_store: RefCounted = null

# Providers
var auth: RefCounted = null
var config: RefCounted = null
var game: RefCounted = null
var player: RefCounted = null
var commands: RefCounted = null
var shop: RefCounted = null
var asset: RefCounted = null
var leaderboard: RefCounted = null
var notification: RefCounted = null
var analytics: RefCounted = null
var session: FlockSession = null

# Events
var on_session_expired: Callable = Callable()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if session and session.is_active:
		session.handle_tick(delta)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			if session and session.is_active:
				session.handle_app_backgrounded(true)
		NOTIFICATION_APPLICATION_FOCUS_IN:
			if session and session.is_active:
				session.handle_app_backgrounded(false)
		NOTIFICATION_WM_CLOSE_REQUEST:
			if session and session.is_active:
				var snapshot = session.end(FlockSessionEndReason.QUIT)
				if snapshot and analytics and analytics is FlockAnalyticsProvider:
					analytics.flush_async()
			if commands:
				commands.flush_on_quit()

func _enter_tree() -> void:
	FlockClient._instance = self

func _exit_tree() -> void:
	FlockClient._instance = null

static func get_instance() -> FlockClient:
	return _instance

func create(init_config: FlockInitConfig, logger: FlockLogger = null) -> void:
	if _instance != null and _instance != self:
		push_error("[Flock SDK] FlockClient is already initialized. Call shutdown() first.")
		return

	_init_config = init_config
	_logger = logger if logger != null else (GodotFlockLogger.new(init_config.enable_debug_logs) if init_config.enable_debug_logs else NullFlockLogger.new())

	# Set events logger
	FlockEvents.get_instance()._logger = _logger

	_logger.log_info("Initializing Flock SDK")

	# Validate game version ID
	if init_config.game_version_id.is_empty():
		var error_msg := "Game Version not resolved. Open Flock Settings while online to resolve your Game Version, then rebuild."
		initialization_error = error_msg
		FlockEvents.get_instance().invoke_initialization_failed(error_msg)
		push_error("[Flock SDK] " + error_msg)
		return

	# Initialize snapshot store
	if init_config.enable_offline_cache:
		_snapshot_store = FlockSnapshotStore.new(
			init_config.offline_cache_directory if not init_config.offline_cache_directory.is_empty() else FlockUtil.flock_snapshots_dir(),
			_logger
		)
		_snapshot_store.prune_other_versions(init_config.game_version_id)

	# Initialize services
	_init_services()

	FlockEvents.get_instance().invoke_initialized()
	_logger.log_info("Flock SDK initialized successfully")

func _init_services() -> void:
	# Create token store
	if _init_config.token_store == null:
		_init_config.token_store = FlockTokenStoreFactory.create()

	# Initialize providers
	player = FlockPlayerProvider.new(self)
	config = FlockConfigProvider.new(self)
	game = FlockGameProvider.new(self)
	commands = FlockCommandProvider.new(self)
	shop = FlockShopProvider.new(self)
	asset = FlockAssetProvider.new(self)
	leaderboard = FlockLeaderboardProvider.new(self)
	notification = FlockNotificationProvider.new(self)
	auth = FlockAuthProvider.new(self)

	# Initialize analytics
	if _init_config.analytics_config.get("enabled", true):
		var analytics_cfg := FlockAnalyticsConfig.from_dict(_init_config.analytics_config)
		session = FlockSession.new(analytics_cfg, _logger)
		analytics = FlockAnalyticsProvider.new(self)
	else:
		analytics = FlockNullAnalytics.new(self)

func shutdown() -> void:
	initialization_error = ""
	if _instance == null:
		return

	if analytics is FlockAnalyticsProvider:
		analytics.uninstall_global_exception_hook()

	if commands:
		commands.unsubscribe_flush_triggers()

	clear_tokens()
	_instance = null
	FlockEvents.get_instance().invoke_shutdown()
	FlockEvents.get_instance().clear_all()
	FlockEvents.get_instance()._logger = null

# --- Token Management ---

func set_tokens(access_token: String, refresh_token: String) -> void:
	var claims := {}
	if not access_token.is_empty():
		claims = JwtTokenParser.parse(access_token)
		if claims.is_empty():
			var ex := FlockException.FlockAuthException.new(
				"Server returned an unparseable JWT access token."
			)
			_logger.log_error("Failed to parse JWT access token")
			return

	_access_token = access_token
	_refresh_token = refresh_token
	_token_claims = claims

	if not claims.is_empty():
		_logger.log_debug("Token set for PlayerId: %s" % str(claims.get("player_id", "")))

	_persist_tokens()


func clear_tokens() -> void:
	_logger.log_info("Clearing authentication tokens")

	if session and session.is_active:
		session.reset(FlockSessionEndReason.LOGOUT)

	if analytics and analytics is FlockAnalyticsProvider:
		analytics.handle_auth_cleared()

	_access_token = ""
	_refresh_token = ""
	_token_claims = {}
	_clear_persisted_tokens()


func load_persisted_tokens() -> Dictionary:
	var store = _init_config.token_store
	if store == null:
		return {}
	return store.load_tokens()


func get_base_headers() -> Dictionary:
	var headers := _init_config.get_base_headers()
	if not _access_token.is_empty():
		headers["Authorization"] = "Bearer " + _access_token
	return headers


func get_api_url() -> String:
	return _init_config.api_url


func get_versioned_api_url() -> String:
	return "%s/%s" % [_init_config.api_url, API_VERSION]


func is_reachable() -> bool:
	return OS.has_feature("online")


# --- Token Refresh ---

func try_refresh_token() -> bool:
	if _refresh_token.is_empty():
		return false

	var refresh_snapshot := _refresh_token
	var player_id_snapshot := current_player_id
	var generation_snapshot := _refresh_generation

	_refresh_mutex.lock()

	if _refresh_token.is_empty():
		_refresh_mutex.unlock()
		return false

	# Someone refreshed while we waited
	if _refresh_generation != generation_snapshot and not _access_token.is_empty():
		_refresh_mutex.unlock()
		return true

	var request := {
		"player_id": player_id_snapshot,
		"refresh_token": refresh_snapshot,
	}

	_refresh_mutex.unlock()

	var url := "%s/%s" % [get_versioned_api_url(), FlockEndpoints.PLAYER_TOKEN_REFRESH]
	var http := FlockHttpRequest.new()
	var result := await http.post_async(url, request, _init_config.get_base_headers())

	if result is Dictionary:
		if result.has("error"):
			clear_tokens()
			FlockEvents.get_instance().invoke_auth_expired()
			return false

		var response: Dictionary = result
		var new_access: String = response.get("access_token", "")
		if new_access.is_empty():
			clear_tokens()
			FlockEvents.get_instance().invoke_auth_expired()
			return false

		set_tokens(new_access, response.get("refresh_token", ""))
		_refresh_generation += 1
		_logger.log_info("Token refresh successful")
		FlockEvents.get_instance().invoke_token_refreshed()
		return true

	return false


# --- Persistence ---

func _persist_tokens() -> void:
	var store = _init_config.token_store
	if store == null:
		return
	store.save_tokens(_access_token, _refresh_token)


func _clear_persisted_tokens() -> void:
	var store = _init_config.token_store
	if store == null:
		return
	store.clear()


# --- Properties ---

var current_player_id: String:
	get:
		return _token_claims.get("player_id", "")

var game_id: String:
	get:
		return _init_config.game_id if _init_config else ""

var game_version_id: String:
	get:
		return _init_config.game_version_id if _init_config else ""

var is_authenticated: bool:
	get:
		return not _access_token.is_empty()

var is_token_expired: bool:
	get:
		if not _token_claims.has("expiration_time"):
			return false
		var exp = _token_claims.get("expiration_time", 0)
		if exp is int or exp is float:
			return Time.get_unix_time_from_system() >= float(exp)
		return false

var token_claims: Dictionary:
	get:
		return _token_claims

var has_active_session: bool:
	get:
		return session != null and session.is_active

var current_session_id: String:
	get:
		if session == null:
			return ""
		return session.server_session_id if session.server_session_id else session.session_id
