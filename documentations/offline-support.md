# Offline Support

The SDK provides comprehensive offline support through caching, snapshots, and write queueing.

## Overview

When the network is unavailable:

1. **Read operations** serve data from local cache/snapshots
2. **Write operations** are queued and synced when online
3. **Analytics events** are cached and flushed on reconnect
4. **Session state** survives app restarts

## Caching Layers

### 1. Memory Cache

Providers cache API responses in memory for the current session:

```gdscript
# First call: fetches from API
var config = await FlockClient.get_instance().config.get_game_config_by_name("settings")

# Second call: served from memory (instant)
var config2 = await FlockClient.get_instance().config.get_game_config_by_name("settings")
```

### 2. Snapshot Cache

API responses are saved to disk for offline use:

```
user://flock/snapshots/{game_version_id}/
├── config/
│   └── game_config_settings.snap
├── player_template/
│   └── all.snap
├── shop/
│   └── all_p1_l100.snap
└── asset/
    └── asset_index.snap
```

### 3. Asset Cache

Downloaded assets are saved locally:

```
user://flock/assets/
├── {asset_id}_{hash}.png
├── {asset_id}_{hash}.json
└── ...
```

### 4. Token Store

JWT tokens are persisted for session restore:

```
user://flock/token_store.cfg
```

## Write Queue

When offline, write operations are queued:

```gdscript
# This queues when offline
var result = await FlockClient.get_instance().commands.update_player_data_async(
    "DATA_ID",
    [{"key": "gold", "value": 500}]
)

# Check if queued
if result is Dictionary and result.get("offline", false):
    print("Queued for sync")
```

### Queue Persistence

The queue persists to disk:

```
user://flock/snapshots/{game_version_id}/command/{player_id}/pending_writes.json
```

### Auto-Flush

The queue auto-flushes:
- Every 30 seconds (when online)
- When connectivity is restored
- On app quit (if online)

### Manual Flush

```gdscript
await FlockClient.get_instance().commands.flush_pending_writes_async()
```

## Configuration

### Enable/Disable Caching

```gdscript
config.enable_offline_cache = true    # Snapshot cache
config.enable_asset_cache = true      # Asset cache
```

### Custom Cache Directories

```gdscript
config.offline_cache_directory = "user://my_game/cache/"
config.asset_cache_directory = "user://my_game/assets/"
```

### Cache Size Limits

```gdscript
config.asset_cache_max_size_mb = 200  # Maximum 200MB for assets
```

## Provider Behavior Offline

### Auth Provider

| Method | Offline Behavior |
|--------|------------------|
| `login_with_device()` | Fails (requires network) |
| `try_restore_session()` | Works (uses stored tokens) |
| `logout()` | Works (clears local state) |

### Player Provider

| Method | Offline Behavior |
|--------|------------------|
| `get_all_data_async()` | Returns cached snapshots |
| `get_data_by_id_async()` | Returns cached snapshots |
| `get_templates_async()` | Returns cached snapshots |

### Config Provider

| Method | Offline Behavior |
|--------|------------------|
| `get_all_patches()` | Returns cached snapshots |
| `get_game_config_by_name()` | Returns cached snapshots |

### Shop Provider

| Method | Offline Behavior |
|--------|------------------|
| `get_all_async()` | Returns cached snapshots |
| `get_by_id_async()` | Returns cached snapshots |
| `purchase_async()` | Fails (requires network) |

### Asset Provider

| Method | Offline Behavior |
|--------|------------------|
| `get_all_async()` | Returns cached index |
| `get_by_id_async()` | Returns cached metadata |
| `download_async()` | Returns cached file if available |

### Commands Provider

| Method | Offline Behavior |
|--------|------------------|
| `update_player_data_async()` | Queues for sync |
| `update_player_data_field_async()` | Queues for sync |
| `add_game_funds_async()` | Fails (requires network) |
| `unlock_achievement_async()` | Queues for sync |

### Analytics Provider

| Method | Offline Behavior |
|--------|------------------|
| `log_event()` | Caches locally |
| `log_error()` | Caches locally |
| `log_exception()` | Caches locally |
| `record_transaction_async()` | Caches locally |
| `start_session_async()` | Caches locally |
| `end_session_async()` | Caches locally |

## Detecting Network State

```gdscript
func is_online() -> bool:
    return OS.has_feature("online")
```

## Common Patterns

### Offline-Aware Data Loading

```gdscript
func load_config() -> Dictionary:
    var result = await FlockClient.get_instance().config.get_game_config_by_name("settings")
    
    if result is Dictionary:
        if result.has("error"):
            # Check if it's a network error
            if result.get("status_code", 0) == 0:
                print("Offline — using cached config")
            else:
                print("Server error: ", result["error"])
            return _get_default_config()
        return result
    return _get_default_config()

func _get_default_config() -> Dictionary:
    return {"difficulty": "normal", "music": true}
```

### Offline-Aware Save

```gdscript
func save_score(score: int):
    var result = await FlockClient.get_instance().commands.update_player_data_field_async(
        "SCORE_DATA_ID",
        "high_score",
        score
    )
    
    if result is Dictionary:
        if result.get("offline", false):
            _show_notification("Score saved locally — will sync when online")
        elif result.has("error"):
            _show_notification("Failed to save: " + result["error"])
        else:
            _show_notification("Score saved!")
```

## Data Integrity

### Conflict Resolution

When the same data is modified offline and on another device:
- Last write wins (server-side)
- The offline queue sends operations in order
- If a conflict is detected, the server returns an error

### Queue Retry

Failed queue operations are retried with exponential backoff:
- Initial delay: 500ms
- Max delay: 5000ms
- Multiplier: 2x

## Best Practices

1. **Always check for offline state** before critical operations
2. **Use the commands provider** for all write operations (auto-queues)
3. **Cache frequently-accessed data** (the SDK does this automatically)
4. **Handle network errors gracefully** in your UI
5. **Let the SDK manage flushing** — don't flush too frequently
