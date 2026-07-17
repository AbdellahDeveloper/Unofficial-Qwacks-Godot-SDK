class_name JwtTokenParser

static func parse(token: String) -> Dictionary:
	if token.is_empty():
		return {}

	var parts := token.split(".")
	if parts.size() != 3:
		return {}

	var payload := _base64_url_decode(parts[1])
	if payload.is_empty():
		return {}

	var json = JSON.parse_string(payload)
	if json == null or not json is Dictionary:
		return {}

	var claims := {}
	claims["player_id"] = _get_claim_value(json, ["sub", "playerId", "player_id", "userId", "user_id"])
	claims["game_id"] = _get_claim_value(json, ["gameId", "game_id", "gid"])
	claims["email"] = _get_claim_value(json, ["email"])
	claims["username"] = _get_claim_value(json, ["username", "name"])
	claims["role"] = _get_claim_value(json, ["role"])
	claims["issuer"] = _get_claim_value(json, ["iss"])
	claims["audience"] = _get_claim_value(json, ["aud"])

	# Expiration
	if json.has("exp"):
		claims["expiration_time"] = int(json["exp"])
	if json.has("iat"):
		claims["issued_at"] = int(json["iat"])

	return claims


static func _get_claim_value(claims: Dictionary, possible_keys: Array) -> String:
	for key: String in possible_keys:
		if claims.has(key) and claims[key] != null:
			return str(claims[key])
	return ""


static func _base64_url_decode(input: String) -> String:
	var output := input.replace("-", "+").replace("_", "/")

	match output.length() % 4:
		0: pass
		2: output += "=="
		3: output += "="

	var decoded := Marshalls.base64_to_utf8(output)
	return decoded


static func is_token_expired(claims: Dictionary) -> bool:
	if not claims.has("expiration_time"):
		return false
	var exp: int = claims["expiration_time"]
	return Time.get_unix_time_from_system() >= float(exp)
