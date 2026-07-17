# Game Config

The `config` provider manages remote game configurations and patches.

## Access

```gdscript
var config = FlockClient.get_instance().config
```

## Get All Patches

Fetch all game configuration patches:

```gdscript
var result = await FlockClient.get_instance().config.get_all_patches()

if result is Array:
    for patch in result:
        print("Patch ID: ", patch.get("id", ""))
        print("Config ID: ", patch.get("config_id", ""))
        print("Data: ", patch.get("data", []))
```

## Get Config by Name

```gdscript
var result = await FlockClient.get_instance().config.get_game_config_by_name("difficulty")

if result is Dictionary:
    print("Config: ", result)
```

## Get Config by ID

```gdscript
var result = await FlockClient.get_instance().config.get_by_config_id("CONFIG_ID")

if result is Dictionary:
    print("Config data: ", result)
```

## Get Patches by Schema

```gdscript
var result = await FlockClient.get_instance().config.get_by_schema("SCHEMA_ID")

if result is Array:
    for patch in result:
        print("Patch: ", patch)
```

## Cache Management

Clear the config cache:

```gdscript
FlockClient.get_instance().config.clear_cache()
```

## Common Patterns

### Get Difficulty Settings

```gdscript
func get_difficulty_settings() -> Dictionary:
    var config = await FlockClient.get_instance().config.get_game_config_by_name("difficulty")
    if config is Dictionary:
        return config
    return {"easy": true, "enemies": 5}
```

### Get Feature Flags

```gdscript
func is_feature_enabled(feature_name: String) -> bool:
    var config = await FlockClient.get_instance().config.get_game_config_by_name("features")
    if config is Dictionary:
        return config.get(feature_name, false)
    return false
```

### Get Level Config

```gdscript
func get_level_config(level: int) -> Dictionary:
    var config = await FlockClient.get_instance().config.get_game_config_by_name("levels")
    if config is Dictionary:
        var levels = config.get("levels", [])
        if level <= levels.size():
            return levels[level - 1]
    return {}
```

## Config Structure

Game configs from the API look like:

```json
{
    "id": "01KXYZ...",
    "name": "difficulty",
    "data": {
        "easy": {
            "enemy_speed": 0.5,
            "player_health": 200,
            "damage_multiplier": 0.5
        },
        "normal": {
            "enemy_speed": 1.0,
            "player_health": 100,
            "damage_multiplier": 1.0
        },
        "hard": {
            "enemy_speed": 1.5,
            "player_health": 75,
            "damage_multiplier": 1.5
        }
    }
}
```
