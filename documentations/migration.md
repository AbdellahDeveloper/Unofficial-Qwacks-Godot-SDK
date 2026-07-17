# Migration from C# Unity SDK

This guide helps you migrate from the official C# Unity SDK to this Godot GDScript port.

## Key Differences

| Aspect | C# Unity SDK | Godot GDScript SDK |
|--------|--------------|-------------------|
| Language | C# | GDScript |
| Engine | Unity | Godot 4.x |
| Async | `async/await` | `await` with signals |
| Error handling | Exceptions | Dictionary `{error: "..."}` |
| Storage | PlayerPrefs | ConfigFile |
| HTTP | UnityWebRequest | HTTPRequest |
| JSON | Newtonsoft.Json | JSON.parse_string() |
| Config | FlockSDKSettings.asset | Inspector @export |

## Initialization

### C# (Unity)

```csharp
// In FlockSettings MonoBehaviour
FlockSDK.Initialize(settings);
```

### GDScript (Godot)

```gdscript
# Option 1: Use FlockAutoInitializer node (Inspector)
# Option 2: Code
var config = FlockInitConfig.new()
config.game_id = "YOUR_GAME_ID"
config.game_version_id = "YOUR_VERSION_ID"
config.api_key = "YOUR_API_KEY"
config.api_url = "https://api-flock.qwacks.com"
FlockClient.get_instance().create(config)
```

## Authentication

### C# (Unity)

```csharp
var result = await FlockClient.Instance.Auth.LoginWithDevice();
if (result.IsSuccess)
{
    Debug.Log($"Player: {result.Data.PlayerId}");
}
```

### GDScript (Godot)

```gdscript
var result = await FlockClient.get_instance().auth.login_with_device()
if result is Dictionary and not result.has("error"):
    print("Player: ", FlockClient.get_instance().current_player_id)
```

## Error Handling

### C# (Unity)

```csharp
try
{
    var result = await FlockClient.Instance.Config.GetGameConfigByName("settings");
}
catch (FlockException ex)
{
    Debug.LogError($"Error: {ex.Message}");
}
```

### GDScript (Godot)

```gdscript
var result = await FlockClient.get_instance().config.get_game_config_by_name("settings")
if result is Dictionary and result.has("error"):
    print("Error: ", result["error"])
```

## Events

### C# (Unity)

```csharp
FlockClient.Instance.OnAuthenticated += (sender, args) => {
    Debug.Log($"Player: {args.PlayerId}");
};
```

### GDScript (Godot)

```gdscript
FlockEvents.get_instance().authenticated.connect(func(info: Dictionary):
    print("Player: ", info["player_id"])
)
```

## Player Data

### C# (Unity)

```csharp
var data = await FlockClient.Instance.Player.GetMyDataByTagAsync("currency");
```

### GDScript (Godot)

```gdscript
var data = await FlockClient.get_instance().player.get_my_data_by_tag_async("currency")
```

## Shop

### C# (Unity)

```csharp
var result = await FlockClient.Instance.Shop.PurchaseAsync(itemId);
```

### GDScript (Godot)

```gdscript
var result = await FlockClient.get_instance().shop.purchase_async(itemId)
```

## Analytics

### C# (Unity)

```csharp
FlockClient.Instance.Analytics.LogEvent("level_complete", new Dictionary<string, object> {
    { "level", 5 }
});
```

### GDScript (Godot)

```gdscript
FlockClient.get_instance().analytics.log_event("level_complete", {"level": 5})
```

## Token Management

### C# (Unity)

```csharp
var isExpired = FlockClient.Instance.IsTokenExpired;
var playerId = FlockClient.Instance.CurrentPlayerId;
```

### GDScript (Godot)

```gdscript
var is_expired = FlockClient.get_instance().is_token_expired
var player_id = FlockClient.get_instance().current_player_id
```

## Config

### C# (Unity)

```csharp
var config = FlockSDKSettings.Instance;
```

### GDScript (Godot)

```gdscript
# Use FlockAutoInitializer Inspector properties
# Or FlockInitConfig in code
var game_id = FlockClient.get_instance().game_id
var version_id = FlockClient.get_instance().game_version_id
```

## Offline Support

Both SDKs support offline operations:

- **C# Unity**: Uses PlayerPrefs and file I/O
- **GDScript Godot**: Uses ConfigFile and FileAccess

The offline queue behavior is identical — writes queue when offline and auto-flush on reconnect.

## Migration Checklist

1. **Remove C# SDK** from Unity project
2. **Copy `addons/flock_sdk/`** to Godot project
3. **Enable plugin** in Project Settings
4. **Add `FlockAutoInitializer`** to root scene
5. **Configure** game ID, version ID, and API key
6. **Update auth calls** — use `await` with Dictionary results
7. **Update error handling** — check `result.has("error")`
8. **Update events** — use `FlockEvents.get_instance()` signals
9. **Test offline behavior** — queue should work same as Unity
10. **Verify analytics** — sessions and events should track

## API Mapping

| C# Method | GDScript Method |
|-----------|-----------------|
| `FlockClient.Instance` | `FlockClient.get_instance()` |
| `FlockClient.Instance.Auth` | `FlockClient.get_instance().auth` |
| `FlockClient.Instance.Player` | `FlockClient.get_instance().player` |
| `FlockClient.Instance.Config` | `FlockClient.get_instance().config` |
| `FlockClient.Instance.Game` | `FlockClient.get_instance().game` |
| `FlockClient.Instance.Shop` | `FlockClient.get_instance().shop` |
| `FlockClient.Instance.Asset` | `FlockClient.get_instance().asset` |
| `FlockClient.Instance.Commands` | `FlockClient.get_instance().commands` |
| `FlockClient.Instance.Analytics` | `FlockClient.get_instance().analytics` |
| `FlockClient.Instance.CurrentPlayerId` | `FlockClient.get_instance().current_player_id` |
| `FlockClient.Instance.IsAuthenticated` | `FlockClient.get_instance().is_authenticated` |
| `FlockClient.Instance.IsTokenExpired` | `FlockClient.get_instance().is_token_expired` |
