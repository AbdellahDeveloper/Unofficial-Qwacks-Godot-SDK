class_name FlockDeviceInfo

static func capture() -> Dictionary:
	return {
		"platform": OS.get_name(),
		"operating_system": OS.get_version(),
		"device_model": OS.get_model_name(),
		"device_type": _get_device_type(),
		"app_version": ProjectSettings.get_setting("application/config/version", ""),
		"screen_width": DisplayServer.window_get_size().x,
		"screen_height": DisplayServer.window_get_size().y,
		"system_language": OS.get_locale(),
		"system_memory_mb": OS.get_memory_info().get("physical", 0) / 1024 / 1024,
		"sdk_version": FlockSdkVersion.CURRENT,
	}

static func _get_device_type() -> String:
	match OS.get_name():
		"Windows", "Linux", "macOS":
			return "Desktop"
		"Android", "iOS":
			return "Mobile"
		"Web":
			return "Web"
		_:
			return "Unknown"
