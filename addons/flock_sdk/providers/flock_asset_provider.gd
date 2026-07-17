class_name FlockAssetProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "asset"
const INDEX_KEY := "asset_index"

var _cache: FlockAssetCache
var _assets_by_id := {}
var _all_assets_fetched := false
var _disk_index_loaded := false
var _all_assets_fetch_task: Variant = null

func _init(client: FlockClient) -> void:
	super(client)
	_cache = FlockAssetCache.new(
		client._init_config.asset_cache_directory if client._init_config else "",
		client._init_config.asset_cache_max_size_mb if client._init_config else 100
	)


var cache_directory: String:
	get:
		return _cache.directory


func get_all_async() -> Variant:
	if _all_assets_fetched:
		return _assets_by_id.values()
	var result = await _fetch_all_assets()
	return result


func _fetch_all_assets() -> Variant:
	if not is_server_reachable() and _try_load_disk_index():
		return _assets_by_id.values()

	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.ASSET]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch assets")

	if result is Dictionary and result.has("error"):
		if not result.has("status_code") or not FlockException.FlockNetworkException.is_permanent_status(result.get("status_code", 0)):
			if _try_load_disk_index():
				_client._logger.log_warning("Fetch assets: serving cached snapshot (network unavailable)")
				return _assets_by_id.values()
		return result

	if result is Dictionary:
		var items = result.get("result", [])
		if items is Array:
			_assets_by_id.clear()
			for asset: Dictionary in items:
				_index_asset(asset)
			_all_assets_fetched = true
			_disk_index_loaded = true
			_persist_index()
			return _assets_by_id.values()

	return result


func get_by_id_async(asset_id: String) -> Variant:
	require_not_empty(asset_id, "Asset ID")
	if _assets_by_id.has(asset_id):
		return _assets_by_id[asset_id]

	if not is_server_reachable() and _try_load_disk_index() and _assets_by_id.has(asset_id):
		return _assets_by_id[asset_id]

	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.asset_by_id(asset_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch asset %s" % asset_id)

	if result is Dictionary and not result.has("error"):
		_index_asset(result)
		_persist_index()

	return result


func get_by_name_async(name: String) -> Variant:
	require_not_empty(name, "Asset Name")
	if not _all_assets_fetched:
		await get_all_async()

	for asset: Dictionary in _assets_by_id.values():
		if asset.get("name", "") == name:
			return asset
	return {"error": "Asset with name '%s' not found" % name}


func download_async(asset_id: String) -> Variant:
	var asset = await get_by_id_async(asset_id)
	if asset is Dictionary and asset.has("error"):
		return asset
	return await _download_from_schema(asset)


func _download_from_schema(asset: Dictionary) -> Variant:
	var url: String = asset.get("s3_download_url", "")
	if url.is_empty():
		return {"error": "Asset has no download URL"}

	# Check cache first
	if _client._init_config.enable_asset_cache:
		var cached_url := _cache.try_get_cached_file_url(asset.get("id", ""), asset.get("updated_at", ""))
		if not cached_url.is_empty():
			var cached_data = _load_from_disk(cached_url)
			if cached_data != null:
				return cached_data

	# Download
	var http := FlockHttpRequest.new(_client._init_config.asset_download_timeout)
	var result = await http.get_async(url)

	if result is Dictionary and result.has("error"):
		return result

	# For now, return the raw response - in a real implementation,
	# we'd need to handle different types (Texture2D, AudioStream, etc.)
	return result


func _load_from_disk(file_path: String) -> PackedByteArray:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return PackedByteArray()
	return file.get_buffer(file.get_length())


func clear_cache() -> void:
	_cache.clear()
	_assets_by_id.clear()
	_all_assets_fetched = false
	_disk_index_loaded = false
	delete_snapshot_category(SNAPSHOT_CATEGORY)


func _index_asset(asset: Dictionary) -> void:
	var id: String = asset.get("id", "")
	if not id.is_empty():
		_assets_by_id[id] = asset


func _try_load_disk_index() -> bool:
	if _disk_index_loaded:
		return _assets_by_id.size() > 0
	_disk_index_loaded = true
	var cached = try_read_snapshot(SNAPSHOT_CATEGORY, INDEX_KEY)
	if cached is Array:
		for asset: Dictionary in cached:
			var id: String = asset.get("id", "")
			if not id.is_empty() and not _assets_by_id.has(id):
				_assets_by_id[id] = asset
	return _assets_by_id.size() > 0


func _persist_index() -> void:
	write_snapshot(SNAPSHOT_CATEGORY, INDEX_KEY, _assets_by_id.values())
