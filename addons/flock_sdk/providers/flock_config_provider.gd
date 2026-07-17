class_name FlockConfigProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "config"

var _patches_by_id := {}
var _game_configs_by_id := {}
var _patch_ids_by_schema := {}
var _config_ids_by_tag := {}
var _config_ids_by_name := {}
var _all_patches_fetched := false
var _all_patches_fetch_task: Variant = null

func _init(client: FlockClient) -> void:
	super(client)


func clear_cache() -> void:
	_patches_by_id.clear()
	_game_configs_by_id.clear()
	_patch_ids_by_schema.clear()
	_config_ids_by_tag.clear()
	_config_ids_by_name.clear()
	_all_patches_fetched = false
	_all_patches_fetch_task = null
	delete_snapshot_category(SNAPSHOT_CATEGORY)


func get_all_patches() -> Variant:
	if _all_patches_fetched:
		return _patches_by_id.values()
	var result = await _fetch_all_patches()
	return result


func _fetch_all_patches() -> Variant:
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_patch_all", func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.GAME_PATCH]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch game configs")


func get_by_id(config_id: String) -> Variant:
	require_not_empty(config_id, "Config ID")
	if _patches_by_id.has(config_id):
		return _patches_by_id[config_id]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_patch_%s" % config_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.game_patch_by_id(config_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch config %s" % config_id)


func get_by_schema(schema_id: String) -> Variant:
	require_not_empty(schema_id, "Schema ID")
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_patch_schema_%s" % schema_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.game_patch_by_config(schema_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch configs for schema %s" % schema_id)


func get_by_config_id(config_id: String) -> Variant:
	require_not_empty(config_id, "Config ID")
	var patches = await get_by_schema(config_id)
	if patches is Array and patches.size() > 0:
		var patch: Dictionary = patches[0]
		return GameConfigModels.get_data_as(patch.get("data", []))

	# Fallback to config base data
	var config = await _get_config_by_id(config_id)
	if config is Dictionary and not config.is_empty():
		return GameConfigModels.get_data_as(config.get("data", []))
	return {}


func _get_config_by_id(config_id: String) -> Variant:
	if _game_configs_by_id.has(config_id):
		return _game_configs_by_id[config_id]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_config_%s" % config_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.game_config_by_id(config_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch config %s" % config_id)


func get_game_config_by_name(name: String) -> Variant:
	require_not_empty(name, "Game Config Name")
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "game_config_name_%s" % name, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.game_config_by_name(name)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch game config by name %s" % name)
