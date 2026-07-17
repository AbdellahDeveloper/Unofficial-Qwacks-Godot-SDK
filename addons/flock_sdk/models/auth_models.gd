class_name AuthModels

static func login_request(login_type: String, email: String = "", password: String = "",
		device_id: String = "", device_type: String = "", facebook_id: String = "",
		discord_id: String = "") -> Dictionary:
	var req := {"login_type": login_type}
	if not email.is_empty(): req["email"] = email
	if not password.is_empty(): req["password"] = password
	if not device_id.is_empty(): req["device_id"] = device_id
	if not device_type.is_empty(): req["device_type"] = device_type
	if not facebook_id.is_empty(): req["facebook_id"] = facebook_id
	if not discord_id.is_empty(): req["discord_id"] = discord_id
	return req

static func email_registration_request(email: String, password: String, name: String = "") -> Dictionary:
	var req := {"email": email, "password": password}
	if not name.is_empty(): req["name"] = name
	return req

static func device_login_request(device_type: String, device_id: String) -> Dictionary:
	return {"device_type": device_type, "device_id": device_id}

static func device_registration_request(device_type: String, device_id: String, name: String = "") -> Dictionary:
	var req := {"device_type": device_type, "device_id": device_id}
	if not name.is_empty(): req["name"] = name
	return req

static func google_login_request(id_token: String) -> Dictionary:
	return {"id_token": id_token}

static func google_registration_request(id_token: String, name: String = "") -> Dictionary:
	var req := {"id_token": id_token}
	if not name.is_empty(): req["name"] = name
	return req

static func apple_login_request(identity_token: String) -> Dictionary:
	return {"identity_token": identity_token}

static func apple_registration_request(identity_token: String, name: String = "") -> Dictionary:
	var req := {"identity_token": identity_token}
	if not name.is_empty(): req["name"] = name
	return req

static func steam_login_request(session_ticket: String) -> Dictionary:
	return {"session_ticket": session_ticket}

static func steam_registration_request(session_ticket: String, name: String = "") -> Dictionary:
	var req := {"session_ticket": session_ticket}
	if not name.is_empty(): req["name"] = name
	return req

static func refresh_token_request(player_id: String, refresh_token: String) -> Dictionary:
	return {"player_id": player_id, "refresh_token": refresh_token}

static func password_forgot_request(email: String) -> Dictionary:
	return {"email": email}

static func password_reset_request(email: String, code: String, new_password: String) -> Dictionary:
	return {"email": email, "code": code, "new_password": new_password}

static func email_verify_request(code: String) -> Dictionary:
	return {"code": code}
