class_name FlockConfigFileTokenStore
extends FlockTokenStore

const CONFIG_SECTION := "flock_tokens"
const ACCESS_KEY := "access_token"
const REFRESH_KEY := "refresh_token"

var _config_path: String

func _init(config_path: String = "") -> void:
	if config_path.is_empty():
		_config_path = FlockUtil.flock_data_dir().path_join("tokens.cfg")
	else:
		_config_path = config_path
	FlockUtil.ensure_dir(_config_path)


func save_tokens(access_token: String, refresh_token: String) -> void:
	var config := ConfigFile.new()
	config.set_value(CONFIG_SECTION, ACCESS_KEY, access_token)
	config.set_value(CONFIG_SECTION, REFRESH_KEY, refresh_token)
	config.save(_config_path)


func load_tokens() -> Dictionary:
	var config := ConfigFile.new()
	if config.load(_config_path) != OK:
		return {}
	var access: String = config.get_value(CONFIG_SECTION, ACCESS_KEY, "")
	var refresh: String = config.get_value(CONFIG_SECTION, REFRESH_KEY, "")
	if access.is_empty():
		return {}
	return {"access_token": access, "refresh_token": refresh}


func clear() -> void:
	var config := ConfigFile.new()
	if config.load(_config_path) == OK:
		config.erase_section(CONFIG_SECTION)
		config.save(_config_path)
	elif FileAccess.file_exists(_config_path):
		DirAccess.remove_absolute(_config_path)
