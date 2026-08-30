class_name FlockLeaderboardProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "leaderboard"

# Name -> board memo: every read resolves a name to an id first, and that shouldn't cost a round trip each time.
var _boards_by_name := {}

func _init(client: FlockClient) -> void:
	super(client)


func clear_cache() -> void:
	_boards_by_name.clear()
	delete_snapshot_category(SNAPSHOT_CATEGORY)


# A board's public configuration. Open to signed-out players; memoized for the session after the first call.
func get_by_name_async(leaderboard_name: String) -> Variant:
	require_not_empty(leaderboard_name, "Leaderboard Name")

	if _boards_by_name.has(leaderboard_name):
		return _boards_by_name[leaderboard_name]

	var board = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "board_name_%s" % leaderboard_name, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.leaderboard_by_name(leaderboard_name)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch leaderboard")

	if board is Dictionary and not board.has("error") and not str(board.get("id", "")).is_empty():
		_boards_by_name[leaderboard_name] = LeaderboardModels.parse_leaderboard(board)
	return LeaderboardModels.parse_leaderboard(board) if board is Dictionary and not board.has("error") else board


# The board's id, for logging or a deep link. Reads take the name — nothing in this provider consumes an id.
func resolve_id_async(leaderboard_name: String) -> Variant:
	var board = await get_by_name_async(leaderboard_name)
	if board is Dictionary:
		return board.get("id", "")
	return ""


# Ranked standings for a board. Open to signed-out players; the default window is whatever the board is currently serving.
func get_standings_async(leaderboard_name: String, window: String = "", country: String = "", page: int = 1, limit: int = 50) -> Variant:
	require_not_empty(leaderboard_name, "Leaderboard Name")

	var query := _build_query({
		"window": window,
		"country": country,
		"page": page,
		"limit": limit,
	})

	var result = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "standings_%s_%s_%s_p%d_l%d" % [leaderboard_name, window, country, page, limit], func() -> Variant:
		var url := "%s/%s%s" % [_client.get_versioned_api_url(), FlockEndpoints.leaderboard_standings(leaderboard_name), query]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch leaderboard standings")

	return _as_caller_mistake_or(result, leaderboard_name)


# The signed-in player's own placement. Rank and score come back null when they have no entry yet — that's a valid result, not an error.
func get_my_rank_async(leaderboard_name: String, window: String = "", country: String = "") -> Variant:
	require_not_empty(leaderboard_name, "Leaderboard Name")
	if not _require_authenticated():
		return {"error": "No player is signed in"}

	var query := _build_query({
		"window": window,
		"country": country,
	})

	var result = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, _player_scoped_key("me_%s_%s_%s" % [leaderboard_name, window, country]), func() -> Variant:
		var url := "%s/%s%s" % [_client.get_versioned_api_url(), FlockEndpoints.leaderboard_me(leaderboard_name), query]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch player rank")

	return _as_caller_mistake_or(result, leaderboard_name)


# The neighbours entries either side of the signed-in player, for a "you are here" view.
func get_around_me_async(leaderboard_name: String, neighbours: int = 5, window: String = "", country: String = "") -> Variant:
	require_not_empty(leaderboard_name, "Leaderboard Name")
	if not _require_authenticated():
		return {"error": "No player is signed in"}

	var query := _build_query({
		"window": window,
		"country": country,
		"n": neighbours,
	})

	var result = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, _player_scoped_key("around_%s_%s_%s_n%d" % [leaderboard_name, window, country, neighbours]), func() -> Variant:
		var url := "%s/%s%s" % [_client.get_versioned_api_url(), FlockEndpoints.leaderboard_around_me(leaderboard_name), query]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch standings around player")

	return _as_caller_mistake_or(result, leaderboard_name)


# Optional filters are omitted rather than sent empty; values are escaped here.
static func _build_query(params: Dictionary) -> String:
	var parts := []
	for key in params:
		var value: String = str(params[key])
		if not value.is_empty():
			parts.append("%s=%s" % [key, value.uri_encode()])
	if parts.is_empty():
		return ""
	return "?" + "&".join(parts)


# A name this game doesn't have is a caller mistake, not an empty result — the routes answer 404 for it.
func _as_caller_mistake_or(result: Variant, leaderboard_name: String) -> Variant:
	if result is Dictionary and result.has("error") and int(result.get("status_code", 0)) == 404:
		var dict: Dictionary = (result as Dictionary).duplicate()
		dict["error"] = "No leaderboard named '%s'" % leaderboard_name
		return dict
	return result


# Bearer-only endpoints — fail fast instead of a guaranteed server 401.
func _require_authenticated() -> bool:
	if not _client.is_authenticated:
		push_error("[Flock SDK] No player is signed in")
		return false
	return true


# Player-scoped so one player's cached placement can't be served to the next player on a shared device.
func _player_scoped_key(key: String) -> String:
	return "%s_%s" % [key, _client.current_player_id]