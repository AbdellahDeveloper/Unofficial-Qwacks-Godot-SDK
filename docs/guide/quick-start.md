# Quick Start

Get your game connected to Qwacks in 5 minutes.

## Step 1: Enable the Plugin

1. Copy `addons/flock_sdk/` into your project
2. Go to **Project → Project Settings → Plugins**
3. Enable **"Flock SDK"**

## Step 2: Add the Auto-Initializer

Add a `FlockAutoInitializer` node to your root scene and fill in the Inspector fields:

- **Game ID**: Your game ID
- **Game Version ID**: Your version ID
- **Api Key**: Your API key

## Step 3: Connect and Login

```gdscript
extends Control

@onready var status_label: Label = %StatusLabel

func _ready():
    # Wait for SDK to initialize
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().initialization_failed.connect(_on_init_failed)

func _on_initialized():
    status_label.text = "SDK Ready! Logging in..."
    
    # Login with device (auto-registers first time)
    var result = await FlockClient.get_instance().auth.login_with_device()
    
    if result is Dictionary and not result.has("error"):
        status_label.text = "Logged in! Player: %s" % FlockClient.get_instance().current_player_id
    else:
        status_label.text = "Login failed: %s" % result.get("error", "Unknown")

func _on_init_failed(error: String):
    status_label.text = "SDK Init Failed: %s" % error
```

## Step 4: Use the SDK

Once authenticated, you can use any provider:

```gdscript
# Log an analytics event
FlockClient.get_instance().analytics.log_event("game_started", {"level": 1})

# Fetch player data
var data = await FlockClient.get_instance().player.get_all_data_async()

# Read game config
var config = await FlockClient.get_instance().config.get_game_config_by_name("settings")

# Get shop items
var shops = await FlockClient.get_instance().shop.get_all_async()
```

## Complete Quick Start Example

Here's a complete `main.gd` that covers all basics:

```gdscript
extends Control

@onready var status_label: Label = %StatusLabel
@onready var player_id_label: Label = %PlayerIdLabel
@onready var login_button: Button = %LoginButton
@onready var logout_button: Button = %LogoutButton
@onready var send_event_button: Button = %SendEventButton

func _ready():
    status_label.text = "Initializing SDK..."
    login_button.disabled = true
    logout_button.disabled = true
    send_event_button.disabled = true

    # Connect to SDK events
    FlockEvents.get_instance().initialized.connect(_on_initialized)
    FlockEvents.get_instance().initialization_failed.connect(_on_init_failed)
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)
    FlockEvents.get_instance().auth_expired.connect(_on_expired)


func _on_initialized():
    status_label.text = "SDK Initialized"
    
    # Check if already logged in (session restored)
    if FlockClient.get_instance().is_authenticated:
        _on_authenticated({"player_id": FlockClient.get_instance().current_player_id})
    else:
        login_button.disabled = false


func _on_init_failed(error: String):
    status_label.text = "SDK Failed: %s" % error


func _on_authenticated(info: Dictionary):
    status_label.text = "Authenticated"
    player_id_label.text = "Player ID: %s" % info.get("player_id", "")
    login_button.disabled = true
    logout_button.disabled = false
    send_event_button.disabled = false


func _on_expired():
    status_label.text = "Session Expired"
    player_id_label.text = ""
    login_button.disabled = false
    logout_button.disabled = true
    send_event_button.disabled = true


func _on_login_pressed():
    status_label.text = "Logging in..."
    login_button.disabled = true
    var result = await FlockClient.get_instance().auth.login_with_device("")
    if result is Dictionary and result.has("error"):
        status_label.text = "Login Failed: %s" % result["error"]
        login_button.disabled = false


func _on_logout_pressed():
    FlockClient.get_instance().auth.logout()
    status_label.text = "Logged out"
    player_id_label.text = ""
    login_button.disabled = false
    logout_button.disabled = true
    send_event_button.disabled = true


func _on_send_event_pressed():
    FlockClient.get_instance().analytics.log_event("test_event", {"source": "quick_start"})
    status_label.text = "Event sent!"
```

## Next Steps

- [Configuration](configuration.md) — Customize SDK behavior
- [Authentication](../providers/authentication.md) — All login methods
- [Events System](../events.md) — React to SDK lifecycle
