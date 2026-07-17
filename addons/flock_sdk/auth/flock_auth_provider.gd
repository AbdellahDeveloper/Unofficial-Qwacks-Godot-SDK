class_name FlockAuthProvider
extends FlockProviderBase

const PREF_KEY_AUTH_METHOD := "flock_auth_method"

var _current_auth_method: String = ""

func _init(client: FlockClient) -> void:
	super(client)


# --- Login Methods ---

func login_with_email(email: String, password: String) -> Variant:
	var request := AuthModels.login_request("email", email, password)
	return await _execute_auth(request, "Email login", "Email")


func login_with_device(device_id: String = "") -> Variant:
	if device_id.is_empty():
		device_id = _get_or_create_device_id()
	var device_type := OS.get_model_name() if OS.get_name() != "Windows" else OS.get_name()
	var request := AuthModels.device_login_request(device_type, device_id)

	# Try login first
	var result = await _execute_auth(request, "Device login", "Device")

	# If login fails with invalid credentials, auto-register then retry
	if result is Dictionary and result.get("code", "") == "player.invalid_login_credentials":
		_client._logger.log_info("Device not registered, attempting auto-registration...")
		var reg_request := AuthModels.device_registration_request(device_type, device_id)
		var reg_result = await _execute_direct(reg_request, "Device registration", FlockEndpoints.PLAYER_REGISTER_DEVICE)

		if reg_result is Dictionary:
			# Registration succeeded — return raw result, caller handles tokens
			if reg_result.has("access_token"):
				var access_token: String = reg_result.get("access_token", "")
				if not access_token.is_empty():
					_client.set_tokens(access_token, reg_result.get("refresh_token", ""))
					_current_auth_method = "Device"
					_persist_auth_method("Device")
					_client._logger.log_info("Device registration successful for player: %s" % _client.current_player_id)
					FlockEvents.get_instance().invoke_authenticated({
						"player_id": _client.current_player_id,
						"method": "Device",
					})
					await _try_initialize_analytics()
					return reg_result

			# Already registered — retry login
			if reg_result.get("code", "") == "player.device_already_registered":
				_client._logger.log_info("Device already registered, retrying login...")
				return await _execute_auth(request, "Device login", "Device")

			return reg_result

	return result


func login_with_google(id_token: String) -> Variant:
	var request := AuthModels.google_login_request(id_token)
	return await _execute_auth(request, "Google login", "Google")


func login_with_apple(identity_token: String) -> Variant:
	var request := AuthModels.apple_login_request(identity_token)
	return await _execute_auth(request, "Apple login", "Apple")


func login_with_steam(session_ticket: String) -> Variant:
	var request := AuthModels.steam_login_request(session_ticket)
	return await _execute_auth(request, "Steam login", "Steam")


func login_with_facebook(facebook_id: String) -> Variant:
	var request := AuthModels.login_request("facebook", "", "", "", "", facebook_id, "")
	return await _execute_auth(request, "Facebook login", "Facebook")


func login_with_discord(discord_id: String) -> Variant:
	var request := AuthModels.login_request("discord", "", "", "", "", "", discord_id)
	return await _execute_auth(request, "Discord login", "Discord")


# --- Registration Methods ---

func register_with_email(email: String, password: String, name: String = "") -> Variant:
	var request := AuthModels.email_registration_request(email, password, name)
	return await _execute_registration(request, "Email registration", "Email")


func register_with_device(device_id: String, name: String = "") -> Variant:
	var device_type := OS.get_model_name() if OS.get_name() != "Windows" else OS.get_name()
	var request := AuthModels.device_registration_request(device_type, device_id, name)
	return await _execute_registration(request, "Device registration", "Device")


func register_with_google(id_token: String, name: String = "") -> Variant:
	var request := AuthModels.google_registration_request(id_token, name)
	return await _execute_registration(request, "Google registration", "Google")


func register_with_apple(identity_token: String, name: String = "") -> Variant:
	var request := AuthModels.apple_registration_request(identity_token, name)
	return await _execute_registration(request, "Apple registration", "Apple")


func register_with_steam(session_ticket: String, name: String = "") -> Variant:
	var request := AuthModels.steam_registration_request(session_ticket, name)
	return await _execute_registration(request, "Steam registration", "Steam")


# --- Account Flows ---

func forgot_password(email: String) -> Variant:
	require_not_empty(email, "email")
	var request := AuthModels.password_forgot_request(email)
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_PASSWORD_FORGOT]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Password forgot", false)


func reset_password(email: String, code: String, new_password: String) -> Variant:
	require_not_empty(email, "email")
	require_not_empty(code, "code")
	require_not_empty(new_password, "new_password")
	_require_email_login()
	var request := AuthModels.password_reset_request(email, code, new_password)
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_PASSWORD_RESET]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Password reset", false)


func send_email_verification() -> Variant:
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_EMAIL_SEND_VERIFICATION]
		return await FlockHttpClient.post_async(url, {}, _client.get_base_headers())
	, "Send email verification", false)


func verify_email(code: String) -> Variant:
	require_not_empty(code, "code")
	var request := AuthModels.email_verify_request(code)
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_EMAIL_VERIFY]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Verify email", false)


func revoke_token() -> Variant:
	_require_authenticated()
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_TOKEN_REVOKE]
		return await FlockHttpClient.post_async(url, {}, _client.get_base_headers())
	, "Token revoke", false)


func is_name_available(name: String) -> Variant:
	require_not_empty(name, "name")
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.player_name_available(name)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Name availability")


# --- Session Restore ---

func try_restore_session() -> bool:
	FlockClient.is_restoring_session = true
	var restored := false
	restored = await _restore_session_core()
	FlockClient.is_restoring_session = false
	FlockEvents.get_instance().invoke_session_restored(restored)
	return restored


func _restore_session_core() -> bool:
	var stored := _client.load_persisted_tokens()
	if stored.is_empty() or stored.get("access_token", "").is_empty():
		return false

	_client.set_tokens(stored.get("access_token", ""), stored.get("refresh_token", ""))

	if _client.is_token_expired:
		var refreshed := await _client.try_refresh_token()
		if not refreshed:
			return false

	_client._logger.log_info("Restored session for PlayerId: %s" % _client.current_player_id)
	_current_auth_method = _load_persisted_auth_method()
	if _current_auth_method.is_empty():
		_current_auth_method = "SessionRestore"

	FlockEvents.get_instance().invoke_authenticated({
		"player_id": _client.current_player_id,
		"method": _current_auth_method,
	})

	await _try_initialize_analytics()
	return true


# --- Logout ---

func logout() -> void:
	var was_authenticated := _client.is_authenticated
	_current_auth_method = ""
	_persist_auth_method("")
	_client.clear_tokens()
	if was_authenticated:
		FlockEvents.get_instance().invoke_logged_out()


# --- Internal ---

func _execute_direct(request: Dictionary, context: String, endpoint: String) -> Variant:
	_client._logger.log_info("%s starting..." % context)
	var url := "%s/%s" % [_client.get_versioned_api_url(), endpoint]
	return await FlockHttpClient.post_async(url, request, _client.get_base_headers())


func _execute_auth(request: Dictionary, context: String, method: String, endpoint: String = "") -> Variant:
	_client._logger.log_info("%s starting..." % context)
	var retry_handler := RetryPolicy.RetryHandler.new(
		_client._init_config.retry_policy if _client._init_config.retry_policy.size() > 0 else null,
		_client._logger
	)

	if endpoint.is_empty():
		endpoint = _get_login_endpoint(method)

	var result = await retry_handler.execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), endpoint]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	)

	if result is Dictionary and result.has("error"):
		_client._logger.log_error("%s failed: %s" % [context, result.get("error", "")])
		return result

	if result is Dictionary:
		var response: Dictionary = result
		var access_token: String = response.get("access_token", "")
		if access_token.is_empty():
			return {"error": "Invalid %s response from server" % context.to_lower()}

		_client.set_tokens(access_token, response.get("refresh_token", ""))
		_current_auth_method = method
		_persist_auth_method(method)
		_client._logger.log_info("%s successful for player: %s" % [context, _client.current_player_id])

		FlockEvents.get_instance().invoke_authenticated({
			"player_id": _client.current_player_id,
			"method": method,
		})

		await _try_initialize_analytics()
		return response

	return {"error": "Unexpected response from server"}


func _execute_registration(request: Dictionary, context: String, method: String) -> Variant:
	var result = await _execute_auth(request, context, method, _get_register_endpoint(method))
	# If already registered, return null (Unity SDK pattern)
	if result is Dictionary and result.has("code"):
		if FlockErrorCodes.is_already_registered(FlockException.new(result.get("error", ""))):
			_client._logger.log_warning("%s skipped: player already registered." % context)
			return null
	return result


func _get_login_endpoint(method: String) -> String:
	match method:
		"Email": return FlockEndpoints.PLAYER_LOGIN
		"Device": return FlockEndpoints.PLAYER_LOGIN_DEVICE
		"Google": return FlockEndpoints.PLAYER_LOGIN_GOOGLE
		"Apple": return FlockEndpoints.PLAYER_LOGIN_APPLE
		"Steam": return FlockEndpoints.PLAYER_LOGIN_STEAM
		_: return FlockEndpoints.PLAYER_LOGIN


func _get_register_endpoint(method: String) -> String:
	match method:
		"Email": return FlockEndpoints.PLAYER_REGISTER
		"Device": return FlockEndpoints.PLAYER_REGISTER_DEVICE
		"Google": return FlockEndpoints.PLAYER_REGISTER_GOOGLE
		"Apple": return FlockEndpoints.PLAYER_REGISTER_APPLE
		"Steam": return FlockEndpoints.PLAYER_REGISTER_STEAM
		_: return FlockEndpoints.PLAYER_REGISTER


func _require_authenticated() -> void:
	if not _client.is_authenticated:
		push_error("[Flock SDK] No player is signed in")


func _require_email_login() -> void:
	_require_authenticated()
	if _current_auth_method != "Email":
		push_error("[Flock SDK] Password reset requires being signed in with email")


func _persist_auth_method(method: String) -> void:
	var config := ConfigFile.new()
	config.set_value("flock", PREF_KEY_AUTH_METHOD, method)
	config.save(FlockUtil.flock_data_dir().path_join("auth_method.cfg"))


func _load_persisted_auth_method() -> String:
	var config := ConfigFile.new()
	if config.load(FlockUtil.flock_data_dir().path_join("auth_method.cfg")) != OK:
		return ""
	return config.get_value("flock", PREF_KEY_AUTH_METHOD, "")


func _try_initialize_analytics() -> Variant:
	if _client.analytics == null:
		return {}
	return await _client.analytics.initialize_async()


const DEVICE_ID_PREF := "flock_device_id"

func _get_or_create_device_id() -> String:
	var config := ConfigFile.new()
	var path := FlockUtil.flock_data_dir().path_join("device.cfg")
	if config.load(path) == OK:
		var stored: String = config.get_value("flock", DEVICE_ID_PREF, "")
		if not stored.is_empty():
			return stored

	var device_id := OS.get_unique_id()
	if device_id.is_empty():
		device_id = str(Time.get_unix_time_from_system()).sha256_text().substr(0, 32)

	config.set_value("flock", DEVICE_ID_PREF, device_id)
	config.save(path)
	return device_id
