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
