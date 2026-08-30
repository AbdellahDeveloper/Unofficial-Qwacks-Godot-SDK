class_name IntegrationEnv
extends RefCounted

## Shared configuration loader for the real-credentials integration pipeline.
##
## Credentials are read from (in priority order):
##   1. Environment variables: FLOCK_API_URL, FLOCK_GAME_ID, FLOCK_GAME_VERSION_ID,
##      FLOCK_API_KEY + any FLOCK_<PIPELINE_KEY> overrides.
##   2. A gitignored INI file at res://tests/integration/secrets.cfg (copy the
##      .example file and fill it in).
##
## The [pipeline] section is a comma-separated list of phases. Every phase the
## pipeline needs is verified to exist on the live backend (and its members of
## the templates checked) before the ordered create -> update -> delete run.

const DEFAULT_API_URL := "https://api-flock.qwacks.com"
const SECRETS_CFG := "res://tests/integration/secrets.cfg"

const PHASES := ["device", "currency", "achievement", "notification", "shop", "leaderboard", "game_config"]

const CREDENTIAL_KEYS := ["api_url", "game_id", "game_version_id", "api_key"]
const ENV_KEYS := [
	"api_url", "game_id", "game_version_id", "api_key",
	"device_id", "player_name",
	"run_phases",
	"currency_template_tag", "currency_fields",
	"achievement_template_tag", "achievement_name",
	"notification_template",
	"shop_item_id",
	"leaderboard_name",
	"game_config_name",
]


static func secrets_cfg_exists() -> bool:
	return FileAccess.file_exists(SECRETS_CFG)


static func _load_ini() -> Dictionary:
	# Hand-rolled INI reader instead of ConfigFile: ConfigFile parses unquoted
	# values as expressions, so game ids like 01KZ... or api keys like flock_... fail
	# with "Unexpected identifier" (and unquoted https:// URLs break on the // comment).
	var out := {}
	if not FileAccess.file_exists(SECRETS_CFG):
		return out
	var f := FileAccess.open(SECRETS_CFG, FileAccess.READ)
	if f == null:
		return out
	var section := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("[") and line.ends_with("]"):
			section = line.substr(1, line.length() - 2).strip_edges().to_lower()
			continue
		var eq := line.find("=")
		if eq == -1:
			continue
		var key := line.substr(0, eq).strip_edges().to_lower()
		var val := line.substr(eq + 1).strip_edges()
		if val.length() >= 2 and val.begins_with("\"") and val.ends_with("\""):
			val = val.substr(1, val.length() - 2)
		if not section.is_empty() and not key.is_empty():
			out[key] = val
	f.close()
	return out


static func environment_overrides() -> Dictionary:
	var out := {}
	for key in ENV_KEYS:
		var v := OS.get_environment("FLOCK_" + key.to_upper())
		if not v.is_empty():
			out[key] = v
	return out


static func config() -> Dictionary:
	var cfg := _load_ini()
	cfg.merge(environment_overrides(), true)
	if not cfg.has("api_url"):
		cfg["api_url"] = DEFAULT_API_URL
	return cfg


static func is_credentials_complete() -> bool:
	var cfg := config()
	for key in ["game_id", "game_version_id", "api_key"]:
		if str(cfg.get(key, "")).is_empty():
			return false
	return true


static func missing_credentials() -> Array:
	var cfg := config()
	var missing: Array = []
	for key in ["game_id", "game_version_id", "api_key"]:
		if str(cfg.get(key, "")).is_empty():
			missing.append(key)
	return missing


static func value(key: String, default_value: Variant = "") -> Variant:
	return config().get(key.to_lower(), default_value)


static func get_phases() -> Array:
	var raw := str(value("run_phases", "device,currency"))
	var phases: Array = []
	for part in raw.split(",", false):
		var name := part.strip_edges().to_lower()
		if phases.has(name):
			continue
		if PHASES.has(name):
			phases.append(name)
	return phases


static func fields_list(key: String, default_value: String = "") -> Array:
	var raw := str(value(key, default_value)).strip_edges()
	var fields: Array = []
	for part in raw.split(",", false):
		var name := part.strip_edges()
		if not name.is_empty() and not fields.has(name):
			fields.append(name)
	return fields


static func secrets_gitignore_hint() -> String:
	return "Set FLOCK_GAME_ID / FLOCK_GAME_VERSION_ID / FLOCK_API_KEY (env) or fill tests/integration/secrets.cfg."