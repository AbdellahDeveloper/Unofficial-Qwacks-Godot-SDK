# Player Data

The `player` provider manages player data templates and CRUD operations.

## Access

```gdscript
var player = FlockClient.get_instance().player
```

## Fetch All Player Data

```gdscript
var result = await FlockClient.get_instance().player.get_all_data_async()

if result is Dictionary:
    var items = result.get("items", [])
    for item in items:
        print("Template: ", item.get("player_template_id", ""))
        print("Data: ", item.get("data", {}))
```

With pagination:

```gdscript
var result = await FlockClient.get_instance().player.get_all_data_async(
    "",     # player_id (empty = current player)
    1,      # page number
    50      # items per page
)
```

## Get Data by ID

```gdscript
var result = await FlockClient.get_instance().player.get_data_by_id_async("PLAYER_DATA_ID")

if result is Dictionary and not result.has("error"):
    print("Template: ", result.get("player_template_id", ""))
    print("Data: ", result.get("data", {}))
```

## Get My Data by Template

```gdscript
var result = await FlockClient.get_instance().player.get_my_data_by_template_async("TEMPLATE_ID")

if result is Dictionary:
    print("Player data for this template: ", result)
```

## Get My Data by Tag

```gdscript
# Fetch player data by template tag (e.g., "currency", "achievement", "profile")
var result = await FlockClient.get_instance().player.get_my_data_by_tag_async("currency")

if result is Dictionary:
    print("Currency data: ", result)
```

## Templates

### Get All Templates

```gdscript
var templates = await FlockClient.get_instance().player.get_templates_async()

if templates is Array:
    for template in templates:
        print("Template: ", template.get("tag", ""), " ID: ", template.get("id", ""))
```

### Get Template by Tag

```gdscript
var template = await FlockClient.get_instance().player.get_template_by_tag_async("currency")

if template is Dictionary and not template.is_empty():
    print("Currency template ID: ", template.get("id", ""))
    print("Template fields: ", template.get("schema", {}))
```

### Get All Templates (Alternative)

```gdscript
var templates = await FlockClient.get_instance().player.get_all_templates_async()
```

## Ban Status

Check if a player is banned:

```gdscript
var result = await FlockClient.get_instance().player.get_ban_async("PLAYER_ID")

if result is Dictionary:
    if result.get("is_banned", false):
        print("Player is banned: ", result.get("reason", ""))
    else:
        print("Player is not banned")
```

## Cache Management

Clear the player data cache:

```gdscript
FlockClient.get_instance().player.clear_cache()
```

## Applying Server Updates

The SDK can apply server-side player data updates to the local cache:

```gdscript
# This is called automatically by the command provider
FlockClient.get_instance().player.apply_server_player_data(updated_data)
```

## Common Patterns

### Get Currency Balance

```gdscript
func get_currency_balance() -> int:
    var wallet = await FlockClient.get_instance().player.get_my_data_by_tag_async("currency")
    if wallet is Dictionary:
        return wallet.get("data", {}).get("gold", 0)
    return 0
```

### Get All Achievements

```gdscript
func get_achievements() -> Array:
    var data = await FlockClient.get_instance().player.get_my_data_by_tag_async("achievement")
    if data is Dictionary:
        return data.get("data", {}).get("unlocked", [])
    return []
```

### Get Player Profile

```gdscript
func get_profile() -> Dictionary:
    var data = await FlockClient.get_instance().player.get_my_data_by_tag_async("profile")
    if data is Dictionary:
        return data.get("data", {})
    return {}
```

## Data Structure

Player data from the API looks like:

```json
{
    "id": "01KXYZ...",
    "player_id": "01KXYZ...",
    "player_template_id": "01KXYZ...",
    "data": {
        "gold": 1000,
        "level": 15,
        "inventory": ["sword", "shield"]
    },
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-06-15T12:00:00Z"
}
```
