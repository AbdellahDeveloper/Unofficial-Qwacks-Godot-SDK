# Analytics

The `analytics` provider handles session tracking, custom events, transactions, and error logging.

## Access

```gdscript
var analytics = FlockClient.get_instance().analytics
```

## Sessions

### Auto-Start

Sessions start automatically when `analytics_config.auto_start_session` is `true` (default).

### Start Session Manually

```gdscript
var result = await FlockClient.get_instance().analytics.start_session_async()
```

### End Session

```gdscript
var result = await FlockClient.get_instance().analytics.end_session_async()
```

### Session Info

```gdscript
var client = FlockClient.get_instance()
if client.session:
    var s = client.session
    print("Active: ", s.is_active)
    print("Session ID: ", s.session_id)
    print("Server Session ID: ", s.server_session_id)
    print("Duration: ", s.elapsed_seconds, "s")
    print("FPS: avg=", s.average_fps, " min=", s.min_fps, " max=", s.max_fps)
    print("Screens: ", s.screens_viewed)
    print("Pauses: ", s.pause_count)
```

## Custom Events

### Log Event

```gdscript
FlockClient.get_instance().analytics.log_event("level_complete", {
    "level": 5,
    "score": 12500,
    "time_seconds": 145
})
```

Events are queued and flushed automatically at regular intervals.

### Log Screen View

```gdscript
FlockClient.get_instance().analytics.record_screen_view("main_menu")
```

## Error Logging

### Log Error

```gdscript
FlockClient.get_instance().analytics.log_error(
    "Failed to load texture: hero_sprite.png",
    "TEXTURE_LOAD_ERROR"
)
```

### Log Exception

```gdscript
FlockClient.get_instance().analytics.log_exception("NullReferenceException in CombatSystem.gd:42")
```

## Transactions

### Record Transaction

```gdscript
var result = await FlockClient.get_instance().analytics.record_transaction_async({
    "player_id": FlockClient.get_instance().current_player_id,
    "amount": 9.99,
    "currency_code": "USD",
    "shop_item_id": "ITEM_ID",
    "quantity": 1,
    "transaction_type": "purchase",
    "status": "completed"
})
```

Transactions are also recorded automatically by the shop provider during purchases.

## Consent

### Set Consent

```gdscript
# Grant consent (enables analytics)
FlockClient.get_instance().analytics.set_consent(true)

# Revoke consent (disables analytics)
FlockClient.get_instance().analytics.set_consent(false)
```

Consent is persisted to disk and survives app restarts.

### Check Consent State

Consent state is stored in `user://flock/consent.cfg`.

## Flush Events

Force-flush all pending events:

```gdscript
await FlockClient.get_instance().analytics.flush_async()
print("All events flushed!")
```

Events auto-flush:
- Every 30 seconds
- On session end
- On app quit
- On consent change

## Erase Local Data

Clear all locally cached analytics data:

```gdscript
FlockClient.get_instance().analytics.erase_local_analytics_data()
```

## Device Info

Get device information for analytics context:

```gdscript
var info = FlockDeviceInfo.capture()
print("Platform: ", info.get("platform", ""))
print("OS: ", info.get("os", ""))
print("Device: ", info.get("device_type", ""))
```

## Common Patterns

### Track Level Completion

```gdscript
func on_level_complete(level: int, score: int, time: float):
    FlockClient.get_instance().analytics.log_event("level_complete", {
        "level": level,
        "score": score,
        "time_seconds": time
    })
```

### Track Player Actions

```gdscript
func on_player_death(cause: String, position: Vector2):
    FlockClient.get_instance().analytics.log_event("player_death", {
        "cause": cause,
        "x": position.x,
        "y": position.y
    })
```

### Track In-App Purchase

```gdscript
func on_iap_purchase(product_id: String, price: float, currency: String):
    await FlockClient.get_instance().analytics.record_transaction_async({
        "player_id": FlockClient.get_instance().current_player_id,
        "amount": price,
        "currency_code": currency,
        "shop_item_id": product_id,
        "quantity": 1,
        "transaction_type": "purchase",
        "status": "completed"
    })
```

### Track Errors with Context

```gdscript
func track_error(error: String, context: String):
    FlockClient.get_instance().analytics.log_error(error, context)
    # Also log as event for custom analytics
    FlockClient.get_instance().analytics.log_event("error_occurred", {
        "error": error,
        "context": context,
        "scene": get_tree().current_scene.name
    })
```

## Event Structure

### Analytics Event

```json
{
    "player_id": "01KXYZ...",
    "event_name": "level_complete",
    "event_category": "custom",
    "session_id": "01KXYZ...",
    "timestamp": "2024-06-15T12:00:00Z",
    "properties": {
        "level": 5,
        "score": 12500
    }
}
```

### Log Event

```json
{
    "message": "Failed to load texture",
    "data": {
        "type": "logic_error",
        "game_version": "",
        "error_message": "Failed to load texture",
        "error_code": "TEXTURE_LOAD_ERROR",
        "error_traceback": "",
        "extra_data": {}
    },
    "timestamp": "2024-06-15T12:00:00Z"
}
```

### Session Start

```json
{
    "player_id": "01KXYZ...",
    "platform": "Windows",
    "device_type": "Windows",
    "game_version_id": "01KXYZ...",
    "started_at": "2024-06-15T12:00:00Z"
}
```

### Session End

```json
{
    "duration_seconds": 145,
    "screens_viewed": 5,
    "is_bounce": false,
    "ended_at": "2024-06-15T12:02:25Z"
}
```
