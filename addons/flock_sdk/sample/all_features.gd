extends Control

## Flock SDK - All Features Demo
## Covers every feature in the Godot plugin

# ── References ──────────────────────────────────────────────────────────────
@onready var output_label: RichTextLabel = %OutputLabel
@onready var tab_container: TabContainer = %TabContainer

# Auth
@onready var auth_email_input: LineEdit = %AuthEmailInput
@onready var auth_password_input: LineEdit = %AuthPasswordInput
@onready var auth_player_id_label: Label = %AuthPlayerIdLabel
@onready var auth_token_label: Label = %AuthTokenLabel
@onready var reg_name_input: LineEdit = %RegNameInput

# Player Data
@onready var player_data_id_input: LineEdit = %PlayerDataIdInput
@onready var player_template_id_input: LineEdit = %PlayerTemplateIdInput
@onready var player_tag_input: LineEdit = %PlayerTagInput
@onready var player_data_output: RichTextLabel = %PlayerDataOutput

# Config
@onready var config_name_input: LineEdit = %ConfigNameInput
@onready var config_id_input: LineEdit = %ConfigIdInput
@onready var config_output: RichTextLabel = %ConfigOutput

# Shop
@onready var shop_id_input: LineEdit = %ShopIdInput
@onready var shop_item_id_input: LineEdit = %ShopItemIdInput
@onready var shop_output: RichTextLabel = %ShopOutput

# Commands
@onready var cmd_player_data_id_input: LineEdit = %CmdPlayerDataIdInput
@onready var cmd_key_input: LineEdit = %CmdKeyInput
@onready var cmd_value_input: LineEdit = %CmdValueInput
@onready var cmd_currency_input: LineEdit = %CmdCurrencyInput
@onready var cmd_amount_input: LineEdit = %CmdAmountInput
@onready var cmd_achievement_input: LineEdit = %CmdAchievementInput
@onready var cmd_output: RichTextLabel = %CmdOutput

# Asset
@onready var asset_id_input: LineEdit = %AssetIdInput
@onready var asset_name_input: LineEdit = %AssetNameInput
@onready var asset_output: RichTextLabel = %AssetOutput

# Analytics
@onready var event_name_input: LineEdit = %EventNameInput
@onready var event_props_input: LineEdit = %EventPropsInput
@onready var error_message_input: LineEdit = %ErrorMessageInput
@onready var error_code_input: LineEdit = %ErrorCodeInput
@onready var analytics_output: RichTextLabel = %AnalyticsOutput

# Session
@onready var session_output: RichTextLabel = %SessionOutput

# Events
@onready var events_output: RichTextLabel = %EventsOutput

# Game
@onready var game_output: RichTextLabel = %GameOutput

# Auth name check
@onready var check_name_input: LineEdit = %CheckNameInput

# Transaction
@onready var tx_amount_input: LineEdit = %TxAmountInput
@onready var tx_currency_input: LineEdit = %TxCurrencyInput
@onready var tx_item_id_input: LineEdit = %TxItemIdInput

# Email verify
@onready var verify_code_input: LineEdit = %VerifyCodeInput

# Password reset
@onready var reset_email_input: LineEdit = %ResetEmailInput
@onready var reset_code_input: LineEdit = %ResetCodeInput
@onready var reset_new_pw_input: LineEdit = %ResetNewPwInput


func _ready() -> void:
	_log_output("=== Flock SDK All Features Demo ===")
	_log_output("Initializing SDK...")

	FlockEvents.get_instance().initialized.connect(_on_initialized)
	FlockEvents.get_instance().initialization_failed.connect(_on_init_failed)
	FlockEvents.get_instance().authenticated.connect(_on_authenticated)
	FlockEvents.get_instance().token_refreshed.connect(_on_token_refreshed)
	FlockEvents.get_instance().auth_expired.connect(_on_auth_expired)
	FlockEvents.get_instance().logged_out.connect(_on_logged_out)
	FlockEvents.get_instance().session_restored.connect(_on_session_restored)
	FlockEvents.get_instance().session_started.connect(_on_session_started)
	FlockEvents.get_instance().session_ended.connect(_on_session_ended)
	FlockEvents.get_instance().session_paused.connect(_on_session_paused)
	FlockEvents.get_instance().session_resumed.connect(_on_session_resumed)
	FlockEvents.get_instance().consent_changed.connect(_on_consent_changed)

	# Update session info (SDK not ready yet, deferred to _on_initialized)
	_update_session_info()


func _update_auth_labels() -> void:
	var client = FlockClient.get_instance()
	auth_player_id_label.text = "Player ID: %s" % client.current_player_id
	var claims = client.token_claims
	var exp = claims.get("expiration_time", 0)
	auth_token_label.text = "Token expires: %s" % Time.get_datetime_string_from_unix_time(int(exp)) if exp else "N/A"


func _update_session_info() -> void:
	var client = FlockClient.get_instance()
	if client.session:
		var s = client.session
		var text := "Session Active: %s\n" % str(s.is_active)
		text += "Session ID: %s\n" % s.session_id
		text += "Server Session ID: %s\n" % s.server_session_id
		text += "Session Number: %d\n" % s.session_number
		text += "Elapsed: %.1fs\n" % s.elapsed_seconds
		text += "FPS: avg=%.1f min=%.1f max=%.1f\n" % [s.average_fps, s.min_fps, s.max_fps]
		text += "Screens Viewed: %d\n" % s.screens_viewed
		text += "Pause Count: %d\n" % s.pause_count
		session_output.text = text
	else:
		session_output.text = "No active session"


# ═══════════════════════════════════════════════════════════════════════════
# AUTH
# ═══════════════════════════════════════════════════════════════════════════

func _on_login_device_pressed() -> void:
	_log_output("[Auth] Login with device...")
	var result = await FlockClient.get_instance().auth.login_with_device()
	_handle_auth_result("Device login", result)


func _on_login_email_pressed() -> void:
	var email = auth_email_input.text.strip_edges()
	var pw = auth_password_input.text.strip_edges()
	if email.is_empty() or pw.is_empty():
		_log_output("[Auth] Email and password required")
		return
	_log_output("[Auth] Login with email...")
	var result = await FlockClient.get_instance().auth.login_with_email(email, pw)
	_handle_auth_result("Email login", result)


func _on_register_email_pressed() -> void:
	var email = auth_email_input.text.strip_edges()
	var pw = auth_password_input.text.strip_edges()
	var name = reg_name_input.text.strip_edges()
	if email.is_empty() or pw.is_empty():
		_log_output("[Auth] Email and password required")
		return
	_log_output("[Auth] Register with email...")
	var result = await FlockClient.get_instance().auth.register_with_email(email, pw, name)
	_handle_auth_result("Email register", result)


func _on_register_device_pressed() -> void:
	var name = reg_name_input.text.strip_edges()
	_log_output("[Auth] Register with device...")
	var result = await FlockClient.get_instance().auth.register_with_device(
		FlockClient.get_instance().auth._get_or_create_device_id(),
		name
	)
	_handle_auth_result("Device register", result)


func _on_logout_pressed() -> void:
	_log_output("[Auth] Logging out...")
	FlockClient.get_instance().auth.logout()
	auth_player_id_label.text = "Player ID: -"
	auth_token_label.text = "Token: -"


func _on_revoke_token_pressed() -> void:
	_log_output("[Auth] Revoking token...")
	var result = await FlockClient.get_instance().auth.revoke_token()
	if result is Dictionary and result.has("error"):
		_log_output("[Auth] Revoke failed: %s" % result.get("error", ""))
	else:
		_log_output("[Auth] Token revoked")


func _on_check_name_pressed() -> void:
	var name_text = check_name_input.text.strip_edges()
	if name_text.is_empty():
		_log_output("[Auth] Enter a name to check")
		return
	_log_output("[Auth] Checking name availability: %s" % name_text)
	var result = await FlockClient.get_instance().auth.is_name_available(name_text)
	_log_output("[Auth] Name result: %s" % str(result))


func _on_forgot_password_pressed() -> void:
	var email = auth_email_input.text.strip_edges()
	if email.is_empty():
		_log_output("[Auth] Enter email first")
		return
	_log_output("[Auth] Forgot password for: %s" % email)
	var result = await FlockClient.get_instance().auth.forgot_password(email)
	_handle_result("[Auth] Forgot password", result)


func _on_reset_password_pressed() -> void:
	var email = reset_email_input.text.strip_edges()
	var code = reset_code_input.text.strip_edges()
	var new_pw = reset_new_pw_input.text.strip_edges()
	if email.is_empty() or code.is_empty() or new_pw.is_empty():
		_log_output("[Auth] Fill email, code, and new password")
		return
	_log_output("[Auth] Resetting password...")
	var result = await FlockClient.get_instance().auth.reset_password(email, code, new_pw)
	_handle_result("[Auth] Reset password", result)


func _on_send_verification_pressed() -> void:
	_log_output("[Auth] Sending email verification...")
	var result = await FlockClient.get_instance().auth.send_email_verification()
	_handle_result("[Auth] Send verification", result)


func _on_verify_email_pressed() -> void:
	var code = verify_code_input.text.strip_edges()
	if code.is_empty():
		_log_output("[Auth] Enter verification code")
		return
	_log_output("[Auth] Verifying email...")
	var result = await FlockClient.get_instance().auth.verify_email(code)
	_handle_result("[Auth] Verify email", result)


func _handle_auth_result(context: String, result: Variant) -> void:
	if result is Dictionary and result.has("error"):
		_log_output("[Auth] %s failed: %s" % [context, result.get("error", "")])
	elif result is Dictionary:
		_log_output("[Auth] %s succeeded" % context)
		_update_auth_labels()
	else:
		_log_output("[Auth] %s: unexpected response" % context)


# ═══════════════════════════════════════════════════════════════════════════
# PLAYER DATA
# ═══════════════════════════════════════════════════════════════════════════

func _on_get_all_player_data_pressed() -> void:
	_require_auth()
	_log_output("[Player] Fetching all player data...")
	var result = await FlockClient.get_instance().player.get_all_data_async()
	_log_json("[Player] All data", result, player_data_output)


func _on_get_player_data_by_id_pressed() -> void:
	_require_auth()
	var id = player_data_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Player] Enter a player data ID")
		return
	_log_output("[Player] Fetching data by ID: %s" % id)
	var result = await FlockClient.get_instance().player.get_data_by_id_async(id)
	_log_json("[Player] Data by ID", result, player_data_output)


func _on_get_my_data_by_template_pressed() -> void:
	_require_auth()
	var tid = player_template_id_input.text.strip_edges()
	if tid.is_empty():
		_log_output("[Player] Enter a template ID")
		return
	_log_output("[Player] Fetching my data for template: %s" % tid)
	var result = await FlockClient.get_instance().player.get_my_data_by_template_async(tid)
	_log_json("[Player] My data by template", result, player_data_output)


func _on_get_my_data_by_tag_pressed() -> void:
	_require_auth()
	var tag = player_tag_input.text.strip_edges()
	if tag.is_empty():
		_log_output("[Player] Enter a tag")
		return
	_log_output("[Player] Fetching my data by tag: %s" % tag)
	var result = await FlockClient.get_instance().player.get_my_data_by_tag_async(tag)
	_log_json("[Player] My data by tag", result, player_data_output)


func _on_get_templates_pressed() -> void:
	_log_output("[Player] Fetching templates...")
	var result = await FlockClient.get_instance().player.get_templates_async()
	_log_json("[Player] Templates", result, player_data_output)


func _on_get_template_by_tag_pressed() -> void:
	var tag = player_tag_input.text.strip_edges()
	if tag.is_empty():
		_log_output("[Player] Enter a tag")
		return
	_log_output("[Player] Fetching template by tag: %s" % tag)
	var result = await FlockClient.get_instance().player.get_template_by_tag_async(tag)
	_log_json("[Player] Template by tag", result, player_data_output)


func _on_get_ban_pressed() -> void:
	_require_auth()
	_log_output("[Player] Checking ban status...")
	var result = await FlockClient.get_instance().player.get_ban_async(
		FlockClient.get_instance().current_player_id
	)
	_log_json("[Player] Ban status", result, player_data_output)


func _on_clear_player_cache_pressed() -> void:
	FlockClient.get_instance().player.clear_cache()
	_log_output("[Player] Cache cleared")


# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

func _on_get_all_patches_pressed() -> void:
	_log_output("[Config] Fetching all patches...")
	var result = await FlockClient.get_instance().config.get_all_patches()
	_log_json("[Config] All patches", result, config_output)


func _on_get_config_by_name_pressed() -> void:
	var name_text = config_name_input.text.strip_edges()
	if name_text.is_empty():
		_log_output("[Config] Enter a config name")
		return
	_log_output("[Config] Fetching config by name: %s" % name_text)
	var result = await FlockClient.get_instance().config.get_game_config_by_name(name_text)
	_log_json("[Config] By name", result, config_output)


func _on_get_config_by_id_pressed() -> void:
	var id = config_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Config] Enter a config ID")
		return
	_log_output("[Config] Fetching config by ID: %s" % id)
	var result = await FlockClient.get_instance().config.get_by_config_id(id)
	_log_json("[Config] By ID", result, config_output)


func _on_get_patches_by_schema_pressed() -> void:
	var id = config_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Config] Enter a schema/config ID")
		return
	_log_output("[Config] Fetching patches by schema: %s" % id)
	var result = await FlockClient.get_instance().config.get_by_schema(id)
	_log_json("[Config] Patches by schema", result, config_output)


func _on_clear_config_cache_pressed() -> void:
	FlockClient.get_instance().config.clear_cache()
	_log_output("[Config] Cache cleared")


# ═══════════════════════════════════════════════════════════════════════════
# GAME
# ═══════════════════════════════════════════════════════════════════════════

func _on_get_game_pressed() -> void:
	_log_output("[Game] Fetching game...")
	var result = await FlockClient.get_instance().game.get_game_async()
	_log_json("[Game] Game", result, game_output)


func _on_get_game_version_pressed() -> void:
	_log_output("[Game] Fetching game version...")
	var result = await FlockClient.get_instance().game.get_game_version_async()
	_log_json("[Game] Version", result, game_output)


func _on_clear_game_cache_pressed() -> void:
	FlockClient.get_instance().game.clear_cache()
	_log_output("[Game] Cache cleared")


# ═══════════════════════════════════════════════════════════════════════════
# SHOP
# ═══════════════════════════════════════════════════════════════════════════

func _on_get_all_shops_pressed() -> void:
	_log_output("[Shop] Fetching all shops...")
	var result = await FlockClient.get_instance().shop.get_all_async()
	_log_json("[Shop] All shops", result, shop_output)


func _on_get_shop_by_id_pressed() -> void:
	var id = shop_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Shop] Enter a shop ID")
		return
	_log_output("[Shop] Fetching shop by ID: %s" % id)
	var result = await FlockClient.get_instance().shop.get_by_id_async(id)
	_log_json("[Shop] By ID", result, shop_output)


func _on_get_shop_items_pressed() -> void:
	var id = shop_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Shop] Enter a shop ID")
		return
	_log_output("[Shop] Fetching items for shop: %s" % id)
	var result = await FlockClient.get_instance().shop.get_items_by_shop_async(id)
	_log_json("[Shop] Items", result, shop_output)


func _on_get_shop_item_pressed() -> void:
	var id = shop_item_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Shop] Enter an item ID")
		return
	_log_output("[Shop] Fetching item: %s" % id)
	var result = await FlockClient.get_instance().shop.get_item_async(id)
	_log_json("[Shop] Item", result, shop_output)


func _on_purchase_item_pressed() -> void:
	_require_auth()
	var item_id = shop_item_id_input.text.strip_edges()
	if item_id.is_empty():
		_log_output("[Shop] Enter an item ID to purchase")
		return
	_log_output("[Shop] Purchasing item: %s" % item_id)
	var result = await FlockClient.get_instance().shop.purchase_async(item_id)
	_handle_result("[Shop] Purchase", result)


func _on_get_inventory_pressed() -> void:
	_require_auth()
	_log_output("[Shop] Fetching inventory...")
	var result = await FlockClient.get_instance().shop.get_player_inventory_async()
	_log_json("[Shop] Inventory", result, shop_output)


func _on_clear_shop_cache_pressed() -> void:
	FlockClient.get_instance().shop.clear_cache()
	_log_output("[Shop] Cache cleared")


# ═══════════════════════════════════════════════════════════════════════════
# COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

func _on_cmd_update_data_pressed() -> void:
	_require_auth()
	var pd_id = cmd_player_data_id_input.text.strip_edges()
	if pd_id.is_empty():
		_log_output("[Cmd] Enter a player data ID")
		return
	_log_output("[Cmd] Updating player data: %s" % pd_id)
	var result = await FlockClient.get_instance().commands.update_player_data_async(pd_id, [{"key": "test", "value": "hello"}])
	_handle_result("[Cmd] Update data", result)


func _on_cmd_update_field_pressed() -> void:
	_require_auth()
	var pd_id = cmd_player_data_id_input.text.strip_edges()
	var key = cmd_key_input.text.strip_edges()
	var val = cmd_value_input.text.strip_edges()
	if pd_id.is_empty() or key.is_empty():
		_log_output("[Cmd] Enter player data ID, key, and value")
		return
	_log_output("[Cmd] Updating field: %s.%s = %s" % [pd_id, key, val])
	var result = await FlockClient.get_instance().commands.update_player_data_field_async(pd_id, key, val)
	_handle_result("[Cmd] Update field", result)


func _on_cmd_add_funds_pressed() -> void:
	_require_auth()
	var currency = cmd_currency_input.text.strip_edges()
	var amount_text = cmd_amount_input.text.strip_edges()
	if currency.is_empty() or amount_text.is_empty():
		_log_output("[Cmd] Enter currency and amount")
		return
	_log_output("[Cmd] Adding funds: %s %s" % [amount_text, currency])
	var result = await FlockClient.get_instance().commands.add_game_funds_async(currency, int(amount_text))
	_handle_result("[Cmd] Add funds", result)


func _on_cmd_unlock_achievement_pressed() -> void:
	_require_auth()
	var achievement = cmd_achievement_input.text.strip_edges()
	if achievement.is_empty():
		_log_output("[Cmd] Enter achievement name")
		return
	_log_output("[Cmd] Unlocking achievement: %s" % achievement)
	var result = await FlockClient.get_instance().commands.unlock_achievement_async(achievement)
	_handle_result("[Cmd] Unlock achievement", result)


func _on_cmd_flush_pressed() -> void:
	_log_output("[Cmd] Flushing pending writes...")
	await FlockClient.get_instance().commands.flush_pending_writes_async()
	_log_output("[Cmd] Flush complete")


func _on_cmd_clear_player_data_cache_pressed() -> void:
	FlockClient.get_instance().player.clear_cache()
	_log_output("[Cmd] Player cache cleared")


# ═══════════════════════════════════════════════════════════════════════════
# ASSETS
# ═══════════════════════════════════════════════════════════════════════════

func _on_get_all_assets_pressed() -> void:
	_log_output("[Asset] Fetching all assets...")
	var result = await FlockClient.get_instance().asset.get_all_async()
	_log_json("[Asset] All", result, asset_output)


func _on_get_asset_by_id_pressed() -> void:
	var id = asset_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Asset] Enter an asset ID")
		return
	_log_output("[Asset] Fetching asset by ID: %s" % id)
	var result = await FlockClient.get_instance().asset.get_by_id_async(id)
	_log_json("[Asset] By ID", result, asset_output)


func _on_get_asset_by_name_pressed() -> void:
	var name_text = asset_name_input.text.strip_edges()
	if name_text.is_empty():
		_log_output("[Asset] Enter an asset name")
		return
	_log_output("[Asset] Fetching asset by name: %s" % name_text)
	var result = await FlockClient.get_instance().asset.get_by_name_async(name_text)
	_log_json("[Asset] By name", result, asset_output)


func _on_download_asset_pressed() -> void:
	var id = asset_id_input.text.strip_edges()
	if id.is_empty():
		_log_output("[Asset] Enter an asset ID to download")
		return
	_log_output("[Asset] Downloading asset: %s" % id)
	var result = await FlockClient.get_instance().asset.download_async(id)
	_handle_result("[Asset] Download", result)


func _on_clear_asset_cache_pressed() -> void:
	FlockClient.get_instance().asset.clear_cache()
	_log_output("[Asset] Cache cleared. Dir: %s" % FlockClient.get_instance().asset.cache_directory)


# ═══════════════════════════════════════════════════════════════════════════
# ANALYTICS
# ═══════════════════════════════════════════════════════════════════════════

func _on_log_event_pressed() -> void:
	_require_auth()
	var event_name = event_name_input.text.strip_edges()
	if event_name.is_empty():
		event_name = "test_event"
	var props_text = event_props_input.text.strip_edges()
	var props := {}
	if not props_text.is_empty():
		var parsed = JSON.parse_string(props_text)
		if parsed is Dictionary:
			props = parsed
	_log_output("[Analytics] Logging event: %s %s" % [event_name, str(props)])
	FlockClient.get_instance().analytics.log_event(event_name, props)
	_log_output("[Analytics] Event logged (will flush on next interval)")


func _on_log_error_pressed() -> void:
	var msg = error_message_input.text.strip_edges()
	var code = error_code_input.text.strip_edges()
	if msg.is_empty():
		msg = "Test error"
	if code.is_empty():
		code = "TEST_ERROR"
	_log_output("[Analytics] Logging error: %s [%s]" % [msg, code])
	FlockClient.get_instance().analytics.log_error(msg, code)
	_log_output("[Analytics] Error logged")


func _on_log_exception_pressed() -> void:
	_log_output("[Analytics] Logging exception...")
	FlockClient.get_instance().analytics.log_exception("Test exception from demo")
	_log_output("[Analytics] Exception logged")


func _on_record_transaction_pressed() -> void:
	_require_auth()
	var amount = float(tx_amount_input.text.strip_edges()) if not tx_amount_input.text.strip_edges().is_empty() else 9.99
	var currency = tx_currency_input.text.strip_edges()
	if currency.is_empty():
		currency = "USD"
	var item_id = tx_item_id_input.text.strip_edges()
	_log_output("[Analytics] Recording transaction: %.2f %s" % [amount, currency])
	var result = await FlockClient.get_instance().analytics.record_transaction_async({
		"player_id": FlockClient.get_instance().current_player_id,
		"amount": amount,
		"currency_code": currency,
		"shop_item_id": item_id,
		"quantity": 1,
		"transaction_type": "purchase",
		"status": "completed",
	})
	_handle_result("[Analytics] Transaction", result)


func _on_record_screen_view_pressed() -> void:
	var screen_name = event_name_input.text.strip_edges()
	if screen_name.is_empty():
		screen_name = "demo_screen"
	_log_output("[Analytics] Recording screen view: %s" % screen_name)
	FlockClient.get_instance().analytics.record_screen_view(screen_name)


func _on_flush_analytics_pressed() -> void:
	_log_output("[Analytics] Flushing analytics...")
	await FlockClient.get_instance().analytics.flush_async()
	_log_output("[Analytics] Flush complete")


func _on_start_session_pressed() -> void:
	_require_auth()
	_log_output("[Analytics] Starting session...")
	var result = await FlockClient.get_instance().analytics.start_session_async()
	_handle_result("[Analytics] Start session", result)
	_update_session_info()


func _on_end_session_pressed() -> void:
	_log_output("[Analytics] Ending session...")
	var result = await FlockClient.get_instance().analytics.end_session_async()
	_handle_result("[Analytics] End session", result)
	_update_session_info()


func _on_set_consent_pressed() -> void:
	var granted = FlockClient.get_instance().analytics != null and FlockClient.get_instance().analytics is FlockAnalyticsProvider
	FlockClient.get_instance().analytics.set_consent(not granted)
	_log_output("[Analytics] Consent set to: %s" % str(not granted))


func _on_erase_analytics_pressed() -> void:
	FlockClient.get_instance().analytics.erase_local_analytics_data()
	_log_output("[Analytics] Local analytics data erased")


func _on_refresh_session_info_pressed() -> void:
	_update_session_info()


func _on_get_device_info_pressed() -> void:
	var info = FlockDeviceInfo.capture()
	_log_json("[Analytics] Device Info", info, analytics_output)


# ═══════════════════════════════════════════════════════════════════════════
# CLIENT INFO
# ═══════════════════════════════════════════════════════════════════════════

func _on_refresh_client_info_pressed() -> void:
	var client = FlockClient.get_instance()
	var text := "Initialized: %s\n" % str(FlockClient.is_initialized)
	text += "Authenticated: %s\n" % str(client.is_authenticated)
	text += "Token Expired: %s\n" % str(client.is_token_expired)
	text += "Player ID: %s\n" % client.current_player_id
	text += "Game ID: %s\n" % client.game_id
	text += "Game Version ID: %s\n" % client.game_version_id
	text += "API URL: %s\n" % client.get_api_url()
	text += "Versioned URL: %s\n" % client.get_versioned_api_url()
	text += "Reachable: %s\n" % str(client.is_reachable())
	text += "Has Active Session: %s\n" % str(client.has_active_session)
	text += "Current Session ID: %s\n" % client.current_session_id
	text += "SDK Version: %s\n" % FlockSdkVersion.CURRENT
	text += "Base Headers: %s" % str(client.get_base_headers())
	output_label.text = text
	_log_output("[Client] Info refreshed")


func _on_shutdown_pressed() -> void:
	_log_output("[Client] Shutting down SDK...")
	FlockClient.get_instance().shutdown()
	output_label.text = "SDK Shutdown"


func _on_delete_data_dir_pressed() -> void:
	var dir = FlockUtil.flock_data_dir()
	_log_output("[Client] Data directory: %s" % dir)
	_log_output("[Client] Snapshots dir: %s" % FlockUtil.flock_snapshots_dir())
	_log_output("[Client] Assets dir: %s" % FlockUtil.flock_assets_dir())


# ═══════════════════════════════════════════════════════════════════════════
# SIGNAL HANDLERS
# ═══════════════════════════════════════════════════════════════════════════

func _on_initialized() -> void:
	_log_event("INITIALIZED")
	# Try restore session now that SDK is ready
	if FlockClient.get_instance().is_authenticated:
		_log_output("Already authenticated: %s" % FlockClient.get_instance().current_player_id)
		_update_auth_labels()
	else:
		var restored = FlockClient.get_instance().auth.try_restore_session()
		if restored:
			_log_output("Session restored")
	_update_session_info()


func _on_init_failed(error: String) -> void:
	_log_event("INIT_FAILED: %s" % error)


func _on_authenticated(info: Dictionary) -> void:
	_log_event("AUTHENTICATED: %s via %s" % [info.get("player_id", ""), info.get("method", "")])
	_update_auth_labels()


func _on_token_refreshed() -> void:
	_log_event("TOKEN_REFRESHED")
	_update_auth_labels()


func _on_auth_expired() -> void:
	_log_event("AUTH_EXPIRED")


func _on_logged_out() -> void:
	_log_event("LOGGED_OUT")
	auth_player_id_label.text = "Player ID: -"
	auth_token_label.text = "Token: -"


func _on_session_restored(restored: bool) -> void:
	_log_event("SESSION_RESTORED: %s" % str(restored))
	_update_session_info()


func _on_session_started(session_id: String) -> void:
	_log_event("SESSION_STARTED: %s" % session_id)
	_update_session_info()


func _on_session_ended(args: Dictionary) -> void:
	_log_event("SESSION_ENDED: %s" % str(args))
	_update_session_info()


func _on_session_paused() -> void:
	_log_event("SESSION_PAUSED")
	_update_session_info()


func _on_session_resumed() -> void:
	_log_event("SESSION_RESUMED")
	_update_session_info()


func _on_consent_changed(granted: bool) -> void:
	_log_event("CONSENT_CHANGED: %s" % str(granted))


# ═══════════════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════════════

func _require_auth() -> void:
	if not FlockClient.get_instance().is_authenticated:
		_log_output("[!] Not authenticated — login first")


func _handle_result(context: String, result: Variant) -> void:
	if result is Dictionary and result.has("error"):
		_log_output("%s failed: %s" % [context, result.get("error", "")])
	elif result is Dictionary:
		_log_output("%s succeeded" % context)
	else:
		_log_output("%s: %s" % [context, str(result)])


func _log_output(msg: String) -> void:
	var time = Time.get_time_string_from_system()
	output_label.text = "[%s] %s\n%s" % [time, msg, output_label.text]


func _log_event(msg: String) -> void:
	var time = Time.get_time_string_from_system()
	events_output.text = "[%s] %s\n%s" % [time, msg, events_output.text]


func _log_json(context: String, data: Variant, target: RichTextLabel = null) -> void:
	var text := ""
	if data is Dictionary:
		if data.has("error"):
			text = "%s failed: %s" % [context, data.get("error", "")]
		else:
			text = "%s:\n%s" % [context, JSON.stringify(data, "  ")]
	elif data is Array:
		text = "%s (%d items):\n%s" % [context, data.size(), JSON.stringify(data, "  ")]
	else:
		text = "%s: %s" % [context, str(data)]

	_log_output(text)
	if target:
		target.text = text
