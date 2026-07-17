class_name FlockUtil

const API_VERSION := "v1"

static func flock_data_dir() -> String:
	return OS.get_user_data_dir().path_join("Flock")

static func flock_snapshots_dir() -> String:
	return flock_data_dir().path_join("snapshots")

static func flock_assets_dir() -> String:
	return flock_data_dir().path_join("flock_assets")

static func flock_token_access_path() -> String:
	return flock_data_dir().path_join("access_token")

static func flock_token_refresh_path() -> String:
	return flock_data_dir().path_join("refresh_token")

static func ensure_dir(path: String) -> void:
	var dir := DirAccess.open(path.get_base_dir())
	if dir and not dir.dir_exists(path.get_file()):
		dir.make_dir_recursive(path)
