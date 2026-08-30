extends GutTest


func test_wire_provider_round_trips() -> void:
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_DEVICE_ID), "device_id", "device wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_EMAIL), "email", "email wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_GOOGLE), "google", "google wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_APPLE), "apple", "apple wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_FACEBOOK), "facebook", "facebook wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_STEAM), "steam", "steam wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_DISCORD), "discord", "discord wire")
	assert_eq(AuthModels.provider_to_wire(AuthModels.PROVIDER_UNKNOWN), "", "unknown wire")
	assert_eq(AuthModels.provider_to_wire(999), "", "bogus wire")


func test_provider_from_wire() -> void:
	assert_eq(AuthModels.provider_from_wire("device_id"), AuthModels.PROVIDER_DEVICE_ID, "from device")
	assert_eq(AuthModels.provider_from_wire("email"), AuthModels.PROVIDER_EMAIL, "from email")
	assert_eq(AuthModels.provider_from_wire("google"), AuthModels.PROVIDER_GOOGLE, "from google")
	assert_eq(AuthModels.provider_from_wire("DISCORD"), AuthModels.PROVIDER_DISCORD, "from uppercase")
	assert_eq(AuthModels.provider_from_wire("xyz"), AuthModels.PROVIDER_UNKNOWN, "from unknown")
	assert_eq(AuthModels.provider_from_wire(""), AuthModels.PROVIDER_UNKNOWN, "from empty")


func test_parse_linked_account() -> void:
	var acc := AuthModels.parse_linked_account({
		"provider": "email",
		"provider_user_id": "u1",
		"email": "a@b.c",
		"email_verified": true,
	})
	assert_eq(acc["provider"], "email", "linked provider")
	assert_eq(acc["provider_user_id"], "u1", "linked provider_user_id")
	assert_eq(acc["email"], "a@b.c", "linked email")
	assert_eq(acc["email_verified"], true, "linked email_verified")
	assert_eq(acc["provider_type"], AuthModels.PROVIDER_EMAIL, "linked provider_type")

	var unknown := AuthModels.parse_linked_account({"provider": "weird_new_provider"})
	assert_eq(unknown["provider_type"], AuthModels.PROVIDER_UNKNOWN, "new provider -> unknown")

	var bare := AuthModels.parse_linked_account({})
	assert_eq([bare["provider"], bare["provider_user_id"], bare["email"], bare["email_verified"], bare["provider_type"]], ["", "", "", false, -1], "bare defaults")


func test_request_builders() -> void:
	assert_eq(AuthModels.link_email_request("a@b.c", "pw"), {"email": "a@b.c", "password": "pw"}, "link email req")
	assert_eq(AuthModels.link_device_request("Desktop", "d1"), {"device_type": "Desktop", "device_id": "d1"}, "link device req")
	assert_eq(AuthModels.link_oauth_request("tok"), {"token": "tok"}, "link oauth req")


func test_new_error_codes_parse() -> void:
	assert_eq(FlockErrorCodes.parse("player.account_already_linked"), FlockErrorCode.PLAYER_ACCOUNT_ALREADY_LINKED, "code account_linked")
	assert_eq(FlockErrorCodes.parse("player.account_not_linked"), FlockErrorCode.PLAYER_ACCOUNT_NOT_LINKED, "code account_not_linked")
	assert_eq(FlockErrorCodes.parse("player.cannot_unlink_last_credential"), FlockErrorCode.PLAYER_CANNOT_UNLINK_LAST_CREDENTIAL, "code cannot_unlink_last")
	assert_eq(FlockErrorCodes.parse("player.invalid_link_request"), FlockErrorCode.PLAYER_INVALID_LINK_REQUEST, "code invalid_link")
	assert_eq(FlockErrorCodes.parse("notification_template.not_found"), FlockErrorCode.NOTIFICATION_TEMPLATE_NOT_FOUND, "code notif_template")