class_name FlockConsentStore

const PREF_KEY_CONSENT_GRANTED := "flock_analytics_consent"
const PREF_KEY_CONSENT_SET := "flock_analytics_consent_set"
const CONFIG_PATH := "user://flock_consent.cfg"

func load_consent() -> Variant:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return null
	if config.get_value("flock", PREF_KEY_CONSENT_SET, 0) == 0:
		return null
	return config.get_value("flock", PREF_KEY_CONSENT_GRANTED, 0) == 1


func save_consent(granted: bool) -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value("flock", PREF_KEY_CONSENT_SET, 1)
	config.set_value("flock", PREF_KEY_CONSENT_GRANTED, 1 if granted else 0)
	config.save(CONFIG_PATH)


func clear() -> void:
	var config := ConfigFile.new()
	config.load(CONFIG_PATH)
	config.erase_section("flock")
	config.save(CONFIG_PATH)
