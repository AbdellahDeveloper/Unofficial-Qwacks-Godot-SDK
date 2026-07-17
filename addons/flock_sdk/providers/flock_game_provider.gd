class_name FlockGameProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "game"

var _game: Dictionary = {}
var _game_version: Dictionary = {}
var _game_version_by_name := {}

func _init(client: FlockClient) -> void:
	super(client)


func clear_cache() -> void:
	_game = {}
	_game_version = {}
	_game_version_by_name.clear()
	delete_snapshot_category(SNAPSHOT_CATEGORY)


func get_game_async() -> Variant:
	if not _game.is_empty():
		return _game

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game", func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.GAME]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch game")


func get_game_version_async() -> Variant:
	if not _game_version.is_empty():
		return _game_version

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_version", func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.GAME_VERSION]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch game version")


func get_game_version_by_name_async(name: String) -> Variant:
	require_not_empty(name, "Game Version Name")
	if _game_version_by_name.has(name):
		return _game_version_by_name[name]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_version_name_%s" % name, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.game_version_by_name(name)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch game version by name %s" % name)
