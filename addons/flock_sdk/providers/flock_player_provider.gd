class_name FlockPlayerProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "player_template"

var _templates_by_id := {}
var _template_id_by_name := {}
var _all_templates_fetched := false
var _all_templates_fetch_task: Variant = null
var _player_data_by_player := {}
var _player_data_fetch_tasks := {}

func _init(client: FlockClient) -> void:
	super(client)


func clear_cache() -> void:
	_templates_by_id.clear()
	_template_id_by_name.clear()
	_all_templates_fetched = false
	_all_templates_fetch_task = null
	_player_data_by_player.clear()
	_player_data_fetch_tasks.clear()
	delete_snapshot_category(SNAPSHOT_CATEGORY)


func apply_server_player_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	var player_id: String = data.get("player_id", "")
	var template_id: String = data.get("player_template_id", "")
	if player_id.is_empty() or template_id.is_empty():
		return
	if _player_data_by_player.has(player_id):
		var by_template: Dictionary = _player_data_by_player[player_id]
		by_template[template_id] = data


func get_all_data_async(player_id: String = "", page: int = 1, limit: int = 100) -> Variant:
	return await execute_async(func() -> Variant:
		var url := "%s/%s?page=%d&limit=%d" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_DATA, page, limit]
		if not player_id.is_empty():
			url += "&player_id=%s" % player_id
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch player data list")


func get_data_by_id_async(player_data_id: String) -> Variant:
	require_not_empty(player_data_id, "Player Data ID")
	return await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.player_data_by_id(player_data_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch player data %s" % player_data_id)


func get_my_data_by_template_async(template_id: String) -> Variant:
	require_not_empty(template_id, "Player Template ID")
	var player_id := _client.current_player_id
	require_not_empty(player_id, "Current Player ID (sign in first)")

	var by_template: Dictionary = await _get_or_fetch_by_template(player_id)
	if by_template.has(template_id):
		return by_template[template_id]
	return null


func get_my_data_by_tag_async(tag: String) -> Variant:
	var template = await get_template_by_tag_async(tag)
	if template.is_empty():
		return null
	return await get_my_data_by_template_async(template.get("id", ""))


func get_template_by_tag_async(tag: String) -> Variant:
	require_not_empty(tag, "Template tag")
	var templates = await get_templates_async()
	if templates is Array:
		for t: Dictionary in templates:
			if t.get("tag", "").to_lower() == tag.to_lower():
				return t
	return {}


func get_templates_async() -> Variant:
	if _all_templates_fetched:
		return _templates_by_id.values()
	var result = await _fetch_all_templates()
	return result


func _fetch_all_templates() -> Variant:
	var response = await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "all", func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_TEMPLATE]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch player templates")
	if response is Dictionary and response.has("items"):
		var items: Array = response.get("items", [])
		_templates_by_id.clear()
		_template_id_by_name.clear()
		for item: Dictionary in items:
			var id: String = item.get("id", "")
			if not id.is_empty():
				_templates_by_id[id] = item
				_template_id_by_name[item.get("tag", "")] = id
		_all_templates_fetched = true
		return items
	return response


func _get_or_fetch_by_template(player_id: String) -> Variant:
	if _player_data_by_player.has(player_id):
		return _player_data_by_player[player_id]

	var result = await _fetch_and_cache_async(player_id)
	return result


func _fetch_and_cache_async(player_id: String) -> Variant:
	var by_template := {}
	var page := 1
	var page_size := 100
	while true:
		var response = await get_all_data_async(player_id, page, page_size)
		if response is Dictionary:
			var items: Array = response.get("items", [])
			if items.is_empty():
				break
			for item: Dictionary in items:
				var template_id: String = item.get("player_template_id", "")
				if not template_id.is_empty():
					by_template[template_id] = item
			if items.size() < page_size:
				break
			page += 1
		else:
			break

	_player_data_by_player[player_id] = by_template
	return by_template


func get_ban_async(player_id: String) -> Variant:
	require_not_empty(player_id, "Player ID")
	return await execute_async(func() -> Variant:
		var url := "%s/%s?player_id=%s" % [_client.get_versioned_api_url(), FlockEndpoints.PLAYER_BAN, player_id]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Get player ban")


func get_all_templates_async() -> Variant:
	return await get_templates_async()
