# Configuration

The SDK is configured through `FlockInitConfig` or the `FlockAutoInitializer` Inspector properties.

## Configuration Options

### Required Fields

| Property | Type | Description |
|----------|------|-------------|
| `game_id` | `String` | Your game's unique identifier from Qwacks |
| `game_version_id` | `String` | The current game version ID |
| `api_key` | `String` | Your API authentication key |
| `api_url` | `String` | API base URL (default: `https://api-flock.qwacks.com`) |

### Optional Fields

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `enable_debug_logs` | `bool` | `false` | Enable verbose logging to output |
| `enable_offline_cache` | `bool` | `true` | Cache API responses for offline use |
| `offline_cache_directory` | `String` | `""` | Custom cache directory (default: `user://flock/`) |
| `enable_asset_cache` | `bool` | `true` | Cache downloaded assets locally |
| `asset_cache_directory` | `String` | `""` | Custom asset cache directory |
| `asset_cache_max_size_mb` | `int` | `100` | Maximum asset cache size in MB |
| `asset_download_timeout` | `float` | `0.0` | Asset download timeout (0 = no timeout) |
| `asset_download_retry_count` | `int` | `3` | Number of retry attempts for asset downloads |
| `asset_max_concurrent_downloads` | `int` | `4` | Max simultaneous asset downloads |
| `http_timeout` | `float` | `30.0` | General HTTP request timeout |
| `analytics_config` | `Dictionary` | `{}` | Analytics configuration (see below) |
| `retry_policy` | `Dictionary` | `{}` | Custom retry policy (see below) |
| `token_store` | `RefCounted` | `null` | Custom token persistence (default: ConfigFile) |

## Analytics Configuration

The `analytics_config` dictionary controls session tracking and event batching:

```gdscript
config.analytics_config = {
    "enabled": true,                    # Enable/disable analytics entirely
    "auto_start_session": true,         # Auto-start session on authentication
    "persist_session_on_disk": true,    # Save session state for crash recovery
    "max_cached_events": 1000,          # Max events queued before flush
    "cache_flush_batch_size": 50,       # Events per flush batch
}
```

### Analytics Config Options

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `enabled` | `bool` | `true` | Master switch for analytics |
| `auto_start_session` | `bool` | `true` | Start tracking session automatically |
| `persist_session_on_disk` | `bool` | `true` | Save session for crash recovery |
| `max_cached_events` | `int` | `1000` | Max queued events before force flush |
| `cache_flush_batch_size` | `int` | `50` | Events sent per batch |

## Retry Policy

Customize retry behavior for failed requests:

```gdscript
config.retry_policy = {
    "max_retries": 3,           # Maximum retry attempts
    "initial_delay_ms": 500,    # Initial delay before first retry
    "max_delay_ms": 5000,       # Maximum delay between retries
    "backoff_multiplier": 2.0,  # Delay multiplier per retry
}
```

## Inspector Configuration

When using `FlockAutoInitializer`, these properties appear in the Inspector:

| Inspector Property | Maps To |
|-------------------|---------|
| **Game Id** | `game_id` |
| **Game Version Id** | `game_version_id` |
| **Api Key** | `api_key` |
| **Api Url** | `api_url` |
| **Offline Cache Enabled** | `enable_offline_cache` |
| **Analytics Enabled** | `analytics_config.enabled` |
| **Enable Debug Logs** | `enable_debug_logs` |

## Full Configuration Example

```gdscript
func _ready():
    var config = FlockInitConfig.new()
    
    # Required
    config.game_id = "YOUR_GAME_ID"
    config.game_version_id = "YOUR_VERSION_ID"
    config.api_key = "YOUR_API_KEY"
    config.api_url = "https://api-flock.qwacks.com"
    
    # Debug
    config.enable_debug_logs = true
    
    # Caching
    config.enable_offline_cache = true
    config.offline_cache_directory = ""  # Uses default
    config.enable_asset_cache = true
    config.asset_cache_max_size_mb = 200
    
    # HTTP
    config.http_timeout = 30.0
    
    # Analytics
    config.analytics_config = {
        "enabled": true,
        "auto_start_session": true,
        "persist_session_on_disk": true,
        "max_cached_events": 500,
        "cache_flush_batch_size": 25,
    }
    
    # Retry
    config.retry_policy = {
        "max_retries": 3,
        "initial_delay_ms": 500,
        "backoff_multiplier": 2.0,
    }
    
    FlockClient.get_instance().create(config)
```

## Data Directory

The SDK stores data in Godot's `user://` directory:

```
user://flock/
├── auth_method.cfg       # Auth method persistence
├── device.cfg            # Device ID
├── token_store.cfg       # JWT tokens
├── consent.cfg           # Analytics consent
├── snapshots/            # Offline cache snapshots
│   └── {game_version_id}/
├── events/               # Cached analytics events
├── log_events/           # Cached log events
└── assets/               # Downloaded asset cache
```

## Next Steps

- [Authentication](../providers/authentication.md) — Login methods
- [Events System](../events.md) — React to SDK lifecycle
- [Offline Support](../offline-support.md) — Caching details
