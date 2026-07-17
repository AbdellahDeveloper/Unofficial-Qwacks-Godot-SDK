# Home

Welcome to the **Unofficial Qwacks Godot SDK** documentation.

This SDK is a pure GDScript port of the [Qwacks](https://qwacks.com) game backend SDK, designed for **Godot 4.x**.

## Features

| Feature | Description |
|---------|-------------|
| **Authentication** | Email, Device, Google, Apple, Steam, Facebook, Discord login & registration |
| **Player Data** | Template-based player data with CRUD operations |
| **Game Config** | Remote configuration with live patching |
| **Shop** | In-game shop, item purchases, and inventory management |
| **Assets** | Remote asset management with local disk caching |
| **Commands** | Player data updates, currency, achievements — with offline queueing |
| **Analytics** | Session tracking, custom events, transactions, error logging |
| **Offline Support** | Automatic caching, snapshot persistence, write queue sync on reconnect |

## Quick Example

```gdscript
# Initialize (use FlockAutoInitializer node or code)
FlockEvents.get_instance().initialized.connect(func():
    # Login with device (auto-registers first time)
    var result = await FlockClient.get_instance().auth.login_with_device()
    
    if result is Dictionary and not result.has("error"):
        # Log a custom event
        FlockClient.get_instance().analytics.log_event("level_complete", {"level": 1})
        
        # Read player config
        var config = await FlockClient.get_instance().config.get_game_config_by_name("difficulty")
        print("Difficulty: ", config)
)
```

## Requirements

- Godot 4.2+ (tested on 4.7.1)
- Internet connection for backend calls
- A [Qwacks](https://qwacks.com) game account

## Links

- [GitHub Repository](https://github.com/unofficial-qwacks-godot-sdk/qwacks-godot-sdk)
- [Qwacks Platform](https://qwacks.com)
- [Full API Reference](api-reference.md)
