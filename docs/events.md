# Events System

The SDK uses a signal-based event system through `FlockEvents`. Connect to these signals to react to SDK lifecycle changes.

## Access

```gdscript
var events = FlockEvents.get_instance()
```

## Available Signals

### Lifecycle

| Signal | Parameters | Description |
|--------|------------|-------------|
| `initialized` | — | SDK successfully initialized |
| `initialization_failed` | `error: String` | SDK failed to initialize |
| `shutdown` | — | SDK is shutting down |

### Authentication

| Signal | Parameters | Description |
|--------|------------|-------------|
| `authenticated` | `info: Dictionary` | Player successfully authenticated |
| `token_refreshed` | — | JWT token was refreshed |
| `auth_expired` | — | Authentication expired (token invalid) |
| `logged_out` | — | Player logged out |

The `authenticated` signal's `info` dictionary contains:
```gdscript
{
    "player_id": "01KXYZ...",
    "method": "Device"  # "Email", "Google", "Apple", "Steam", etc.
}
```

### Session

| Signal | Parameters | Description |
|--------|------------|-------------|
| `session_restored` | `restored: bool` | Previous session restored (or not) |
| `session_started` | `session_id: String` | New analytics session started |
| `session_ended` | `args: Dictionary` | Session ended |
| `session_paused` | — | Session paused (app backgrounded) |
| `session_resumed` | — | Session resumed (app foregrounded) |

### Other

| Signal | Parameters | Description |
|--------|------------|-------------|
| `consent_changed` | `granted: bool` | Analytics consent changed |

## Connecting to Events

### Basic Connection

```gdscript
func _ready():
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)
    FlockEvents.get_instance().auth_expired.connect(_on_expired)

func _on_initialized():
    print("SDK Ready!")

func _on_authenticated(info: Dictionary):
    print("Player: ", info["player_id"])

func _on_expired():
    print("Session expired!")
```

### Lambda Connection

```gdscript
FlockEvents.get_instance().initialized.connect(func():
    print("SDK Ready!")
)

FlockEvents.get_instance().authenticated.connect(func(info: Dictionary):
    print("Player: ", info["player_id"], " via ", info["method"])
)
```

### Disconnecting

```gdscript
var _on_init_callable: Callable

func _ready():
    _on_init_callable = func(): print("SDK Ready!")
    FlockEvents.get_instance().initialized.connect(_on_init_callable)

func _cleanup():
    if FlockEvents.get_instance().initialized.is_connected(_on_init_callable):
        FlockEvents.get_instance().initialized.disconnect(_on_init_callable)
```

## Event Flow

### Startup Flow

```
App Start
  → FlockRuntimeSetup creates FlockEvents + FlockClient
  → FlockAutoInitializer calls FlockClient.create()
  → FlockClient initializes providers
  → FlockEvents.initialized emitted
  → If session exists: auth.try_restore_session()
  → FlockEvents.authenticated emitted (if restored)
  → FlockEvents.session_restored emitted
```

### Login Flow

```
auth.login_with_device()
  → API call to /player/login/device
  → Success: FlockEvents.authenticated emitted
  → Analytics session started automatically
  → FlockEvents.session_started emitted
```

### Session Lifecycle

```
Session Started
  → FPS tracking begins
  → Heartbeat timer active
  → Events queued and flushed periodically
  
App Backgrounded
  → FlockEvents.session_paused emitted
  → Session pauses (timer stops)
  → Events flushed
  
App Foregrounded
  → FlockEvents.session_resumed emitted
  → Session resumes (timer restarts)
  
Session Ended
  → FlockEvents.session_ended emitted
  → Session data sent to server
  → Events flushed
```

## Full Example

```gdscript
extends Control

func _ready():
    # Connect all events
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().initialization_failed.connect(_on_init_failed)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)
    FlockEvents.get_instance().token_refreshed.connect(_on_token_refreshed)
    FlockEvents.get_instance().auth_expired.connect(_on_auth_expired)
    FlockEvents.get_instance().logged_out.connect(_on_logged_out)
    FlockEvents.get_instance().session_restored.connect(_on_session_restored)
    FlockEvents.get_instance().session_started.connect(_on_session_started)
    FlockEvents.get_instance().session_ended.connect(_on_session_ended)
    FlockEvents.get_instance().session_paused.connect(_on_session_paused)
    FlockEvents.get_instance().session_resumed.connect(_on_session_resumed)
    FlockEvents.get_instance().consent_changed.connect(_on_consent_changed)


func _on_initialized():
    print("[Event] SDK Initialized")

func _on_init_failed(error: String):
    print("[Event] Init Failed: ", error)

func _on_authenticated(info: Dictionary):
    print("[Event] Authenticated: ", info["player_id"], " via ", info["method"])

func _on_token_refreshed():
    print("[Event] Token Refreshed")

func _on_auth_expired():
    print("[Event] Auth Expired")

func _on_logged_out():
    print("[Event] Logged Out")

func _on_session_restored(restored: bool):
    print("[Event] Session Restored: ", restored)

func _on_session_started(session_id: String):
    print("[Event] Session Started: ", session_id)

func _on_session_ended(args: Dictionary):
    print("[Event] Session Ended: ", args)

func _on_session_paused():
    print("[Event] Session Paused")

func _on_session_resumed():
    print("[Event] Session Resumed")

func _on_consent_changed(granted: bool):
    print("[Event] Consent Changed: ", granted)
```
