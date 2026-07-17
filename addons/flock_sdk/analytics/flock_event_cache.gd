class_name FlockEventCache

const EXTENSION := ".evt"
const TMP_EXTENSION := ".evt.tmp"

var _directory: String
var _max_events: int
var _batch_size: int
var _logger: FlockLogger
var _flushing := false
var _pending_count := 0

func _init(directory: String, subfolder: String, max_events: int, batch_size: int, logger: FlockLogger) -> void:
	_directory = directory.path_join(subfolder)
	_max_events = maxi(1, max_events)
	_batch_size = maxi(1, batch_size)
	_logger = logger
	FlockUtil.ensure_dir(_directory)
	_pending_count = _sweep_stale_temp_files()


var pending_count: int:
	get:
		return _pending_count


func enqueue(evt: Dictionary) -> String:
	if evt.is_empty():
		return ""

	var name := "%d_%s" % [Time.get_ticks_msec(), str(randi())]
	var final_path := _directory.path_join(name + EXTENSION)
	var tmp_path := _directory.path_join(name + TMP_EXTENSION)

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return ""
	file.store_string(JSON.stringify(evt))
	file.close()

	# Atomic rename
	var dir := DirAccess.open(_directory)
	if dir:
		dir.rename(name + TMP_EXTENSION, name + EXTENSION)
		_pending_count += 1
		_trim_oldest()
		return final_path

	return ""


func remove(handle: String) -> void:
	if handle.is_empty():
		return
	var dir := DirAccess.open(handle.get_base_dir())
	if dir and FileAccess.file_exists(handle):
		dir.remove(handle.get_file())
		_pending_count = maxi(0, _pending_count - 1)


func flush_async(sender: Callable) -> void:
	if sender == null or _flushing:
		return
	_flushing = true

	var ct := {}

	while true:
		var batch := _read_batch()
		if batch.is_empty():
			break

		var events := []
		for item: Dictionary in batch:
			events.append(item.get("event", {}))

		var result = await sender.call(events, ct)
		if result is String and result == "defer":
			break

		_drop_batch(batch)

	_flushing = false


func clear() -> void:
	for path in _enumerate_files():
		var dir := DirAccess.open(path.get_base_dir())
		if dir:
			dir.remove(path.get_file())
	_pending_count = 0


func _read_batch() -> Array:
	var batch := []
	for path in _enumerate_files():
		if batch.size() >= _batch_size:
			break
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			file.close()
			var parsed = JSON.parse_string(json_text)
			if parsed is Dictionary:
				batch.append({"path": path, "event": parsed})
	return batch


func _drop_batch(batch: Array) -> void:
	for item: Dictionary in batch:
		var path: String = item.get("path", "")
		if not path.is_empty():
			var dir := DirAccess.open(path.get_base_dir())
			if dir and FileAccess.file_exists(path):
				dir.remove(path.get_file())
				_pending_count = maxi(0, _pending_count - 1)


func _trim_oldest() -> void:
	var files := _enumerate_files()
	if files.size() <= _max_events:
		return
	files.sort()
	var overflow := files.size() - _max_events
	for i in range(overflow):
		var dir := DirAccess.open(files[i].get_base_dir())
		if dir:
			dir.remove(files[i].get_file())
			_pending_count = maxi(0, _pending_count - 1)


func _sweep_stale_temp_files() -> int:
	var count := 0
	var dir := DirAccess.open(_directory)
	if dir == null:
		return 0
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(TMP_EXTENSION):
			dir.remove(file_name)
		elif file_name.ends_with(EXTENSION):
			count += 1
		file_name = dir.get_next()
	return count


func _enumerate_files() -> Array:
	var files := []
	var dir := DirAccess.open(_directory)
	if dir == null:
		return files
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(EXTENSION):
			files.append(_directory.path_join(file_name))
		file_name = dir.get_next()
	return files
