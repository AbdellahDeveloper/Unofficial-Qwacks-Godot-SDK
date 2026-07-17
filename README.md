# Unofficial Qwacks Godot SDK

A pure GDScript implementation of the [Flock/QwackStack](https://qwacks.com) game backend SDK for **Godot 4.x**.

> **Version 1.28.0** — Ported from the official C# Unity SDK.

[![Godot 4.x](https://img.shields.io/badge/Godot-4.x-blue)](https://godotengine.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/Docs-docsify-blue)](https://unofficial-qwacks-godot-sdk.github.io/qwacks-godot-sdk/)

---

## What is this?

This SDK connects your Godot game to the [Qwacks](https://qwacks.com) backend platform, providing:

- **Authentication** — Email, Device, Google, Apple, Steam, Facebook, Discord
- **Player Data** — CRUD operations on player templates with offline caching
- **Game Config** — Remote configuration with live patching
- **Shop** — In-game shop with item purchases and inventory
- **Assets** — Remote asset management with local caching
- **Commands** — Player data updates, currency, achievements
- **Analytics** — Session tracking, events, transactions, error logging
- **Offline Support** — Automatic caching and write queuing when offline

## Quick Setup

### 1. Install the plugin

Copy the `addons/flock_sdk/` folder into your Godot project:

```
your-project/
├── addons/
│   └── flock_sdk/
│       ├── plugin.cfg
│       ├── plugin.gd
│       ├── core/
│       ├── auth/
│       ├── providers/
│       ├── models/
│       ├── http/
│       ├── analytics/
│       ├── bootstrap/
│       ├── config/
│       ├── logging/
│       ├── exceptions/
│       └── sample/
└── project.godot
```

### 2. Enable the plugin

In Godot Editor: **Project → Project Settings → Plugins → Enable "Flock SDK"**

### 3. Add the Auto-Initializer

Add a `FlockAutoInitializer` node to your root scene and configure it in the Inspector:

![Inspector setup](screenshots/inspector-setup.png)

Or add it via code:

```gdscript
# In your main scene or autoload
func _ready():
    var flock = FlockAutoInitializer.new()
    flock.game_id = "YOUR_GAME_ID"
    flock.game_version_id = "YOUR_VERSION_ID"
    flock.api_key = "YOUR_API_KEY"
    add_child(flock)
```

### 4. Connect to events

```gdscript
FlockEvents.get_instance().initialized.connect(func():
    print("SDK Ready!")
    # Start using the SDK
)

FlockEvents.get_instance().authenticated.connect(func(info: Dictionary):
    print("Player: ", info["player_id"])
)
```

### 5. Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_device()
if result is Dictionary and not result.has("error"):
    print("Logged in!")
```

## Documentation

Full documentation is available at: **[unofficial-qwacks-godot-sdk.github.io/qwacks-godot-sdk](https://unofficial-qwacks-godot-sdk.github.io/qwacks-godot-sdk/)**

- [Getting Started](docs/guide/getting-started.md)
- [Installation](docs/guide/installation.md)
- [Configuration](docs/guide/configuration.md)
- [Authentication](docs/providers/authentication.md)
- [Player Data](docs/providers/player-data.md)
- [Game Config](docs/providers/game-config.md)
- [Shop](docs/providers/shop.md)
- [Assets](docs/providers/assets.md)
- [Commands](docs/providers/commands.md)
- [Analytics](docs/providers/analytics.md)
- [Events System](docs/events.md)
- [Error Handling](docs/error-handling.md)
- [Offline Support](docs/offline-support.md)
- [API Reference](docs/api-reference.md)
- [Migration from C#](docs/migration.md)

## Requirements

- **Godot 4.2+** (tested on 4.7.1)
- **Internet connection** for backend calls
- A [Qwacks](https://qwacks.com) game account with API key and Game Version ID

## License

MIT — See [LICENSE](LICENSE) for details.

> **Disclaimer:** This is an unofficial community port. Not affiliated with QwackStack or Flock.
