class_name FlockErrorHints

# Turns a coded server error into the next step the developer should take. Keyed on FlockErrorCode only — never on message text.

# Dashboard-authored content only reaches the game after a codegen sync, which is the step newcomers miss.
const AUTHOR_AND_SYNC := "Author it in the Flock dashboard, then sync the SDK's generated player-data models so the code matches."

const AUTHOR_IN_DASHBOARD := "Author it in the Flock dashboard and publish it to this game version."

static var _hints: Dictionary = _build_hints()


static func _build_hints() -> Dictionary:
	var hints := {
		# Auth — login never creates an account, which is the single most common first-run mistake.
		FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS: "No account matches these credentials. Logging in never creates an account — call the matching authentication register_with_*_async method once first.",
		FlockErrorCode.PLAYER_DEVICE_ALREADY_REGISTERED: "This device already has an account. Call Authentication.login_with_device_async(device_id) instead of registering it again.",
		FlockErrorCode.PLAYER_EMAIL_ALREADY_REGISTERED: "That email already has an account. Call Authentication.login_with_email_async(email, password), or Authentication.forgot_password_async(email) if the password is lost.",
		FlockErrorCode.PLAYER_GOOGLE_ACCOUNT_ALREADY_REGISTERED: "That Google account is already registered. Call Authentication.login_with_google_async(id_token) instead.",
		FlockErrorCode.PLAYER_APPLE_ACCOUNT_ALREADY_REGISTERED: "That Apple account is already registered. Call Authentication.login_with_apple_async(identity_token) instead.",
		FlockErrorCode.PLAYER_STEAM_ACCOUNT_ALREADY_REGISTERED: "That Steam account is already registered. Call Authentication.login_with_steam_async(...) instead.",
		FlockErrorCode.PLAYER_NAME_ALREADY_REGISTERED: "Display names are unique per game. Check Authentication.is_name_available_async(name) first, or register with name: null and set it later.",
		FlockErrorCode.PLAYER_INVALID_REFRESH_TOKEN: "The saved session is no longer valid. Call Authentication.logout() and sign in again.",
		FlockErrorCode.PLAYER_INVALID_VERIFICATION_CODE: "The email verification code is wrong or expired. Call Authentication.send_email_verification_async() to issue a new one.",
		FlockErrorCode.PLAYER_INVALID_RESET_CODE: "The password reset code is wrong or expired. Call Authentication.forgot_password_async(email) to issue a new one.",
		FlockErrorCode.PLAYER_NO_EMAIL_ACCOUNT: "This player has no email credential. Link one with Authentication.link_email_async(email, password) before using email-only flows.",
		FlockErrorCode.PLAYER_ACCOUNT_ALREADY_LINKED: "That credential already belongs to an account. Call Authentication.get_linked_accounts_async() to see what this player is already linked to.",
		FlockErrorCode.PLAYER_ACCOUNT_NOT_LINKED: "That credential is not linked to this player. Link it with the matching Authentication.link_*_async call first.",
		FlockErrorCode.PLAYER_CANNOT_UNLINK_LAST_CREDENTIAL: "A player must keep at least one way to sign in. Link another credential before unlinking this one.",
		FlockErrorCode.PLAYER_GAME_JWK_NOT_CONFIGURED: "The game has no signing key configured. Set it up in the Flock dashboard before players can authenticate.",
		FlockErrorCode.PLAYER_GAME_VERSION_ID_REQUIRED: "This route needs a game version. Pick one in Flock > Settings so it is baked into the build.",
		FlockErrorCode.PLAYER_PLAYER_NOT_FOUND: "No player matches that id. Sign in first — most calls act on FlockClient.get_instance().current_player_id.",

		# Dashboard-authored content the consumer has not created or not synced yet.
		FlockErrorCode.GAME_COMMAND_PLAYER_TEMPLATE_NOT_FOUND: "No player-data template by that name. " + AUTHOR_AND_SYNC,
		FlockErrorCode.PLAYER_TEMPLATE_NOT_FOUND: "No player-data template by that id. " + AUTHOR_AND_SYNC,
		FlockErrorCode.PLAYER_TEMPLATE_NOT_FOUND_BY_NAME: "No player-data template by that name. " + AUTHOR_AND_SYNC,
		FlockErrorCode.GAME_COMMAND_ACHIEVEMENT_NOT_FOUND: "No achievement by that id. " + AUTHOR_AND_SYNC,
		FlockErrorCode.GAME_COMMAND_CURRENCY_NOT_FOUND: "No currency by that name. " + AUTHOR_AND_SYNC,
		FlockErrorCode.SHOP_CURRENCY_TEMPLATE_NOT_FOUND: "No currency template by that name. " + AUTHOR_AND_SYNC,
		FlockErrorCode.GAME_COMMAND_TEMPLATE_VALIDATION_FAILED: "The value does not match the template's schema. Compare the field names and types in the Flock dashboard, then re-sync so the generated models match.",
		FlockErrorCode.GAME_COMMAND_PLAYER_DATA_NOT_LINKED_TO_TEMPLATE: "That record is not linked to a template, so template-aware commands cannot act on it. Re-create it from the template in the Flock dashboard.",
		FlockErrorCode.GAME_COMMAND_NOT_A_WALLET: "That record is not a wallet. Currency commands only work on wallet-typed player data.",
		FlockErrorCode.GAME_COMMAND_NOT_AN_ACHIEVEMENT_RECORD: "That record is not an achievement. Achievement commands only work on achievement-typed player data.",
		FlockErrorCode.GAME_COMMAND_INVALID_AMOUNT: "The amount must be greater than zero.",
		FlockErrorCode.GAME_CONFIG_CONFIG_NOT_FOUND: "No game config by that name. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.GAME_CONFIG_FEATURE_CONFIG_NOT_FOUND: "No feature config by that name. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.NOTIFICATION_TEMPLATE_NOT_FOUND: "No notification template by that name. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.ASSET_ASSET_NOT_FOUND: "No asset by that id. Upload it in the Flock dashboard and publish it to this game version.",
		FlockErrorCode.SHOP_SHOP_NOT_FOUND: "No shop by that name. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.SHOP_ITEM_NOT_FOUND: "No shop item by that id. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.SHOP_ITEM_SHOP_NOT_FOUND: "No shop by that id. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.SHOP_ITEM_SHOP_ITEM_NOT_FOUND: "No shop item by that id. " + AUTHOR_IN_DASHBOARD,
		FlockErrorCode.GAME_GAME_NOT_FOUND: "The API key does not resolve to a game. Check the API Key in Flock > Settings against the dashboard.",
		FlockErrorCode.GAME_VERSION_NOT_FOUND: "That game version does not exist. Pick an existing one in Flock > Settings — the id is baked at build time.",
		FlockErrorCode.GAME_VERSION_BY_NAME_NOT_FOUND: "That game version name does not exist. Pick an existing one in Flock > Settings — the id is baked at build time.",
		FlockErrorCode.GAME_CONFIG_PLAYER_NO_GAME_VERSION: "The player has no game version attached. Pick one in Flock > Settings so it is sent on every request.",

		# Runtime state the caller can act on rather than misconfiguration.
		FlockErrorCode.SHOP_INSUFFICIENT_FUNDS: "The player cannot afford this item. Read the wallet balance before offering the purchase.",
		FlockErrorCode.SHOP_CURRENCY_NOT_HELD: "The player holds no wallet for that currency yet. Grant funds once with Commands.add_game_funds_async to create it.",
		FlockErrorCode.SHOP_WALLET_NOT_FOUND: "The player has no wallet for that currency yet. Grant funds once with Commands.add_game_funds_async to create it.",
		FlockErrorCode.GAME_COMMAND_PLAYER_DATA_NOT_FOUND: "The player has no record for that template yet. Reads do not create it — write it first with Commands.update_player_data_async.",
		FlockErrorCode.PLAYER_DATA_NOT_FOUND: "The player has no record for that template yet. Reads do not create it — write it first with Commands.update_player_data_async.",
		FlockErrorCode.ANALYTICS_CURRENCY_NOT_FOUND: "Transaction analytics need a currency entity for this game. Create one in the Flock dashboard.",
	}
	return hints


# Next step for a coded error, or "" when the SDK has nothing to add beyond the server's own reason.
static func for_code(code: int) -> String:
	if code == FlockErrorCode.UNKNOWN:
		return ""
	return str(_hints.get(code, ""))


# Next step for an auth failure. The credential disambiguates codes that mean different things per method —
# notably invalid_login_credentials, which means "register this device first" but "wrong password" for email.
# `method` is the auth provider's method name ("email", "device", "google", ...).
static func for_auth(code: int, method: String) -> String:
	if code != FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS:
		return for_code(code)

	var m := method.to_lower()
	var name := m.capitalize()
	match m:
		"device":
			return "This device is not registered yet. Call Authentication.register_with_device_async(device_id) once to create the account, then Authentication.login_with_device_async(device_id) on later launches."
		"email":
			return "Wrong email or password. If the account does not exist yet, call Authentication.register_with_email_async(email, password) first — logging in never creates one."
		"google", "apple", "steam":
			return "No Flock account is linked to that %s identity yet. Call Authentication.register_with_%s_async(...) once, or link it to the signed-in player with Authentication.link_%s_async(...)." % [name, m, m]
		"facebook", "discord":
			# No register route exists for these two — linking to an existing player is the only way in.
			return "No Flock account is linked to that %s identity yet. Sign in another way, then call Authentication.link_%s_async(...) — there is no %s registration route." % [name, m, name]
		_:
			return for_code(code)


# Composes the one-line error message Unity builds for FlockException.Message: the operation that failed, the
# server's own reason when the body carried one, a bounded [code, HTTP status] tag, and the "Fix:" hint on its own line.
static func compose(operation: String, server_message: String, code: String, status_code: int, hint: String, fallback: String) -> String:
	var text := ""
	if not operation.is_empty():
		text += "%s failed: " % operation
	text += server_message if not server_message.is_empty() else fallback

	var tag := compose_tag(code, status_code)
	if not tag.is_empty():
		text += " " + tag

	if not hint.is_empty():
		text += "\nFix: " + hint
	return text


# Bounded, low-cardinality identifiers only — keeps error-tracker grouping meaningful.
static func compose_tag(code: String, status_code: int) -> String:
	var has_code := not code.is_empty()
	if has_code and status_code >= 0:
		return "[%s, HTTP %d]" % [code, status_code]
	if has_code:
		return "[%s]" % code
	if status_code >= 0:
		return "[HTTP %d]" % status_code
	return ""