extends GutTest


func test_unknown_codes_return_empty() -> void:
	assert_eq(FlockErrorHints.for_code(FlockErrorCode.UNKNOWN), "", "hint unknown")
	assert_eq(FlockErrorHints.for_code(42), "", "hint no table entry")


func test_known_auth_complaints() -> void:
	assert_true(FlockErrorHints.for_code(FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS) != "", "hint invalid login non-empty")
	assert_eq(FlockErrorHints.for_code(FlockErrorCode.PLAYER_CANNOT_UNLINK_LAST_CREDENTIAL), "A player must keep at least one way to sign in. Link another credential before unlinking this one.", "hint last credential")
	assert_true(FlockErrorHints.for_code(FlockErrorCode.PLAYER_TEMPLATE_NOT_FOUND_BY_NAME).contains("Author it in the Flock dashboard, then sync the SDK"), "hint template sync")
	assert_true(FlockErrorHints.for_code(FlockErrorCode.SHOP_INSUFFICIENT_FUNDS).contains("Read the wallet balance"), "hint shop funds")
	assert_true(FlockErrorHints.for_code(FlockErrorCode.NOTIFICATION_TEMPLATE_NOT_FOUND).contains("publish it to this game version"), "hint notification template")


func test_for_auth_refines_invalid_login_only() -> void:
	assert_eq(FlockErrorHints.for_auth(FlockErrorCode.PLAYER_ACCOUNT_NOT_LINKED, "email"), FlockErrorHints.for_code(FlockErrorCode.PLAYER_ACCOUNT_NOT_LINKED), "forAuth non-invalid passes through")
	var device := FlockErrorHints.for_auth(FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS, "Device")
	assert_true(device.contains("register_with_device_async"), "forAuth device mentions register")
	assert_eq(device.contains("Wrong email"), false, "forAuth device never wrong password")
	var email := FlockErrorHints.for_auth(FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS, "Email")
	assert_true(email.contains("Wrong email or password"), "forAuth email wrong creds")
	var steam := FlockErrorHints.for_auth(FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS, "Steam")
	assert_true(steam.contains("register_with_steam_async") and steam.contains("link_steam_async"), "forAuth steam register/link")
	var discord := FlockErrorHints.for_auth(FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS, "Discord")
	assert_true(discord.contains("no Discord registration route") and not discord.contains("register_with_discord"), "forAuth discord no register route")


func test_compose() -> void:
	assert_eq(FlockErrorHints.compose("", "", "", -1, "", "HTTP request failed"), "HTTP request failed", "compose bare")
	assert_eq(FlockErrorHints.compose("", "", "", 404, "", "HTTP request failed"), "HTTP request failed [HTTP 404]", "compose status tag")
	assert_eq(FlockErrorHints.compose("", "", "player.x", 400, "", "Validation failed"), "Validation failed [player.x, HTTP 400]", "compose code+status")
	assert_eq(FlockErrorHints.compose("", "", "player.x", -1, "", "Validation failed"), "Validation failed [player.x]", "compose code only")
	assert_eq(FlockErrorHints.compose("", "", "player.x", -1, "", ""), " [player.x]", "compose empty fallback tag (Unity literal)")
	assert_eq(FlockErrorHints.compose("", "The email is taken.", "player.y", 400, "", "Validation failed"), "The email is taken. [player.y, HTTP 400]", "compose server message beats fallback")
	assert_eq(FlockErrorHints.compose("Email login", "Wrong password.", "player.invalid_login_credentials", 400, "No account matches these credentials. ...", "Authentication failed"), "Email login failed: Wrong password. [player.invalid_login_credentials, HTTP 400]\nFix: No account matches these credentials. ...", "compose operation prefix")
	assert_eq(FlockErrorHints.compose("", "gone", "", 404, "Create one.", "HTTP request failed"), "gone [HTTP 404]\nFix: Create one.", "compose hint line")


func test_422_field_errors_via_private_helper() -> void:
	var req := FlockHttpRequest.new()
	var detail: Dictionary = req._parse_error_detail("{\"detail\": [{\"loc\": [\"body\", \"player_data\"], \"msg\": \"Input should be a valid dictionary\"}, {\"loc\": [], \"msg\": \"Broken\"}, {\"loc\": [\"headers\", \"x\"], \"msg\": \"missing\"}, {\"loc\": [\"a\",\"b\"], \"msg\": \"four\"}, {\"loc\": [\"c\"], \"msg\": \"five\"}]}")
	assert_eq(detail["message"], "body.player_data: Input should be a valid dictionary; Broken; headers.x: missing; (+2 more)", "422 four fields capped")
	assert_eq(detail["code"], "", "422 no code")

	var detail2: Dictionary = req._parse_error_detail("{\"detail\": [{\"loc\": [\"x\"], \"msg\": \"\"}, {\"loc\": [], \"msg\": \"plain\"}]}")
	assert_eq(detail2["message"], "plain", "422 skips empty msg")

	var detail3: Dictionary = req._parse_error_detail("{\"detail\": {\"code\": \"player.ban_player_not_found\", \"message\": \"Banned\"}}")
	assert_eq(detail3["code"], "player.ban_player_not_found", "object detail code")
	assert_eq(detail3["message"], "Banned", "object detail msg")

	assert_eq(req._parse_error_detail("{\"detail\": \"nope\"}")["message"], "nope", "string detail")
	assert_eq(req._parse_error_detail("null"), {}, "non-dict detail")