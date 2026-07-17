# API Reference

Complete reference for all SDK classes and methods.

## Singletons

### FlockClient

Main SDK singleton. Access via `FlockClient.get_instance()`.

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `is_initialized` | `bool` (static) | Whether SDK is initialized |
| `is_authenticated` | `bool` | Whether player is authenticated |
| `is_token_expired` | `bool` | Whether JWT token is expired |
| `current_player_id` | `String` | Current player's ID |
| `game_id` | `String` | Game ID from config |
| `game_version_id` | `String` | Game version ID from config |
| `token_claims` | `Dictionary` | JWT token claims |
| `has_active_session` | `bool` | Whether analytics session is active |
| `current_session_id` | `String` | Current session ID |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `create(config: FlockInitConfig)` | `void` | Initialize SDK |
| `shutdown()` | `void` | Shutdown SDK |
| `set_tokens(access_token, refresh_token)` | `void` | Set JWT tokens |
| `clear_tokens()` | `void` | Clear all tokens |
| `get_base_headers()` | `Dictionary` | Get auth headers |
| `get_api_url()` | `String` | Get API base URL |
| `get_versioned_api_url()` | `String` | Get versioned API URL |
| `is_reachable()` | `bool` | Check network |
| `try_refresh_token()` | `bool` | Refresh JWT token |

### FlockEvents

Event hub singleton. Access via `FlockEvents.get_instance()`.

#### Signals

See [Events System](events.md) for complete signal reference.

---

## Providers

### FlockAuthProvider

Access: `FlockClient.get_instance().auth`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `login_with_email` | `email, password` | `Variant` | Login with email |
| `login_with_device` | `device_id = ""` | `Variant` | Login with device |
| `login_with_google` | `id_token` | `Variant` | Login with Google |
| `login_with_apple` | `identity_token` | `Variant` | Login with Apple |
| `login_with_steam` | `session_ticket` | `Variant` | Login with Steam |
| `login_with_facebook` | `facebook_id` | `Variant` | Login with Facebook |
| `login_with_discord` | `discord_id` | `Variant` | Login with Discord |
| `register_with_email` | `email, password, name = ""` | `Variant` | Register with email |
| `register_with_device` | `device_id, name = ""` | `Variant` | Register with device |
| `register_with_google` | `id_token, name = ""` | `Variant` | Register with Google |
| `register_with_apple` | `identity_token, name = ""` | `Variant` | Register with Apple |
| `register_with_steam` | `session_ticket, name = ""` | `Variant` | Register with Steam |
| `forgot_password` | `email` | `Variant` | Request password reset |
| `reset_password` | `email, code, new_password` | `Variant` | Reset password |
| `send_email_verification` | — | `Variant` | Send verification email |
| `verify_email` | `code` | `Variant` | Verify email |
| `revoke_token` | — | `Variant` | Revoke current token |
| `is_name_available` | `name` | `Variant` | Check name availability |
| `try_restore_session` | — | `bool` | Restore previous session |
| `logout` | — | `void` | Logout and clear tokens |

### FlockPlayerProvider

Access: `FlockClient.get_instance().player`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_all_data_async` | `player_id = "", page = 1, limit = 100` | `Variant` | Get all player data |
| `get_data_by_id_async` | `player_data_id` | `Variant` | Get data by ID |
| `get_my_data_by_template_async` | `template_id` | `Variant` | Get data by template |
| `get_my_data_by_tag_async` | `tag` | `Variant` | Get data by tag |
| `get_templates_async` | — | `Variant` | Get all templates |
| `get_template_by_tag_async` | `tag` | `Variant` | Get template by tag |
| `get_all_templates_async` | — | `Variant` | Get all templates |
| `get_ban_async` | `player_id` | `Variant` | Check ban status |
| `clear_cache` | — | `void` | Clear player cache |

### FlockConfigProvider

Access: `FlockClient.get_instance().config`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_all_patches` | — | `Variant` | Get all patches |
| `get_by_id` | `config_id` | `Variant` | Get config by ID |
| `get_by_schema` | `schema_id` | `Variant` | Get patches by schema |
| `get_by_config_id` | `config_id` | `Variant` | Get config data |
| `get_game_config_by_name` | `name` | `Variant` | Get config by name |
| `clear_cache` | — | `void` | Clear config cache |

### FlockGameProvider

Access: `FlockClient.get_instance().game`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_game_async` | — | `Variant` | Get game info |
| `get_game_version_async` | — | `Variant` | Get game version |
| `get_game_version_by_name_async` | `name` | `Variant` | Get version by name |
| `clear_cache` | — | `void` | Clear game cache |

### FlockShopProvider

Access: `FlockClient.get_instance().shop`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_all_async` | `page = 1, limit = 100` | `Variant` | Get all shops |
| `get_by_id_async` | `shop_id` | `Variant` | Get shop by ID |
| `get_by_name_async` | `name` | `Variant` | Get shop by name |
| `get_item_async` | `shop_item_id` | `Variant` | Get item by ID |
| `get_items_by_shop_async` | `shop_id` | `Variant` | Get items for shop |
| `purchase_async` | `shop_item_id, player_id = ""` | `Variant` | Purchase item |
| `get_player_inventory_async` | `player_id = "", page = 1, limit = 100` | `Variant` | Get inventory |
| `clear_cache` | — | `void` | Clear shop cache |

### FlockAssetProvider

Access: `FlockClient.get_instance().asset`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `get_all_async` | — | `Variant` | Get all assets |
| `get_by_id_async` | `asset_id` | `Variant` | Get asset by ID |
| `get_by_name_async` | `name` | `Variant` | Get asset by name |
| `download_async` | `asset_id` | `Variant` | Download asset |
| `clear_cache` | — | `void` | Clear asset cache |

### FlockCommandProvider

Access: `FlockClient.get_instance().commands`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `update_player_data_async` | `player_data_id, data` | `Variant` | Update player data |
| `update_player_data_field_async` | `player_data_id, key, value` | `Variant` | Update single field |
| `add_game_funds_async` | `currency, amount` | `Variant` | Add currency |
| `unlock_achievement_async` | `achievement_name` | `Variant` | Unlock achievement |
| `flush_pending_writes_async` | — | `void` | Flush offline queue |

### FlockAnalyticsProvider

Access: `FlockClient.get_instance().analytics`

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `log_event` | `event_name, properties = {}` | `void` | Log custom event |
| `log_error` | `message, error_code = ""` | `void` | Log error |
| `log_exception` | `exception` | `void` | Log exception |
| `record_transaction_async` | `transaction: Dictionary` | `Variant` | Record transaction |
| `record_screen_view` | `screen_name` | `void` | Record screen view |
| `start_session_async` | — | `Variant` | Start session |
| `end_session_async` | — | `Variant` | End session |
| `flush_async` | — | `Variant` | Flush all events |
| `set_consent` | `granted` | `void` | Set analytics consent |
| `erase_local_analytics_data` | — | `void` | Clear analytics cache |

---

## Configuration

### FlockInitConfig

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `api_url` | `String` | `""` | API base URL |
| `api_key` | `String` | `""` | API authentication key |
| `game_id` | `String` | `""` | Game identifier |
| `game_version` | `String` | `""` | Game version name |
| `game_version_id` | `String` | `""` | Game version ID |
| `enable_debug_logs` | `bool` | `false` | Enable debug logging |
| `enable_offline_cache` | `bool` | `true` | Enable snapshot cache |
| `enable_asset_cache` | `bool` | `true` | Enable asset cache |
| `asset_cache_max_size_mb` | `int` | `100` | Max asset cache size |
| `http_timeout` | `float` | `30.0` | HTTP timeout |
| `analytics_config` | `Dictionary` | `{}` | Analytics settings |
| `retry_policy` | `Dictionary` | `{}` | Retry settings |

### FlockAutoInitializer (Inspector)

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `game_id` | `String` | `""` | Game ID |
| `game_version_id` | `String` | `""` | Version ID |
| `api_url` | `String` | `"https://api-flock.qwacks.com"` | API URL |
| `api_key` | `String` | `""` | API key |
| `offline_cache_enabled` | `bool` | `true` | Enable cache |
| `analytics_enabled` | `bool` | `true` | Enable analytics |
| `enable_debug_logs` | `bool` | `false` | Debug logging |

---

## Utility Classes

### FlockDeviceInfo

```gdscript
var info = FlockDeviceInfo.capture()
# Returns: {platform, os, device_type, ...}
```

### FlockUtil

```gdscript
var dir = FlockUtil.flock_data_dir()        # user://flock/
var snap = FlockUtil.flock_snapshots_dir()  # user://flock/snapshots/
var assets = FlockUtil.flock_assets_dir()   # user://flock/assets/
```

### FlockSdkVersion

```gdscript
print(FlockSdkVersion.CURRENT)  # "1.28.0"
```

---

## Data Models

### AuthModels

| Method | Returns | Description |
|--------|---------|-------------|
| `login_request(...)` | `Dictionary` | Build login request |
| `email_registration_request(...)` | `Dictionary` | Build email registration |
| `device_login_request(...)` | `Dictionary` | Build device login |
| `device_registration_request(...)` | `Dictionary` | Build device registration |
| `google_login_request(...)` | `Dictionary` | Build Google login |
| `apple_login_request(...)` | `Dictionary` | Build Apple login |
| `steam_login_request(...)` | `Dictionary` | Build Steam login |

### AnalyticsModels

| Method | Returns | Description |
|--------|---------|-------------|
| `session_start_request(...)` | `Dictionary` | Build session start |
| `session_end_request(...)` | `Dictionary` | Build session end |
| `analytics_event_request(...)` | `Dictionary` | Build analytics event |
| `analytics_events_request(...)` | `Dictionary` | Build events batch |
| `analytics_transaction_request(...)` | `Dictionary` | Build transaction |

### GameCommandModels

| Method | Returns | Description |
|--------|---------|-------------|
| `update_player_data_input(...)` | `Dictionary` | Build data update |
| `update_player_data_key_input(...)` | `Dictionary` | Build field update |
| `add_game_funds_input(...)` | `Dictionary` | Build funds add |
| `unlock_achievement_input(...)` | `Dictionary` | Build achievement unlock |
| `shop_transaction_request(...)` | `Dictionary` | Build shop transaction |
