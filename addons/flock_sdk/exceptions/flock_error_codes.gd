class_name FlockErrorCodes

static func parse(code: String) -> int:
	if code.is_empty():
		return FlockErrorCode.UNKNOWN

	var parts := code.replace(".", "_").split("_", false)
	var name := ""
	for part: String in parts:
		if part.length() > 0:
			name += part[0].to_upper()
			if part.length() > 1:
				name += part.substr(1)

	var map := {
		"analytics_currency_not_found": FlockErrorCode.ANALYTICS_CURRENCY_NOT_FOUND,
		"analytics_player_not_found": FlockErrorCode.ANALYTICS_PLAYER_NOT_FOUND,
		"analytics_session_not_found": FlockErrorCode.ANALYTICS_SESSION_NOT_FOUND,
		"asset_asset_not_found": FlockErrorCode.ASSET_ASSET_NOT_FOUND,
		"game_game_not_found": FlockErrorCode.GAME_GAME_NOT_FOUND,
		"game_missing_studio_id": FlockErrorCode.GAME_MISSING_STUDIO_ID,
		"gamecommandachievementnotfound": FlockErrorCode.GAME_COMMAND_ACHIEVEMENT_NOT_FOUND,
		"gamecommandcurrencynotfound": FlockErrorCode.GAME_COMMAND_CURRENCY_NOT_FOUND,
		"gamecommandinvalidamount": FlockErrorCode.GAME_COMMAND_INVALID_AMOUNT,
		"gamecommandnotawallet": FlockErrorCode.GAME_COMMAND_NOT_A_WALLET,
		"gamecommandnotanachievementrecord": FlockErrorCode.GAME_COMMAND_NOT_AN_ACHIEVEMENT_RECORD,
		"gamecommandplayerdatanotfound": FlockErrorCode.GAME_COMMAND_PLAYER_DATA_NOT_FOUND,
		"gamecommandplayerdatanotlinkedtotemplate": FlockErrorCode.GAME_COMMAND_PLAYER_DATA_NOT_LINKED_TO_TEMPLATE,
		"gamecommandplayertemplatenotfound": FlockErrorCode.GAME_COMMAND_PLAYER_TEMPLATE_NOT_FOUND,
		"gamecommandtemplatevalidationfailed": FlockErrorCode.GAME_COMMAND_TEMPLATE_VALIDATION_FAILED,
		"gameconfigconfignotfound": FlockErrorCode.GAME_CONFIG_CONFIG_NOT_FOUND,
		"gameconfigfeatureconfignotfound": FlockErrorCode.GAME_CONFIG_FEATURE_CONFIG_NOT_FOUND,
		"gameconfiginvalidtag": FlockErrorCode.GAME_CONFIG_INVALID_TAG,
		"gameconfigplayernogameversion": FlockErrorCode.GAME_CONFIG_PLAYER_NO_GAME_VERSION,
		"gameconfigplayernotfound": FlockErrorCode.GAME_CONFIG_PLAYER_NOT_FOUND,
		"gamepatchgameconfignotfound": FlockErrorCode.GAME_PATCH_GAME_CONFIG_NOT_FOUND,
		"gamepatchpatchnotfound": FlockErrorCode.GAME_PATCH_PATCH_NOT_FOUND,
		"gameversiongameversionbynamenotfound": FlockErrorCode.GAME_VERSION_BY_NAME_NOT_FOUND,
		"gameversiongamenotfound": FlockErrorCode.GAME_VERSION_NOT_FOUND,
		"logeventgamenotfound": FlockErrorCode.LOG_EVENT_GAME_NOT_FOUND,
"notification_template_not_found": FlockErrorCode.NOTIFICATION_TEMPLATE_NOT_FOUND,
		"player_account_already_linked": FlockErrorCode.PLAYER_ACCOUNT_ALREADY_LINKED,
		"player_account_not_linked": FlockErrorCode.PLAYER_ACCOUNT_NOT_LINKED,
		"player_cannot_unlink_last_credential": FlockErrorCode.PLAYER_CANNOT_UNLINK_LAST_CREDENTIAL,
		"playerdevicealreadyregistered": FlockErrorCode.PLAYER_DEVICE_ALREADY_REGISTERED,
		"playeremailalreadyregistered": FlockErrorCode.PLAYER_EMAIL_ALREADY_REGISTERED,
		"playergamejwknotconfigured": FlockErrorCode.PLAYER_GAME_JWK_NOT_CONFIGURED,
		"playergameversionidrequired": FlockErrorCode.PLAYER_GAME_VERSION_ID_REQUIRED,
		"playergoogleaccountalreadyregistered": FlockErrorCode.PLAYER_GOOGLE_ACCOUNT_ALREADY_REGISTERED,
		"playerinvaliddeviceregistrationrequest": FlockErrorCode.PLAYER_INVALID_DEVICE_REGISTRATION_REQUEST,
		"player_invalid_link_request": FlockErrorCode.PLAYER_INVALID_LINK_REQUEST,
		"playerinvalidlogincredentials": FlockErrorCode.PLAYER_INVALID_LOGIN_CREDENTIALS,
		"playerinvalidrefreshtoken": FlockErrorCode.PLAYER_INVALID_REFRESH_TOKEN,
		"playerinvalidregistrationrequest": FlockErrorCode.PLAYER_INVALID_REGISTRATION_REQUEST,
		"playerinvalidresetcode": FlockErrorCode.PLAYER_INVALID_RESET_CODE,
		"playerinvalidverificationcode": FlockErrorCode.PLAYER_INVALID_VERIFICATION_CODE,
		"playernamealreadyregistered": FlockErrorCode.PLAYER_NAME_ALREADY_REGISTERED,
		"playernoemailaccount": FlockErrorCode.PLAYER_NO_EMAIL_ACCOUNT,
		"playeroauthfailed": FlockErrorCode.PLAYER_OAUTH_FAILED,
		"playerplayernotfound": FlockErrorCode.PLAYER_PLAYER_NOT_FOUND,
		"playersteamaccountalreadyregistered": FlockErrorCode.PLAYER_STEAM_ACCOUNT_ALREADY_REGISTERED,
		"playerbanplayernotfound": FlockErrorCode.PLAYER_BAN_PLAYER_NOT_FOUND,
		"playerdatanotfound": FlockErrorCode.PLAYER_DATA_NOT_FOUND,
		"playerdataplayernotfound": FlockErrorCode.PLAYER_DATA_PLAYER_NOT_FOUND,
		"playerinventoryplayernotfound": FlockErrorCode.PLAYER_INVENTORY_PLAYER_NOT_FOUND,
		"playertemplatenotfound": FlockErrorCode.PLAYER_TEMPLATE_NOT_FOUND,
		"playertemplatenotfoundbyname": FlockErrorCode.PLAYER_TEMPLATE_NOT_FOUND_BY_NAME,
		"shopcurrencynotheld": FlockErrorCode.SHOP_CURRENCY_NOT_HELD,
		"shopcurrencytemplatenotfound": FlockErrorCode.SHOP_CURRENCY_TEMPLATE_NOT_FOUND,
		"shopinsufficientfunds": FlockErrorCode.SHOP_INSUFFICIENT_FUNDS,
		"shopitemnotfound": FlockErrorCode.SHOP_ITEM_NOT_FOUND,
		"shopplayernotfound": FlockErrorCode.SHOP_PLAYER_NOT_FOUND,
		"shopshopnotfound": FlockErrorCode.SHOP_SHOP_NOT_FOUND,
		"shopwalletnotfound": FlockErrorCode.SHOP_WALLET_NOT_FOUND,
		"shopitemshopitemnotfound": FlockErrorCode.SHOP_ITEM_SHOP_ITEM_NOT_FOUND,
		"shopitemshopnotfound": FlockErrorCode.SHOP_ITEM_SHOP_NOT_FOUND,
	}

	return map.get(code.to_lower().replace(".", "_"), FlockErrorCode.UNKNOWN)


static func is_already_registered(ex: RefCounted) -> bool:
	if not ex is FlockException:
		return false
	var err: FlockException = ex as FlockException
	match err.error_code:
		FlockErrorCode.PLAYER_EMAIL_ALREADY_REGISTERED, \
		FlockErrorCode.PLAYER_DEVICE_ALREADY_REGISTERED, \
		FlockErrorCode.PLAYER_GOOGLE_ACCOUNT_ALREADY_REGISTERED, \
		FlockErrorCode.PLAYER_APPLE_ACCOUNT_ALREADY_REGISTERED, \
		FlockErrorCode.PLAYER_STEAM_ACCOUNT_ALREADY_REGISTERED:
			return true
	return false
