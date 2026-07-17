# Commands

The `commands` provider handles write operations — player data updates, currency, and achievements — with automatic offline queueing.

## Access

```gdscript
var commands = FlockClient.get_instance().commands
```

## Update Player Data

Update all fields in a player data record:

```gdscript
var result = await FlockClient.get_instance().commands.update_player_data_async(
    "PLAYER_DATA_ID",
    [
        {"key": "gold", "value": 500},
        {"key": "level", "value": 10},
        {"key": "inventory", "value": ["sword", "shield", "potion"]}
    ]
)

if result is Dictionary:
    if result.has("error"):
        print("Update failed: ", result["error"])
    else:
        print("Data updated!")
    if result.get("offline", false):
        print("Queued for sync (offline)")
```

## Update Single Field

Update a single field in a player data record:

```gdscript
var result = await FlockClient.get_instance().commands.update_player_data_field_async(
    "PLAYER_DATA_ID",
    "gold",
    750
)

if result is Dictionary:
    if result.has("error"):
        print("Update failed: ", result["error"])
    else:
        print("Field updated!")
```

## Add Game Funds

Add currency to the player's wallet:

```gdscript
var result = await FlockClient.get_instance().commands.add_game_funds_async(
    "gold",   # Currency name
    100       # Amount to add
)

if result is Dictionary:
    if result.has("error"):
        print("Failed: ", result["error"])
    else:
        print("Added 100 gold!")
```

This method automatically:
1. Looks up the currency template by tag "currency"
2. Finds the player's wallet for that template
3. Sends the add funds command

## Unlock Achievement

```gdscript
var result = await FlockClient.get_instance().commands.unlock_achievement_async("first_blood")

if result is Dictionary:
    if result.has("error"):
        print("Failed: ", result["error"])
    else:
        print("Achievement unlocked: first_blood!")
```

## Flush Pending Writes

Manually flush all queued offline writes:

```gdscript
await FlockClient.get_instance().commands.flush_pending_writes_async()
print("All pending writes synced!")
```

## Offline Queue

When the network is unavailable, write operations are automatically queued:

```gdscript
# This works offline — queues for later sync
var result = await FlockClient.get_instance().commands.update_player_data_async(
    "PLAYER_DATA_ID",
    [{"key": "gold", "value": 500}]
)

if result is Dictionary and result.get("offline", false):
    print("Operation queued — will sync when online")
```

The queue:
- Persists to disk (survives app restart)
- Auto-flushes every 30 seconds when online
- Auto-flushes when connectivity is restored
- Auto-flushes on app quit

## Common Patterns

### Add Currency

```gdscript
func add_gold(amount: int):
    var result = await FlockClient.get_instance().commands.add_game_funds_async("gold", amount)
    if result is Dictionary and not result.has("error"):
        print("Added %d gold" % amount)
```

### Spend Currency

```gdscript
func spend_gold(amount: int) -> bool:
    # Get current balance
    var wallet = await FlockClient.get_instance().player.get_my_data_by_tag_async("currency")
    if wallet is Dictionary:
        var current = wallet.get("data", {}).get("gold", 0)
        if current >= amount:
            var new_amount = current - amount
            var result = await FlockClient.get_instance().commands.update_player_data_field_async(
                wallet.get("id", ""),
                "gold",
                new_amount
            )
            return result is Dictionary and not result.has("error")
    return false
```

### Unlock Multiple Achievements

```gdscript
func unlock_achievements(names: Array):
    for name in names:
        await FlockClient.get_instance().commands.unlock_achievement_async(name)
```

### Save Player Progress

```gdscript
func save_progress(level: int, score: int, data: Dictionary):
    var player_data = await FlockClient.get_instance().player.get_my_data_by_tag_async("progress")
    if player_data is Dictionary:
        var id = player_data.get("id", "")
        var result = await FlockClient.get_instance().commands.update_player_data_async(id, [
            {"key": "level", "value": level},
            {"key": "score", "value": score},
            {"key": "data", "value": data},
            {"key": "last_save", "value": Time.get_datetime_string_from_system()},
        ])
```

## Data Structure

### Pending Write (Internal)

```gdscript
# PendingDataWrite
{
    "path": "game_command/update_player_data",
    "payload_json": "{...}",
    "context": "Update player data",
    "created_at": "2024-01-01T00:00:00Z"
}
```

## Commands vs Direct API

| Feature | Commands Provider | Direct API |
|---------|-------------------|------------|
| Offline queue | Yes | No |
| Auto-retry | Yes | No |
| Player cache sync | Yes | No |
| Analytics tracking | Yes | No |

**Recommendation:** Always use the commands provider for write operations.
