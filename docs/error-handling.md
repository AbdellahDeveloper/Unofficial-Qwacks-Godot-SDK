# Error Handling

The SDK uses a consistent error handling pattern across all providers.

## Error Pattern

All provider methods return `Variant`:
- **Success**: `Dictionary` (response data) or `Array` (list of items)
- **Failure**: `Dictionary` with `error` key

```gdscript
var result = await FlockClient.get_instance().auth.login_with_device()

if result is Dictionary:
    if result.has("error"):
        # Error case
        print("Error: ", result["error"])
        print("Code: ", result.get("code", ""))
        print("Status: ", result.get("status_code", 0))
    else:
        # Success case
        print("Player ID: ", FlockClient.get_instance().current_player_id)
```

## Error Dictionary Structure

```gdscript
{
    "error": "Human-readable error message",
    "code": "error.code.identifier",      # Optional
    "status_code": 401,                   # Optional: HTTP status
    "detail": {}                          # Optional: additional info
}
```

## Common Error Codes

### Authentication Errors

| Code | Description |
|------|-------------|
| `player.invalid_login_credentials` | Wrong email/password or device not registered |
| `player.device_already_registered` | Device ID already in use |
| `player.email_already_registered` | Email already in use |
| `player.name_not_available` | Display name is taken |
| `player.invalid_verification_code` | Wrong email verification code |
| `player.token_expired` | JWT token has expired |
| `player.token_revoked` | Token was revoked |

### Network Errors

| Code | Description |
|------|-------------|
| `network.unreachable` | Server is not reachable |
| `network.timeout` | Request timed out |
| `network.server_error` | Server returned 5xx |

### Validation Errors

| Code | Description |
|------|-------------|
| `validation.required_field` | Required field is missing |
| `validation.invalid_format` | Field format is invalid |

## Handling Specific Errors

### Login Failure

```gdscript
var result = await FlockClient.get_instance().auth.login_with_email(email, password)

if result is Dictionary:
    if result.has("error"):
        match result.get("code", ""):
            "player.invalid_login_credentials":
                print("Wrong email or password")
            "player.email_already_registered":
                print("Email already in use")
            _:
                print("Login failed: ", result["error"])
    else:
        print("Login successful!")
```

### Network Failure

```gdscript
var result = await FlockClient.get_instance().config.get_game_config_by_name("settings")

if result is Dictionary and result.has("error"):
    if result.get("status_code", 0) >= 500:
        print("Server error — try again later")
    elif result.get("status_code", 0) == 0:
        print("Network unavailable — using cached data")
```

### Offline Operations

```gdscript
var result = await FlockClient.get_instance().commands.update_player_data_async(id, data)

if result is Dictionary:
    if result.get("offline", false):
        print("Queued for sync: ", result.get("queued", false))
    elif result.has("error"):
        print("Update failed: ", result["error"])
    else:
        print("Updated successfully")
```

## Error Events

The SDK emits events for certain error conditions:

```gdscript
# Auth expired (token invalid)
FlockEvents.get_instance().auth_expired.connect(func():
    print("Session expired — please re-login")
)

# SDK initialization failed
FlockEvents.get_instance().initialization_failed.connect(func(error: String):
    print("SDK failed to initialize: ", error)
)
```

## Logging Errors

Use the SDK's error logging for analytics:

```gdscript
# Log a logic error
FlockClient.get_instance().analytics.log_error("Player data sync failed", "SYNC_ERROR")

# Log an exception
FlockClient.get_instance().analytics.log_exception("NullReferenceException in Combat.gd:42")
```

## Debug Logging

Enable debug logging in the config to see detailed logs:

```gdscript
config.enable_debug_logs = true
```

This outputs logs to Godot's output panel:

```
[Flock SDK] Initializing Flock SDK
[Flock SDK] Token set for PlayerId: 01KXYZ...
[Flock SDK] Flock SDK initialized successfully
[AuthProvider] Device login starting...
[AuthProvider] Device login successful for player: 01KXYZ...
```

## Error Recovery

### Retry on Failure

```gdscript
func login_with_retry(max_retries: int = 3) -> Variant:
    for i in range(max_retries):
        var result = await FlockClient.get_instance().auth.login_with_device()
        if result is Dictionary and not result.has("error"):
            return result
        if i < max_retries - 1:
            await get_tree().create_timer(1.0).timeout
    return {"error": "Login failed after %d attempts" % max_retries}
```

### Graceful Degradation

```gdscript
func get_config_with_fallback() -> Dictionary:
    var result = await FlockClient.get_instance().config.get_game_config_by_name("settings")
    if result is Dictionary and not result.has("error"):
        return result
    
    # Return defaults if network fails
    return {
        "difficulty": "normal",
        "music_enabled": true,
        "sfx_enabled": true
    }
```
