class_name FlockAssetCache
extends RefCounted

const CACHE_EXT := ".cache"
const TMP_EXT := ".tmp"

var directory: String
var max_size_bytes: int

func _init(cache_dir: String = "", max_size_mb: int = 100) -> void:
	directory = cache_dir if not cache_dir.is_empty() else FlockUtil.flock_assets_dir()
	max_size_bytes = max_size_mb * 1024 * 1024 if max_size_mb > 0 else 0
	FlockUtil.ensure_dir(directory)


func try_get_cached_file_url(asset_id: String, updated_at: String) -> String:
	var path := _cache_path(asset_id, updated_at)
	if FileAccess.file_exists(path):
		return "file://" + path
	return ""


func write(asset_id: String, updated_at: String, data: PackedByteArray) -> void:
	FlockUtil.ensure_dir(directory)
	var path := _cache_path(asset_id, updated_at)
	var tmp_path := path + TMP_EXT

	# Delete old versions of same asset
	_delete_old_versions(asset_id, updated_at)

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_buffer(data)
	file.close()

	# Atomic move
	var dir := DirAccess.open(directory)
	if dir:
		if FileAccess.file_exists(path):
			dir.remove(path.get_file())
		dir.rename(tmp_path.get_file(), path.get_file())

	_trim_cache()


func _cache_path(asset_id: String, updated_at: String) -> String:
	var safe_updated := updated_at.replace(":", "-").replace(" ", "_")
	return directory.path_join("%s_%s%s" % [asset_id, safe_updated, CACHE_EXT])


func _delete_old_versions(asset_id: String, except_updated: String) -> void:
	var dir := DirAccess.open(directory)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.begins_with(asset_id + "_") and file_name.ends_with(CACHE_EXT):
			if file_name.find(except_updated.replace(":", "-").replace(" ", "_")) < 0:
				dir.remove(file_name)
		file_name = dir.get_next()


func _trim_cache() -> void:
	if max_size_bytes <= 0:
		return

	var files := _list_cache_files()
	var total_size := 0
	for f in files:
		var file := FileAccess.open(f, FileAccess.READ)
		if file:
			total_size += file.get_length()
			file.close()

	if total_size <= max_size_bytes:
		return

	# Sort by access time (oldest first) and evict
	files.sort()
	for f: String in files:
		if total_size <= max_size_bytes:
			break
		var file := FileAccess.open(f, FileAccess.READ)
		if file:
			total_size -= file.get_length()
			file.close()
		var dir := DirAccess.open(f.get_base_dir())
		if dir:
			dir.remove(f.get_file())


func _list_cache_files() -> Array:
	var files := []
	var dir := DirAccess.open(directory)
	if dir == null:
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(CACHE_EXT):
			files.append(directory.path_join(file_name))
		file_name = dir.get_next()
	return files


func clear() -> void:
	for f in _list_cache_files():
		var dir := DirAccess.open(f.get_base_dir())
		if dir:
			dir.remove(f.get_file())
