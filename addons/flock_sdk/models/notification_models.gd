class_name NotificationModels

# Channels to deliver on — combine with |. None sends nothing and lets the template's own channels apply.
const CHANNEL_NONE := 0
const CHANNEL_IN_APP := 1
const CHANNEL_EMAIL := 2
const CHANNEL_PUSH := 4

# Schedule states the server reports. Strings rather than an enum so a state added later can't break deserialization.
const STATUS_PENDING := "pending"
const STATUS_DELIVERED := "delivered"
const STATUS_CANCELED := "canceled"

# Platforms the push backend accepts a device token for. There is no desktop value — PC/Mac/Linux cannot receive push at all.
const PLATFORM_ANDROID := 0
const PLATFORM_IOS := 1
const PLATFORM_WEB := 2

# Wire values for the channel flags. Mapped explicitly rather than via ToString() so casing can't drift with the caller's locale.
static func channels_to_wire(channels: int) -> Array:
	if channels == CHANNEL_NONE:
		return []
	var wire := []
	if channels & CHANNEL_IN_APP:
		wire.append("in_app")
	if channels & CHANNEL_EMAIL:
		wire.append("email")
	if channels & CHANNEL_PUSH:
		wire.append("push")
	return wire

# Wire value for a device platform. Mapped explicitly rather than via ToString() so casing can't drift with the caller's locale.
static func platform_to_wire(platform: int) -> String:
	match platform:
		PLATFORM_ANDROID:
			return "android"
		PLATFORM_WEB:
			return "web"
		_:
			return "ios"

# Convenience over read_at — the API has no separate read flag.
static func notification_is_read(data: Dictionary) -> bool:
	return not str(data.get("read_at", "")).is_empty()

# Reads one data entry, returning fallback when it's absent or the wrong shape.
static func notification_get_data(data: Dictionary, key: String, fallback: Variant = null) -> Variant:
	var entry: Dictionary = data.get("data", {}) if data.has("data") else {}
	if not entry.has(key):
		return fallback
	return entry[key]

# Reads one data entry as an int.
static func notification_get_data_int(data: Dictionary, key: String, fallback: int = 0) -> int:
	var value = notification_get_data(data, key, null)
	if value == null:
		return fallback
	if value is int:
		return value
	if value is float:
		return int(value)
	if value is String:
		if value.is_valid_int():
			return int(value)
	return fallback