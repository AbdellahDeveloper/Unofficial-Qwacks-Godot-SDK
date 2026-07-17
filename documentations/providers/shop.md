# Shop

The `shop` provider manages in-game shops, items, purchases, and player inventory.

## Access

```gdscript
var shop = FlockClient.get_instance().shop
```

## Get All Shops

```gdscript
var result = await FlockClient.get_instance().shop.get_all_async()

if result is Dictionary:
    var items = result.get("items", [])
    for shop_item in items:
        print("Shop: ", shop_item.get("name", ""))
        print("ID: ", shop_item.get("id", ""))
```

With pagination:

```gdscript
var result = await FlockClient.get_instance().shop.get_all_async(1, 50)
```

## Get Shop by ID

```gdscript
var result = await FlockClient.get_instance().shop.get_by_id_async("SHOP_ID")

if result is Dictionary:
    print("Shop: ", result.get("name", ""))
    print("Description: ", result.get("description", ""))
```

## Get Shop by Name

```gdscript
var result = await FlockClient.get_instance().shop.get_by_name_async("Main Shop")
```

## Get Shop Items

Get all items for a specific shop:

```gdscript
var result = await FlockClient.get_instance().shop.get_items_by_shop_async("SHOP_ID")

if result is Dictionary:
    var items = result.get("items", [])
    for item in items:
        print("Item: ", item.get("name", ""))
        print("Price: ", item.get("price", 0), " ", item.get("currency", "USD"))
```

## Get Single Item

```gdscript
var result = await FlockClient.get_instance().shop.get_item_async("ITEM_ID")

if result is Dictionary:
    print("Name: ", result.get("name", ""))
    print("Price: ", result.get("price", 0))
    print("Description: ", result.get("description", ""))
```

## Purchase Item

```gdscript
var result = await FlockClient.get_instance().shop.purchase_async("ITEM_ID")

if result is Dictionary:
    if result.has("error"):
        print("Purchase failed: ", result["error"])
    else:
        print("Purchase successful!")
        # Analytics transaction is recorded automatically
```

The purchase method automatically:
1. Records a "Started" analytics transaction
2. Executes the purchase
3. Records "Purchased" or "Failed" analytics transaction

## Get Player Inventory

```gdscript
var result = await FlockClient.get_instance().shop.get_player_inventory_async()

if result is Dictionary:
    var items = result.get("items", [])
    for item in items:
        print("Item ID: ", item.get("shop_item_id", ""))
        print("Status: ", item.get("status", ""))
        print("Acquired: ", item.get("created_at", ""))
```

With pagination:

```gdscript
var result = await FlockClient.get_instance().shop.get_player_inventory_async("", 1, 20)
```

## Cache Management

```gdscript
FlockClient.get_instance().shop.clear_cache()
```

## Common Patterns

### Display Shop Items

```gdscript
func display_shop(shop_id: String):
    var result = await FlockClient.get_instance().shop.get_items_by_shop_async(shop_id)
    if result is Dictionary:
        var items = result.get("items", [])
        for item in items:
            var btn = Button.new()
            btn.text = "%s - %s %s" % [item.get("name", ""), item.get("price", 0), item.get("currency", "")]
            btn.pressed.connect(_on_item_pressed.bind(item.get("id", "")))
            $ShopContainer.add_child(btn)

func _on_item_pressed(item_id: String):
    var result = await FlockClient.get_instance().shop.purchase_async(item_id)
    if result is Dictionary and not result.has("error"):
        print("Item purchased!")
        _refresh_inventory()
```

### Check Player Owns Item

```gdscript
func owns_item(item_id: String) -> bool:
    var inventory = await FlockClient.get_instance().shop.get_player_inventory_async()
    if inventory is Dictionary:
        var items = inventory.get("items", [])
        for item in items:
            if item.get("shop_item_id", "") == item_id:
                return true
    return false
```

## Shop Data Structure

### Shop Item

```json
{
    "id": "01KXYZ...",
    "name": "Health Potion",
    "description": "Restores 50 HP",
    "price": 100,
    "currency": "gold",
    "category": "consumable",
    "metadata": {}
}
```

### Inventory Entry

```json
{
    "id": "01KXYZ...",
    "player_id": "01KXYZ...",
    "shop_item_id": "01KXYZ...",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z",
    "used_at": null
}
```
