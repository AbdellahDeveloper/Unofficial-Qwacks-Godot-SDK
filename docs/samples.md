# Sample Projects

The SDK includes two sample scenes demonstrating all features.

## Quick Start

**File:** `addons/flock_sdk/sample/quick_start.tscn`

A minimal example covering:
- SDK initialization
- Device login
- Session management
- Basic event logging

### How to Run

1. Open `addons/flock_sdk/sample/quick_start.tscn` in Godot Editor
2. Add a `FlockAutoInitializer` node and configure it
3. Press F5 to run

### Code Overview

```gdscript
extends Control

func _ready():
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)

func _on_initialized():
    if FlockClient.get_instance().is_authenticated:
        _on_authenticated({"player_id": FlockClient.get_instance().current_player_id})
    else:
        login_button.disabled = false

func _on_login_pressed():
    var result = await FlockClient.get_instance().auth.login_with_device("")
    if result is Dictionary and result.has("error"):
        status_label.text = "Login Failed: " + result["error"]

func _on_send_event_pressed():
    FlockClient.get_instance().analytics.log_event("test_event", {"source": "quick_start"})
```

## All Features Demo

**File:** `addons/flock_sdk/sample/all_features.tscn`

A comprehensive tabbed demo covering every SDK feature:
- Authentication (device, email, register, logout)
- Player Data (CRUD, templates, tags)
- Game Config (patches, by name/ID)
- Shop (browse, purchase, inventory)
- Commands (data updates, currency, achievements)
- Assets (browse, download)
- Analytics (events, errors, transactions, consent)
- Session (info, start/end)
- Client Info (status, version, reachability)

### How to Run

1. Open `addons/flock_sdk/sample/all_features.tscn` in Godot Editor
2. Add a `FlockAutoInitializer` node and configure it
3. Press F5 to run

### Tab Overview

| Tab | Features |
|-----|----------|
| **Auth** | Login, register, logout, name check, password reset, email verify |
| **Player** | Fetch data, templates, bans, cache management |
| **Config** | Patches, configs by name/ID/schema |
| **Game** | Game info, version info |
| **Shop** | Browse shops, items, purchase, inventory |
| **Commands** | Update data, add funds, unlock achievements |
| **Asset** | Browse assets, download, cache |
| **Analytics** | Log events, errors, exceptions, transactions |
| **Session** | Session info, start/end, refresh |
| **Events** | Event log viewer |

## Creating Your Own Scene

### Basic Setup

```gdscript
extends Control

func _ready():
    # Connect to SDK events
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)
    FlockEvents.get_instance().auth_expired.connect(_on_expired)

func _on_initialized():
    # SDK is ready — check for existing session
    if FlockClient.get_instance().is_authenticated:
        _on_authenticated({"player_id": FlockClient.get_instance().current_player_id})

func _on_authenticated(info: Dictionary):
    print("Player logged in: ", info["player_id"])
    # Start using the SDK

func _on_expired():
    print("Session expired")
    # Handle re-login
```

### Minimal Login Flow

```gdscript
extends Control

@onready var login_btn: Button = %LoginButton
@onready var status: Label = %Status

func _ready():
    login_btn.pressed.connect(_on_login)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)

func _on_login():
    login_btn.disabled = true
    status.text = "Logging in..."
    var result = await FlockClient.get_instance().auth.login_with_device()
    if result is Dictionary and result.has("error"):
        status.text = "Failed: " + result["error"]
        login_btn.disabled = false

func _on_authenticated(info: Dictionary):
    status.text = "Logged in: " + info["player_id"]
```
