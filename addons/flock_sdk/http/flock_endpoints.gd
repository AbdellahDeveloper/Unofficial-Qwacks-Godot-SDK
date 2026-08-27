class_name FlockEndpoints

# Auth — login/register
const PLAYER_LOGIN := "player/login"
const PLAYER_LOGIN_DEVICE := "player/login/device"
const PLAYER_LOGIN_GOOGLE := "player/login/google"
const PLAYER_LOGIN_APPLE := "player/login/apple"
const PLAYER_LOGIN_STEAM := "player/login/steam"
const PLAYER_REGISTER := "player/register"
const PLAYER_REGISTER_DEVICE := "player/register/device"
const PLAYER_REGISTER_GOOGLE := "player/register/google"
const PLAYER_REGISTER_APPLE := "player/register/apple"
const PLAYER_REGISTER_STEAM := "player/register/steam"

# Auth — session & account
const PLAYER_TOKEN_REFRESH := "player/token/refresh"
const PLAYER_TOKEN_REVOKE := "player/token/revoke"
const PLAYER_PASSWORD_FORGOT := "player/password/forgot"
const PLAYER_PASSWORD_RESET := "player/password/reset"
const PLAYER_EMAIL_SEND_VERIFICATION := "player/email/send-verification"
const PLAYER_EMAIL_VERIFY := "player/email/verify"

static func player_name_available(name: String) -> String:
	return "player/name-available?name=%s" % name.uri_encode()

# Account linking — `provider` is a closed LoginType set (FlockCredentialProviders.to_wire), so no escaping needed.
const PLAYER_ACCOUNTS := "player/accounts"
const PLAYER_LINK_EMAIL := "player/link/email"
const PLAYER_LINK_DEVICE := "player/link/device"

static func player_link_oauth(provider: String) -> String:
	return "player/link/oauth/%s" % provider

static func player_unlink(provider: String) -> String:
	return "player/unlink/%s" % provider

# Player data / templates / bans
const PLAYER_DATA := "player_data"
const PLAYER_TEMPLATE := "player_template"
const PLAYER_BAN := "player-ban"

static func player_data_by_id(id: String) -> String:
	return "player_data/%s" % id

static func player_template_by_id(id: String) -> String:
	return "player_template/%s" % id

static func player_template_by_name(name: String) -> String:
	return "player_template/by-name/%s" % name.uri_encode()

static func player_template_data(template_id: String) -> String:
	return "player_template/%s/player-data" % template_id

# Game / versions
const GAME := "game"
const GAME_VERSION := "game_version"

static func game_version_by_name(name: String) -> String:
	return "game_version/by-name/%s" % name.uri_encode()

# Config / patches
const GAME_CONFIG := "game_config"
const GAME_CONFIG_VERSION := "game_config/version"
const GAME_PATCH := "game_patch"

static func game_config_by_id(id: String) -> String:
	return "game_config/%s" % id

static func game_config_by_name(name: String) -> String:
	return "game_config/by-name/%s" % name.uri_encode()

static func game_config_player_features(player_id: String) -> String:
	return "game_config/player/%s/features" % player_id

static func game_patch_by_id(id: String) -> String:
	return "game_patch/%s" % id

static func game_patch_by_config(schema_id: String) -> String:
	return "game_patch/config/%s" % schema_id

# Shop / inventory
const SHOP := "shop"
const SHOP_TRANSACTION := "shop/transaction"

static func shop_by_id(shop_id: String) -> String:
	return "shop/%s" % shop_id

static func shop_by_name(name: String) -> String:
	return "shop/by-name/%s" % name.uri_encode()

static func shop_item_by_id(item_id: String) -> String:
	return "shop_item/%s" % item_id

static func shop_items_by_shop(shop_id: String) -> String:
	return "shop_item/shop/%s" % shop_id

static func player_inventory_by_player(player_id: String) -> String:
	return "player_inventory/player/%s" % player_id

static func player_inventory_consume(inventory_id: String) -> String:
	return "player_inventory/%s/consume" % inventory_id

# Leaderboards — read-only. There is no submit path by design: a board projects over a player-data field, so scores move by writing that field.
# Every read is addressed by name — the /v1 surface has no by-id read routes.
static func leaderboard_by_name(name: String) -> String:
	return "leaderboard/by-name/%s" % name.uri_encode()

static func leaderboard_standings(name: String) -> String:
	return "%s/standings" % leaderboard_by_name(name)

static func leaderboard_me(name: String) -> String:
	return "%s/me" % leaderboard_by_name(name)

static func leaderboard_around_me(name: String) -> String:
	return "%s/around-me" % leaderboard_by_name(name)

# Notifications — the player inbox plus game-scheduled reminders.
const NOTIFICATION := "notification"
const NOTIFICATION_UNREAD_COUNT := "notification/unread_count"
const NOTIFICATION_SUMMARY := "notification/summary"
const NOTIFICATION_READ_ALL := "notification/read_all"

static func notification_read_by_id(notification_id: String) -> String:
	return "notification/%s/read" % notification_id

const DEVICE_TOKEN_REGISTER := "device_token/register"
const DEVICE_TOKEN_UNREGISTER := "device_token/unregister"
const NOTIFICATION_SCHEDULE := "notification/schedule"

static func notification_schedule_by_id(scheduled_id: String) -> String:
	return "notification/schedule/%s" % scheduled_id

const NOTIFICATION_TEMPLATE := "notification_template"

# Name rides in the query, not the path: template names carry spaces, colons and slashes, none of which survive a single path segment.
static func notification_template_by_name(name: String, locale: String = "") -> String:
	var query := "?name=%s" % name.uri_encode()
	if not locale.is_empty():
		query += "&locale=%s" % locale.uri_encode()
	return "notification_template/by-name%s" % query

# Assets
const ASSET := "asset"

static func asset_by_id(asset_id: String) -> String:
	return "asset/%s" % asset_id

# Analytics
const ANALYTICS_SESSIONS := "analytics/sessions"
const ANALYTICS_EVENTS := "analytics/events"
const ANALYTICS_EVENTS_SINGLE := "analytics/events/single"
const ANALYTICS_TRANSACTIONS := "analytics/transactions"
const LOG_EVENT := "log_event"
const LOG_EVENT_SINGLE := "log_event/single"

static func analytics_session_by_id(session_id: String) -> String:
	return "analytics/sessions/%s" % session_id

# Commands
const COMMAND_UPDATE_PLAYER_DATA := "game_command/update_player_data"
const COMMAND_UPDATE_PLAYER_DATA_KEY := "game_command/update_player_data_key"
const COMMAND_UNLOCK_ACHIEVEMENT := "game_command/unlock_achievement"
const COMMAND_ADD_GAME_FUNDS := "game_command/add_game_funds"
