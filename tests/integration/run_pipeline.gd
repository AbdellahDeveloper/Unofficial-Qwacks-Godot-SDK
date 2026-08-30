extends SceneTree

## Real-credentials integration pipeline. NOT a GUT test — a dedicated runner so
## order is guaranteed and the prerequisite checker can print setup instructions.
##
## Usage:
##   godot --headless -s res://tests/integration/run_pipeline.gd
##
## Credentials: FLOCK_GAME_ID / FLOCK_GAME_VERSION_ID / FLOCK_API_KEY env vars, or
## res://tests/integration/secrets.cfg (copy secrets.cfg.example, it is gitignored).
##
## Flow (ordered):
##   1. CREATE  — register/login a fresh device player.
##   2. INFRA   — verify every template/member the configured phases need exists on
##                the live backend. Prints exactly what is missing and how to create
##                it; exits WITHOUT running UPDATE/DELETE when anything is missing.
##   3. UPDATE  — currency wallet write + readback verify (plus optional phases).
##   4. DELETE  — revoke the test token.
##
## Exit codes: 0 = all phases passed
##             1 = a phase failed at runtime
##             2 = credentials missing/misconfigured
##             3 = prerequisites missing (instructions printed)

const EXIT_OK := 0
const EXIT_RUNTIME := 1
const EXIT_SETUP := 2
const EXIT_PREREQ := 3

var _cfg: Dictionary = {}
var _client: FlockClient = null
var _device_id: String = ""
var _player_id: String = ""
var _fail_count := 0
var _infra_notes: Array = []


func _initialize() -> void:
	# Don't kick off the pipeline here: during _initialize the SceneTree root isn't
	# in the tree yet, so nodes added to it are "outside tree" and HTTPRequest fails
	# with ERR_UNCONFIGURED. Start on the first processed frame instead.
	process_frame.connect(_run_async, CONNECT_ONE_SHOT)


func _run_async() -> void:
	_cfg = IntegrationEnv.config()
	_print_banner()

	if not IntegrationEnv.is_credentials_complete():
		_print_missing_credentials()
		quit(EXIT_SETUP)
		return

	_boot()

	if not await _phase_create_device():
		quit(EXIT_RUNTIME)
		return

	await _infra_check_async()
	if _infra_notes.size() > 0:
		_print_infra_instructions()
		await _best_effort_revoke()
		quit(EXIT_PREREQ)
		return

	var ok := true
	ok = await _phase_update_currency() and ok
	ok = await _phase_achievement() and ok
	ok = await _phase_notification() and ok
	ok = await _phase_shop() and ok
	ok = await _phase_leaderboard() and ok
	ok = await _phase_game_config() and ok
	ok = await _phase_delete_device() and ok

	_print_summary()
	quit(EXIT_OK if ok and _fail_count == 0 else EXIT_RUNTIME)


func _boot() -> void:
	# In -s (headless) mode the flock_sdk editor plugin never loads, so its
	# FlockRuntimeSetup autoload that normally owns FlockEvents/FlockClient is absent.
	# Build the same singleton wiring here.
	var events := FlockEvents.new()
	events.name = "FlockEventsNode"
	root.add_child(events)

	var cfg := FlockInitConfig.new()
	cfg.api_url = str(_cfg.get("api_url", IntegrationEnv.DEFAULT_API_URL))
	cfg.api_key = str(_cfg.get("api_key", ""))
	cfg.game_id = str(_cfg.get("game_id", ""))
	cfg.game_version_id = str(_cfg.get("game_version_id", ""))
	cfg.enable_debug_logs = false
	cfg.enable_offline_cache = false
	cfg.enable_asset_cache = false
	cfg.analytics_config = {"enabled": false}

	_client = FlockClient.new()
	root.add_child(_client)
	_client.create(cfg)

	_device_id = str(_cfg.get("device_id", ""))
	if _device_id.is_empty():
		_device_id = "gut_pipeline_%d" % Time.get_unix_time_from_system()


# --- Phase 1: CREATE ---

func _phase_create_device() -> bool:
	print("---")
	print("PHASE 1/3  CREATE  register/login device player")
	print("---")
	var result = await _client.auth.login_with_device(_device_id)
	if _is_error(result):
		var msg := str(result.get("error", "device login failed"))
		var code := str(result.get("code", ""))
		print("  error: ", msg)
		if not code.is_empty():
			print("  code:  ", code)
		_report("device player create", false, code if not code.is_empty() else msg)
		return false
	if not _client.is_authenticated:
		_report("device player create", false, "no access token after login")
		return false
	_player_id = _client.current_player_id
	_report("device player create", true, "player_id=%s" % _player_id)
	return true


# --- Phase 2: INFRASTRUCTURE PREREQUISITES (read-only, smart instructions) ---

func _infra_check_async() -> void:
	print("---")
	print("INFRA      verify every template/member the configured phases need")
	print("---")
	for name in IntegrationEnv.get_phases():
		match name:
			"device":
				_infra_report("device phase", true, "always runs; no backend resources required")
			"currency":
				await _check_currency_infra()
			"achievement":
				await _check_achievement_infra()
			"notification":
				await _check_notification_infra()
			"shop":
				await _check_shop_infra()
			"leaderboard":
				await _check_leaderboard_infra()
			"game_config":
				await _check_game_config_infra()


func _check_currency_infra() -> void:
	var tag := str(_cfg.get("currency_template_tag", "currency"))
	var template = await _client.player.get_template_by_tag_async(tag)
	if _is_error(template) or template.is_empty():
		_infra_report("currency", false, "template (tag '%s') NOT found on the backend" % tag)
		_infra_notes.append("MISSING  player-data template tagged '%s'.\n" % tag \
			+ "         In the Flock dashboard: Game -> Player Data -> Templates -> New -> tag '%s'.\n" % tag \
			+ "         Give it a Number field for each currency (see currency_fields below).")
		return
	var schema_keys := _schema_keys(template.get("schema", []))
	var required := IntegrationEnv.fields_list("currency_fields", "gold")
	var missing: Array = []
	for field in required:
		if not schema_keys.has(field):
			missing.append(field)
	if missing.size() > 0:
		_infra_report("currency", false, "template exists but is missing fields %s" % str(missing))
		_infra_notes.append("MISSING  currency template '%s' has fields %s but the pipeline needs %s.\n" \
			% [str(template.get("name", tag)), str(schema_keys), str(required)] \
			+ "         In the template schema, add a Number field for each one listed.")
		return
	var wallet = await _client.player.get_my_data_by_tag_async(tag)
	if _is_error(wallet) or wallet.is_empty():
		_infra_report("currency", false, "wallet row for a fresh device player NOT auto-provisioned")
		_infra_notes.append("MISSING  no %s row exists for a freshly-registered device player.\n" % str(template.get("name", tag)) \
			+ "         The UPDATE phase writes the player's wallet, so the server must auto-create a\n" \
			+ "         %s row on registration (or register a template that does)." % str(template.get("name", tag)))
		return
	_infra_report("currency", true, "template '%s' fields=%s wallet=%s" % [
		str(template.get("name", tag)), str(schema_keys), str(wallet.get("id", ""))])


func _check_achievement_infra() -> void:
	var tag := str(_cfg.get("achievement_template_tag", "achievement"))
	var template = await _client.player.get_template_by_tag_async(tag)
	if _is_error(template) or template.is_empty():
		_infra_report("achievement", false, "template (tag '%s') NOT found" % tag)
		_infra_notes.append("MISSING  achievement player-data template tagged '%s'.\n" % tag \
			+ "         Game -> Player Data -> Templates -> New -> tag '%s'." % tag)
		return
	var name := str(_cfg.get("achievement_name", ""))
	if name.is_empty():
		_infra_report("achievement", true, "template '%s' found; set pipeline achievement_name to unlock one" % str(template.get("name", tag)))
		return
	var schema_keys := _schema_keys(template.get("schema", []))
	if not schema_keys.has(name):
		_infra_report("achievement", false, "achievement '%s' not a member of template '%s' (has %s)" % [name, str(template.get("name", tag)), str(schema_keys)])
		_infra_notes.append("MISSING  achievement '%s' is not in template '%s'.\n" % [name, str(template.get("name", tag))] \
			+ "         Add it as a member of that template (schema), it will be picked up on sync.\n" \
			+ "         Current members: %s" % str(schema_keys))
		return
	_infra_report("achievement", true, "template '%s' contains achievement '%s'" % [str(template.get("name", tag)), name])


func _check_notification_infra() -> void:
	var template_name := str(_cfg.get("notification_template", ""))
	var template = await _client.notification.get_template_by_name_async(template_name)
	if _is_error(template) or template.is_empty():
		_infra_report("notification", false, "template '%s' NOT found" % template_name)
		_infra_notes.append("MISSING  notification template '%s'.\n" % template_name \
			+ "         Game -> Notifications -> Templates -> New -> '%s', then publish it to this game version." % template_name)
		return
	_infra_report("notification", true, "template '%s' exists" % template_name)


func _check_shop_infra() -> void:
	var item_id := str(_cfg.get("shop_item_id", ""))
	var item = await _client.shop.get_item_async(item_id)
	if _is_error(item) or item.is_empty():
		_infra_report("shop", false, "shop item '%s' NOT found" % item_id)
		_infra_notes.append("MISSING  shop item '%s'.\n" % item_id \
			+ "         Game -> Shop -> Items -> New with id/name '%s'; publish it to this game version." % item_id)
		return
	_infra_report("shop", true, "shop item '%s' exists (%s)" % [item_id, str(item.get("name", ""))])


func _check_leaderboard_infra() -> void:
	var name := str(_cfg.get("leaderboard_name", ""))
	var board = await _client.leaderboard.get_by_name_async(name)
	if _is_error(board) or board.is_empty():
		_infra_report("leaderboard", false, "leaderboard '%s' NOT found" % name)
		_infra_notes.append("MISSING  leaderboard named '%s'.\n" % name \
			+ "         Game -> Leaderboards -> New -> name '%s'; publish it to this game version." % name)
		return
	var standings = await _client.leaderboard.get_standings_async(name)
	_infra_report("leaderboard", true, "leaderboard '%s' exists — %s" % [name, _standings_summary(standings)])


func _check_game_config_infra() -> void:
	var name := str(_cfg.get("game_config_name", ""))
	var game_config = await _client.config.get_game_config_by_name(name)
	if _is_error(game_config) or game_config.is_empty():
		_infra_report("game_config", false, "game config named '%s' NOT found" % name)
		_infra_notes.append("MISSING  game config named '%s'.\n" % name \
			+ "         Game -> Game Config -> Create -> name '%s'; publish a patch to this game version." % name)
		return
	_infra_report("game_config", true, "game config '%s' exists" % name)


func _infra_report(name: String, ok: bool, note: String) -> void:
	var status := "OK  " if ok else "MISS"
	print("[INFRA] [%s] %s  %s" % [status, name, note])


func _print_infra_instructions() -> void:
	print("---")
	print("PREREQUISITES MISSING - the pipeline did NOT run UPDATE/DELETE.")
	print("Fix the following in the Flock dashboard, then re-run this script:")
	for note in _infra_notes:
		print(note)
	print("After fixing, run: godot --headless -s res://tests/integration/run_pipeline.gd")


# --- Phase 3: UPDATE ---

func _phase_update_currency() -> bool:
	if not _phase_requested("currency"):
		return true
	print("---")
	print("PHASE 2/3  UPDATE  currency wallet write + readback verify")
	print("---")
	var tag := str(_cfg.get("currency_template_tag", "currency"))
	var wallet = await _client.player.get_my_data_by_tag_async(tag)
	if _is_error(wallet) or wallet.is_empty():
		_report("load wallet", false, "no %s row for the test player" % tag)
		return false
	var wallet_id := str(wallet.get("id", ""))
	var fields := IntegrationEnv.fields_list("currency_fields", "gold")
	var field := str(fields[0]) if not fields.is_empty() else "gold"

	var current: int = _field_value_int(wallet.get("data", []), field)
	var funded = await _client.commands.add_game_funds_async(field, 25)
	if _is_error(funded):
		_report("add_game_funds", false, str(funded.get("error", "")))
		return false
	_report("add_game_funds", true, "currency='%s' +25" % field)

	var new_value := current + 100
	var updated = await _client.commands.update_player_data_field_async(wallet_id, field, new_value)
	if _is_error(updated):
		_report("update_player_data_field", false, str(updated.get("error", "")))
		return false
	_report("update_player_data_field", true, "%s=%d" % [field, new_value])

	var verify = await _client.player.get_data_by_id_async(wallet_id)
	if _is_error(verify):
		_report("readback verify", false, str(verify.get("error", "")))
		return false
	var got := _field_value_int(verify.get("data", []), field)
	_report("readback verify", got == new_value, "expected %d got %d" % [new_value, got])
	return got == new_value


func _phase_achievement() -> bool:
	if not _phase_requested("achievement"):
		return true
	var name := str(_cfg.get("achievement_name", ""))
	print("---")
	print("PHASE 2/3  UPDATE  unlock achievement '%s'" % name)
	print("---")
	var result = await _client.commands.unlock_achievement_async(name)
	if _is_error(result):
		_report("unlock_achievement", false, str(result.get("error", "")))
		return false
	_report("unlock_achievement", true, "unlocked '%s'" % name)
	return true


func _phase_notification() -> bool:
	if not _phase_requested("notification"):
		return true
	var template_name := str(_cfg.get("notification_template", ""))
	print("---")
	print("PHASE 2/3  UPDATE  schedule then cancel notification '%s'" % template_name)
	print("---")
	var scheduled = await _client.notification.schedule_delayed_async(template_name, 3600.0)
	if _is_error(scheduled):
		_report("notification schedule", false, str(scheduled.get("error", "")))
		return false
	_report("notification schedule", true, "scheduled '%s'" % template_name)
	var cancelled = await _client.notification.cancel_scheduled_async(scheduled)
	if _is_error(cancelled):
		_report("notification cancel", false, str(cancelled.get("error", "")))
		return false
	_report("notification cancel", true, "cancelled scheduled notification")
	return true


func _phase_shop() -> bool:
	if not _phase_requested("shop"):
		return true
	var item_id := str(_cfg.get("shop_item_id", ""))
	print("---")
	print("PHASE 2/3  UPDATE  purchase then consume shop item '%s'" % item_id)
	print("---")
	var purchased = await _client.shop.purchase_async(item_id)
	if _is_error(purchased):
		_report("shop purchase", false, str(purchased.get("error", "")))
		return false
	var inventory_id := str(purchased.get("inventory", {}).get("id", ""))
	if inventory_id.is_empty():
		_report("shop purchase", false, "no inventory id in response")
		return false
	_report("shop purchase", true, "inventory=%s" % inventory_id)
	var consumed = await _client.shop.consume_async(inventory_id)
	if _is_error(consumed):
		_report("shop consume", false, str(consumed.get("error", "")))
		return false
	_report("shop consume", true, "consumed inventory=%s" % inventory_id)
	return true


func _phase_leaderboard() -> bool:
	if not _phase_requested("leaderboard"):
		return true
	var name := str(_cfg.get("leaderboard_name", ""))
	print("---")
	print("PHASE 2/3  UPDATE  read leaderboard '%s' + my rank" % name)
	print("---")
	var standings = await _client.leaderboard.get_standings_async(name)
	if _is_error(standings):
		_report("leaderboard standings", false, str(standings.get("error", "")))
		return false
	_report("leaderboard standings", true, "standings for '%s' (%s)" % [name, _standings_summary(standings)])
	var my_rank = await _client.leaderboard.get_my_rank_async(name)
	if _is_error(my_rank):
		_report("leaderboard my_rank", false, str(my_rank.get("error", "")))
		return false
	_report("leaderboard my_rank", true, "rank read")
	return true


func _phase_game_config() -> bool:
	if not _phase_requested("game_config"):
		return true
	var name := str(_cfg.get("game_config_name", ""))
	print("---")
	print("PHASE 2/3  UPDATE  read game config '%s'" % name)
	print("---")
	var result = await _client.config.get_game_config_by_name(name)
	if _is_error(result) or result.is_empty():
		_report("game config read", false, str(result.get("error", "")) if result is Dictionary else "empty")
		return false
	_report("game config read", true, "config '%s' data=%s" % [name, str(result.get("data", {}))])
	return true


# --- Phase 4: DELETE ---

func _phase_delete_device() -> bool:
	print("---")
	print("PHASE 3/3  DELETE  revoke test token")
	print("---")
	var result = await _client.auth.revoke_token()
	if _is_error(result):
		_report("revoke token", false, str(result.get("error", "")))
		return false
	# revoke_token() only revokes server-side; the SDK keeps local sessions until the caller clears them.
	_client.clear_tokens()
	if _client.is_authenticated:
		_report("revoke token", false, "still authenticated after revoke + clear_tokens")
		return false
	_report("revoke token", true, "token revoked; test player %s left as a disposable account" % _player_id)
	return true


# --- Utilities ---

func _phase_requested(name: String) -> bool:
	return IntegrationEnv.get_phases().has(name)


func _is_error(result: Variant) -> bool:
	return result is Dictionary and result.has("error")


func _report(step: String, ok: bool, detail: String) -> void:
	var tag := "[PASS]" if ok else "[FAIL]"
	print("%s %s  %s" % [tag, step, detail])
	if not ok:
		_fail_count += 1


func _schema_keys(schema: Variant) -> Array:
	var keys: Array = []
	if schema is Array:
		for entry in schema:
			if not entry is Dictionary:
				continue
			var found := ""
			for key in ["field_name", "key", "name"]:
				var value := str(entry.get(key, ""))
				if not value.is_empty():
					found = value
					break
			if not found.is_empty() and not keys.has(found):
				keys.append(found)
	elif schema is Dictionary:
		for key in schema.keys():
			if not keys.has(str(key)):
				keys.append(str(key))
	keys.sort()
	return keys


func _field_value_int(data_fields: Variant, field_name: String) -> int:
	if data_fields is Dictionary:
		var raw = data_fields.get(field_name, 0)
		return int(raw) if raw is int or raw is float or (raw is String and raw.is_valid_int()) else 0
	for entry in data_fields:
		if entry is Dictionary and str(entry.get("field_name", "")) == field_name:
			var value: Variant = entry.get("value", 0)
			return int(value) if value is int or value is float or (value is String and value.is_valid_int()) else 0
	return 0


# Human-readable proof the ranked data is real: total entries plus the top standing.
func _standings_summary(result: Variant) -> String:
	if result is Dictionary:
		var items: Variant = result.get("items", [])
		if items is Array and items.size() > 0:
			var first: Variant = items[0]
			if first is Dictionary:
				var label := str(first.get("player_name", ""))
				if label.is_empty():
					label = str(first.get("player_id", ""))
				return "%s entries, top: rank %s '%s' score %s" % [
					_fmt_num(result.get("total", items.size())),
					_fmt_num(first.get("rank", "")),
					label,
					_fmt_num(first.get("score", "")),
				]
		return "%s entries, none ranked yet" % _fmt_num(result.get("total", 0))
	return "no standings data"


# JSON numbers arrive as floats; drop the ".0" for whole values.
static func _fmt_num(v: Variant) -> String:
	if v is float and v == round(v):
		return str(int(v))
	return str(v)


func _best_effort_revoke() -> void:
	if _client and _client.is_authenticated:
		await _client.auth.revoke_token()
		_client.clear_tokens()


func _print_banner() -> void:
	var phases := IntegrationEnv.get_phases()
	print("===========================================================")
	print("Flock SDK  real-credentials integration pipeline")
	print("===========================================================")
	print("game_id          %s" % str(_cfg.get("game_id", "")))
	print("game_version_id  %s" % str(_cfg.get("game_version_id", "")))
	print("api_url          %s" % str(_cfg.get("api_url", "")))
	print("phases           %s" % str(phases))
	if not _cfg.get("device_id", "") == "":
		print("device_id        %s (stable - player is reused)" % str(_cfg.get("device_id", "")))
	else:
		print("device_id        fresh per run (disposable test player)")


func _print_missing_credentials() -> void:
	print("-----------------------------------------------------------")
	print("INTEGRATION CREDENTIALS NOT CONFIGURED")
	print("")
	print("The real-credentials pipeline needs three values:")
	print("  game_id           (your game; Flock dashboard -> Game)")
	print("  game_version_id   (a published game version)")
	print("  api_key           (an API key with x-api-key access)")
	print("")
	print("Provide them via environment variables:")
	print("  FLOCK_GAME_ID=... FLOCK_GAME_VERSION_ID=... FLOCK_API_KEY=...")
	print("  godot --headless -s res://tests/integration/run_pipeline.gd")
	print("")
	print("or copy res://tests/integration/secrets.cfg.example to")
	print("res://tests/integration/secrets.cfg and fill it in (it is gitignored).")
	print("")
	print("Missing: %s" % str(IntegrationEnv.missing_credentials()))
	print("-----------------------------------------------------------")


func _print_summary() -> void:
	print("---")
	var verdict := "ALL PHASES PASSED" if _fail_count == 0 else "%d FAILURES" % _fail_count
	print("SUMMARY  %s  player_id=%s" % [verdict, _player_id])
	print("Repeated runs create a fresh device player unless device_id is set in")
	print("tests/integration/secrets.cfg (or FLOCK_DEVICE_ID).")