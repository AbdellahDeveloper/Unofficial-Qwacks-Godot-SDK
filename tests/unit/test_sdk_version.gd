extends GutTest


func test_version_is_non_empty_semver() -> void:
	assert_false(FlockSdkVersion.CURRENT.is_empty(), "version non-empty")
	assert_true(FlockSdkVersion.CURRENT.is_valid_identifier() or FlockSdkVersion.CURRENT.contains("."), "version looks like semver")


func test_version_matches_plugin_cfg() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load("res://addons/flock_sdk/plugin.cfg")
	assert_eq(err, OK, "plugin.cfg loads")
	assert_eq(str(cfg.get_value("plugin", "version", "")), FlockSdkVersion.CURRENT, "plugin version matches SDK version string")