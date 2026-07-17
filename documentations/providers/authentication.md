# Authentication

The `auth` provider handles player authentication, registration, and session management.

## Access

```gdscript
var auth = FlockClient.get_instance().auth
```

## Login Methods

### Device Login (Recommended for quick testing)

Auto-registers on first use:

```gdscript
var result = await FlockClient.get_instance().auth.login_with_device()

if result is Dictionary and not result.has("error"):
    var player_id = FlockClient.get_instance().current_player_id
    print("Logged in as: ", player_id)
else:
    print("Error: ", result.get("error", ""))
```

Device login uses `OS.get_unique_id()` for identification. On first use, the player is auto-registered. On subsequent uses, they're logged in automatically.

### Email Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_email(
    "player@example.com",
    "secure_password_123"
)
```

### Google Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_google(id_token)
```

### Apple Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_apple(identity_token)
```

### Steam Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_steam(session_ticket)
```

### Facebook Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_facebook(facebook_id)
```

### Discord Login

```gdscript
var result = await FlockClient.get_instance().auth.login_with_discord(discord_id)
```

## Registration Methods

### Email Registration

```gdscript
var result = await FlockClient.get_instance().auth.register_with_email(
    "player@example.com",
    "secure_password_123",
    "PlayerName"  # Optional display name
)
```

### Device Registration

```gdscript
var device_id = FlockClient.get_instance().auth._get_or_create_device_id()
var result = await FlockClient.get_instance().auth.register_with_device(device_id, "PlayerName")
```

### Other Registration Methods

```gdscript
# Google
var result = await FlockClient.get_instance().auth.register_with_google(id_token, "Name")

# Apple
var result = await FlockClient.get_instance().auth.register_with_apple(identity_token, "Name")

# Steam
var result = await FlockClient.get_instance().auth.register_with_steam(session_ticket, "Name")
```

## Account Management

### Check Name Availability

```gdscript
var result = await FlockClient.get_instance().auth.is_name_available("CoolGamer123")
# result: true or false
```

### Forgot Password

```gdscript
var result = await FlockClient.get_instance().auth.forgot_password("player@example.com")
```

### Reset Password

```gdscript
var result = await FlockClient.get_instance().auth.reset_password(
    "player@example.com",
    "verification_code",
    "new_secure_password"
)
```

### Email Verification

```gdscript
# Send verification email
var result = await FlockClient.get_instance().auth.send_email_verification()

# Verify with code
var result = await FlockClient.get_instance().auth.verify_email("123456")
```

### Revoke Token

```gdscript
var result = await FlockClient.get_instance().auth.revoke_token()
```

## Logout

```gdscript
FlockClient.get_instance().auth.logout()
```

This clears all tokens and fires the `logged_out` event.

## Session Restore

On app restart, the SDK automatically restores the previous session:

```gdscript
# The SDK attempts session restore during initialization
FlockEvents.get_instance().session_restored.connect(func(restored: bool):
    if restored:
        print("Previous session restored!")
        print("Player: ", FlockClient.get_instance().current_player_id)
    else:
        print("No previous session found")
)
```

You can also manually attempt restore:

```gdscript
var restored = await FlockClient.get_instance().auth.try_restore_session()
```

## Authentication State

Check the current authentication state:

```gdscript
var client = FlockClient.get_instance()

# Is the player authenticated?
print(client.is_authenticated)  # true/false

# Get current player ID
print(client.current_player_id)  # "01KXYZ..."

# Is the token expired?
print(client.is_token_expired)  # true/false

# Get token claims
print(client.token_claims)  # Dictionary with JWT claims
```

## Token Refresh

Tokens are refreshed automatically. You can listen for refresh events:

```gdscript
FlockEvents.get_instance().token_refreshed.connect(func():
    print("Token refreshed!")
)

FlockEvents.get_instance().auth_expired.connect(func():
    print("Auth expired — please re-login")
)
```

## Handling Auth Results

All auth methods return a `Variant`:
- **Success**: `Dictionary` with `access_token`, `refresh_token`, etc.
- **Failure**: `Dictionary` with `error` key

```gdscript
var result = await FlockClient.get_instance().auth.login_with_device()

if result is Dictionary:
    if result.has("error"):
        # Login failed
        print("Error: ", result["error"])
        print("Code: ", result.get("code", ""))
    else:
        # Login succeeded
        print("Player ID: ", FlockClient.get_instance().current_player_id)
```

## Error Codes

| Code | Description |
|------|-------------|
| `player.invalid_login_credentials` | Wrong email/password or device not registered |
| `player.device_already_registered` | Device ID already in use |
| `player.email_already_registered` | Email already in use |
| `player.name_not_available` | Display name is taken |
| `player.invalid_verification_code` | Wrong email verification code |
| `player.token_expired` | JWT token has expired |
| `player.token_revoked` | Token was revoked |

## Full Example

```gdscript
extends Control

func _ready():
    FlockEvents.get_instance().authenticated.connect(_on_authenticated)
    FlockEvents.get_instance().auth_expired.connect(_on_expired)
    
    # Try restore previous session
    if FlockClient.get_instance().is_authenticated:
        _on_authenticated({"player_id": FlockClient.get_instance().current_player_id})

func _on_authenticated(info: Dictionary):
    print("Logged in: ", info["player_id"], " via ", info["method"])

func _on_expired():
    print("Session expired!")

func _on_device_login_pressed():
    var result = await FlockClient.get_instance().auth.login_with_device()
    if result is Dictionary and result.has("error"):
        print("Login failed: ", result["error"])

func _on_email_login_pressed():
    var email = "player@example.com"
    var password = "my_password"
    var result = await FlockClient.get_instance().auth.login_with_email(email, password)
    if result is Dictionary and result.has("error"):
        print("Login failed: ", result["error"])

func _on_logout_pressed():
    FlockClient.get_instance().auth.logout()
```
