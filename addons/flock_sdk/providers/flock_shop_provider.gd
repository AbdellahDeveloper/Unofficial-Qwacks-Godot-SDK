class_name FlockShopProvider
extends FlockProviderBase

const SNAPSHOT_CATEGORY := "shop"

var _shops_by_id := {}
var _shop_id_by_name := {}
var _items_by_id := {}
var _item_ids_by_shop := {}

func _init(client: FlockClient) -> void:
	super(client)


func clear_cache() -> void:
	_shops_by_id.clear()
	_shop_id_by_name.clear()
	_items_by_id.clear()
	_item_ids_by_shop.clear()
	delete_snapshot_category(SNAPSHOT_CATEGORY)


func get_all_async(page: int = 1, limit: int = 100) -> Variant:
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "all_p%d_l%d" % [page, limit], func() -> Variant:
		var url := "%s/%s?page=%d&limit=%d" % [_client.get_versioned_api_url(), FlockEndpoints.SHOP, page, limit]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch shops")


func get_by_id_async(shop_id: String) -> Variant:
	require_not_empty(shop_id, "Shop ID")
	if _shops_by_id.has(shop_id):
		return _shops_by_id[shop_id]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "shop_%s" % shop_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.shop_by_id(shop_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch shop")


func get_by_name_async(name: String) -> Variant:
	require_not_empty(name, "Shop Name")
	if _shop_id_by_name.has(name) and _shops_by_id.has(_shop_id_by_name[name]):
		return _shops_by_id[_shop_id_by_name[name]]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "shop_name_%s" % name, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.shop_by_name(name)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch shop by name %s" % name)


func get_item_async(shop_item_id: String) -> Variant:
	require_not_empty(shop_item_id, "Shop Item ID")
	if _items_by_id.has(shop_item_id):
		return _items_by_id[shop_item_id]

	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "item_%s" % shop_item_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.shop_item_by_id(shop_item_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch shop item")


func get_items_by_shop_async(shop_id: String) -> Variant:
	require_not_empty(shop_id, "Shop ID")
	return await fetch_with_snapshot_async(SNAPSHOT_CATEGORY, "items_shop_%s" % shop_id, func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.shop_items_by_shop(shop_id)]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Fetch shop items")


func purchase_async(shop_item_id: String, player_id: String = "") -> Variant:
	require_not_empty(shop_item_id, "Shop Item ID")
	if player_id.is_empty():
		player_id = _client.current_player_id
	require_not_empty(player_id, "Player ID (sign in first)")

	# Record analytics - started
	var shop_item = await get_item_async(shop_item_id)
	if shop_item is Dictionary and _client.analytics != null:
		_client.analytics.record_transaction_async({
			"player_id": player_id,
			"amount": shop_item.get("price", 0),
			"currency_code": shop_item.get("currency", "USD"),
			"shop_item_id": shop_item_id,
			"transaction_type": "Purchase",
			"status": "Started",
		})

	# Execute purchase (non-idempotent)
	var request := GameCommandModels.shop_transaction_request(shop_item_id, player_id)
	var result = await execute_async(func() -> Variant:
		var url := "%s/%s" % [_client.get_versioned_api_url(), FlockEndpoints.SHOP_TRANSACTION]
		return await FlockHttpClient.post_async(url, request, _client.get_base_headers())
	, "Purchase shop item", false)

	# Record analytics - failed
	if result is Dictionary and result.has("error") and shop_item is Dictionary and _client.analytics != null:
		_client.analytics.record_transaction_async({
			"player_id": player_id,
			"amount": shop_item.get("price", 0),
			"currency_code": shop_item.get("currency", "USD"),
			"shop_item_id": shop_item_id,
			"transaction_type": "Purchase",
			"status": "Failed",
		})
		return result

	# Record analytics - purchased
	if result is Dictionary and not result.has("error") and shop_item is Dictionary and _client.analytics != null:
		_client.analytics.record_transaction_async({
			"player_id": player_id,
			"amount": shop_item.get("price", 0),
			"currency_code": shop_item.get("currency", "USD"),
			"shop_item_id": shop_item_id,
			"transaction_type": "Purchase",
			"status": "Purchased",
		})

	return result


func get_player_inventory_async(player_id: String = "", page: int = 1, limit: int = 100) -> Variant:
	if player_id.is_empty():
		player_id = _client.current_player_id
	require_not_empty(player_id, "Player ID (sign in first)")
	return await execute_async(func() -> Variant:
		var url := "%s/%s?page=%d&limit=%d" % [_client.get_versioned_api_url(), FlockEndpoints.player_inventory_by_player(player_id), page, limit]
		return await FlockHttpClient.get_async(url, _client.get_base_headers())
	, "Get player inventory")
