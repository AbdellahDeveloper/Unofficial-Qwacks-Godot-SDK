extends GutTest

var _base_dir: String = ""


func before_each() -> void:
	_base_dir = OS.get_temp_dir().path_join("flocktest_gut_%d" % Time.get_ticks_msec())


func test_permanent_failure_classifier() -> void:
	assert_eq(FlockCommandProvider._is_permanent_failure({}), false, "cmd -1 offline")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 401, "error": "e"}), false, "cmd 401 relogin")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 403, "error": "e"}), false, "cmd 403 bare")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 403, "code": "ban", "error": "e"}), true, "cmd 403 coded")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 400, "error": "e"}), true, "cmd 400 bad req")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 404, "error": "e"}), true, "cmd 404")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 408, "error": "e"}), false, "cmd 408 timeout")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 429, "error": "e"}), false, "cmd 429 rate")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 500, "error": "e"}), false, "cmd 500 server")
	assert_eq(FlockCommandProvider._is_permanent_failure({"status_code": 200}), false, "cmd 200 ok")


func test_pending_write_round_trip() -> void:
	var w := PendingDataWrite.new("cmd/update", "{\"player_data_id\":\"r1\"}", "Update player data")
	assert_eq(w.attempts, 0, "write attempts default")
	w.attempts = 47
	var w2 := PendingDataWrite.deserialize(w.serialize())
	assert_eq(w2.attempts, 47, "write attempts roundtrip")
	assert_eq(w2.path, "cmd/update", "write path roundtrip")
	assert_eq(w2.payload_json, "{\"player_data_id\":\"r1\"}", "write payload roundtrip")


func test_snapshot_store_write_and_readback() -> void:
	var store := FlockSnapshotStore.new(_base_dir, GodotFlockLogger.new())
	var wrote: bool = store.write("ver1/command/p1", "pending_writes", [{"path": "a"}, {"path": "b"}])
	assert_eq(wrote, true, "store write returns true")
	var read_back = store.try_read("ver1/command/p1", "pending_writes")
	assert_eq(read_back.size(), 2, "store readback size")
	assert_eq(read_back[1]["path"], "b", "store readback item")


func test_event_cache_classifier() -> void:
	var cache := _new_cache("events")
	assert_eq(cache._outcome_is_permanent({}), false, "cache -1 offline")
	assert_eq(cache._outcome_is_permanent({"status_code": 401, "error": "e"}), false, "cache 401")
	assert_eq(cache._outcome_is_permanent({"status_code": 403, "error": "e"}), false, "cache 403 bare")
	assert_eq(cache._outcome_is_permanent({"status_code": 403, "code": "ban", "error": "e"}), true, "cache 403 coded")
	assert_eq(cache._outcome_is_permanent({"status_code": 400, "error": "e"}), true, "cache 400")
	assert_eq(cache._outcome_is_permanent({"status_code": 408, "error": "e"}), false, "cache 408 timeout")
	assert_eq(cache._outcome_is_permanent({"status_code": 429, "error": "e"}), false, "cache 429 rate")
	assert_eq(cache._outcome_is_permanent({"status_code": 500, "error": "e"}), false, "cache 500 server")


func test_event_cache_enqueue_and_clear() -> void:
	var cache := _new_cache("events")
	assert_eq(cache.enqueue({}), "", "enqueue empty handle")
	var h1 := cache.enqueue({"name": "a"})
	cache.enqueue({"name": "b"})
	assert_eq(h1.is_empty(), false, "enqueue handle non-empty")
	assert_eq(cache.pending_count, 2, "enqueue pending count")
	var epoch_before := cache._epoch
	cache.clear()
	assert_eq(cache.pending_count, 0, "clear zeroes pending")
	assert_eq(cache._epoch, epoch_before + 1, "clear bumps epoch")
	assert_eq(FileAccess.file_exists(h1), false, "clear removed files")


func test_epoch_guard_stops_after_clear() -> void:
	var cache := _new_cache("events_epoch")
	cache.enqueue({"name": "x"})
	cache.enqueue({"name": "y"})
	await cache.flush_async(func(events: Array, _ct) -> Variant:
		cache.clear()
		return "ok"
	)
	assert_eq(cache.pending_count, 0, "epoch guard stops after clear")


func test_flush_ok_drops_batch() -> void:
	var cache := _new_cache("outcome_ok")
	cache.enqueue({"name": "a"})
	cache.enqueue({"name": "b"})
	await cache.flush_async(func(events: Array, _ct) -> Variant:
		return "ok"
	)
	assert_eq(cache.pending_count, 0, "flush ok drops batch")


func test_flush_defer_keeps_batch() -> void:
	var cache := _new_cache("outcome_defer")
	cache.enqueue({"name": "a"})
	cache.enqueue({"name": "b"})
	await cache.flush_async(func(events: Array, _ct) -> Variant:
		return "defer"
	)
	assert_eq(cache.pending_count, 2, "flush defer keeps batch")


func test_flush_permanent_drops_batch() -> void:
	var cache := _new_cache("outcome_perm")
	cache.enqueue({"name": "a"})
	await cache.flush_async(func(events: Array, _ct) -> Variant:
		return {"error": "bad", "status_code": 400}
	)
	assert_eq(cache.pending_count, 0, "flush permanent drops batch")


func test_flush_transient_keeps_batch() -> void:
	var cache := _new_cache("outcome_trans")
	cache.enqueue({"name": "a"})
	await cache.flush_async(func(events: Array, _ct) -> Variant:
		return {"error": "unauth", "status_code": 401}
	)
	assert_eq(cache.pending_count, 1, "flush transient keeps batch")


func test_session_snapshot_round_trip() -> void:
	var snap := FlockSessionSnapshot.new()
	snap.session_id = "s1"
	snap.server_session_id = "ss1"
	snap.player_id = "p1"
	snap.start_time_utc = "2026-01-01T00:00:00Z"
	snap.end_time_utc = "2026-01-01T00:01:00Z"
	snap.duration_seconds = 60.0
	snap.screens_viewed = 3
	snap.is_bounce = false
	snap.device_info = {"platform": "Windows", "device_type": "Desktop"}
	var snap2 := FlockSessionSnapshot.deserialize(snap.serialize())
	assert_eq(snap2.session_id, "s1", "snap id")
	assert_eq(snap2.server_session_id, "ss1", "snap server id")
	assert_eq(snap2.player_id, "p1", "snap player id")
	assert_eq(snap2.duration_seconds, 60.0, "snap duration")
	assert_eq(snap2.screens_viewed, 3, "snap screens")
	assert_eq(snap2.device_info["platform"], "Windows", "snap device platform")


func _new_cache(tag: String) -> FlockEventCache:
	return FlockEventCache.new(_base_dir, tag, 100, 10, NullFlockLogger.new())