class_name FlockSnapshotStore
extends RefCounted

var _directory: String
var _logger: FlockLogger

func _init(directory: String = "", logger: FlockLogger = null) -> void:
	_directory = directory if not directory.is_empty() else FlockUtil.flock_snapshots_dir()
	_logger = logger
	FlockUtil.ensure_dir(_directory)


func prune_other_versions(current_version_id: String) -> void:
	var dir := DirAccess.open(_directory)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			if file_name != current_version_id:
				_delete_dir_recursive(_directory.path_join(file_name))
		file_name = dir.get_next()


func try_read(scope: String, key: String) -> Variant:
	var path := _snapshot_path(scope, key)
	if not FileAccess.file_exists(path):
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var json_text := file.get_as_text()
	file.close()
	return JSON.parse_string(json_text)


func write(scope: String, key: String, value: Variant) -> bool:
	FlockUtil.ensure_dir(_snapshot_path(scope, key).get_base_dir())
	var file := FileAccess.open(_snapshot_path(scope, key), FileAccess.WRITE)
	if file == null:
		_logger.log_warning("Failed to write snapshot: %s/%s" % [scope, key])
		return false
	file.store_string(JSON.stringify(value))
	file.close()
	return true


func delete_scope(scope: String) -> void:
	var dir_path := _directory.path_join(scope)
	_delete_dir_recursive(dir_path)


# Clears a scope except keys starting with one of these prefixes - a scope is shared by every player, so
# per-player state can't survive a plain delete_scope. Keys are "{key}.json".
func delete_scope_except(scope: String, keep_key_prefixes: Array) -> void:
	var dir := DirAccess.open(_directory.path_join(scope))
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var preserve := false
		for prefix in keep_key_prefixes:
			if file_name.begins_with(str(prefix)):
				preserve = true
				break
		if not preserve and dir.current_is_dir() == false:
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()


func _snapshot_path(scope: String, key: String) -> String:
	return _directory.path_join(scope).path_join(key + ".json")


func _delete_dir_recursive(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue
		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			_delete_dir_recursive(full_path)
		else:
			dir.remove(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)
