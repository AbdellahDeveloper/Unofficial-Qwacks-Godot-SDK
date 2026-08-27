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
	if DirAccess.dir_exists_absolute(path):
		return
	DirAccess.make_dir_recursive_absolute(path)
